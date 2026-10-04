#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }
<#
    Pester tests for winget-install.ps1

    The script runs its installation logic as soon as it is loaded, so these tests never
    dot-source it. Instead they extract every function definition with the PowerShell parser
    and load those into the test scope. Nothing here touches the real PATH, installs anything,
    changes ACLs outside the test drive, or calls the network.

    Functions that call 'exit' (UpdateSelf, CheckForUpdate) run inside a background job so an
    exit cannot end the Pester run.

    Run from the repository root:
        Invoke-Pester -Path .\tests

    Windows PowerShell 5.1 ships Pester 3.4, so import a newer one first:
        Import-Module Pester -MinimumVersion 5.0; Invoke-Pester -Path .\tests
#>

BeforeAll {
    $script:ScriptPath = (Resolve-Path (Join-Path $PSScriptRoot '..\winget-install.ps1')).Path
    $script:ScriptContent = Get-Content -Path $script:ScriptPath -Raw

    $tokens = $null
    $parseErrors = $null
    $script:Ast = [System.Management.Automation.Language.Parser]::ParseFile($script:ScriptPath, [ref]$tokens, [ref]$parseErrors)
    $script:ParseErrors = $parseErrors

    function Get-ScriptFunctionText {
        # Returns the source text of the named functions (or all functions) from the script
        param([string[]]$Name)
        $defs = $script:Ast.FindAll({ param($node)
                $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                (-not $Name -or $node.Name -in $Name) }, $true)
        return ($defs | ForEach-Object { $_.Extent.Text }) -join "`n`n"
    }

    function Invoke-Isolated {
        # Runs $Body in a background job with the named script functions loaded. Used for
        # functions that call 'exit', which would otherwise terminate this Pester run.
        param([string[]]$Functions, [scriptblock]$Body)
        $text = Get-ScriptFunctionText -Name $Functions
        Start-Job -ScriptBlock {
            param($text, $body)
            . ([scriptblock]::Create($text))
            . ([scriptblock]::Create($body))
        } -ArgumentList $text, $Body.ToString() | Receive-Job -Wait -AutoRemoveJob
    }

    # Stubs for Appx cmdlets so nothing real is installed and mocks have a command to attach to
    function Get-AppxPackage { [CmdletBinding()] param($Name, [switch]$AllUsers) }
    function Add-AppxPackage { [CmdletBinding()] param($Path, [switch]$RegisterByFamilyName, $MainPackage) }
    function Add-ProvisionedAppxPackage { [CmdletBinding()] param([switch]$Online, [switch]$SkipLicense, $PackagePath) }
    function Add-AppxProvisionedPackage { [CmdletBinding()] param([switch]$Online, $PackagePath, $LicensePath) }
    function Get-PackageProvider { [CmdletBinding()] param($Name, [switch]$ListAvailable) }
    function Install-PackageProvider { [CmdletBinding()] param($Name, [switch]$Force, [switch]$ForceBootstrap) }

    # Load every function from the script without running the script body
    . ([scriptblock]::Create((Get-ScriptFunctionText)))

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    function New-TestZip {
        # Creates a zip at $Path from a hashtable of entryName = content
        param([string]$Path, [hashtable]$Entries)
        $zip = [System.IO.Compression.ZipFile]::Open($Path, 'Create')
        try {
            foreach ($name in $Entries.Keys) {
                $writer = New-Object System.IO.StreamWriter($zip.CreateEntry($name).Open())
                $writer.Write($Entries[$name])
                $writer.Dispose()
            }
        } finally {
            $zip.Dispose()
        }
    }

    function New-TestError {
        param([string]$Message)
        try { throw $Message } catch { return $_ }
    }
}

Describe 'Script file' {
    It 'parses without errors' {
        $script:ParseErrors | Should -BeNullOrEmpty
    }

    It 'declares the same version in every location' {
        $psScriptInfo = [regex]::Match($script:ScriptContent, '(?m)^\.VERSION (\S+)').Groups[1].Value
        $notes = [regex]::Match($script:ScriptContent, '(?m)^\s+Version\s+: (\S+)').Groups[1].Value
        $variable = [regex]::Match($script:ScriptContent, "(?m)^\`$CurrentVersion = '([^']+)'").Groups[1].Value
        $releaseNotes = ([regex]::Matches($script:ScriptContent, '(?m)^\[Version ([\d.]+)\]') | Select-Object -Last 1).Groups[1].Value

        $psScriptInfo | Should -Not -BeNullOrEmpty
        $notes | Should -Be $psScriptInfo
        $variable | Should -Be $psScriptInfo
        $releaseNotes | Should -Be $psScriptInfo
    }

    It 'prints the version with -Version' {
        $expected = [regex]::Match($script:ScriptContent, "(?m)^\`$CurrentVersion = '([^']+)'").Groups[1].Value
        & $script:ScriptPath -Version | Should -Be $expected
    }

    It 'documents every parameter in comment-based help' {
        $declared = $script:Ast.ParamBlock.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath }
        $documented = [regex]::Matches($script:ScriptContent, '(?m)^\.PARAMETER (\w+)') | ForEach-Object { $_.Groups[1].Value }
        foreach ($name in $declared) {
            $documented | Should -Contain $name -Because "-$name is a script parameter"
        }
    }

    It 'never writes the GitHub token to output' {
        $script:ScriptContent | Should -Not -Match 'GHtoken=\$GHtoken'
    }

    It 'uses only ASCII dashes and box characters' {
        $script:ScriptContent | Should -Not -Match '[\u2013\u2014\u2500-\u257F]'
    }
}

