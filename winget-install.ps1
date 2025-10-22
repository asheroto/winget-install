<#PSScriptInfo

.VERSION 5.2.1

.GUID 3b581edb-5d90-4fa1-ba15-4f2377275463

.AUTHOR asheroto

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
[Version 3.0.0] - Major changes. Added OS version detection checks - detects OS version, release ID, ensures compatibility. Forces older file installation for Server 2022 to avoid issues after installing. Added DebugMode, DisableCleanup, Force. Renamed CheckForUpdates to CheckForUpdate. Improved output. Improved error handling. Improved comments. Improved code readability. Moved CheckForUpdate into function. Added PowerShellGalleryName. Renamed Get-OSVersion to Get-OSInfo. Moved architecture detection into Get-OSInfo. Renamed Get-NewestLink to Get-WingetDownloadUrl. Have Get-WingetDownloadUrl not get preview releases.
[Version 3.0.1] - Updated Get-OSInfo function to fix issues when used on non-English systems. Improved error handling of "resources in use" error.
[Version 3.0.2] - Added winget registration command for Windows 10 machines.
[Version 3.1.0] - Added support for one-line installation with irm and iex compatible with $Force session variable. Added UpdateSelf command to automatically update the script to the latest version. Created short URL asheroto.com/winget.
[Version 3.1.1] - Changed winget register command to run on all OS versions.
[Version 3.2.0] - Added -ForceClose logic to relaunch the script in conhost.exe and automatically end active processes associated with winget that could interfere with the installation. Improved verbiage on winget already installed.
[Version 3.2.1] - Fixed minor glitch when using -Version or -Help parameters.
[Version 3.2.2] - Improved script exit functionality.
[Version 3.2.3] - Improved -ForceClose window handling with x86 PowerShell process.
[Version 3.2.4] - Improved verbiage for incompatible systems. Added importing Appx module on Windows Server with PowerShell 7+ systems to avoid error message.
[Version 3.2.5] - Removed pause after script completion. Added optional Wait parameter to force script to wait several seconds for script output.
[Version 3.2.6] - Improved ExitWithDelay function. Sometimes PowerShell will close the window accidentally, even when using the proper 'exit' command. Adjusted several closures for improved readability. Improved error code checking. Fixed glitch with -Wait param.
[Version 3.2.7] - Addded ability to install for all users. Added checks for Windows Sandbox and administrative privileges.
[Version 4.0.0] - Microsoft created some short URLs for winget. Removed a large portion of the script to use short URLs instead. Simplified and refactored. Switched debug param from DebugMode to Debug.
[Version 4.0.1] - Fixed PowerShell help information.
[Version 4.0.2] - Adjusted UpdateSelf function to reset PSGallery to original state if it was not trusted. Improved comments.
[Version 4.0.3] - Updated UI.Xaml package as per winget-cli issue #4208.
[Version 4.0.4] - Fixed detection for Windows multi-session.
[Version 4.0.5] - Improved error handling when registering winget.
[Version 4.1.0] - Support for Windows Server 2019 added by installing Visual C++ Redistributable.
[Version 4.1.1] - Minor revisions to comments & debug output.
[Version 4.1.2] - Implemented Visual C++ Redistributable version detection to ensure compatibility with winget.
[Version 4.1.3] - Added additional debug output for Visual C++ Redistributable version detection.
[Version 5.0.0] - Completely changed method to use winget-cli Repair-WingetPackageManager. Added environment path detection and addition if needed. Added NoExit parameter to prevent script from exiting after completion. Adjusted permissions of winget folder path for Server 2019. Improved exit handling to avoid PowerShell window closing.
[Version 5.0.1] - Fixed typo in variable name.
[Version 5.0.2] - Added detection of NuGet and PowerShell version to determine if package provider installation is needed.
[Version 5.0.3] - Fixed missing argument in call to Add-ToEnvironmentPath.
[Version 5.0.4] - Fixed bug with UpdateSelf function. Fixed bug when installing that may cause NuGet prompt to not be suppressed. Introduced Install-NuGetIfRequired function.
[Version 5.0.5] - Fixed exit code issue. Fixes #52.
[Version 5.0.6] - Fixed installation issue on Server 2022 by changing installation method to same as Server 2019. Fixes #62.
[Version 5.0.7] - Added the literal %LOCALAPPDATA% path to the user environment PATH to prevent issues when usernames or user profile paths change, or when using non-Latin characters. Fixes #45. Added support to catch Get-CimInstance errors, lately occurring in Windows Sandbox. Removed Server 2022 changes introduced in version 5.0.6. Register winget command in all OS versions except Server 2019. Fixes #57.
[Version 5.0.8] - Fixed an issue on Server 2019 where the script failed if the dependency was already installed by adding library/dependency version check functionality. Fixes #61. Thank you to @MatthiasGuelck for the fix.
[Version 5.0.9] - Improved script output. Fixed error messages caused when checking for an existing library/dependency version with multiple installed variants by choosing highest version number of the installed dependency.
[Version 5.1.0] - Added support for installing and using winget under the SYSTEM context. Thanks to @GraphicHealer for the contribution.
[Version 5.2.0] - Added support for installing winget dependencies from winget-cli GitHub repository. Added fix for issue #66 and #65. Fixed version detection for winget dependencies. Thanks to @JonathanPitre for the contribution.
[Version 5.2.1] - Switched SYSTEM account specification to SID identifier to avoid issues in non-US locales. Added avoidance of pre-release versions and dynamically installing dependencies. Thanks to @langermi and @AAGITLTD for the contribution.

#>

<#
.SYNOPSIS
    Downloads and installs the latest version of winget and its dependencies.
.DESCRIPTION
    Downloads and installs the latest version of winget and its dependencies.

This script is designed to be straightforward and easy to use, removing the hassle of manually downloading, installing, and configuring winget. This function should be run with administrative privileges.
.EXAMPLE
    winget-install
.PARAMETER Debug
    Enables debug mode, which shows additional information for debugging.
.PARAMETER Force
    Ensures installation of winget and its dependencies, even if already present.
.PARAMETER ForceClose
    Relaunches the script in conhost.exe and automatically ends active processes associated with winget that could interfere with the installation.
.PARAMETER Wait
    Forces the script to wait several seconds before exiting.
.PARAMETER NoExit
    Forces the script to wait indefinitely before exiting.
.PARAMETER UpdateSelf
    Updates the script to the latest version on PSGallery.
.PARAMETER CheckForUpdate
    Checks if there is an update available for the script.
.PARAMETER Version
    Displays the version of the script.
.PARAMETER Help
    Displays the full help information for the script.
.NOTES
    Version      : 5.2.1
    Created by   : asheroto
.LINK
    Project Site: https://github.com/asheroto/winget-install
#>
[CmdletBinding()]
param (
    [switch]$Force,
    [switch]$ForceClose,
    [switch]$AlternateInstallMethod,
    [switch]$CheckForUpdate,
    [switch]$Wait,
    [switch]$NoExit,
    [switch]$UpdateSelf,
    [switch]$Version,
    [switch]$Help
)

# Script information
$CurrentVersion = '5.2.1'
$RepoOwner = 'asheroto'
$RepoName = 'winget-install'
$PowerShellGalleryName = 'winget-install'

# Preferences
$ProgressPreference = 'SilentlyContinue' # Suppress progress bar (makes downloading super fast)
$ConfirmPreference = 'None' # Suppress confirmation prompts

# Display version if -Version is specified
if ($Version.IsPresent) {
    $CurrentVersion
    exit 0
}

# Display full help if -Help is specified
if ($Help) {
    Get-Help -Name $MyInvocation.MyCommand.Source -Full
    exit 0
}

