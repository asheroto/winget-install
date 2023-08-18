<#PSScriptInfo

.VERSION 3.0.0

.GUID 3b581edb-5d90-4fa1-ba15-4f2377275463

.AUTHOR asheroto, 1ckov, MisterZeus, ChrisTitusTech

.COMPANYNAME asheroto

.TAGS PowerShell Windows winget win get install installer fix script setup

.PROJECTURI https://github.com/asheroto/winget-install

.RELEASENOTES
[Version 0.0.1] - Initial Release.
[Version 0.0.2] - Implemented function to get the latest version of winget and its license.
[Version 0.0.3] - Signed file for PSGallery.
[Version 0.0.4] - Changed URI to grab latest release instead of releases and preleases.
[Version 0.0.5] - Updated version number of dependencies.
[Version 1.0.0] - Major refactor code, see release notes for more information.
[Version 1.0.1] - Fixed minor bug where version 2.8 was hardcoded in URL.
[Version 1.0.2] - Hardcoded UI Xaml version 2.8.4 as a failsafe in case the API fails. Added CheckForUpdates, Version, Help functions. Various bug fixes.
[Version 1.0.3] - Added error message to catch block. Fixed bug where appx package was not being installed.
[Version 1.0.4] - MisterZeus optimized code for readability.
[Version 2.0.0] - Major refactor. Reverted to UI.Xaml 2.7.3 for stability. Adjusted script to fix install issues due to winget changes (thank you ChrisTitusTech). Added in all architecture support.
[Version 2.0.1] - Renamed repo and URL references from winget-installer to winget-install. Added extra space after the last line of output.
[Version 2.0.2] - Adjusted CheckForUpdates to include Install-Script instructions and extra spacing.
[Version 2.1.0] - Added alternate method/URL for dependencies in case the main URL is down. Fixed licensing issue when winget is installed on Server 2022.
[Version 2.1.1] - Switched primary/alternate methods. Added Cleanup function to avoid errors when cleaning up temp files. Added output of URL for alternate method. Suppressed Add-AppxProvisionedPackage output. Improved success message. Improved verbiage. Improve PS script comments. Added check if the URL is empty. Moved display of URL beneath the check.
[Version 3.0.0] - Major changes. Added OS version detection checks - detects OS version, release ID, ensures compatibility. Forces older file installation for Server 2022 to avoid issues after installing.

#>

<#
.SYNOPSIS
	Downloads and installs the latest version of winget and its dependencies. Updates the PATH variable if needed.
.DESCRIPTION
	Downloads and installs the latest version of winget and its dependencies. Updates the PATH variable if needed.

This script is designed to be straightforward and easy to use, removing the hassle of manually downloading, installing, and configuring winget. To make the newly installed winget available for use, a system reboot may be required after running the script.

This function should be run with administrative privileges.
.EXAMPLE
	winget-install
.PARAMETER Version
    Displays the version of the script.
.PARAMETER Help
    Displays the help information for the script.
.PARAMETER CheckForUpdate
    Checks for updates of the script.
.NOTES
	Version      : 3.0.0
	Created by   : asheroto
.LINK
	Project Site: https://github.com/asheroto/winget-install
#>
[CmdletBinding()]
param (
    [switch]$Version,
    [switch]$Help,
    [switch]$CheckForUpdates,
    [switch]$CleanupDisabled
)

# Version
$CurrentVersion = '3.0.0'
$RepoOwner = 'asheroto'
$RepoName = 'winget-install'

# Versions
$ProgressPreference = 'SilentlyContinue' # Suppress progress bar (makes downloading super fast)

# Check if -Version is specified
if ($Version.IsPresent) {
    $CurrentVersion
    exit 0
}

# Help
if ($Help) {
    Get-Help -Name $MyInvocation.MyCommand.Source -Full
    exit 0
}

# If user runs "winget-install -Verbose", output their PS and Host info.
if ($PSBoundParameters.ContainsKey('Verbose') -and $PSBoundParameters['Verbose']) {
    $PSVersionTable
    Get-Host
}

# Check if the script running is code signed, if not, it may be running from the repo and we should warn the user
# NOTE TO USER - Change the variable below to $false to disable this check
$CheckCodeSigned = $true
if ($CheckCodeSigned -eq $true) {
    $scriptPath = $MyInvocation.MyCommand.Path
    $signature = Get-AuthenticodeSignature -FilePath $scriptPath
    if ($signature.Status -ne 'Valid') {
        Write-Error "This script is not code signed. If you are running it directly from the repo, please use the release version instead. The repo version may contain bugs or be broken.`n`nIf you are modifying the script for your own use, you can disable this check by setting the variable `$CheckCodeSigned to `$false. Running this script as-is is not recommended as this script is not ready for release and may not work as expected."
        exit 1
    }
}

function Get-ArchitectureType {
    # Determine architecture
    $cpuArchitecture = (Get-CimInstance -ClassName Win32_Processor).Architecture
    # 0 - x86, 9 - x64, 5 - ARM, 12 - ARM64
    switch ($cpuArchitecture) {
        0 { $arch = "x86" }
        9 { $arch = "x64" }
        5 { $arch = "arm" }
        12 { $arch = "arm64" }
        default { throw "Unknown CPU architecture detected." }
    }
    return $arch
}

function Get-TempFolder {
    return [System.IO.Path]::GetTempPath()
}

function Get-OSVersion {
    <#
        .SYNOPSIS
        Gets the OS version details of the current system.

        .DESCRIPTION
        This function retrieves the ReleaseId, DisplayVersion, ProductName, and Type (Server/Workstation) of the current OS.

        .EXAMPLE
        Get-OSVersion
    #>
    [CmdletBinding()]
    param ()

    try {
        # Get registry values
        $registryValues = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
        $releaseIdValue = $registryValues.ReleaseId
        $displayVersionValue = $registryValues.DisplayVersion
        $productNameValue = $registryValues.ProductName

        # Determine Type based on ProductName
        $typeValue = if ($productNameValue -match "Server") { "Server" } else { "Workstation" }
        $typeValue = if ($productNameValue -match "Server") { "Server" } else { "Workstation" }

        # Extract numerical value from ProductName
        $numericVersion = ($productNameValue -replace "[^\d]").Trim()

        # Create and return custom object with the required properties
        $result = [PSCustomObject]@{
            ReleaseId      = $releaseIdValue
            DisplayVersion = $displayVersionValue
            ProductName    = $productNameValue
            Type           = $typeValue
            NumericVersion = $numericVersion
        }

        return $result
    } catch {
        Write-Error "Unable to get OS version details.`nError: $_"
        exit 1
    }
}