Describe 'Install method routing' {
    BeforeAll {
        # The four top-level 'if' blocks inside the main try that choose an install path:
        # Portable, Standard, Alternate, and winget registration, in document order
        $conditions = $script:Ast.FindAll({ param($node)
                $node -is [System.Management.Automation.Language.IfStatementAst] -and
                $node.Clauses[0].Item1.Extent.Text -match 'InstallationType' }, $true) |
            Where-Object {
                $parent = $_.Parent
                $inTry = $false
                $inFunction = $false
                while ($parent) {
                    if ($parent -is [System.Management.Automation.Language.TryStatementAst]) { $inTry = $true }
                    if ($parent -is [System.Management.Automation.Language.FunctionDefinitionAst]) { $inFunction = $true }
                    $parent = $parent.Parent
                }
                $inTry -and -not $inFunction
            }
        $script:RouteConditions = @($conditions | ForEach-Object { [scriptblock]::Create($_.Clauses[0].Item1.Extent.Text) })
        $script:RouteNames = 'Portable', 'Standard', 'Alternate', 'Register'

        function Get-ActiveRoutes {
            param($OS, [switch]$Portable, [switch]$Alternate, [switch]$System)
            $osVersion = $OS
            $PortableInstallMethod = [bool]$Portable
            $AlternateInstallMethod = [bool]$Alternate
            $RunAsSystem = [bool]$System
            $active = for ($i = 0; $i -lt $script:RouteConditions.Count; $i++) {
                if (& $script:RouteConditions[$i]) { $script:RouteNames[$i] }
            }
            return ($active -join ',')
        }

        function New-OS {
            param($Type = 'Workstation', $NumericVersion = '11', $InstallationType = 'Client')
            [PSCustomObject]@{ Type = $Type; NumericVersion = $NumericVersion; InstallationType = $InstallationType; Architecture = 'x64' }
        }
    }

    It 'finds the four routing conditions' {
        $script:RouteConditions | Should -HaveCount 4
    }

    It 'routes <Name> to <Expected>' -ForEach @(
        @{ Name = 'Windows 11'; OS = @{}; Expected = 'Standard,Register' }
        @{ Name = 'Windows 10'; OS = @{ NumericVersion = '10' }; Expected = 'Standard,Register' }
        @{ Name = 'Windows 11 with -PortableInstallMethod'; OS = @{}; Portable = $true; Expected = 'Portable' }
        @{ Name = 'Windows 11 with -AlternateInstallMethod'; OS = @{}; Alternate = $true; Expected = 'Alternate' }
        @{ Name = 'Windows 11 running as SYSTEM'; OS = @{}; System = $true; Expected = 'Alternate' }
        @{ Name = 'Server 2019'; OS = @{ Type = 'Server'; NumericVersion = '2019'; InstallationType = 'Server' }; Expected = 'Alternate' }
        @{ Name = 'Server 2022'; OS = @{ Type = 'Server'; NumericVersion = '2022'; InstallationType = 'Server' }; Expected = 'Alternate' }
        @{ Name = 'Server 2025'; OS = @{ Type = 'Server'; NumericVersion = '2025'; InstallationType = 'Server' }; Expected = 'Standard,Register' }
        @{ Name = 'Server Core 2022'; OS = @{ Type = 'Server'; NumericVersion = '2022'; InstallationType = 'Server Core' }; Expected = 'Portable' }
        @{ Name = 'Server Core 2025'; OS = @{ Type = 'Server'; NumericVersion = '2025'; InstallationType = 'Server Core' }; Expected = 'Portable' }
    ) {
        $os = New-OS @OS
        Get-ActiveRoutes -OS $os -Portable:([bool]$Portable) -Alternate:([bool]$Alternate) -System:([bool]$System) | Should -Be $Expected
    }
}