# Display $PSVersionTable and Get-Host if -Verbose is specified
if ($PSBoundParameters.ContainsKey('Verbose') -and $PSBoundParameters['Verbose']) {
    $PSVersionTable
    Get-Host
}

# Set debug preferences if -Debug is specified
if ($PSBoundParameters.ContainsKey('Debug') -and $PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
    $ConfirmPreference = 'None'
}

# Check if running as SYSTEM
$RunAsSystem = $false
if ([System.Security.Principal.WindowsIdentity]::GetCurrent().User -match "S-1-5-18") {
    Write-Debug "Running as SYSTEM"
    $RunAsSystem = $true
}

# Find the WinGet Executable Loaction (for use when running in SYSTEM context)
function Find-WinGet {
    try {
        # Get the WinGet path
        $WinGetPathToResolve = Join-Path -Path $ENV:ProgramFiles -ChildPath 'WindowsApps\Microsoft.DesktopAppInstaller_*_*__8wekyb3d8bbwe'
        $ResolveWinGetPath = Resolve-Path -Path $WinGetPathToResolve -ErrorAction Stop | Sort-Object {
            [version]($_.Path -replace '^[^\d]+_((\d+\.)*\d+)_.*', '$1')
        }

        if ($ResolveWinGetPath) {
            # If we have multiple versions - use the latest.
            $WinGetPath = $ResolveWinGetPath[-1].Path
        }

        $WinGet = Join-Path $WinGetPath 'winget.exe'

        # Test if WinGet Executable exists
        if (Test-Path -Path $WinGet) {
            return $WinGet
        } else {
            return $null
        }
    } catch {
        Write-Debug "Could not resolve winget path: $($_.Exception.Message)"
        return $null
    }
}