function Get-GitHubRelease {
    <#
        .SYNOPSIS
        Fetches the latest release information of a GitHub repository.

        .DESCRIPTION
        This function uses the GitHub API to get information about the latest release of a specified repository, including its version and the date it was published.

        .PARAMETER Owner
        The GitHub username of the repository owner.

        .PARAMETER Repo
        The name of the repository.

        .EXAMPLE
        Get-GitHubRelease -Owner "asheroto" -Repo "winget-install"
        This command retrieves the latest release version and published datetime of the winget-install repository owned by asheroto.
    #>
    [CmdletBinding()]
    param (
        [string]$Owner,
        [string]$Repo
    )
    try {
        $url = "https://api.github.com/repos/$Owner/$Repo/releases/latest"
        $response = Invoke-RestMethod -Uri $url -ErrorAction Stop

        $latestVersion = $response.tag_name
        $publishedAt = $response.published_at

        # Convert UTC time string to local time
        $UtcDateTime = [DateTime]::Parse($publishedAt, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::RoundtripKind)
        $PublishedLocalDateTime = $UtcDateTime.ToLocalTime()

        [PSCustomObject]@{
            LatestVersion     = $latestVersion
            PublishedDateTime = $PublishedLocalDateTime
        }
    } catch {
        Write-Error "Unable to check for updates.`nError: $_"
        exit 1
    }
}

# Generates a section divider for easy reading of the output.
function Write-Section($text) {
    <#
        .SYNOPSIS
        Prints a text block surrounded by a section divider for enhanced output readability.

        .DESCRIPTION
        This function takes a string input and prints it to the console, surrounded by a section divider made of hash characters.
        It is designed to enhance the readability of console output.

        .PARAMETER text
        The text to be printed within the section divider.

        .EXAMPLE
        Write-Section "Downloading Files..."
        This command prints the text "Downloading Files..." surrounded by a section divider.
    #>
    Write-Output ""
    Write-Output ("#" * ($text.Length + 4))
    Write-Output "# $text #"
    Write-Output ("#" * ($text.Length + 4))
    Write-Output ""
}

function Get-NewestLink($match) {
    <#
        .SYNOPSIS
        Retrieves the download URL of the latest release asset that matches a specified pattern from the GitHub repository.

        .DESCRIPTION
        This function uses the GitHub API to get information about the latest release of the winget-cli repository.
        It then retrieves the download URL for the release asset that matches a specified pattern.

        .PARAMETER match
        The pattern to match in the asset names.

        .EXAMPLE
        Get-NewestLink "msixbundle"
        This command retrieves the download URL for the latest release asset with a name that contains "msixbundle".
    #>
    [CmdletBinding()]
    $uri = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
    Write-Debug "Getting information from $uri"
    $get = Invoke-RestMethod -uri $uri -Method Get -ErrorAction stop
    Write-Debug "Getting latest release..."
    $data = $get.assets | Where-Object name -Match $match
    return $data.browser_download_url
}

function Update-PathEnvironmentVariable {
    <#
        .SYNOPSIS
        Updates the PATH environment variable with a new path for both the User and Machine levels.

        .DESCRIPTION
        The function will add a new path to the PATH environment variable, making sure it is not a duplicate.
        If the new path is already in the PATH variable, the function will skip adding it.
        This function operates at both User and Machine levels.

        .PARAMETER NewPath
        The new directory path to be added to the PATH environment variable.

        .EXAMPLE
        Update-PathEnvironmentVariable -NewPath "C:\NewDirectory"
        This command will add the directory "C:\NewDirectory" to the PATH variable at both the User and Machine levels.
    #>
    param(
        [string]$NewPath
    )

    foreach ($Level in "Machine", "User") {
        # Get the current PATH variable
        $path = [Environment]::GetEnvironmentVariable("PATH", $Level)

        # Check if the new path is already in the PATH variable
        if (!$path.Contains($NewPath)) {
            Write-Output "Adding $NewPath to PATH variable for $Level..."

            # Add the new path to the PATH variable
            $path = ($path + ";" + $NewPath).Split(';') | Select-Object -Unique
            $path = $path -join ';'

            # Set the new PATH variable
            [Environment]::SetEnvironmentVariable("PATH", $path, $Level)
        } else {
            Write-Output "$NewPath already present in PATH variable for $Level, skipping."
        }
    }
}

function Handle-Error {
    <#
        .SYNOPSIS
            Handles common errors that may occur during an installation process.

        .DESCRIPTION
            This function takes an ErrorRecord object and checks for certain known error codes.
            Depending on the error code, it writes appropriate warning messages or throws the error.

        .PARAMETER ErrorRecord
            The ErrorRecord object that represents the error that was caught. This object contains
            information about the error, including the exception that was thrown.

        .EXAMPLE
            try {
                # Some code that may throw an error...
            } catch {
                Handle-Error $_
            }
            This example shows how you might use the Handle-Error function in a try-catch block.
            If an error occurs in the try block, the catch block catches it and calls Handle-Error,
            passing the error (represented by the $_ variable) to the function.
    #>
    param($ErrorRecord)

    # Store current value
    $OriginalErrorActionPreference = $ErrorActionPreference

    # Set to silently continue
    $ErrorActionPreference = 'SilentlyContinue'

    if ($ErrorRecord.Exception.Message -match '0x80073D06') {
        Write-Warning "Higher version already installed."
        Write-Warning "That's okay, continuing..."
    } elseif ($ErrorRecord.Exception.Message -match '0x80073CF0') {
        Write-Warning "Same version already installed."
        Write-Warning "That's okay, continuing..."
    } elseif ($ErrorRecord.Exception.Message -match '0x80073D02') {
        # Stop execution and return the ErrorRecord so that the calling try/catch block throws the error
        Write-Warning "Resources modified are in-use. Try closing Windows Terminal / PowerShell / Command Prompt and try again."
        Write-Warning "If the problem persists, restart your computer."
        return $ErrorRecord
    } elseif ($ErrorRecord.Exception.Message -match 'Unable to connect to the remote server') {
        Write-Warning "Cannot connect to the Internet to download the required files."
        Write-Warning "Try running the script again and make sure you are connected to the Internet."
        Write-Warning "Sometimes the nuget.org server is down, so you may need to try again later."
        return $ErrorRecord
    } else {
        # For other errors, we should stop the execution and return the ErrorRecord so that the calling try/catch block throws the error
        return $ErrorRecord
    }

    # Reset to original value
    $ErrorActionPreference = $OriginalErrorActionPreference
}

function Cleanup {
    <#
        .SYNOPSIS
            Deletes a file or directory specified without prompting for confirmation or displaying errors.

        .DESCRIPTION
            This function takes a path to a file or directory and deletes it without prompting for confirmation or displaying errors.
            If the path is a directory, the function will delete the directory and all its contents.

        .PARAMETER Path
            The path of the file or directory to be deleted.

        .PARAMETER Recurse
            If the path is a directory, this switch specifies whether to delete the directory and all its contents.

        .EXAMPLE
            Cleanup -Path "C:\Temp"
            This example deletes the directory "C:\Temp" and all its contents.

        .EXAMPLE
            Cleanup -Path "C:\Temp" -Recurse
            This example deletes the directory "C:\Temp" and all its contents.

        .EXAMPLE
            Cleanup -Path "C:\Temp\file.txt"
            This example deletes the file "C:\Temp\file.txt".
    #>
    param (
        [string]$Path,
        [bool]$Recurse = $false
    )

    # If CleanupDisabled switch is present, skip cleanup
    if ($CleanupDisabled) {
        Write-Warning "Skipping cleanup of $Path."
        return
    }

    try {
        if (Test-Path -Path $Path) {
            if ($Recurse -and (Get-Item -Path $Path) -is [System.IO.DirectoryInfo]) {
                Get-ChildItem -Path $Path -Recurse | Remove-Item -Force -Recurse
                Remove-Item -Path $Path -Force -Recurse
            } else {
                Remove-Item -Path $Path -Force
            }
        }
        if ($Debug) {
            Write-Output "Deleted: $Path"
        }
    } catch {
        # Errors are ignored
    }
}