Describe 'UpdateSelf' {
    It 'updates when PSGallery has a newer version with a two-digit component' {
        $output = Invoke-Isolated -Functions 'UpdateSelf', 'Install-NuGetIfRequired' -Body {
            function Find-Script { [CmdletBinding()] param($Name) [PSCustomObject]@{ Version = [version]'5.3.10' } }
            function Get-PackageProvider { [CmdletBinding()] param($Name, [switch]$ListAvailable) $true }
            function Get-PSRepository { [CmdletBinding()] param($Name) [PSCustomObject]@{ InstallationPolicy = 'Trusted' } }
            function Install-Script { [CmdletBinding()] param($Name, [switch]$Force) }
            $CurrentVersion = '5.3.8'
            $PowerShellGalleryName = 'winget-install'
            UpdateSelf
        }
        $output | Should -Contain 'Updating script to version 5.3.10...'
        $output | Should -Contain 'Script updated to version 5.3.10.'
    }

    It 'reports up to date when PSGallery has the same version' {
        $output = Invoke-Isolated -Functions 'UpdateSelf', 'Install-NuGetIfRequired' -Body {
            function Find-Script { [CmdletBinding()] param($Name) [PSCustomObject]@{ Version = [version]'5.3.8' } }
            $CurrentVersion = '5.3.8'
            $PowerShellGalleryName = 'winget-install'
            UpdateSelf
        }
        $output | Should -Contain 'Script is already up to date.'
    }
}

Describe 'CheckForUpdate' {
    It 'reports a new version when the release tag is higher' {
        $output = Invoke-Isolated -Functions 'CheckForUpdate' -Body {
            function Get-GitHubRelease { param($Owner, $Repo, $GHtoken) [PSCustomObject]@{ LatestVersion = 'v5.3.10'; PublishedDateTime = Get-Date } }
            CheckForUpdate -RepoOwner 'asheroto' -RepoName 'winget-install' -CurrentVersion '5.3.8' -PowerShellGalleryName 'winget-install'
        }
        ($output -join "`n") | Should -Match 'A new version is available'
        ($output -join "`n") | Should -Match 'Install-Script winget-install -Force'
    }

    It 'reports up to date when the release tag matches' {
        $output = Invoke-Isolated -Functions 'CheckForUpdate' -Body {
            function Get-GitHubRelease { param($Owner, $Repo, $GHtoken) [PSCustomObject]@{ LatestVersion = 'v5.3.8'; PublishedDateTime = Get-Date } }
            CheckForUpdate -RepoOwner 'asheroto' -RepoName 'winget-install' -CurrentVersion '5.3.8' -PowerShellGalleryName 'winget-install'
        }
        ($output -join "`n") | Should -Match 'Up to date'
    }
}