function Get-OSInfo {
    <#
        .SYNOPSIS
        Retrieves detailed information about the operating system version and architecture.

        .DESCRIPTION
        This function queries both the Windows registry and the Win32_OperatingSystem class to gather comprehensive information about the operating system. It returns details such as the release ID, display version, name, type (Workstation/Server), numeric version, edition ID, version (object that includes major, minor, and build numbers), and architecture (OS architecture, not processor architecture).

        .EXAMPLE
        Get-OSInfo

        This example retrieves the OS version details of the current system and returns an object with properties like ReleaseId, DisplayVersion, Name, Type, NumericVersion, EditionId, Version, and Architecture.

        .EXAMPLE
        (Get-OSInfo).Version.Major

        This example retrieves the major version number of the operating system. The Get-OSInfo function returns an object with a Version property, which itself is an object containing Major, Minor, and Build properties. You can access these sub-properties using dot notation.

        .EXAMPLE
        $osDetails = Get-OSInfo
        Write-Output "OS Name: $($osDetails.Name)"
        Write-Output "OS Type: $($osDetails.Type)"
        Write-Output "OS Architecture: $($osDetails.Architecture)"

        This example stores the result of Get-OSInfo in a variable and then accesses various properties to print details about the operating system.
    #>
    [CmdletBinding()]
    param ()

    try {
        # Get registry values
        $registryValues = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
        $releaseIdValue = $registryValues.ReleaseId
        $displayVersionValue = $registryValues.DisplayVersion
        $nameValue = $registryValues.ProductName
        $editionIdValue = $registryValues.EditionId
        $installationType = $registryValues.InstallationType

        # Strip out "Server" from the $editionIdValue if it exists
        $editionIdValue = $editionIdValue -replace "Server", ""

        # Get OS details using Get-CimInstance because the registry key for Name is not always correct with Windows 11
        try {
            $osDetails = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        } catch {
            throw "Unable to run the command ""Get-CimInstance -ClassName Win32_OperatingSystem"". If you're using Window Sandbox, this may be related to a known issue with winget on Windows Sandbox: https://github.com/microsoft/Windows-Sandbox/issues/67"
        }

        # Get OS caption
        $nameValue = $osDetails.Caption

        # Get architecture details of the OS (not the processor)
        # Get only the numbers
        $architecture = ($osDetails.OSArchitecture -replace "[^\d]").Trim()

        # If 32-bit or 64-bit replace with x32 and x64
        if ($architecture -eq "32") {
            $architecture = "x32"
        } elseif ($architecture -eq "64") {
            $architecture = "x64"
        }

        # Get OS version details (as version object)
        $versionValue = [System.Environment]::OSVersion.Version

        # Determine product type
        # Reference: https://learn.microsoft.com/en-us/dotnet/api/microsoft.powershell.commands.producttype?view=powershellsdk-1.1.0
        if ($osDetails.ProductType -eq 1) {
            $typeValue = "Workstation"
        } elseif ($osDetails.ProductType -eq 2 -or $osDetails.ProductType -eq 3) {
            $typeValue = "Server"
        } else {
            $typeValue = "Unknown"
        }

        # Extract numerical value from Name
        $numericVersion = ($nameValue -replace "[^\d]").Trim()

        # If the numeric version is 10 or above, and the caption contains "multi-session", consider it a workstation
        if ($numericVersion -ge 10 -and $osDetails.Caption -match "multi-session") {
            $typeValue = "Workstation"
        }

        # Create and return custom object with the required properties
        $result = [PSCustomObject]@{
            ReleaseId        = $releaseIdValue
            DisplayVersion   = $displayVersionValue
            Name             = $nameValue
            Type             = $typeValue
            NumericVersion   = $numericVersion
            EditionId        = $editionIdValue
            InstallationType = $installationType
            Version          = $versionValue
            Architecture     = $architecture
        }

        return $result
    } catch {
        Write-Error "Unable to get OS version details.`nError: $_"
        ExitWithDelay 1
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

function CheckForUpdate {
    param (
        [string]$RepoOwner,
        [string]$RepoName,
        [version]$CurrentVersion,
        [string]$PowerShellGalleryName
    )

    $Data = Get-GitHubRelease -Owner $RepoOwner -Repo $RepoName

    Write-Output ""
    Write-Output ("Repository:       {0,-40}" -f "https://github.com/$RepoOwner/$RepoName")
    Write-Output ("Current Version:  {0,-40}" -f $CurrentVersion)
    Write-Output ("Latest Version:   {0,-40}" -f $Data.LatestVersion)
    Write-Output ("Published at:     {0,-40}" -f $Data.PublishedDateTime)

    if ($Data.LatestVersion -gt $CurrentVersion) {
        Write-Output ("Status:           {0,-40}" -f "A new version is available.")
        Write-Output "`nOptions to update:"
        Write-Output "- Download latest release: https://github.com/$RepoOwner/$RepoName/releases"
        if ($PowerShellGalleryName) {
            Write-Output "- Run: $RepoName -UpdateSelf"
            Write-Output "- Run: Install-Script $PowerShellGalleryName -Force"
        }
    } else {
        Write-Output ("Status:           {0,-40}" -f "Up to date.")
    }
    exit 0
}

function UpdateSelf {
    try {
        # Get PSGallery version of script
        $psGalleryScriptVersion = (Find-Script -Name $PowerShellGalleryName).Version

        # If the current version is less than the PSGallery version, update the script
        if ($CurrentVersion -lt $psGalleryScriptVersion) {
            Write-Output "Updating script to version $psGalleryScriptVersion..."

            # Check if running in PowerShell 7 or greater
            Write-Debug "Checking if NuGet PackageProvider is already installed..."
            Install-NuGetIfRequired

            # Trust the PSGallery if not already trusted
            $psRepoInstallationPolicy = (Get-PSRepository -Name 'PSGallery').InstallationPolicy
            if ($psRepoInstallationPolicy -ne 'Trusted') {
                Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted | Out-Null
            }

            # Update the script
            Install-Script $PowerShellGalleryName -Force

            # If PSGallery was not trusted, reset it to its original state
            if ($psRepoInstallationPolicy -ne 'Trusted') {
                Set-PSRepository -Name 'PSGallery' -InstallationPolicy $psRepoInstallationPolicy | Out-Null
            }

            Write-Output "Script updated to version $psGalleryScriptVersion."
            exit 0
        } else {
            Write-Output "Script is already up to date."
            exit 0
        }
    } catch {
        Write-Output "An error occurred: $_"
        exit 1
    }
}

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

function Get-WingetDownloadUrl {
    <#
        .SYNOPSIS
        Retrieves the download URL of the latest release asset that matches a specified pattern from the GitHub repository.

        .DESCRIPTION
        This function uses the GitHub API to get information about the latest release of the winget-cli repository.
        It then retrieves the download URL for the release asset that matches a specified pattern.

        .PARAMETER Match
        The pattern to match in the asset names.

        .EXAMPLE
        Get-WingetDownloadUrl "msixbundle"
        This command retrieves the download URL for the latest release asset with a name that contains "msixbundle".
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Match
    )

    $uri = "https://api.github.com/repos/microsoft/winget-cli/releases"
    $releases = Invoke-RestMethod -uri $uri -Method Get -ErrorAction Stop

    Write-Debug "Getting latest release..."
    foreach ($release in $releases) {
        if ($release.name -match "preview" -or $release.prerelease) {
            continue
        }
        $data = $release.assets | Where-Object name -Match $Match
        if ($data) {
            return $data.browser_download_url
        }
    }

    Write-Debug "Falling back to the latest release..."
    $latestRelease = $releases | Select-Object -First 1
    $data = $latestRelease.assets | Where-Object name -Match $Match
    return $data.browser_download_url
}

function Get-WingetStatus {
    <#
        .SYNOPSIS
        Checks if winget is installed.

        .DESCRIPTION
        This function checks if winget is installed.

        .EXAMPLE
        Get-WingetStatus
    #>

    # Check if winget is installed
    if ($RunAsSystem) {
        $wingetPath = Find-WinGet
        if ($null -ne $wingetPath) {
            $winget = & $wingetPath -v
        } else {
            $winget = $null
        }
    } else {
        $winget = Get-Command -Name winget -ErrorAction SilentlyContinue
    }

    # If winget is installed, return $true
    if ($null -ne $winget -and $winget -notlike '*failed to run*') {
        return $true
    }

    # If winget is not installed, return $false
    return $false
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

    # Handle common errors
    # Not returning $ErrorRecord on some errors is intentional
    if ($ErrorRecord.Exception.Message -match '0x80073D06') {
        Write-Warning "Higher version already installed."
        Write-Warning "That's okay, continuing..."
    } elseif ($ErrorRecord.Exception.Message -match '0x80073CF0') {
        Write-Warning "Same version already installed."
        Write-Warning "That's okay, continuing..."
    } elseif ($ErrorRecord.Exception.Message -match '0x80073D02') {
        # Stop execution and return the ErrorRecord so that the calling try/catch block throws the error
        Write-Warning "Resources modified are in-use. Try closing Windows Terminal / PowerShell / Command Prompt and try again."
        Write-Warning "Windows Terminal sometimes has trouble installing winget. If you are using Windows Terminal and the problem persists, run the script with the -ForceClose parameter which will relaunch the script in conhost.exe and automatically end active processes associated with winget that could interfere with the installation. Please note that using the -ForceClose parameter will close the PowerShell window and could break custom scripts that rely on the current PowerShell session."
        return $ErrorRecord
    } elseif ($ErrorRecord.Exception.Message -match '0x80073CF3') {
        # Prerequisite not detected, tell user to run it again
        Write-Warning "Problem with one of the prerequisites."
        Write-Warning "Try running the script again which usually fixes the issue. If the problem persists, try running the script with the -ForceClose parameter which will relaunch the script in conhost.exe and automatically end active processes associated with winget that could interfere with the installation. Please note that using the -ForceClose parameter will close the PowerShell window and could break custom scripts that rely on the current PowerShell session."
        return $ErrorRecord
    } elseif ($ErrorRecord.Exception.Message -match '0x80073CF9') {
        Write-Warning "Registering winget failed with error code 0x80073CF9."
        Write-Warning "This error usually occurs when using the Local System account to install winget. The SYSTEM account is not officially supported by winget and may not work. See the requirements section of the README. If winget is not working, run the installation script again using an Administrator account."
    } elseif ($ErrorRecord.Exception.Message -match 'Unable to connect to the remote server') {
        Write-Warning "Cannot connect to the Internet to download the required files."
        Write-Warning "Try running the script again and make sure you are connected to the Internet."
        Write-Warning "Sometimes the nuget.org server is down, so you may need to try again later."
        return $ErrorRecord
    } elseif ($ErrorRecord.Exception.Message -match "The remote name could not be resolved") {
        Write-Warning "Cannot connect to the Internet to download the required files."
        Write-Warning "Try running the script again and make sure you are connected to the Internet."
        Write-Warning "Make sure DNS is working correctly on your computer."
    } else {
        # For other errors, we should stop the execution and return the ErrorRecord so that the calling try/catch block throws the error
        return $ErrorRecord
    }

    # Reset to original value
    $ErrorActionPreference = $OriginalErrorActionPreference
}

function Get-CurrentProcess {
    <#
        .SYNOPSIS
            Retrieves the current PowerShell process information.

        .DESCRIPTION
            The Get-CurrentProcess function identifies the current PowerShell process by temporarily changing the console window title. It then filters the list of running processes to find the one with the matching window title. The function returns a custom object containing the Name and Id of the current process.

        .EXAMPLE
            PS C:\> $result = Get-CurrentProcess
            PS C:\> Write-Output $result

            This example demonstrates how to call the Get-CurrentProcess function and store its output in a variable named $result. The output is then displayed using Write-Output.

        .NOTES
            The function temporarily changes the console window title. Ensure no other scripts or processes are dependent on the window title during execution. The function uses a 1-second sleep to allow time for the window title change to take effect. This may vary based on system performance.
    #>
    $oldTitle = $host.ui.RawUI.WindowTitle
    $tempTitle = ([Guid]::NewGuid())
    $host.ui.RawUI.WindowTitle = $tempTitle
    Start-Sleep 1
    $currentProcess = Get-Process | Where-Object { $_.MainWindowTitle -eq $tempTitle }
    $currentProcess = [PSCustomObject]@{
        Name = $currentProcess.Name
        Id   = $currentProcess.Id
    }
    $host.ui.RawUI.WindowTitle = $oldTitle
    return $currentProcess
}

function ExitWithDelay {
    <#
        .SYNOPSIS
            Exits the script with a specified exit code after a specified delay, 10 seconds by default.

        .DESCRIPTION
            This function takes an exit code as an argument, waits for 10 seconds unless specified, and then exits the script with the given exit code.

        .PARAMETER ExitCode
            The exit code to use when exiting the script.

        .EXAMPLE
            ExitWithDelay -ExitCode 1
            Waits for 10 seconds (default) and then exits the script with an exit code of 1.

        .EXAMPLE
            ExitWithDelay -ExitCode 2 -Seconds 5
            Waits for 5 seconds and then exits the script with an exit code of 2.
        .NOTES
            Use this function to introduce a delay before exiting the script, allowing time for any cleanup or logging activities.
    #>

    param (
        [int]$ExitCode,
        [int]$Seconds = 10
    )

    # Debug mode output
    if ($Debug -and $Wait) {
        Write-Warning "Wait specified, waiting several seconds..."
    } elseif ($Debug -and !$Wait) {
        Write-Warning "Wait not specified, exiting immediately..."
    }

    # If Wait is specified, wait for x seconds before exiting
    if ($Wait) {
        # Waiting for x seconds output
        Write-Output "`nWaiting for $Seconds seconds before exiting..."
        Start-Sleep -Seconds $Seconds
    }

    # If NoExit is specified, do not exit the script
    if ($NoExit) {
        Write-Output "Script completed. Pausing indefinitely. Press any key to exit..."
        Read-Host
    }

    # Exit the script with exit code
    if ($MyInvocation.CommandOrigin -eq "Runspace") {
        Break
    } else {
        Exit $ExitCode
    }
}

function Import-GlobalVariable {
    <#
        .SYNOPSIS
        This function checks if a specified global variable exists and imports its value into a script scope variable of the same name.

        .DESCRIPTION
        The Import-GlobalVariable function allows you to specify the name of a variable. It checks if a global variable with that name exists, and if it does, it imports its value into a script scope variable with the same name.

        .PARAMETER VariableName
        The name of the variable to check and import if it exists in the global scope.

    #>

    [CmdletBinding()]
    param(
        [string]$VariableName
    )

    # Check if the specified global variable exists; if yes, import its value
    try {
        $globalValue = Get-Variable -Name $VariableName -ValueOnly -Scope Global -ErrorAction Stop
        Set-Variable -Name $VariableName -Value $globalValue -Scope Script
    } catch {
        # If the variable does not exist, do nothing
    }
}

function Test-AdminPrivileges {
    <#
    .SYNOPSIS
        Checks if the script is running with Administrator privileges. Returns $true if running with Administrator privileges, $false otherwise.

    .DESCRIPTION
        This function checks if the current PowerShell session is running with Administrator privileges by examining the role of the current user. It returns $true if the current user is an Administrator, $false otherwise.

    .EXAMPLE
        Test-AdminPrivileges

    .NOTES
        This function is particularly useful for scripts that require elevated permissions to run correctly.
    #>
    if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        return $true
    }
    return $false
}

