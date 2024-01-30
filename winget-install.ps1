<#PSScriptInfo

.VERSION 4.0.0

.GUID 3b581edb-5d90-4fa1-ba15-4f2377275463

.AUTHOR asheroto, 1ckov, MisterZeus, ChrisTitusTech, uffemcev

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
.PARAMETER Debug
    Enables debug mode, which shows additional information for debugging.
.PARAMETER DisableCleanup
    Disables cleanup of the script and prerequisites after installation.
.PARAMETER Force
    Ensures installation of winget and its dependencies, even if already present.
.PARAMETER UpdateSelf
    Updates the script to the latest version on PSGallery.
.PARAMETER CheckForUpdate
    Checks if there is an update available for the script.
.PARAMETER Version
    Displays the version of the script.
.PARAMETER Help
    Displays the full help information for the script.
.NOTES
	Version      : 4.0.0
	Created by   : asheroto
.LINK
	Project Site: https://github.com/asheroto/winget-install
#>
[CmdletBinding()]
param (
    [switch]$Force,
    [switch]$ForceClose,
    [switch]$CheckForUpdate,
    [switch]$Wait,
    [switch]$UpdateSelf,
    [switch]$Version,
    [switch]$Help
)

# Version
$CurrentVersion = '4.0.0'
$RepoOwner = 'asheroto'
$RepoName = 'winget-install'
$PowerShellGalleryName = 'winget-install'

# Versions
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

        # Strip out "Server" from the $editionIdValue if it exists
        $editionIdValue = $editionIdValue -replace "Server", ""

        # Get OS details using Get-CimInstance because the registry key for Name is not always correct with Windows 11
        $osDetails = Get-CimInstance -ClassName Win32_OperatingSystem
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

        # Create and return custom object with the required properties
        $result = [PSCustomObject]@{
            ReleaseId      = $releaseIdValue
            DisplayVersion = $displayVersionValue
            Name           = $nameValue
            Type           = $typeValue
            NumericVersion = $numericVersion
            EditionId      = $editionIdValue
            Version        = $versionValue
            Architecture   = $architecture
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

            # Install NuGet PackageProvider if not already installed
            if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
                Install-PackageProvider -Name "NuGet" -Force
            }

            # Trust the PSGallery if not already trusted
            $repo = Get-PSRepository -Name 'PSGallery'
            if ($repo.InstallationPolicy -ne 'Trusted') {
                Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
            }

            # Update the script
            Install-Script $PowerShellGalleryName -Force

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
    $releases = Invoke-RestMethod -uri $uri -Method Get -ErrorAction stop

    Write-Debug "Getting latest release..."
    foreach ($release in $releases) {
        if ($release.name -match "preview") {
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
    $winget = Get-Command -Name winget -ErrorAction SilentlyContinue

    # If winget is installed, return $true
    if ($null -ne $winget) {
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

    # Exit the script with error code
    # Some systems may accidentally close the window, but that's a PowerShell bug
    # https://stackoverflow.com/questions/67593504/why-wont-the-exit-function-work-in-my-powershell-code
    Exit $ExitCode
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

# ============================================================================ #
# Initial checks
# ============================================================================ #

# Use global variables if specified by user
Import-GlobalVariable -VariableName "Debug"
Import-GlobalVariable -VariableName "ForceClose"
Import-GlobalVariable -VariableName "Force"

# First heading
Write-Output "winget-install $CurrentVersion"

# Check for updates if -CheckForUpdate is specified
if ($CheckForUpdate) { CheckForUpdate -RepoOwner $RepoOwner -RepoName $RepoName -CurrentVersion $CurrentVersion -PowerShellGalleryName $PowerShellGalleryName }

# Update the script if -UpdateSelf is specified
if ($UpdateSelf) { UpdateSelf }

# Heading
Write-Output "To check for updates, run winget-install -CheckForUpdate"

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

# If it's a server, it needs to be 2022+
if ($osVersion.Type -eq "Server" -and $osVersion.NumericVersion -lt 2022) {
    Write-Error "winget requires Windows Server 2022 or newer on server platforms. Your version of Windows Server is not supported."
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
    # Install prerequisites
    # ============================================================================ #

    Write-Section "Prerequisites"

    try {
        # Download VCLibs
        $VCLibs_Path = New-TemporaryFile2
        $VCLibs_Url = "https://aka.ms/Microsoft.VCLibs.${arch}.14.00.Desktop.appx"
        Write-Output "Downloading VCLibs..."
        Write-Debug "Downloading VCLibs from $VCLibs_Url to $VCLibs_Path`n`n"
        Invoke-WebRequest -Uri $VCLibs_Url -OutFile $VCLibs_Path

        # Download UI.Xaml
        $UIXaml_Path = New-TemporaryFile2
        $UIXaml_Url = "https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.7.3/Microsoft.UI.Xaml.2.7.${arch}.appx"
        Write-Output "Downloading UI.Xaml..."
        Write-Debug "Downloading UI.Xaml from $UIXaml_Url to $UIXaml_Path`n"
        Invoke-WebRequest -Uri $UIXaml_Url -OutFile $UIXaml_Path
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

    # winget
    try {
        # Download winget license
        $winget_license_path = New-TemporaryFile2
        $winget_license_url = Get-WingetDownloadUrl -Match "License1.xml"
        Write-Output "Downloading winget license..."
        Write-Debug "Downloading winget license from $winget_license_url to $winget_license_path`n`n"
        Invoke-WebRequest -Uri $winget_license_url -OutFile $winget_license_path

        # Download winget
        $winget_path = New-TemporaryFile2
        $winget_url = "https://aka.ms/getwinget"
        Write-Output "Downloading winget..."
        Write-Debug "Downloading winget from $winget_url to $winget_path`n`n"
        Invoke-WebRequest -Uri $winget_url -OutFile $winget_path

        # Install everything
        Write-Output "Installing winget and its dependencies..."
        Add-AppxProvisionedPackage -Online -PackagePath $winget_path -DependencyPackagePath $UIXaml_Path, $VCLibs_Path -LicensePath $winget_license_path | Out-Null

        # Remove
        Remove-Item $VCLibs_Path
        Remove-Item $UIXaml_Path
        Remove-Item $winget_path
        Remove-Item $winget_license_path
    } catch {
        $errorHandled = Handle-Error $_
        if ($null -ne $errorHandled) {
            throw $errorHandled
        }
        $errorHandled = $null
    }

    # ============================================================================ #
    #  Done
    # ============================================================================ #

    Write-Section "Complete"

    Write-Output "winget installed successfully."

    # ============================================================================ #
    # Finished
    # ============================================================================ #

    # Timeout for 5 seconds to check winget
    Write-Output "Checking if winget is installed and working..."
    Start-Sleep -Seconds 3

    # Check if winget is installed
    if (Get-WingetStatus -eq $true) {
        Write-Output "winget is installed and working now, you can go ahead and use it."
    } else {
        # ============================================================================ #
        # Register winget
        # ============================================================================ #

        # If winget is not detected as a command, try registering it
        Write-Section "Registering"
        try {
            Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
            Write-Output "winget command registered successfully."
        } catch {
            Write-Warning "Unable to register winget. You may need to restart your computer for winget to work."
        }

        # If winget is still not detected as a command, show warning
        if (Get-WingetStatus -eq $false) {
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