function Install-Prerequisite {
    param (
        [string]$Name,
        [string]$Arch,
        [string]$Url,
        [string]$AlternateUrl,
        [string]$ContentType,
        [string]$Body,
        [string]$NupkgVersion,
        [string]$AppxFileVersion
    )

    $Arch = Get-ArchitectureType
    $osVersion = Get-OSVersion

    Write-Section "Downloading & installing ${Arch} ${Name}..."

    $ThrowReason = @{
        Message = ""
        Code    = 0
    }
    try {
        # If Server 2022 or Workstation 10, force older version of VCLibs (return true)
        if ($osVersion.Type -eq "Server" -and $osVersion.NumericVersion -eq 2022) {
            $ThrowReason.Message = "Server 2022 detected. Using older version of $Name."
            $ThrowReason.Code = 1
            throw
        } elseif ($osVersion.Type -eq "Workstation" -and $osVersion.NumericVersion -eq 10) {
            $ThrowReason.Message = "Windows 10 detected. Using older version of $Name."
            $ThrowReason.Code = 1
            throw
        }

        # Primary method
        $url = Invoke-WebRequest -Uri $Url -Method "POST" -ContentType $ContentType -Body $Body -UseBasicParsing | ForEach-Object Links | Where-Object outerHTML -match "$Name.+_${Arch}__8wekyb3d8bbwe.appx" | ForEach-Object href

        # If the URL is empty, try the alternate method
        if ($url -eq "") {
            $ThrowReason.Message = "URL is empty"
            $ThrowReason.Code = 2
            throw
        }

        Write-Output "URL: ${url}"
        Write-Output "`nInstalling ${Arch} ${Name}..."
        Add-AppxPackage $url -ErrorAction Stop
        Write-Output "`n$Name installed successfully."
    } catch {
        # Alternate method
        try {
            $url = $AlternateUrl

            # Throw reason if alternate method is required
            if ($ThrowReason.Code -eq 0) {
                Write-Warning "Error when trying to download or install $Name. Trying alternate method..."
            } else {
                Write-Warning $ThrowReason.Message
            }
            Write-Output ""

            # If the URL is empty, throw error
            if ($url -eq "") {
                throw "URL is empty"
            }

            # Specific logic for VCLibs alternate method
            if ($Name -eq "VCLibs") {
                if ($Debug) {
                    Write-Output "URL: $($url)`n"
                }
                Write-Output "Installing ${Arch} ${Name}..."
                Add-AppxPackage $url -ErrorAction Stop
                Write-Output "`n$Name installed successfully."
            }

            # Specific logic for UI.Xaml
            if ($Name -eq "UI.Xaml") {
                $TempFolder = Get-TempFolder

                $uiXaml = @{
                    url           = $url
                    appxFolder    = "tools/AppX/$Arch/Release/"
                    appxFilename  = "Microsoft.UI.Xaml.$AppxFileVersion.appx"
                    nupkgFilename = Join-Path -Path $TempFolder -ChildPath "Microsoft.UI.Xaml.$NupkgVersion.nupkg"
                    nupkgFolder   = Join-Path -Path $TempFolder -ChildPath "Microsoft.UI.Xaml.$NupkgVersion"
                }

                # Debug
                if ($Debug) { Write-Output "uiXaml: $($uiXaml | ConvertTo-Json -Depth 100)" }

                # Downloading
                Write-Output "Downloading UI.Xaml..."
                if ($Debug) {
                    Write-Output "URL: $($uiXaml.url)"
                }
                Invoke-WebRequest -Uri $uiXaml.url -OutFile $uiXaml.nupkgFilename

                # Check if folder exists and delete if needed
                if (Test-Path -Path $uiXaml.nupkgFolder) {
                    Remove-Item -Path $uiXaml.nupkgFolder -Recurse
                }

                # Extracting
                Write-Output "Extracting: $($uiXaml.nupkgFolder)`n"
                if ($Debug) {
                    Write-Output "Into folder: $($uiXaml.nupkgFolder)`n"
                }
                Add-Type -Assembly System.IO.Compression.FileSystem
                [IO.Compression.ZipFile]::ExtractToDirectory($uiXaml.nupkgFilename, $uiXaml.nupkgFolder)

                # Prep for install
                Write-Output "Installing ${Arch} ${Name}..."
                $XamlAppxFolder = Join-Path -Path $uiXaml.nupkgFolder -ChildPath $uiXaml.appxFolder
                $XamlAppxPath = Join-Path -Path $XamlAppxFolder -ChildPath $uiXaml.appxFilename

                # Debugging
                if ($Debug) { Write-Output "Installing Appx Packages in: $XamlAppxFolder" }

                # Install
                Get-ChildItem -Path $XamlAppxPath -Filter *.appx | ForEach-Object {
                    if ($Debug) { Write-Output "Installing appx Package: $($_.Name)" }
                    Add-AppxPackage $_.FullName -ErrorAction Stop
                }
                Write-Output "`nUI.Xaml installed successfully."

                # Debugging
                if ($Debug) {
                    Write-Output ""
                    Cleanup -Path $uiXaml.nupkgFilename
                    Cleanup -Path $uiXaml.nupkgFolder -Recurse $true
                }
            }
        } catch {
            if ($_.Exception.Message -match 'Unable to connect to the remote server') {
                # If Windows 10 or Server 2022 failed, let user know that URL may be to blame and manual installation is required
                $SometimesDownMessage = "There is an issue connecting to the server to download $Name. Unforunately this is a known issue with the prerequisite server URLs - sometimes they are down. Since you're using $WindowsCaption you must use the older versions of the prerequisites, the prerequisites from the Windows store will probably not work."
                if ($osVersion.Type -eq "Workstation" -and $osVersion.NumericVersion -eq 10) {
                    $WindowsCaption = "Windows 10"
                    Write-Warning $SometimesDownMessage
                } elseif ($osVersion.Type -eq "Server" -and $osVersion.NumericVersion -eq 2022) {
                    $WindowsCaption = "Server 2022"
                    Write-Warning $SometimesDownMessage
                } else {
                    Write-Warning "Error when trying to download or install $Name. Please try again later or manually install $Name."
                }
            }
            $errorHandled = Handle-Error $_
            if ($null -ne $errorHandled) {
                throw $errorHandled
            }
            $errorHandled = $null
        }
    }
}

# Set OS version
$osVersion = Get-OSVersion