Function New-TemporaryFile2 {
    <#
    .SYNOPSIS
        Creates a new temporary file.

    .DESCRIPTION
        This function generates a temporary file and returns the full path of the file. The New-TemporaryFile command is not available in PowerShell 5.1 and earlier so this function is a workaround.

    .EXAMPLE
        $tempFile = New-TemporaryFile2
        This example creates a new temporary file and stores its path in the $tempFile variable.

    .OUTPUTS
        String. The full path of the created temporary file.
    #>

    # Create a temporary file
    $tempPath = [System.IO.Path]::GetTempPath()
    $tempFile = [System.IO.Path]::Combine($tempPath, [System.IO.Path]::GetRandomFileName())
    $null = New-Item -Path $tempFile -ItemType File -Force

    # Return the path of the temporary file
    return $tempFile
}

function Path-ExistsInEnvironment {
    param (
        [string]$PathToCheck,
        [string]$Scope = 'Both' # Valid values: 'User', 'System', 'Both'
    )
    <#
    .SYNOPSIS
    Checks if the specified path exists in the specified PATH environment variable.

    .DESCRIPTION
    This function checks if a given path is present in the user, system-wide, or both PATH environment variables.

    .PARAMETER PathToCheck
    The directory path to check in the environment PATH variable.

    .PARAMETER Scope
    The scope to check in the environment PATH variable. Valid values are 'User', 'System', or 'Both'. Default is 'Both'.

    .EXAMPLE
    Path-ExistsInEnvironment -PathToCheck "C:\Program Files\MyApp" -Scope 'User'
    #>

    $pathExists = $false

    if ($Scope -eq 'User' -or $Scope -eq 'Both') {
        $userEnvPath = $env:PATH
        if (($userEnvPath -split ';').Contains($PathToCheck)) {
            $pathExists = $true
        }
    }

    if ($Scope -eq 'System' -or $Scope -eq 'Both') {
        $systemEnvPath = [System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::Machine)
        if (($systemEnvPath -split ';').Contains($PathToCheck)) {
            $pathExists = $true
        }
    }

    return $pathExists
}

function Add-ToEnvironmentPath {
    param (
        [Parameter(Mandatory = $true)]
        [string]$PathToAdd,

        [Parameter(Mandatory = $true)]
        [ValidateSet('User', 'System')]
        [string]$Scope
    )
    <#
    .SYNOPSIS
    Adds the specified path to the environment PATH variable.

    .DESCRIPTION
    This function adds a given path to the specified scope (user or system) and the current process environment PATH variable if it is not already present.

    .PARAMETER PathToAdd
    The directory path to add to the environment PATH variable.

    .PARAMETER Scope
    Specifies whether to add the path to the user or system environment PATH variable.

    .EXAMPLE
    Add-ToEnvironmentPath -PathToAdd "C:\Program Files\MyApp" -Scope 'System'
    #>

    # Check if the path is already in the environment PATH variable
    if (-not (Path-ExistsInEnvironment -PathToCheck $PathToAdd -Scope $Scope)) {
        if ($Scope -eq 'System') {
            # Get the current system PATH
            $systemEnvPath = [System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::Machine)
            # Add to system PATH
            $systemEnvPath += ";$PathToAdd"
            [System.Environment]::SetEnvironmentVariable('PATH', $systemEnvPath, [System.EnvironmentVariableTarget]::Machine)
            Write-Debug "Adding $PathToAdd to the system PATH."
        } elseif ($Scope -eq 'User') {
            # Get the current user PATH
            $userEnvPath = [System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::User)
            # Add to user PATH
            $userEnvPath += ";$PathToAdd"
            [System.Environment]::SetEnvironmentVariable('PATH', $userEnvPath, [System.EnvironmentVariableTarget]::User)
            Write-Debug "Adding $PathToAdd to the user PATH."
        }

        # Update the current process environment PATH
        if (-not ($env:PATH -split ';').Contains($PathToAdd)) {
            $env:PATH += ";$PathToAdd"
            Write-Debug "Adding $PathToAdd to the current process environment PATH."
        }
    } else {
        Write-Debug "$PathToAdd is already in the PATH."
    }
}

function Set-PathPermissions {
    param (
        [string]$FolderPath
    )
    <#
    .SYNOPSIS
    Grants full control permissions for the Administrators group on the specified directory path.

    .DESCRIPTION
    This function sets full control permissions for the Administrators group on the specified directory path.
    Useful for ensuring that administrators have unrestricted access to a given folder.

    .PARAMETER FolderPath
    The directory path for which to set full control permissions.

    .EXAMPLE
    Set-PathPermissions -FolderPath "C:\Program Files\MyApp"

    Sets full control permissions for the Administrators group on "C:\Program Files\MyApp".
    #>

    Write-Debug "Setting full control permissions for the Administrators group on $FolderPath."

    # Define the SID for the Administrators group
    $administratorsGroupSid = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
    $administratorsGroup = $administratorsGroupSid.Translate([System.Security.Principal.NTAccount])

    # Retrieve the current ACL for the folder
    $acl = Get-Acl -Path $FolderPath

    # Define the access rule for full control inheritance
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $administratorsGroup,
        "FullControl",
        "ContainerInherit,ObjectInherit",
        "None",
        "Allow"
    )

    # Apply the access rule to the ACL and set it on the folder
    $acl.SetAccessRule($accessRule)
    Set-Acl -Path $FolderPath -AclObject $acl
}