Describe 'Get-GitHubRelease' {
    BeforeAll {
        Mock Invoke-RestMethod { [PSCustomObject]@{ tag_name = 'v5.3.9'; published_at = '2026-10-02T12:00:00Z' } }
    }

    It 'returns the tag and the publish time converted to local time' {
        $result = Get-GitHubRelease -Owner 'asheroto' -Repo 'winget-install'
        $result.LatestVersion | Should -Be 'v5.3.9'
        $expected = [DateTime]::Parse('2026-10-02T12:00:00Z', [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::RoundtripKind).ToLocalTime()
        $result.PublishedDateTime | Should -Be $expected
    }

    It 'sends a bearer token when one is supplied' {
        Get-GitHubRelease -Owner 'asheroto' -Repo 'winget-install' -GHtoken 'abc123' | Out-Null
        Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter { $Headers.Authorization -eq 'Bearer abc123' }
    }

    It 'sends no Authorization header without a token' {
        Get-GitHubRelease -Owner 'asheroto' -Repo 'winget-install' | Out-Null
        Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter { -not $Headers }
    }
}

Describe 'Get-WingetDownloadUrl' {
    BeforeAll {
        Mock Invoke-RestMethod {
            if ($Uri -like '*/releases/latest') {
                return [PSCustomObject]@{ tag_name = 'v1.9.25200' }
            }
            $tag = ([string]$Uri).Split('/')[-1]
            [PSCustomObject]@{
                assets = @(
                    [PSCustomObject]@{ name = 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'; browser_download_url = "https://example.test/$tag/winget.msixbundle" }
                    [PSCustomObject]@{ name = 'DesktopAppInstaller_Dependencies.zip'; browser_download_url = "https://example.test/$tag/deps.zip" }
                    [PSCustomObject]@{ name = 'e53e159d00e04f729cc2180cffd1c02e_License1.xml'; browser_download_url = "https://example.test/$tag/License1.xml" }
                )
            }
        }
    }

    It 'resolves the latest release tag and returns the matching asset' {
        $url = Get-WingetDownloadUrl -Match 'msixbundle'
        $url | Should -Be 'https://example.test/v1.9.25200/winget.msixbundle'
        Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter { $Uri -like '*/releases/latest' }
        Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter { $Uri -like '*/releases/tags/v1.9.25200' }
    }

    It 'uses an explicit version and adds the v prefix' {
        Get-WingetDownloadUrl -Match 'Dependencies.zip' -WingetVersion '1.8.1911' | Should -Be 'https://example.test/v1.8.1911/deps.zip'
        Should -Invoke Invoke-RestMethod -Times 0 -ParameterFilter { $Uri -like '*/releases/latest' }
    }

    It 'does not double the v prefix' {
        Get-WingetDownloadUrl -Match 'License1.xml' -WingetVersion 'v1.8.1911' | Should -Be 'https://example.test/v1.8.1911/License1.xml'
    }

    It 'returns a single string' {
        $url = Get-WingetDownloadUrl -Match 'msixbundle'
        $url | Should -BeOfType [string]
    }

    It 'throws when no asset matches' {
        { Get-WingetDownloadUrl -Match 'does-not-exist' } | Should -Throw '*no asset matched*'
    }

    It 'sends a bearer token when one is supplied' {
        Get-WingetDownloadUrl -Match 'msixbundle' -GHtoken 'abc123' | Out-Null
        Should -Invoke Invoke-RestMethod -Times 2 -Exactly -ParameterFilter { $Headers.Authorization -eq 'Bearer abc123' }
    }

    It 'sends an empty header table without a token' {
        Get-WingetDownloadUrl -Match 'msixbundle' | Out-Null
        Should -Invoke Invoke-RestMethod -Times 2 -Exactly -ParameterFilter { $Headers.Count -eq 0 }
    }
}

Describe 'Handle-Error' {
    It 'continues past <Message>' -ForEach @(
        @{ Message = 'Deployment failed with HRESULT: 0x80073D06' }
        @{ Message = 'Deployment failed with HRESULT: 0x80073CF0' }
        @{ Message = 'Deployment failed with HRESULT: 0x80073CF9' }
        @{ Message = 'The remote name could not be resolved' }
    ) {
        Handle-Error (New-TestError $Message) 3>$null | Should -BeNullOrEmpty
    }

    It 'returns the record to stop on <Message>' -ForEach @(
        @{ Message = 'Deployment failed with HRESULT: 0x80073D02' }
        @{ Message = 'Deployment failed with HRESULT: 0x80073CF3' }
        @{ Message = 'Unable to connect to the remote server' }
        @{ Message = 'Something nobody anticipated' }
    ) {
        $result = Handle-Error (New-TestError $Message) 3>$null
        $result | Should -BeOfType [System.Management.Automation.ErrorRecord]
        $result.Exception.Message | Should -Be $Message
    }
}

Describe 'Get-OSInfo' {
    BeforeAll {
        Mock Get-ItemProperty {
            [PSCustomObject]@{ ReleaseId = '2009'; DisplayVersion = '24H2'; ProductName = 'Registry Name'; EditionId = 'ServerDatacenter'; InstallationType = 'Client' }
        }
    }

    It 'classifies "<Caption>" (ProductType <ProductType>) as <ExpectedType> <ExpectedVersion>' -ForEach @(
        @{ Caption = 'Microsoft Windows 11 Pro'; ProductType = 1; ExpectedType = 'Workstation'; ExpectedVersion = '11' }
        @{ Caption = 'Microsoft Windows 10 Enterprise'; ProductType = 1; ExpectedType = 'Workstation'; ExpectedVersion = '10' }
        @{ Caption = 'Microsoft Windows Server 2022 Datacenter'; ProductType = 3; ExpectedType = 'Server'; ExpectedVersion = '2022' }
        @{ Caption = 'Microsoft Windows Server 2019 Standard'; ProductType = 2; ExpectedType = 'Server'; ExpectedVersion = '2019' }
        @{ Caption = 'Microsoft Windows 11 Enterprise multi-session'; ProductType = 3; ExpectedType = 'Workstation'; ExpectedVersion = '11' }
    ) {
        Mock Get-CimInstance { [PSCustomObject]@{ Caption = $Caption; OSArchitecture = '64-bit'; ProductType = $ProductType } }
        $info = Get-OSInfo
        $info.Type | Should -Be $ExpectedType
        $info.NumericVersion | Should -Be $ExpectedVersion
        $info.Name | Should -Be $Caption
    }

    It 'maps "<OSArchitecture>" to <Expected>' -ForEach @(
        @{ OSArchitecture = '64-bit'; Expected = 'x64' }
        @{ OSArchitecture = '32-bit'; Expected = 'x32' }
    ) {
        Mock Get-CimInstance { [PSCustomObject]@{ Caption = 'Microsoft Windows 11 Pro'; OSArchitecture = $OSArchitecture; ProductType = 1 } }
        (Get-OSInfo).Architecture | Should -Be $Expected
    }

    It 'strips Server from the edition and passes through the other registry values' {
        Mock Get-CimInstance { [PSCustomObject]@{ Caption = 'Microsoft Windows 11 Pro'; OSArchitecture = '64-bit'; ProductType = 1 } }
        $info = Get-OSInfo
        $info.EditionId | Should -Be 'Datacenter'
        $info.ReleaseId | Should -Be '2009'
        $info.DisplayVersion | Should -Be '24H2'
        $info.InstallationType | Should -Be 'Client'
        $info.Version | Should -Be ([System.Environment]::OSVersion.Version)
    }
}

Describe 'Environment PATH helpers' {
    BeforeAll {
        $script:ProbeKey = 'HKCU:\Software\winget-install-tests'
        Mock Get-EnvironmentPathRegistryKey { $script:ProbeKey }
    }

    BeforeEach {
        New-Item -Path $script:ProbeKey -Force | Out-Null
        Set-ItemProperty -Path $script:ProbeKey -Name 'Path' -Value '%USERPROFILE%\AppData\Local\Microsoft\WindowsApps;X:\Existing' -Type ExpandString
        $script:SavedProcessPath = $env:PATH
    }

    AfterEach {
        $env:PATH = $script:SavedProcessPath
        Remove-Item -Path $script:ProbeKey -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'reads the stored value without expanding variables' {
        Get-RawEnvironmentPath -Scope 'User' | Should -Be '%USERPROFILE%\AppData\Local\Microsoft\WindowsApps;X:\Existing'
    }

    It 'finds an existing entry' {
        Path-ExistsInEnvironment -PathToCheck 'X:\Existing' -Scope 'User' | Should -BeTrue
    }

    It 'matches entries without regard to case' {
        Path-ExistsInEnvironment -PathToCheck 'x:\existing' -Scope 'User' | Should -BeTrue
    }

    It 'does not find a missing entry' {
        Path-ExistsInEnvironment -PathToCheck 'X:\Missing' -Scope 'User' | Should -BeFalse
    }

    It 'appends a literal %VAR% entry and keeps the value as REG_EXPAND_SZ' {
        Add-ToEnvironmentPath -PathToAdd '%LOCALAPPDATA%\Microsoft\WindowsApps' -Scope 'User'
        Get-RawEnvironmentPath -Scope 'User' | Should -Be '%USERPROFILE%\AppData\Local\Microsoft\WindowsApps;X:\Existing;%LOCALAPPDATA%\Microsoft\WindowsApps'
        (Get-Item -Path $script:ProbeKey).GetValueKind('Path') | Should -Be 'ExpandString'
    }

    It 'does not add a duplicate on a second run' {
        Add-ToEnvironmentPath -PathToAdd '%LOCALAPPDATA%\Microsoft\WindowsApps' -Scope 'User'
        Add-ToEnvironmentPath -PathToAdd '%LOCALAPPDATA%\Microsoft\WindowsApps' -Scope 'User'
        @((Get-RawEnvironmentPath -Scope 'User') -split ';' | Where-Object { $_ -eq '%LOCALAPPDATA%\Microsoft\WindowsApps' }) | Should -HaveCount 1
    }

    It 'adds the entry to the current process PATH' {
        Add-ToEnvironmentPath -PathToAdd 'X:\NewEntry' -Scope 'User'
        ($env:PATH -split ';') | Should -Contain 'X:\NewEntry'
    }

    It 'does not write when the entry already exists' {
        Add-ToEnvironmentPath -PathToAdd 'X:\Existing' -Scope 'User'
        Get-RawEnvironmentPath -Scope 'User' | Should -Be '%USERPROFILE%\AppData\Local\Microsoft\WindowsApps;X:\Existing'
    }

    It 'handles an empty PATH value' {
        Set-ItemProperty -Path $script:ProbeKey -Name 'Path' -Value '' -Type ExpandString
        Add-ToEnvironmentPath -PathToAdd 'X:\NewEntry' -Scope 'User'
        Get-RawEnvironmentPath -Scope 'User' | Should -Be 'X:\NewEntry'
    }

    It 'does not produce a double semicolon after a trailing one' {
        Set-ItemProperty -Path $script:ProbeKey -Name 'Path' -Value 'X:\Existing;' -Type ExpandString
        Add-ToEnvironmentPath -PathToAdd 'X:\NewEntry' -Scope 'User'
        Get-RawEnvironmentPath -Scope 'User' | Should -Be 'X:\Existing;X:\NewEntry'
    }
}

Describe 'Get-EnvironmentPathRegistryKey' {
    It 'returns the user and system environment keys' {
        Get-EnvironmentPathRegistryKey -Scope 'User' | Should -Be 'HKCU:\Environment'
        Get-EnvironmentPathRegistryKey -Scope 'System' | Should -Be 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
    }
}

Describe 'Get-ManifestProperty' {
    BeforeAll {
        $manifest = '<?xml version="1.0" encoding="utf-8"?><Package xmlns="http://schemas.microsoft.com/appx/manifest/foundation/windows10"><Identity Name="Microsoft.VCLibs.140.00.UWPDesktop" Publisher="CN=Microsoft Corporation" Version="14.0.33728.0" ProcessorArchitecture="x64" /></Package>'
        $script:LibPath = Join-Path $TestDrive 'lib.appx'
        New-TestZip -Path $script:LibPath -Entries @{ 'AppxManifest.xml' = $manifest; 'other.txt' = 'x' }
        $script:NoManifestPath = Join-Path $TestDrive 'nomanifest.appx'
        New-TestZip -Path $script:NoManifestPath -Entries @{ 'other.txt' = 'x' }
    }

    It 'reads the package name' {
        Get-ManifestProperty -Lib_Path $script:LibPath -Property Name | Should -Be 'Microsoft.VCLibs.140.00.UWPDesktop'
    }

    It 'reads the package version' {
        Get-ManifestProperty -Lib_Path $script:LibPath -Property Version | Should -Be '14.0.33728.0'
    }

    It 'writes an error and returns nothing when the manifest is missing' {
        { Get-ManifestProperty -Lib_Path $script:NoManifestPath -Property Name -ErrorAction Stop } | Should -Throw '*AppxManifest.xml not found*'
        Get-ManifestProperty -Lib_Path $script:NoManifestPath -Property Name -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'rejects a manifest that declares a DTD' {
        $xxe = '<?xml version="1.0"?><!DOCTYPE Package [<!ENTITY xxe SYSTEM "file:///C:/Windows/win.ini">]><Package><Identity Name="&xxe;" Version="1.0.0.0" /></Package>'
        $path = Join-Path $TestDrive 'xxe.appx'
        New-TestZip -Path $path -Entries @{ 'AppxManifest.xml' = $xxe }
        { Get-ManifestProperty -Lib_Path $path -Property Name } | Should -Throw '*DTD*'
    }

    It 'releases the file handle on success and on failure' {
        $copy1 = Join-Path $TestDrive 'copy1.appx'
        $copy2 = Join-Path $TestDrive 'copy2.appx'
        Copy-Item $script:LibPath $copy1
        Copy-Item $script:NoManifestPath $copy2
        Get-ManifestProperty -Lib_Path $copy1 -Property Name | Out-Null
        Get-ManifestProperty -Lib_Path $copy2 -Property Name -ErrorAction SilentlyContinue | Out-Null
        { Remove-Item $copy1, $copy2 -ErrorAction Stop } | Should -Not -Throw
    }
}

Describe 'Get-InstalledLibVersion' {
    It 'returns the highest installed version' {
        Mock Get-AppxPackage { @([PSCustomObject]@{ Version = '14.0.30704.0' }, [PSCustomObject]@{ Version = '14.0.33728.0' }) }
        Get-InstalledLibVersion -Lib_Name 'VCLibs.140.00.UWPDesktop' | Should -Be '14.0.33728.0'
    }

    It 'returns only null when the library is not installed' {
        Mock Get-AppxPackage { $null }
        $result = Get-InstalledLibVersion -Lib_Name 'VCLibs.140.00.UWPDesktop'
        $result | Should -BeNullOrEmpty
    }
}

Describe 'Install-LibIfRequired' {
    BeforeAll {
        Mock Get-ManifestProperty { '14.0.33728.0' }
        Mock Add-AppxPackage {}
        Mock Add-ProvisionedAppxPackage {}
    }

    It 'installs when the library is not installed' {
        Mock Get-AppxPackage { $null }
        Install-LibIfRequired -Lib_Name 'VCLibs' -Lib_Path 'X:\lib.appx' | Out-Null
        Should -Invoke Add-AppxPackage -Times 1 -Exactly -ParameterFilter { $Path -eq 'X:\lib.appx' }
    }

    It 'installs when the downloaded version is newer, even across a digit-count change' {
        Mock Get-AppxPackage { [PSCustomObject]@{ Version = '14.0.9999.0' } }
        Install-LibIfRequired -Lib_Name 'VCLibs' -Lib_Path 'X:\lib.appx' | Out-Null
        Should -Invoke Add-AppxPackage -Times 1 -Exactly
    }

    It 'skips when the same version is installed' {
        Mock Get-AppxPackage { [PSCustomObject]@{ Version = '14.0.33728.0' } }
        Install-LibIfRequired -Lib_Name 'VCLibs' -Lib_Path 'X:\lib.appx' | Should -Match 'Skipping installation'
        Should -Invoke Add-AppxPackage -Times 0
    }

    It 'skips when a newer version is installed' {
        Mock Get-AppxPackage { [PSCustomObject]@{ Version = '14.0.40000.0' } }
        Install-LibIfRequired -Lib_Name 'VCLibs' -Lib_Path 'X:\lib.appx' | Out-Null
        Should -Invoke Add-AppxPackage -Times 0
    }

    It 'provisions instead of installing when running as SYSTEM' {
        Mock Get-AppxPackage { $null }
        $RunAsSystem = $true
        Install-LibIfRequired -Lib_Name 'VCLibs' -Lib_Path 'X:\lib.appx' | Out-Null
        Should -Invoke Add-ProvisionedAppxPackage -Times 1 -Exactly -ParameterFilter { $PackagePath -eq 'X:\lib.appx' -and $Online -and $SkipLicense }
        Should -Invoke Add-AppxPackage -Times 0
    }
}

Describe 'Install-NuGetIfRequired' {
    It 'does not install when the provider is already present' {
        Mock Get-PackageProvider { [PSCustomObject]@{ Name = 'NuGet' } }
        Mock Install-PackageProvider {}
        Install-NuGetIfRequired
        Should -Invoke Install-PackageProvider -Times 0
    }

    It 'warns instead of installing on PowerShell 7 or later' -Skip:($PSVersionTable.PSVersion.Major -lt 7) {
        Mock Get-PackageProvider { $null }
        Mock Install-PackageProvider {}
        Mock Write-Warning {}
        Install-NuGetIfRequired
        Should -Invoke Install-PackageProvider -Times 0
        Should -Invoke Write-Warning -Times 1 -Exactly
    }

    It 'installs the provider on Windows PowerShell' -Skip:($PSVersionTable.PSVersion.Major -ge 7) {
        Mock Get-PackageProvider { $null }
        Mock Install-PackageProvider {}
        Install-NuGetIfRequired
        Should -Invoke Install-PackageProvider -Times 1 -Exactly -ParameterFilter { $Name -eq 'NuGet' -and $Force -and $ForceBootstrap }
    }
}

Describe 'Get-WingetStatus' {
    It 'is true when the winget command resolves' {
        Mock Get-Command { [PSCustomObject]@{ Name = 'winget.exe' } }
        Get-WingetStatus | Should -BeTrue
    }

    It 'is false when the winget command is missing' {
        Mock Get-Command { $null }
        Get-WingetStatus | Should -BeFalse
    }

    It 'is false under SYSTEM when no package folder exists' {
        Mock Find-WinGet { $null }
        $RunAsSystem = $true
        Get-WingetStatus | Should -BeFalse
    }
}

Describe 'Apply-PathPermissionsFixAndAddPath' {
    BeforeAll {
        Mock Set-PathPermissions {}
        Mock Add-ToEnvironmentPath {}
        Mock Write-Warning {}
    }

    It 'uses the portable folder on Server Core' {
        $os = [PSCustomObject]@{ InstallationType = 'Server Core'; Architecture = 'x64' }
        Apply-PathPermissionsFixAndAddPath -OSVersion $os | Out-Null
        $expected = [System.IO.Path]::Combine($env:ProgramFiles, 'Microsoft', 'winget')
        Should -Invoke Set-PathPermissions -Times 1 -Exactly -ParameterFilter { $FolderPath -eq $expected }
        Should -Invoke Add-ToEnvironmentPath -Times 1 -Exactly -ParameterFilter { $PathToAdd -eq $expected -and $Scope -eq 'System' }
    }

    It 'picks the highest sorted WindowsApps package folder otherwise' {
        Mock Get-ChildItem {
            @(
                [PSCustomObject]@{ Name = 'Microsoft.DesktopAppInstaller_1.22.0.0_x64__8wekyb3d8bbwe'; FullName = 'X:\WindowsApps\Microsoft.DesktopAppInstaller_1.22.0.0_x64__8wekyb3d8bbwe' }
                [PSCustomObject]@{ Name = 'Microsoft.DesktopAppInstaller_1.9.0.0_x64__8wekyb3d8bbwe'; FullName = 'X:\WindowsApps\Microsoft.DesktopAppInstaller_1.9.0.0_x64__8wekyb3d8bbwe' }
            )
        }
        $os = [PSCustomObject]@{ InstallationType = 'Client'; Architecture = 'x64' }
        Apply-PathPermissionsFixAndAddPath -OSVersion $os | Out-Null
        Should -Invoke Get-ChildItem -Times 1 -Exactly -ParameterFilter { $Filter -eq 'Microsoft.DesktopAppInstaller_*_*x64__8wekyb3d8bbwe' }
        Should -Invoke Add-ToEnvironmentPath -Times 1 -Exactly -ParameterFilter { $PathToAdd -eq 'X:\WindowsApps\Microsoft.DesktopAppInstaller_1.9.0.0_x64__8wekyb3d8bbwe' }
    }

    It 'warns and skips when no package folder is found' {
        Mock Get-ChildItem { $null }
        $os = [PSCustomObject]@{ InstallationType = 'Client'; Architecture = 'x64' }
        Apply-PathPermissionsFixAndAddPath -OSVersion $os | Out-Null
        Should -Invoke Add-ToEnvironmentPath -Times 0
        Should -Invoke Set-PathPermissions -Times 0
        Should -Invoke Write-Warning -Times 1 -Exactly
    }
}

Describe 'Set-PathPermissions' {
    It 'grants the Administrators group inherited full control' {
        $dir = Join-Path $TestDrive 'acl'
        New-Item -ItemType Directory -Path $dir | Out-Null
        Set-PathPermissions -FolderPath $dir
        $rule = (Get-Acl -Path $dir).Access | Where-Object {
            $_.IdentityReference.Translate([System.Security.Principal.SecurityIdentifier]).Value -eq 'S-1-5-32-544' -and
            $_.FileSystemRights -eq 'FullControl' -and
            $_.AccessControlType -eq 'Allow' -and
            $_.InheritanceFlags -eq 'ContainerInherit, ObjectInherit'
        }
        $rule | Should -Not -BeNullOrEmpty
    }

    It 'warns instead of throwing on a missing folder' {
        Mock Write-Warning {}
        { Set-PathPermissions -FolderPath (Join-Path $TestDrive 'does-not-exist') } | Should -Not -Throw
        Should -Invoke Write-Warning -Times 1 -Exactly
    }
}

Describe 'Expand-Zip' {
    It 'extracts nested entries and overwrites on a second run' {
        $zipPath = Join-Path $TestDrive 'nested.zip'
        New-TestZip -Path $zipPath -Entries @{ 'root.txt' = 'root'; 'sub/child.txt' = 'child' }
        $dest = Join-Path $TestDrive 'out'
        Expand-Zip -Source $zipPath -Destination $dest
        Get-Content (Join-Path $dest 'root.txt') | Should -Be 'root'
        Get-Content (Join-Path $dest 'sub\child.txt') | Should -Be 'child'
        { Expand-Zip -Source $zipPath -Destination $dest } | Should -Not -Throw
    }

    It 'refuses an entry that would extract outside the destination' {
        $zipPath = Join-Path $TestDrive 'slip.zip'
        New-TestZip -Path $zipPath -Entries @{ 'ok.txt' = 'ok'; '../escaped.txt' = 'escaped' }
        $dest = Join-Path $TestDrive 'slip-out'
        { Expand-Zip -Source $zipPath -Destination $dest } | Should -Throw '*outside*'
        Test-Path (Join-Path $TestDrive 'escaped.txt') | Should -BeFalse
    }

    It 'releases the archive after a refused entry' {
        $zipPath = Join-Path $TestDrive 'slip2.zip'
        New-TestZip -Path $zipPath -Entries @{ '../escaped2.txt' = 'escaped' }
        { Expand-Zip -Source $zipPath -Destination (Join-Path $TestDrive 'slip-out2') } | Should -Throw
        { Remove-Item $zipPath -ErrorAction Stop } | Should -Not -Throw
    }
}

Describe 'Small helpers' {
    It 'Write-Section frames the text with a hash border' {
        $lines = @(Write-Section 'Hello')
        $lines | Should -HaveCount 5
        $lines[1] | Should -Be ('#' * 9)
        $lines[2] | Should -Be '# Hello #'
        $lines[3] | Should -Be ('#' * 9)
    }

    It 'New-TemporaryFile2 creates a file in the temp folder' {
        $file = New-TemporaryFile2
        try {
            Test-Path -Path $file | Should -BeTrue
            (Split-Path $file -Parent).TrimEnd('\') | Should -Be ([System.IO.Path]::GetTempPath().TrimEnd('\'))
        } finally {
            Remove-Item -Path $file -ErrorAction SilentlyContinue
        }
    }

    It 'TryRemove removes an existing file' {
        $file = Join-Path $TestDrive 'remove-me.txt'
        Set-Content -Path $file -Value 'x'
        TryRemove -FilePath $file
        Test-Path -Path $file | Should -BeFalse
    }

    It 'TryRemove ignores a missing file' {
        { TryRemove -FilePath (Join-Path $TestDrive 'never-existed.txt') } | Should -Not -Throw
    }

    It 'Test-AdminPrivileges returns a boolean' {
        Test-AdminPrivileges | Should -BeOfType [bool]
    }
}