# If it's a workstation, make sure it is Windows 10+
if ($osVersion.Type -eq "Workstation" -and $osVersion.NumericVersion -lt 10) {
    Write-Error "winget is only compatible with Windows 10 or greater."
    exit 1
}

# If it's a workstation with Windows 10, make sure it's version 1809 or greater
if ($osVersion.Type -eq "Workstation" -and $osVersion.NumericVersion -eq 10 -and $osVersion.ReleaseId -lt 1809) {
    Write-Error "winget is only compatible with Windows 10 version 1809 or greater."
    exit 1
}

# If it's a server, it needs to be 2022+
if ($osVersion.Type -eq "Server" -and $osVersion.NumericVersion -lt 2022) {
    Write-Error "winget is only compatible with Windows Server 2022+."
    exit 1
}

# Check for updates
if ($CheckForUpdates) {
    $Data = Get-GitHubRelease -Owner $RepoOwner -Repo $RepoName

    if ($Data.LatestVersion -gt $CurrentVersion) {
        Write-Output "`nA new version of $RepoName is available.`n"
        Write-Output "Current version: $CurrentVersion."
        Write-Output "Latest version: $($Data.LatestVersion)."
        Write-Output "Published at: $($Data.PublishedDateTime).`n"
        Write-Output "You can download the latest version from https://github.com/$RepoOwner/$RepoName/releases`n"
        Write-Output "Or you can run the following command to update:"
        Write-Output "Install-Script winget-install -Force`n"
    } else {
        Write-Output "`n$RepoName is up to date.`n"
        Write-Output "Current version: $CurrentVersion."
        Write-Output "Latest version: $($Data.LatestVersion)."
        Write-Output "Published at: $($Data.PublishedDateTime)."
        Write-Output "`nRepository: https://github.com/$RepoOwner/$RepoName/releases`n"
    }
    exit 0
}