function Test-VCRedistInstalled {
    <#
    .SYNOPSIS
    Checks if Visual C++ Redistributable is installed and verifies the major version is 14.

    .DESCRIPTION
    This function checks the registry and the file system to determine if Visual C++ Redistributable is installed
    and if the major version is 14.

    .EXAMPLE
    Test-VCRedistInstalled
    #>

    # Assets
    $64BitOS = [System.Environment]::Is64BitOperatingSystem
    $64BitProcess = [System.Environment]::Is64BitProcess

    # Require running system native process
    if ($64BitOS -and -not $64BitProcess) {
        Throw 'Please run PowerShell in the system native architecture (x64 PowerShell if x64 Windows).'
    }

    # Check that uninstall information exists in the registry
    $registryPath = [string]::Format(
        'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\{0}\Microsoft\VisualStudio\14.0\VC\Runtimes\X{1}',
        $(if ($64BitOS -and $64BitProcess) { 'WOW6432Node' } else { '' }),
        $(if ($64BitOS) { '64' } else { '86' })
    )

    $registryExists = Test-Path -Path $registryPath

    Write-Debug "Registry Path: $registryPath"
    Write-Debug "Registry Exists: $registryExists"

    # Check the major version
    $majorVersion = if ($registryExists) {
        (Get-ItemProperty -Path $registryPath -Name 'Major').Major
    } else {
        0
    }

    # Check the full version
    $version = if ($registryExists) {
        (Get-ItemProperty -Path $registryPath -Name 'Version').Version
    } else {
        0
    }

    Write-Debug "Major Version: $majorVersion"
    Write-Debug "Version: $version"

    # Check that one required DLL exists on the file system
    $dllPath = [string]::Format(
        '{0}\system32\concrt140.dll',
        $env:windir
    )

    $dllExists = [System.IO.File]::Exists($dllPath)

    Write-Debug "DLL Path: $dllPath"
    Write-Debug "DLL Exists: $dllExists"

    # Determine if VCRedist is installed and major version is 14
    return $registryExists -and $majorVersion -eq 14 -and $dllExists
}

function TryRemove {
    <#
    .SYNOPSIS
    Tries to remove a specified file if it exists.

    .DESCRIPTION
    This function checks if the specified file exists and attempts to remove it.
    It will not produce an error if the file does not exist or if the removal fails.

    .PARAMETER FilePath
    The path to the file that should be removed.

    .EXAMPLE
    TryRemove -FilePath "C:\path\to\file.txt"
    #>

    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    try {
        if (Test-Path -Path $FilePath) {
            Remove-Item -Path $FilePath -ErrorAction SilentlyContinue
            if ($?) {
                Write-Debug "File '$FilePath' was successfully removed."
            } else {
                Write-Debug "Failed to remove the file '$FilePath'."
            }
        } else {
            Write-Debug "File '$FilePath' does not exist."
        }
    } catch {
        Write-Debug "An error occurred while trying to remove the file '$FilePath'."
    }
}

function Install-NuGetIfRequired {
    <#
    .SYNOPSIS
    Checks if the NuGet PackageProvider is installed and installs it if required.

    .DESCRIPTION
    This function checks whether the NuGet PackageProvider is already installed on the system. If it is not found and the current PowerShell version is less than 7, it attempts to install the NuGet provider using Install-PackageProvider.
    For PowerShell 7 or greater, it assumes NuGet is available by default and advises reinstallation if NuGet is missing.

    .PARAMETER Debug
    Enables debug output for additional details during installation.

    .EXAMPLE
    Install-NuGetIfRequired
    # Checks for the NuGet provider and installs it if necessary.

    .NOTES
    This function only attempts to install NuGet if the PowerShell version is less than 7.
    For PowerShell 7 or greater, NuGet is typically included by default and does not require installation.
    #>

    # Check if NuGet PackageProvider is already installed, skip package provider installation if found
    if (-not (Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue)) {
        Write-Debug "NuGet PackageProvider not found."

        # Check if running in PowerShell version less than 7
        if ($PSVersionTable.PSVersion.Major -lt 7) {
            # Install NuGet PackageProvider if running PowerShell version less than 7
            # PowerShell 7 has limited support for installing package providers, but NuGet is available by default in PowerShell 7 so installation is not required

            Write-Debug "Installing NuGet PackageProvider..."

            if ($Debug) {
                try { Install-PackageProvider -Name "NuGet" -Force -ForceBootstrap -ErrorAction SilentlyContinue } catch { }
            } else {
                try { Install-PackageProvider -Name "NuGet" -Force -ForceBootstrap -ErrorAction SilentlyContinue | Out-Null } catch {}
            }
        } else {
            # NuGet should be included by default in PowerShell 7, so if it's not detected, advise reinstallation
            Write-Warning "NuGet is not detected in PowerShell 7. Consider reinstalling PowerShell 7, as NuGet should be included by default."
        }
    } else {
        # NuGet PackageProvider is already installed
        Write-Debug "NuGet PackageProvider is already installed. Skipping installation."
    }
}

function Get-ManifestName {
    <#
    .SYNOPSIS
    Retrieves the name of the library from the AppxManifest.xml file from a specified library path.

    .DESCRIPTION
    This function opens a ZIP file at the specified path, reads the AppxManifest.xml file inside it,
    and retrieves the name of the library from the manifest.

    .PARAMETER Lib_Path
    The path to the library (ZIP) file containing the AppxManifest.xml.

    .EXAMPLE
    Get-ManifestName -Lib_Path "C:\path\to\library.zip"
    #>

    param(
        [Parameter(Mandatory)]
        [string]$Lib_Path
    )

    Write-Debug "Checking manifest name of $($Lib_Path)..."

    # Load ZIP assembly to read the package contents
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($Lib_Path)

    Write-Debug "Reading AppxManifest.xml from $($Lib_Path)..."
    # Find and read the AppxManifest.xml
    $entry = $zip.Entries | Where-Object { $_.FullName -eq "AppxManifest.xml" }

    if ($entry) {
        $stream = $entry.Open()
        $reader = New-Object System.IO.StreamReader($stream)
        [xml]$xml = $reader.ReadToEnd()
        $reader.Close()
        $zip.Dispose()

        # Output the name from the manifest
        $DownloadedLibName = $xml.Package.Identity.Name
        Write-Debug "Downloaded library name: $DownloadedLibName"
    } else {
        Write-Error "AppxManifest.xml not found inside the file: $Lib_Path"
    }

    return $DownloadedLibName
}

function Get-ManifestVersion {
    <#
    .SYNOPSIS
    Retrieves the version of the AppxManifest.xml file from a specified library path.

    .DESCRIPTION
    This function opens a ZIP file at the specified path, reads the AppxManifest.xml file inside it,
    and retrieves the version information from the manifest.

    .PARAMETER Lib_Path
    The path to the library (ZIP) file containing the AppxManifest.xml.

    .EXAMPLE
    Get-ManifestVersion -Lib_Path "C:\path\to\library.zip"
    #>

    param(
        [Parameter(Mandatory)]
        [string]$Lib_Path
    )

    Write-Debug "Checking manifest version of $($Lib_Path)..."

    # Load ZIP assembly to read the package contents
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($Lib_Path)

    Write-Debug "Reading AppxManifest.xml from $($Lib_Path)..."
    # Find and read the AppxManifest.xml
    $entry = $zip.Entries | Where-Object { $_.FullName -eq "AppxManifest.xml" }

    if ($entry) {
        $stream = $entry.Open()
        $reader = New-Object System.IO.StreamReader($stream)
        [xml]$xml = $reader.ReadToEnd()
        $reader.Close()
        $zip.Dispose()

        # Output the version from the manifest
        $DownloadedLibVersion = $xml.Package.Identity.Version
        Write-Debug "Downloaded library version: $DownloadedLibVersion"
    } else {
        Write-Error "AppxManifest.xml not found inside the file: $Lib_Path"
    }

    return $DownloadedLibVersion
}

function Get-InstalledLibVersion {
    <#
    .SYNOPSIS
    Retrieves the installed version of a specified library.

    .DESCRIPTION
    This function checks if a specified library is installed on the system and retrieves its version information.

    .PARAMETER Lib_Name
    The name of the library to check for installation and retrieve the version.

    .EXAMPLE
    Get-InstalledLibVersion -Lib_Name "VCLibs.140.00.UWPDesktop"
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Lib_Name
    )

    Write-Debug "Checking installed library version of $($Lib_Name)..."

    # Get the highest version of the installed library
    $InstalledLib = Get-AppxPackage -Name "*$($Lib_Name)*" -ErrorAction SilentlyContinue | Sort-Object Version -Descending | Select-Object -First 1

    if ($InstalledLib) {
        $InstalledLibVersion = $InstalledLib.Version
        Write-Debug "Installed library version: $InstalledLibVersion"
    } else {
        Write-Output "Library is not installed."
        $InstalledLibVersion = $null
    }

    return $InstalledLibVersion
}

function Install-LibIfRequired {
    <#
    .SyNOPSIS
    Installs a specified library if it is not already installed or if the downloaded version is newer.

    .DESCRIPTION
    This function checks if a specified library is installed on the system.
    If it is not installed or if the downloaded version is newer than the installed version, it installs the library.

    .PARAMETER Lib_Name
    The name of the library to check for installation and retrieve the version.

    .PARAMETER Lib_Path
    The path to the library (ZIP) file containing the AppxManifest.xml.

    .EXAMPLE
    Install-LibIfRequired -Lib_Name "VCLibs.140.00.UWPDesktop" -Lib_Path "C:\path\to\library.zip"
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Lib_Name,
        [Parameter(Mandatory)]
        [string]$Lib_Path
    )

    # Check the installed version of Lib
    $InstalledLibVersion = Get-InstalledLibVersion -Lib_Name $Lib_Name

    # Extract version from the downloaded file
    $DownloadedLibVersion = Get-ManifestVersion -Lib_Path $Lib_Path

    # Compare versions and install if necessary
    if (!$InstalledLibVersion -or !$DownloadedLibVersion -or ($DownloadedLibVersion -gt $InstalledLibVersion)) {
        if ($RunAsSystem) {
            Write-Debug 'Running as system...'
            Write-Debug "Installing library version $($DownloadedLibVersion)..."
            $null = Add-ProvisionedAppxPackage -Online -SkipLicense -PackagePath $Lib_Path
        } else {
            Write-Debug 'Running as user...'
            Write-Debug "Installing library version $($DownloadedLibVersion)..."
            $null = Add-AppxPackage -Path $Lib_Path
        }
    } else {
        Write-Output "Installed library version is up-to-date or newer. Skipping installation."
    }
}


# ============================================================================ #
# Initial checks
# ============================================================================ #

# Use global variables if specified by user
Import-GlobalVariable -VariableName "Debug"
Import-GlobalVariable -VariableName "ForceClose"
Import-GlobalVariable -VariableName "Force"
Import-GlobalVariable -VariableName "AlternateInstallMethod"

# First heading
Write-Output "winget-install $CurrentVersion"

# Check for updates if -CheckForUpdate is specified
if ($CheckForUpdate) { CheckForUpdate -RepoOwner $RepoOwner -RepoName $RepoName -CurrentVersion $CurrentVersion -PowerShellGalleryName $PowerShellGalleryName }

# Update the script if -UpdateSelf is specified
if ($UpdateSelf) { UpdateSelf }

# Heading
Write-Output "To check for updates, run winget-install -CheckForUpdate"
Write-Output "To delay script exit, run winget-install -Wait"
Write-Output "To force script pausing after execution, run winget-install -NoExit"

# Check if the current user is an administrator
if (-not (Test-AdminPrivileges)) {
    Write-Warning "winget requires Administrator privileges to install. Please run the script as an Administrator and try again."
    ExitWithDelay 1
}

# Get OS version
$osVersion = Get-OSInfo

# Get architecture type
$arch = $osVersion.Architecture

# Get current process module name to determine if launched in conhost
$currentProcess = Get-CurrentProcess

# If it's a workstation, make sure it is Windows 10+
if ($osVersion.Type -eq "Workstation" -and $osVersion.NumericVersion -lt 10) {
    Write-Error "winget requires Windows 10 or later on workstations. Your version of Windows is not supported."
    ExitWithDelay 1
}

# If it's a workstation with Windows 10, make sure it's version 1809 or greater
if ($osVersion.Type -eq "Workstation" -and $osVersion.NumericVersion -eq 10 -and $osVersion.ReleaseId -lt 1809) {
    Write-Error "winget requires Windows 10 version 1809 or later on workstations. Please update Windows to a compatible version."
    ExitWithDelay 1
}

# If it's a server, it needs to be 2019+
if ($osVersion.Type -eq "Server" -and $osVersion.NumericVersion -lt 2019) {
    Write-Error "winget requires Windows Server 2019 or newer on server platforms. Your version of Windows Server is not supported."
    ExitWithDelay 1
}

# Check if winget is already installed
if (Get-WingetStatus) {
    if ($Force -eq $false) {
        Write-Warning "winget is already installed, exiting..."
        Write-Warning "If you want to reinstall winget, run the script with the -Force parameter."
        ExitWithDelay 0 5
    }
}

# Check if ForceClose parameter is specified. If terminal detected, so relaunch in conhost
if ($ForceClose) {
    Write-Warning "ForceClose parameter is specified."
    if ($currentProcess.Name -eq "WindowsTerminal") {
        Write-Warning "Terminal detected, relaunching in conhost in 10 seconds..."
        Write-Warning "It may break your custom batch files and ps1 scripts with extra commands!"
        Start-Sleep -Seconds 10

        # Prepare the command to relaunch
        $command = "cd '$pwd'; $($MyInvocation.Line)"

        # Append parameters if their corresponding variables are $true and not already in the command
        if ($Force -and !($command -imatch '\s-Force\b')) { $command += " -Force" }
        if ($ForceClose -and !($command -imatch '\s-ForceClose\b')) { $command += " -ForceClose" }
        if ($Debug -and !($command -imatch '\s-Debug\b')) { $command += " -Debug" }

        # Relaunch in conhost
        if ([Environment]::Is64BitOperatingSystem) {
            if ([Environment]::Is64BitProcess) {
                Start-Process -FilePath "conhost.exe" -ArgumentList "powershell -ExecutionPolicy Bypass -Command &{$command}" -Verb RunAs
            } else {
                Start-Process -FilePath "$env:windir\sysnative\conhost.exe" -ArgumentList "powershell -ExecutionPolicy Bypass -Command &{$command}" -Verb RunAs
            }
        } else {
            Start-Process -FilePath "conhost.exe" -ArgumentList "powershell -ExecutionPolicy Bypass -Command &{$command}" -Verb RunAs
        }

        # Stop the current process module
        Stop-Process -id $currentProcess.Id
    } else {
        Write-Warning "Windows Terminal not detected, continuing..."
    }
}

# ============================================================================ #
# Beginning of installation process
# ============================================================================ #