try {
    ########################
    # Prerequisites
    ########################

    # VCLibs
    Install-Prerequisite -Name "VCLibs" -Version "14.00" -Arch $arch -Url "https://store.rg-adguard.net/api/GetFiles" -AlternateUrl "https://aka.ms/Microsoft.VCLibs.$arch.14.00.Desktop.appx" -ContentType "application/x-www-form-urlencoded" -Body "type=PackageFamilyName&url=Microsoft.VCLibs.140.00_8wekyb3d8bbwe&ring=RP&lang=en-US"

    # UI.Xaml
    Install-Prerequisite -Name "UI.Xaml" -Version "2.7.3" -Arch $arch -Url "https://store.rg-adguard.net/api/GetFiles" -AlternateUrl "https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.7.3" -ContentType "application/x-www-form-urlencoded" -Body "type=ProductId&url=9P5VK8KZB5QZ&ring=RP&lang=en-US" -NupkgVersion "2.7.3" -AppxFileVersion "2.7"

    ########################
    # winget
    ########################

    $TempFolder = Get-TempFolder

    # Output
    Write-Section "Downloading & installing $(Get-ArchitectureType) winget..."

    Write-Output "Retrieving download URL for winget from GitHub..."
    $wingetUrl = Get-NewestLink("msixbundle")
    $wingetPath = Join-Path -Path $tempFolder -ChildPath "winget.msixbundle"
    $wingetLicenseUrl = Get-NewestLink("License1.xml")
    $wingetLicensePath = Join-Path -Path $tempFolder -ChildPath "license1.xml"

    Write-Output "Downloading winget..."
    if ($Debug) {
        Write-Output "`nURL: $wingetUrl"
        Write-Output "Saving as: $wingetPath"
    }
    Invoke-WebRequest -Uri $wingetUrl -OutFile $wingetPath

    Write-Output "Downloading license..."
    if ($Debug) {
        Write-Output "`nURL: $wingetLicenseUrl"
        Write-Output "Saving as: $wingetLicensePath"
    }
    Invoke-WebRequest -Uri $wingetLicenseUrl -OutFile $wingetLicensePath

    Write-Output "`nInstalling winget..."

    # Debugging
    if ($Debug) {
        Write-Output "wingetPath: $wingetPath"
        Write-Output "wingetLicensePath: $wingetLicensePath"
    }

    # Try to install winget
    try {
        # Add-AppxPackage will throw an error if the app is already installed or higher version installed, so we need to catch it and continue
        Add-AppxProvisionedPackage -Online -PackagePath $wingetPath -LicensePath $wingetLicensePath -ErrorAction SilentlyContinue | Out-Null
        Write-Output "`nwinget installed successfully."
    } catch {
        $errorHandled = Handle-Error $_
        if ($null -ne $errorHandled) {
            throw $errorHandled
        }
        $errorHandled = $null
    }

    # Debugging
    if ($Debug) {
        Write-Output ""
        Cleanup -Path $wingetPath
        Cleanup -Path $wingetLicensePath
    }

    ########################
    # PATH environment variable
    ########################

    # Add the WindowsApps directory to the PATH variable
    Write-Section "Checking and adding WindowsApps directory to PATH variable for current user if not present..."
    $WindowsAppsPath = [IO.Path]::Combine([Environment]::GetEnvironmentVariable("LOCALAPPDATA"), "Microsoft", "WindowsApps")
    Update-PathEnvironmentVariable -NewPath $WindowsAppsPath

    ########################
    # Finished
    ########################

    Write-Section "Installation complete!"
    Write-Output "Try using 'winget' now. If the command isn't recognized, restart your computer.`n"
    Write-Output "If you restart your computer and the command still isn't recognized, please read the"
    Write-Output "troubleshooting section of the README: https://github.com/asheroto/winget-install#troubleshooting`n"
} catch {
    ########################
    # Error handling
    ########################

    Write-Section "WARNING! An error occurred during installation!"

    Write-Warning "Something went wrong. If messages above don't help and the problem persists, please read the`nTroubleshooting section of the README: https://github.com/asheroto/winget-install#troubleshooting"

    # If it's not 0x80073D02 (resources in use), show error
    if ($_.Exception.Message -notmatch '0x80073D02') {
        Write-Warning "Line number : $($_.InvocationInfo.ScriptLineNumber)"
        Write-Warning "Error: $($_.Exception.Message)`n"
    }
}
# SIG # Begin signature block
# MIIpMwYJKoZIhvcNAQcCoIIpJDCCKSACAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCHiWCVDhL8x9oD
# v44VBeKLByawhcvyMFIvPjlYQuYySaCCDh8wggawMIIEmKADAgECAhAIrUCyYNKc
# TJ9ezam9k67ZMA0GCSqGSIb3DQEBDAUAMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNV
# BAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDAeFw0yMTA0MjkwMDAwMDBaFw0z
# NjA0MjgyMzU5NTlaMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2RlIFNpZ25pbmcg
# UlNBNDA5NiBTSEEzODQgMjAyMSBDQTEwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAw
# ggIKAoICAQDVtC9C0CiteLdd1TlZG7GIQvUzjOs9gZdwxbvEhSYwn6SOaNhc9es0
# JAfhS0/TeEP0F9ce2vnS1WcaUk8OoVf8iJnBkcyBAz5NcCRks43iCH00fUyAVxJr
# Q5qZ8sU7H/Lvy0daE6ZMswEgJfMQ04uy+wjwiuCdCcBlp/qYgEk1hz1RGeiQIXhF
# LqGfLOEYwhrMxe6TSXBCMo/7xuoc82VokaJNTIIRSFJo3hC9FFdd6BgTZcV/sk+F
# LEikVoQ11vkunKoAFdE3/hoGlMJ8yOobMubKwvSnowMOdKWvObarYBLj6Na59zHh
# 3K3kGKDYwSNHR7OhD26jq22YBoMbt2pnLdK9RBqSEIGPsDsJ18ebMlrC/2pgVItJ
# wZPt4bRc4G/rJvmM1bL5OBDm6s6R9b7T+2+TYTRcvJNFKIM2KmYoX7BzzosmJQay
# g9Rc9hUZTO1i4F4z8ujo7AqnsAMrkbI2eb73rQgedaZlzLvjSFDzd5Ea/ttQokbI
# YViY9XwCFjyDKK05huzUtw1T0PhH5nUwjewwk3YUpltLXXRhTT8SkXbev1jLchAp
# QfDVxW0mdmgRQRNYmtwmKwH0iU1Z23jPgUo+QEdfyYFQc4UQIyFZYIpkVMHMIRro
# OBl8ZhzNeDhFMJlP/2NPTLuqDQhTQXxYPUez+rbsjDIJAsxsPAxWEQIDAQABo4IB
# WTCCAVUwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQUaDfg67Y7+F8Rhvv+
# YXsIiGX0TkIwHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5nP+e6mK4cD08wDgYDVR0P
# AQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMDMHcGCCsGAQUFBwEBBGswaTAk
# BggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEEGCCsGAQUFBzAC
# hjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9v
# dEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3JsMy5kaWdpY2VydC5j
# b20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAcBgNVHSAEFTATMAcGBWeBDAED
# MAgGBmeBDAEEATANBgkqhkiG9w0BAQwFAAOCAgEAOiNEPY0Idu6PvDqZ01bgAhql
# +Eg08yy25nRm95RysQDKr2wwJxMSnpBEn0v9nqN8JtU3vDpdSG2V1T9J9Ce7FoFF
# UP2cvbaF4HZ+N3HLIvdaqpDP9ZNq4+sg0dVQeYiaiorBtr2hSBh+3NiAGhEZGM1h
# mYFW9snjdufE5BtfQ/g+lP92OT2e1JnPSt0o618moZVYSNUa/tcnP/2Q0XaG3Ryw
# YFzzDaju4ImhvTnhOE7abrs2nfvlIVNaw8rpavGiPttDuDPITzgUkpn13c5Ubdld
# AhQfQDN8A+KVssIhdXNSy0bYxDQcoqVLjc1vdjcshT8azibpGL6QB7BDf5WIIIJw
# 8MzK7/0pNVwfiThV9zeKiwmhywvpMRr/LhlcOXHhvpynCgbWJme3kuZOX956rEnP
# LqR0kq3bPKSchh/jwVYbKyP/j7XqiHtwa+aguv06P0WmxOgWkVKLQcBIhEuWTatE
# QOON8BUozu3xGFYHKi8QxAwIZDwzj64ojDzLj4gLDb879M4ee47vtevLt/B3E+bn
# KD+sEq6lLyJsQfmCXBVmzGwOysWGw/YmMwwHS6DTBwJqakAwSEs0qFEgu60bhQji
# WQ1tygVQK+pKHJ6l/aCnHwZ05/LWUpD9r4VIIflXO7ScA+2GRfS0YW6/aOImYIbq
# yK+p/pQd52MbOoZWeE4wggdnMIIFT6ADAgECAhAN0Uk2zX4f3m8X7HdlwxBNMA0G
# CSqGSIb3DQEBCwUAMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2RlIFNpZ25pbmcg
# UlNBNDA5NiBTSEEzODQgMjAyMSBDQTEwHhcNMjMwMzE3MDAwMDAwWhcNMjQwMzE2
# MjM1OTU5WjBvMQswCQYDVQQGEwJVUzERMA8GA1UECBMIT2tsYWhvbWExETAPBgNV
# BAcTCE11c2tvZ2VlMRwwGgYDVQQKExNBc2hlciBTb2x1dGlvbnMgSW5jMRwwGgYD
# VQQDExNBc2hlciBTb2x1dGlvbnMgSW5jMIICIjANBgkqhkiG9w0BAQEFAAOCAg8A
# MIICCgKCAgEA081RwO7808Fuab0RP0L2gthlZB8fiiGUBpnqJhsD1Bzpk+45B2LA
# qmrUp+nZIXNwr5me/55enGI9CkhaxmZoFhBxoM1u5lODNp8GaAYzIEi0IJldzZ9y
# PAQMfhTkHRiOwKBqTGO3h/gSZtaZ+8F+ltCmlXvv2vpqFpt5JL+uJm9SRIN5WLiP
# QM/isjYR+eIcaZxQeHLfbnemNcaT4cXOMChUsmG6WsoHZO1o76dCN+owz23koLy2
# Y1R3N2PMQj3kj8Bnlph6ffNnitKhXuwj3NkWwPSSQvYhcBuTcCOxpXpUjWlQNuTt
# llTHp9leKMq11raPkSaLe2qVX4eBc6HPtBT+7XagpaA409d7fmYTOLKmE0BCEdgb
# YZzYmKSyjrAgWlU9SYxurhFgHuQFD0CsBW1aXl6IEjn26cVx+hmj2KCOFELAdh1r
# 9UTNt37a/o/TYCp/mQ22/oa/224is1dpNj7RAHnNaix5n8RKKHufEh85lVjS/cBn
# 7z3cCKejyfBaUGK10SUwZKJiJ51DKkRkdh4A5cL85wKkQcFnRpfT/T+KTOEYRFT/
# vz3uK9bMLwuBj+gkP3WnlVXf67IY3FfZaQUDNdtwur4UTGrDQOn8Xl2rEy7L9VlJ
# UOCjX93WfW0B1Q4IxSdF6vIJw1m44HpIU4jxnqTBEo6BVVRCtdmp/x0CAwEAAaOC
# AgMwggH/MB8GA1UdIwQYMBaAFGg34Ou2O/hfEYb7/mF7CIhl9E5CMB0GA1UdDgQW
# BBTH3/U7rGshoJKjtOAVqNAEWJ/PBDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAww
# CgYIKwYBBQUHAwMwgbUGA1UdHwSBrTCBqjBToFGgT4ZNaHR0cDovL2NybDMuZGln
# aWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZEc0Q29kZVNpZ25pbmdSU0E0MDk2U0hB
# Mzg0MjAyMUNBMS5jcmwwU6BRoE+GTWh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9E
# aWdpQ2VydFRydXN0ZWRHNENvZGVTaWduaW5nUlNBNDA5NlNIQTM4NDIwMjFDQTEu
# Y3JsMD4GA1UdIAQ3MDUwMwYGZ4EMAQQBMCkwJwYIKwYBBQUHAgEWG2h0dHA6Ly93
# d3cuZGlnaWNlcnQuY29tL0NQUzCBlAYIKwYBBQUHAQEEgYcwgYQwJAYIKwYBBQUH
# MAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBcBggrBgEFBQcwAoZQaHR0cDov
# L2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZEc0Q29kZVNpZ25p
# bmdSU0E0MDk2U0hBMzg0MjAyMUNBMS5jcnQwCQYDVR0TBAIwADANBgkqhkiG9w0B
# AQsFAAOCAgEAQtDUmTp7UG2w4A4WaT6BoMLBLqzm09S64nFfuIUFjWk3KTCStpwR
# 3KzwG78CpYb7I0G6T7O2Emv+u0WgKVaWPbLFlnrjXXB+68DxR+CFWh6UDioz/9wo
# +eD/V2eKilAc2WSEIC8NzXT3C4yEtxUmnebK7Ysxy4qLlb4Sxk9NspS+Lg3jKBxb
# ExduQWHi1ytqw9NCghzK1Y2h5/AHwSYfwz7AyRerN3gTwzmmgTaWYEHVCL0NQddO
# 1lkSz6LPq2/JWHns7I0tNPCT5nZYva1v34EZvP9+P+SUDBH8bfrm6HlTd+Z6qNW5
# ACsALaCCAsZRQ6i7UZfjolD/lADn65f46XfnNMIo8PPpagFBIvxg03DGDJQu4QnY
# AyZhtrLDxc8VLtGZP8QVBf9JVcjVD8FxMMobDnuDq0YZ1h3ydRo1dqOzWVDipp0i
# oPd0UbL7EcZr6QcM72LWFvAACyVcIiXlh5jY+JehqaZMlS9aw4WQT0gpvBOaOJqb
# vGoAbtyHRFIkFbJG/Wxkpr+VkU1JvilXCh8g0OsXwvJk4dK4GeBVa7VLlq95fLiK
# zL54EZDTY1W+YfKYUseiptRlu5XBUn15C9rTpqDZhHFz6exyLfYcJzdxJJdArjio
# UKKR9ZhLfxm1bmFMb8NPWOKH/ZI6vR0jNgwalk3nTx63ZnVAOJLH+BkxghpqMIIa
# ZgIBATB9MGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjFB
# MD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2RlIFNpZ25pbmcgUlNBNDA5
# NiBTSEEzODQgMjAyMSBDQTECEA3RSTbNfh/ebxfsd2XDEE0wDQYJYIZIAWUDBAIB
# BQCgfDAQBgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIB
# BDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQg
# T5scObT1PiVpSsvUm5TdbbtSxNJLc0SBnxGJDQqMTXowDQYJKoZIhvcNAQEBBQAE
# ggIACyeTY2+ZAlAjKI7tBFwRp/HhYMJr+WldHhTB24BJaRfvG6uuUcwzl5IvOoaO
# 534JWf75/9eSiSyOb/nPf6EbO6w9anW6eLUw2lkfmDbUG58Xn+OxweSWb+s3gt0n
# w3hEwQ8tujK9gMEL9gAnMYw+U91YTl2aZcJg59cUHibTVXtHzJ4U2UvN/9mUo+H0
# WDLL4W34iJyf1plnbzIc+j+UUkh9l5vEDQCF1TgFOPCyBFzGMszMhQUn28gtysBJ
# 730CxPLMeRd5cl5WTiJYo66a5XnCKJZKndzwIotOYHfESGuEj/KAyxI31lkCIdKo
# 9MFDdBGs3AEFPEkuoYyKb5LqzoZkRsS0G7x4xZuHbwQuXVGl5AK54tdBVjQ0Ktb9
# zBKk74LlJr1J5Pmjxrkjr4HeafFS89Lud2mjBy6TFDLJ11DYygJ9r7Sz9yvwdmGL
# B082vVM/b1q7YfnsBvsfDDTktYVhsJrolY+9LhBfFMtqSCnQyW5EQATeNUgNfGun
# GzbYLqXkSs4wvz/qNsqux6ZKoJZsSxOeZTOrccPxnULthlw7hOuB/c9Nc3yrAJb/
# x1xMhJOk0nWzkH3CC5Q+hA2d0xq7Sa8+kbxk3ZVbcDchh1CB/SLdJcajEuj2tuqb
# cz8YMK7HOhukxY278gLe7lpa26u2S/snBeL6GKGsVjL99BihghdAMIIXPAYKKwYB
# BAGCNwMDATGCFywwghcoBgkqhkiG9w0BBwKgghcZMIIXFQIBAzEPMA0GCWCGSAFl
# AwQCAQUAMHgGCyqGSIb3DQEJEAEEoGkEZzBlAgEBBglghkgBhv1sBwEwMTANBglg
# hkgBZQMEAgEFAAQgOMHrFswqOkdb9WkTpnaOHwoAr+E4ci0A/NS+WnQVYeYCEQCQ
# 9jojf7/Oks682Cn0oZWBGA8yMDIzMDgxODE5MDIwMFqgghMJMIIGwjCCBKqgAwIB
# AgIQBUSv85SdCDmmv9s/X+VhFjANBgkqhkiG9w0BAQsFADBjMQswCQYDVQQGEwJV
# UzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFRy
# dXN0ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5nIENBMB4XDTIzMDcx
# NDAwMDAwMFoXDTM0MTAxMzIzNTk1OVowSDELMAkGA1UEBhMCVVMxFzAVBgNVBAoT
# DkRpZ2lDZXJ0LCBJbmMuMSAwHgYDVQQDExdEaWdpQ2VydCBUaW1lc3RhbXAgMjAy
# MzCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAKNTRYcdg45brD5UsyPg
# z5/X5dLnXaEOCdwvSKOXejsqnGfcYhVYwamTEafNqrJq3RApih5iY2nTWJw1cb86
# l+uUUI8cIOrHmjsvlmbjaedp/lvD1isgHMGXlLSlUIHyz8sHpjBoyoNC2vx/CSSU
# pIIa2mq62DvKXd4ZGIX7ReoNYWyd/nFexAaaPPDFLnkPG2ZS48jWPl/aQ9OE9dDH
# 9kgtXkV1lnX+3RChG4PBuOZSlbVH13gpOWvgeFmX40QrStWVzu8IF+qCZE3/I+PK
# hu60pCFkcOvV5aDaY7Mu6QXuqvYk9R28mxyyt1/f8O52fTGZZUdVnUokL6wrl76f
# 5P17cz4y7lI0+9S769SgLDSb495uZBkHNwGRDxy1Uc2qTGaDiGhiu7xBG3gZbeTZ
# D+BYQfvYsSzhUa+0rRUGFOpiCBPTaR58ZE2dD9/O0V6MqqtQFcmzyrzXxDtoRKOl
# O0L9c33u3Qr/eTQQfqZcClhMAD6FaXXHg2TWdc2PEnZWpST618RrIbroHzSYLzrq
# awGw9/sqhux7UjipmAmhcbJsca8+uG+W1eEQE/5hRwqM/vC2x9XH3mwk8L9Cgsqg
# cT2ckpMEtGlwJw1Pt7U20clfCKRwo+wK8REuZODLIivK8SgTIUlRfgZm0zu++uuR
# ONhRB8qUt+JQofM604qDy0B7AgMBAAGjggGLMIIBhzAOBgNVHQ8BAf8EBAMCB4Aw
# DAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAgBgNVHSAEGTAX
# MAgGBmeBDAEEAjALBglghkgBhv1sBwEwHwYDVR0jBBgwFoAUuhbZbU2FL3Mpdpov
# dYxqII+eyG8wHQYDVR0OBBYEFKW27xPn783QZKHVVqllMaPe1eNJMFoGA1UdHwRT
# MFEwT6BNoEuGSWh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0
# ZWRHNFJTQTQwOTZTSEEyNTZUaW1lU3RhbXBpbmdDQS5jcmwwgZAGCCsGAQUFBwEB
# BIGDMIGAMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wWAYI
# KwYBBQUHMAKGTGh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRy
# dXN0ZWRHNFJTQTQwOTZTSEEyNTZUaW1lU3RhbXBpbmdDQS5jcnQwDQYJKoZIhvcN
# AQELBQADggIBAIEa1t6gqbWYF7xwjU+KPGic2CX/yyzkzepdIpLsjCICqbjPgKjZ
# 5+PF7SaCinEvGN1Ott5s1+FgnCvt7T1IjrhrunxdvcJhN2hJd6PrkKoS1yeF844e
# ktrCQDifXcigLiV4JZ0qBXqEKZi2V3mP2yZWK7Dzp703DNiYdk9WuVLCtp04qYHn
# bUFcjGnRuSvExnvPnPp44pMadqJpddNQ5EQSviANnqlE0PjlSXcIWiHFtM+YlRpU
# urm8wWkZus8W8oM3NG6wQSbd3lqXTzON1I13fXVFoaVYJmoDRd7ZULVQjK9WvUzF
# 4UbFKNOt50MAcN7MmJ4ZiQPq1JE3701S88lgIcRWR+3aEUuMMsOI5ljitts++V+w
# QtaP4xeR0arAVeOGv6wnLEHQmjNKqDbUuXKWfpd5OEhfysLcPTLfddY2Z1qJ+Pan
# x+VPNTwAvb6cKmx5AdzaROY63jg7B145WPR8czFVoIARyxQMfq68/qTreWWqaNYi
# yjvrmoI1VygWy2nyMpqy0tg6uLFGhmu6F/3Ed2wVbK6rr3M66ElGt9V/zLY4wNjs
# HPW2obhDLN9OTH0eaHDAdwrUAuBcYLso/zjlUlrWrBciI0707NMX+1Br/wd3H3GX
# REHJuEbTbDJ8WC9nR2XlG3O2mflrLAZG70Ee8PBf4NvZrZCARK+AEEGKMIIGrjCC
# BJagAwIBAgIQBzY3tyRUfNhHrP0oZipeWzANBgkqhkiG9w0BAQsFADBiMQswCQYD
# VQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGln
# aWNlcnQuY29tMSEwHwYDVQQDExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQwHhcN
# MjIwMzIzMDAwMDAwWhcNMzcwMzIyMjM1OTU5WjBjMQswCQYDVQQGEwJVUzEXMBUG
# A1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFRydXN0ZWQg
# RzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5nIENBMIICIjANBgkqhkiG9w0B
# AQEFAAOCAg8AMIICCgKCAgEAxoY1BkmzwT1ySVFVxyUDxPKRN6mXUaHW0oPRnkyi
# baCwzIP5WvYRoUQVQl+kiPNo+n3znIkLf50fng8zH1ATCyZzlm34V6gCff1DtITa
# EfFzsbPuK4CEiiIY3+vaPcQXf6sZKz5C3GeO6lE98NZW1OcoLevTsbV15x8GZY2U
# KdPZ7Gnf2ZCHRgB720RBidx8ald68Dd5n12sy+iEZLRS8nZH92GDGd1ftFQLIWhu
# NyG7QKxfst5Kfc71ORJn7w6lY2zkpsUdzTYNXNXmG6jBZHRAp8ByxbpOH7G1WE15
# /tePc5OsLDnipUjW8LAxE6lXKZYnLvWHpo9OdhVVJnCYJn+gGkcgQ+NDY4B7dW4n
# JZCYOjgRs/b2nuY7W+yB3iIU2YIqx5K/oN7jPqJz+ucfWmyU8lKVEStYdEAoq3ND
# zt9KoRxrOMUp88qqlnNCaJ+2RrOdOqPVA+C/8KI8ykLcGEh/FDTP0kyr75s9/g64
# ZCr6dSgkQe1CvwWcZklSUPRR8zZJTYsg0ixXNXkrqPNFYLwjjVj33GHek/45wPmy
# MKVM1+mYSlg+0wOI/rOP015LdhJRk8mMDDtbiiKowSYI+RQQEgN9XyO7ZONj4Kbh
# PvbCdLI/Hgl27KtdRnXiYKNYCQEoAA6EVO7O6V3IXjASvUaetdN2udIOa5kM0jO0
# zbECAwEAAaOCAV0wggFZMBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFLoW
# 2W1NhS9zKXaaL3WMaiCPnshvMB8GA1UdIwQYMBaAFOzX44LScV1kTN8uZz/nupiu
# HA9PMA4GA1UdDwEB/wQEAwIBhjATBgNVHSUEDDAKBggrBgEFBQcDCDB3BggrBgEF
# BQcBAQRrMGkwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBB
# BggrBgEFBQcwAoY1aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0
# VHJ1c3RlZFJvb3RHNC5jcnQwQwYDVR0fBDwwOjA4oDagNIYyaHR0cDovL2NybDMu
# ZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcmwwIAYDVR0gBBkw
# FzAIBgZngQwBBAIwCwYJYIZIAYb9bAcBMA0GCSqGSIb3DQEBCwUAA4ICAQB9WY7A
# k7ZvmKlEIgF+ZtbYIULhsBguEE0TzzBTzr8Y+8dQXeJLKftwig2qKWn8acHPHQfp
# PmDI2AvlXFvXbYf6hCAlNDFnzbYSlm/EUExiHQwIgqgWvalWzxVzjQEiJc6VaT9H
# d/tydBTX/6tPiix6q4XNQ1/tYLaqT5Fmniye4Iqs5f2MvGQmh2ySvZ180HAKfO+o
# vHVPulr3qRCyXen/KFSJ8NWKcXZl2szwcqMj+sAngkSumScbqyQeJsG33irr9p6x
# eZmBo1aGqwpFyd/EjaDnmPv7pp1yr8THwcFqcdnGE4AJxLafzYeHJLtPo0m5d2aR
# 8XKc6UsCUqc3fpNTrDsdCEkPlM05et3/JWOZJyw9P2un8WbDQc1PtkCbISFA0LcT
# JM3cHXg65J6t5TRxktcma+Q4c6umAU+9Pzt4rUyt+8SVe+0KXzM5h0F4ejjpnOHd
# I/0dKNPH+ejxmF/7K9h+8kaddSweJywm228Vex4Ziza4k9Tm8heZWcpw8De/mADf
# IBZPJ/tgZxahZrrdVcA6KYawmKAr7ZVBtzrVFZgxtGIJDwq9gdkT/r+k0fNX2bwE
# +oLeMt8EifAAzV3C+dAjfwAL5HYCJtnwZXZCpimHCUcr5n8apIUP/JiW9lVUKx+A
# +sDyDivl1vupL0QVSucTDh3bNzgaoSv27dZ8/DCCBY0wggR1oAMCAQICEA6bGI75
# 0C3n79tQ4ghAGFowDQYJKoZIhvcNAQEMBQAwZTELMAkGA1UEBhMCVVMxFTATBgNV
# BAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIG
# A1UEAxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTIyMDgwMTAwMDAw
# MFoXDTMxMTEwOTIzNTk1OVowYjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lD
# ZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGln
# aUNlcnQgVHJ1c3RlZCBSb290IEc0MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIIC
# CgKCAgEAv+aQc2jeu+RdSjwwIjBpM+zCpyUuySE98orYWcLhKac9WKt2ms2uexuE
# DcQwH/MbpDgW61bGl20dq7J58soR0uRf1gU8Ug9SH8aeFaV+vp+pVxZZVXKvaJNw
# wrK6dZlqczKU0RBEEC7fgvMHhOZ0O21x4i0MG+4g1ckgHWMpLc7sXk7Ik/ghYZs0
# 6wXGXuxbGrzryc/NrDRAX7F6Zu53yEioZldXn1RYjgwrt0+nMNlW7sp7XeOtyU9e
# 5TXnMcvak17cjo+A2raRmECQecN4x7axxLVqGDgDEI3Y1DekLgV9iPWCPhCRcKtV
# gkEy19sEcypukQF8IUzUvK4bA3VdeGbZOjFEmjNAvwjXWkmkwuapoGfdpCe8oU85
# tRFYF/ckXEaPZPfBaYh2mHY9WV1CdoeJl2l6SPDgohIbZpp0yt5LHucOY67m1O+S
# kjqePdwA5EUlibaaRBkrfsCUtNJhbesz2cXfSwQAzH0clcOP9yGyshG3u3/y1Yxw
# LEFgqrFjGESVGnZifvaAsPvoZKYz0YkH4b235kOkGLimdwHhD5QMIR2yVCkliWzl
# DlJRR3S+Jqy2QXXeeqxfjT/JvNNBERJb5RBQ6zHFynIWIgnffEx1P2PsIV/EIFFr
# b7GrhotPwtZFX50g/KEexcCPorF+CiaZ9eRpL5gdLfXZqbId5RsCAwEAAaOCATow
# ggE2MA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFOzX44LScV1kTN8uZz/nupiu
# HA9PMB8GA1UdIwQYMBaAFEXroq/0ksuCMS1Ri6enIZ3zbcgPMA4GA1UdDwEB/wQE
# AwIBhjB5BggrBgEFBQcBAQRtMGswJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRp
# Z2ljZXJ0LmNvbTBDBggrBgEFBQcwAoY3aHR0cDovL2NhY2VydHMuZGlnaWNlcnQu
# Y29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNydDBFBgNVHR8EPjA8MDqgOKA2
# hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290
# Q0EuY3JsMBEGA1UdIAQKMAgwBgYEVR0gADANBgkqhkiG9w0BAQwFAAOCAQEAcKC/
# Q1xV5zhfoKN0Gz22Ftf3v1cHvZqsoYcs7IVeqRq7IviHGmlUIu2kiHdtvRoU9BNK
# ei8ttzjv9P+Aufih9/Jy3iS8UgPITtAq3votVs/59PesMHqai7Je1M/RQ0SbQyHr
# lnKhSLSZy51PpwYDE3cnRNTnf+hZqPC/Lwum6fI0POz3A8eHqNJMQBk1RmppVLC4
# oVaO7KTVPeix3P0c2PR3WlxUjG/voVA9/HYJaISfb8rbII01YBwCA8sgsKxYoA5A
# Y8WYIsGyWfVVa88nq2x2zm8jLfR+cWojayL/ErhULSd+2DrZ8LaHlv1b0VysGMNN
# n3O3AamfV6peKOK5lDGCA3YwggNyAgEBMHcwYzELMAkGA1UEBhMCVVMxFzAVBgNV
# BAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQDEzJEaWdpQ2VydCBUcnVzdGVkIEc0
# IFJTQTQwOTYgU0hBMjU2IFRpbWVTdGFtcGluZyBDQQIQBUSv85SdCDmmv9s/X+Vh
# FjANBglghkgBZQMEAgEFAKCB0TAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQw
# HAYJKoZIhvcNAQkFMQ8XDTIzMDgxODE5MDIwMFowKwYLKoZIhvcNAQkQAgwxHDAa
# MBgwFgQUZvArMsLCyQ+CXc6qisnGTxmcz0AwLwYJKoZIhvcNAQkEMSIEIByakEFI
# jx8Yu+b4g69EjUEy4BDnhWbMRUZuMhtaWtb5MDcGCyqGSIb3DQEJEAIvMSgwJjAk
# MCIEINL25G3tdCLM0dRAV2hBNm+CitpVmq4zFq9NGprUDHgoMA0GCSqGSIb3DQEB
# AQUABIICABbicX9TjpeJ0XXq8cP46qzkDWFbQpfFNPyPZ8HKIyg4T7G54EknNx+l
# n2j5os+IvQ22vQ7GmzlTs6FJkyj1CAldQJ6eJXzbTzKoh3c68nkb9Upvom+S4xiK
# MX4PBFpaK13fCqY3pg8kQEApu52auhrf89zW4FJ72kRBSOQM4uElAzJGMpW/WuYd
# z9dPuMjOvkBGFU1zxI17m3+ntwyf52SOtLqmobeXZFzxlp5cp9lGSY0NGDbOJ1hS
# m+XXSS82IZUqj0L8kKkl3T1VqvEHOoiT7rGTxmcokMK4icmbwr+k8N0F03z82L9G
# o9yGmcTKuvXZ+0gvAbhR0Lw9FCDqfklDupb58beXD/qwVc1DOKQJbwQr79fW3RLq
# q+cLwP4DvQRoGMUntygXGorZVYlQFSOJrrbFOodY+ohFEgjwA7ZXX7Y6ZCXa7C45
# stDmDty+djHuVZw/HWCufgr7HG7gdUvLXPrIEoDemDNUj53kWRe41eeBmq/+B5kP
# vhqZZuDW2JOSzvYGwg/wiwJ8eezugKixhBBoa+14Q/xrtH9o76aR3kxuOIbYuFFN
# LPaQFzR7UBdA/E347VONR+chu+uM1UTMLrAFIxJHBJ+66GVgGZjJAbISGBRz7gPY
# UEZb0j3iUgbWuD9fv6kJivEACwqcozQGYrJYdiTl+HELrYAS7Bqy
# SIG # End signature block