try {
    # ============================================================================ #
    # Server Core Portable winget Installation (No AppX registration)
    # ============================================================================ #

    if ($osVersion.Type -eq "Server" -and $osVersion.InstallationType -eq "Server Core") {
        Write-Output ""
        Write-Output "Detected Windows Server Core. Performing portable winget extraction."

        Write-Section "Portable winget"

        $PortableWingetDirectory = Join-Path $env:ProgramFiles "Microsoft\winget"

        # Determine architecture
        $arch = (Get-OSInfo).Architecture
        if ($arch -eq "x32") { $arch = "x86" }

        # Helper – compatible ExtractToDirectory (no .NET 6 overloads)
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        function Expand-ZipOverwrite($Source, $Destination) {
            if (Test-Path $Destination) {
                Remove-Item -Recurse -Force $Destination -ErrorAction SilentlyContinue
            }
            [System.IO.Compression.ZipFile]::ExtractToDirectory($Source, $Destination)
        }

        # ------------------------------------------------------------------------ #
        # Download and extract dependencies
        # ------------------------------------------------------------------------ #
        Write-Section "Dependencies"

        $WingetDependenciesPath = New-TemporaryFile2
        $WingetDependenciesUrl = Get-WingetDownloadUrl -Match 'DesktopAppInstaller_Dependencies.zip'
        Write-Output "Downloading winget dependencies from $WingetDependenciesUrl..."
        Invoke-WebRequest -Uri $WingetDependenciesUrl -OutFile $WingetDependenciesPath -UseBasicParsing

        $Zip = [System.IO.Compression.ZipFile]::OpenRead($WingetDependenciesPath)
        $MatchingEntries = $Zip.Entries | Where-Object { $_.FullName -match ".*$arch/.*\.appx$" }
        if (-not $MatchingEntries) { Write-Error "No matching dependencies found for $arch."; ExitWithDelay 1 }

        $ExtractedAppx = @()
        foreach ($Entry in $MatchingEntries) {
            $DestPath = Join-Path ([System.IO.Path]::GetTempPath()) $Entry.Name
            Write-Output "Extracting $($Entry.FullName) to $DestPath..."
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($Entry, $DestPath, $true)
            $ExtractedAppx += $DestPath
        }
        $Zip.Dispose()

        # Expand .appx contents
        $StagingDir = Join-Path $env:TEMP "winget_staging_$arch"
        if (-not (Test-Path $StagingDir)) { New-Item -ItemType Directory -Force -Path $StagingDir | Out-Null }

        foreach ($Appx in $ExtractedAppx) {
            Write-Output "Expanding $Appx..."
            Expand-ZipOverwrite $Appx $StagingDir
        }

        # ------------------------------------------------------------------------ #
        # Extract AppInstaller (winget) package itself
        # ------------------------------------------------------------------------ #
        $WingetPackagePath = New-TemporaryFile2
        $WingetPackageUrl = (Get-WingetDownloadUrl -Match '(AppInstaller|DesktopAppInstaller).*\.(msixbundle|msix)$' | Select-Object -First 1)
        if (-not $WingetPackageUrl) { Write-Error "Unable to locate AppInstaller package."; ExitWithDelay 1 }

        Write-Output "Downloading App Installer (winget) package from $WingetPackageUrl..."
        Invoke-WebRequest -Uri $WingetPackageUrl -OutFile $WingetPackagePath -UseBasicParsing

        $AppInstallerExtractDir = Join-Path $env:TEMP "winget_appinstaller_$arch"
        Expand-ZipOverwrite $WingetPackagePath $AppInstallerExtractDir

        $NestedMsix = Get-ChildItem -Path $AppInstallerExtractDir -Recurse -Include '*.msix' -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($NestedMsix) {
            Write-Output "Extracting nested $($NestedMsix.Name)..."
            Expand-ZipOverwrite $NestedMsix.FullName $StagingDir
        }

        # ------------------------------------------------------------------------ #
        # Copy extracted files into final portable directory
        # ------------------------------------------------------------------------ #
        Write-Output "Copying extracted files to $PortableWingetDirectory..."

        if (-not (Test-Path $PortableWingetDirectory)) {
            New-Item -ItemType Directory -Force -Path $PortableWingetDirectory | Out-Null
        }

        # Only copy when source and destination differ
        Get-ChildItem -Path $StagingDir -Recurse | ForEach-Object {
            $TargetPath = $_.FullName.Replace($StagingDir, $PortableWingetDirectory)
            if ($_.FullName -ieq $TargetPath) { return }

            $TargetFolder = Split-Path $TargetPath -Parent
            if (-not (Test-Path $TargetFolder)) {
                New-Item -ItemType Directory -Force -Path $TargetFolder | Out-Null
            }

            try {
                Copy-Item -LiteralPath $_.FullName -Destination $TargetPath -Force -ErrorAction Stop
            } catch {
                Write-Warning "Skipping $($_.FullName): $($_.Exception.Message)"
            }
        }

        # ------------------------------------------------------------------------ #
        # Final link fix
        # ------------------------------------------------------------------------ #
        $GlobalizationDll = Join-Path $PortableWingetDirectory "Windows.Globalization.dll"
        $UserProfileLink = Join-Path $PortableWingetDirectory "Windows.System.UserProfile.dll"

        if ((Test-Path $GlobalizationDll) -and (-not (Test-Path $UserProfileLink))) {
            New-Item -ItemType SymbolicLink -Path $UserProfileLink -Target $GlobalizationDll -Force | Out-Null
        }

        Write-Output "Portable winget extraction completed successfully."
        Remove-Item -LiteralPath $WingetDependenciesPath -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $StagingDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    # ============================================================================ #
    # Install using the regular method, Windows 10+
    # ============================================================================ #

    if ($osVersion.NumericVersion -ne 2019 -and $osVersion.InstallationType -ne "Server Core" -and $AlternateInstallMethod -eq $false -and $RunAsSystem -eq $false) {

        Write-Section "winget"

        try {
            Write-Debug "Checking if NuGet PackageProvider is already installed..."
            Install-NuGetIfRequired

            Write-Output "Installing Microsoft.WinGet.Client module..."
            if ($Debug) {
                try { Install-Module -Name Microsoft.WinGet.Client -Force -AllowClobber -Repository PSGallery -ErrorAction SilentlyContinue } catch { }
            } else {
                try { Install-Module -Name Microsoft.WinGet.Client -Force -AllowClobber -Repository PSGallery -ErrorAction SilentlyContinue *>&1 | Out-Null } catch { }
            }

            Write-Output "Installing winget (this takes a minute or two)..."
            if ($Debug) {
                try { Repair-WinGetPackageManager -AllUsers -Force -Latest } catch { }
            } else {
                try { Repair-WinGetPackageManager -AllUsers -Force -Latest *>&1 | Out-Null } catch { }
            }
        } catch {
            $errorHandled = Handle-Error $_
            if ($null -ne $errorHandled) {
                throw $errorHandled
            }
            $errorHandled = $null
        }

        # Add to environment PATH to avoid issues when usernames or user profile paths change, or when using non-Latin characters (see #45)
        # Adding with literal %LOCALAPPDATA% to ensure it isn't resolved to the current user's LocalAppData as a fixed path
        Add-ToEnvironmentPath -PathToAdd "%LOCALAPPDATA%\Microsoft\WindowsApps" -Scope 'User'

    }

    # ============================================================================ #
    #  Server 2019 or alternate install method only
    # ============================================================================ #

    if (($osVersion.Type -eq "Server" -and ($osVersion.NumericVersion -eq 2019)) -and $osVersion.InstallationType -ne "Server Core" -or $AlternateInstallMethod -or $RunAsSystem) {

        # ============================================================================ #
        # Dependencies
        # ============================================================================ #

        Write-Section "Dependencies"

        try {
            # Download winget dependencies (VCLibs.140.00.UWPDesktop and UI.Xaml.2.8)
            $winget_dependencies_path = New-TemporaryFile2
            $winget_dependencies_url = Get-WingetDownloadUrl -Match 'DesktopAppInstaller_Dependencies.zip'
            Write-Output 'Downloading winget dependencies...'
            Write-Debug "Downloading winget dependencies from $winget_dependencies_url to $winget_dependencies_path`n`n"
            Invoke-WebRequest -Uri $winget_dependencies_url -OutFile $winget_dependencies_path

            # Load ZIP assembly to read the package contents
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            $zip = [System.IO.Compression.ZipFile]::OpenRead($winget_dependencies_path)

            $matchingEntries = $zip.Entries | Where-Object { $_.FullName -match ".*$arch.appx" }
            if ($matchingEntries) {
                $matchingEntries | ForEach-Object {
                    $destPath = Join-Path ([System.IO.Path]::GetTempPath()) $_.Name
                    Write-Debug "Extracting $($_.FullName) to $destPath..."
                    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, $destPath, $true)

                    $AppName = Get-ManifestName $destPath
                    Write-Output "Installing $AppName..."
                    Install-LibIfRequired -Lib_Name $AppName -Lib_Path $destPath
                    Write-Debug "Removing temporary library file..."
                    TryRemove $destPath
                }
                $zip.Dispose()
            } else {
                Write-Error "Dependency not found inside the file: $winget_dependencies_path"
            }

            Write-Debug "Removing temporary files..."
            TryRemove $winget_dependencies_path

        } catch {
            $errorHandled = Handle-Error $_
            if ($null -ne $errorHandled) {
                throw $errorHandled
            }
            $errorHandled = $null
        }

        # ============================================================================ #
        #  winget
        # ============================================================================ #

        Write-Section "winget"

        try {

            # Download winget license
            $winget_license_path = New-TemporaryFile2
            $winget_license_url = Get-WingetDownloadUrl -Match "License1.xml"
            Write-Output "Downloading winget license..."
            Write-Debug "Downloading winget license from $winget_license_url to $winget_license_path`n`n"
            Invoke-WebRequest -Uri $winget_license_url -OutFile $winget_license_path

            # Download winget
            $winget_path = New-TemporaryFile2
            $winget_url = Get-WingetDownloadUrl -Match 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'
            Write-Output "Downloading winget..."
            Write-Debug "Downloading winget from $winget_url to $winget_path`n`n"
            Invoke-WebRequest -Uri $winget_url -OutFile $winget_path

            # Install winget
            Write-Output "Installing winget..."
            Add-AppxProvisionedPackage -Online -PackagePath $winget_path -LicensePath $winget_license_path | Out-Null

            # Remove temporary files
            Write-Debug "Removing temporary files..."
            TryRemove $winget_path
            TryRemove $winget_license_path
        } catch {
            $errorHandled = Handle-Error $_
            if ($null -ne $errorHandled) {
                throw $errorHandled
            }
            $errorHandled = $null
        }

        # ============================================================================ #
        # Visual C++ Redistributable
        # ============================================================================ #

        Write-Section "Visual C++ Redistributable"

        # Test if Visual C++ Redistributable is not installed
        if (!(Test-VCRedistInstalled)) {
            Write-Debug "Visual C++ Redistributable is not installed.`n`n"

            # Define the URL and temporary file path for the download
            $VCppRedistributable_Url = "https://aka.ms/vs/17/release/vc_redist.${arch}.exe"
            $VCppRedistributable_Path = New-TemporaryFile2
            Write-Output "Downloading Visual C++ Redistributable..."
            Write-Debug "Downloading Visual C++ Redistributable from $VCppRedistributable_Url to $VCppRedistributable_Path`n`n"
            Invoke-WebRequest -Uri $VCppRedistributable_Url -OutFile $VCppRedistributable_Path

            # Rename file
            $VCppRedistributableExe_Path = $VCppRedistributable_Path + ".exe"
            Rename-Item -Path $VCppRedistributable_Path -NewName $VCppRedistributableExe_Path

            # Install Visual C++ Redistributable
            Write-Output "Installing Visual C++ Redistributable..."
            Write-Debug "Installing Visual C++ Redistributable from $VCppRedistributableExe_Path`n`n"
            Start-Process -FilePath $VCppRedistributableExe_Path -ArgumentList "/install", "/quiet", "/norestart" -Wait

            Write-Debug "Removing temporary file..."
            TryRemove $VCppRedistributableExe_Path
        } else {
            Write-Output "Visual C++ Redistributable is already installed."
        }

        # ============================================================================ #
        # Fix environment PATH and permissions
        # ============================================================================ #

        # Fix permissions for winget folder
        Write-Output "Fixing permissions for winget folder..."

        # Find winget folder path in Program Files
        $WinGetFolderPath = (Get-ChildItem -Path ([System.IO.Path]::Combine($env:ProgramFiles, 'WindowsApps')) -Filter "Microsoft.DesktopAppInstaller_*_${arch}__8wekyb3d8bbwe" | Sort-Object Name | Select-Object -Last 1).FullName
        Write-Debug "WinGetFolderPath: $WinGetFolderPath"

        if ($null -ne $WinGetFolderPath) {
            # Fix Permissions by adding Administrators group with FullControl
            Set-PathPermissions -FolderPath $WinGetFolderPath

            # Add Environment Path
            Add-ToEnvironmentPath -PathToAdd $WinGetFolderPath -Scope 'System'
        } else {
            Write-Warning "winget folder path not found. You may need to manually add winget's folder path to your system PATH environment variable."
        }
    }

    # ============================================================================ #
    # Force registration
    # ============================================================================ #
    Write-Output "Registering winget..."

    # Register for all except Server 2019 and Server Core
    if ($osVersion.NumericVersion -ne 2019 -and $osVersion.InstallationType -ne "Server Core" -and $RunAsSystem -eq $false -and $osVersion) {
        # Register winget
        Write-Debug "Registering winget..."
        Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
    }

    # ============================================================================ #
    #  Done
    # ============================================================================ #

    Write-Section "Complete"

    Write-Output "winget installed successfully."

    # ============================================================================ #
    # Finished
    # ============================================================================ #

    # Timeout before checking winget
    Write-Output "Checking if winget is installed and working..."
    Start-Sleep -Seconds 3

    # Check if winget is installed
    if (Get-WingetStatus -eq $true) {
        Write-Output "winget is installed and working. You can go ahead and use it."
        # If running as SYSTEM, inform the user a restart may be required for the winget command to work
        if ($RunAsSystem) {
            Write-Output "Since this script is running under the SYSTEM context, you may need to restart the computer or session for the winget command to function as expected."
        }
    } else {
        # If winget is still not detected as a command, show warning
        Write-Debug "Get-WinGetStatus: $(Get-WingetStatus)"
        if (Get-WingetStatus -ne $true) {
            Write-Warning "winget is installed but is not detected as a command. Try using winget now. If it doesn't work, wait about 1 minute and try again (it is sometimes delayed). Also try restarting your computer."
            Write-Warning "If you restart your computer and the command still isn't recognized, please read the Troubleshooting section`nof the README: https://github.com/asheroto/winget-install#troubleshooting`n"
            Write-Warning "Make sure you have the latest version of the script by running this command: $PowerShellGalleryName -CheckForUpdate`n`n"
        }
    }

    ExitWithDelay 0
} catch {
    # ============================================================================ #
    # Error handling
    # ============================================================================ #

    Write-Section "WARNING! An error occurred during installation!"
    Write-Warning "If messages above don't help and the problem persists, please read the Troubleshooting section`nof the README: https://github.com/asheroto/winget-install#troubleshooting"
    Write-Warning "Make sure you have the latest version of the script by running this command: $PowerShellGalleryName -CheckForUpdate`n`n"

    # If it's not 0x80073D02 (resources in use), show error
    if ($_.Exception.Message -notmatch '0x80073D02') {
        if ($Debug) {
            Write-Warning "Line number : $($_.InvocationInfo.ScriptLineNumber)"
        }
        Write-Warning "Error: $($_.Exception.Message)`n"
    }

    ExitWithDelay 1
}