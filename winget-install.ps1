<#PSScriptInfo

.VERSION 1.0.3

.GUID 3b581edb-5d90-4fa1-ba15-4f2377275463

.AUTHOR asherto, 1ckov, MisterZeus

.COMPANYNAME asheroto

.TAGS PowerShell Windows winget win get install installer fix script

.PROJECTURI https://github.com/asheroto/winget-installer

.RELEASENOTES
[Version 0.0.1] - Initial Release.
[Version 0.0.2] - Implemented function to get the latest version of Winget and its license.
[Version 0.0.3] - Signed file for PSGallery.
[Version 0.0.4] - Changed URI to grab latest release instead of releases and preleases.
[Version 0.0.5] - Updated version number of dependencies.
[Version 1.0.0] - Major refactor code, see release notes for more information.
[Version 1.0.1] - Fixed minor bug where version 2.8 was hardcoded in URL.
[Version 1.0.2] - Hardcoded UI Xaml version 2.8.4 as a failsafe in case the API fails. Added CheckForUpdates, Version, Help functions. Various bug fixes.
[Version 1.0.3] - Added error message to catch block. Fixed bug where appx package was not being installed.

#>

<#
.SYNOPSIS
	Downloads the latest version of Winget, its dependencies, and installs everything. PATH variable is adjusted after installation. Reboot required after installation.
.DESCRIPTION
	Downloads the latest version of Winget, its dependencies, and installs everything. PATH variable is adjusted after installation. Reboot required after installation.
.EXAMPLE
	Install-Winget
.NOTES
	Version      : 1.0.3
	Created by   : asheroto
.LINK
	Project Site: https://github.com/asheroto/winget-installer
#>
[CmdletBinding()]
param (
	[switch]$Version,
	[switch]$Help,
	[switch]$CheckForUpdates
)

# Version
$CurrentVersion = '1.0.3'
$RepoOwner = 'asheroto'
$RepoName = 'winget-installer'

# Versions
$VCLibsVersion = "14.00"
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

# If people run "winget-install -Verbose",
# output their PS and Host info.
if ($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent) {
	$PSVersionTable
	Get-Host
}

function Get-GitHubRelease {
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
		$UtcDateTimeFormat = "MM/dd/yyyy HH:mm:ss"

		# Convert UTC time string to local time
		$UtcDateTime = [DateTime]::ParseExact($publishedAt, $UtcDateTimeFormat, $null)
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

# Check for updates
if ($CheckForUpdates) {
	$Data = Get-GitHubRelease -Owner $RepoOwner -Repo $RepoName

	if ($Data.LatestVersion -gt $CurrentVersion) {
		Write-Host "A new version of $RepoName is available."
		Write-Host "Current version: $CurrentVersion."
		Write-Host "Latest  version: $($Data.LatestVersion)."
		Write-Host "Published at: $($Data.PublishedDateTime)."
		Write-Host "You can download the latest version from https://github.com/$RepoOwner/$RepoName/releases"
	} else {
		Write-Host "$RepoName is up to date."
		Write-Host "Current version: $CurrentVersion."
		Write-Host "Latest  version: $($Data.LatestVersion)."
		Write-Host "Published at: $($Data.PublishedDateTime)."
		Write-Host "Repository: https://github.com/$RepoOwner/$RepoName/releases"
	}
	exit 0
}

# Get latest version of Microsoft.UI.Xaml
function Get-LatestMicrosoftUIXamlVersion {
	[CmdletBinding()]
	# Get latest version from API
	$url = "https://api.nuget.org/v3-flatcontainer/Microsoft.UI.Xaml/index.json"

	# Try to get the latest version from the API, if it fails, use the hardcoded version
	try {
		# Get the JSON from the API
		$json = Invoke-RestMethod -Method Get -Uri $url

		# Remove all versions containing "prerelease"
		$filteredVersions = $json.versions | Where-Object { $_ -notlike "*-*" }

		# Extract the versions using regular expressions
		$versions = $filteredVersions | ForEach-Object {
			if ($_ -match '(\d+\.\d+\.\d+)') {
				$matches[1]
			}
		}

		# Sort the versions array in descending order
		$sortedVersions = $versions | Sort-Object -Descending

		# Get the latest version
		$latestVersion = $sortedVersions[0]
	} catch {
		$latestVersion = "2.8.4"
		Write-Warning "Failed getting latest Microsoft.UI.Xaml version from API $url"
		Write-Warning "Using the hardcoded version $latestVersion"
	}

	return $latestVersion
}

## KEEP THIS HERE AFTER Get-LatestMicrosoftUIXamlVersion
# Initialize Microsoft.UI.Xaml version
$MicrosoftUIXamlVersion = Get-LatestMicrosoftUIXamlVersion

# KEEP THIS HERE AFTER $MicrosoftUIXamlVersion
# URLs
$urlMicrosoftUIXaml = "https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/$MicrosoftUIXamlVersion"

$urlVCLibsx64       = "https://aka.ms/Microsoft.VCLibs.x64.$VCLibsVersion.Desktop.appx"
$urlVCLibsx86       = "https://aka.ms/Microsoft.VCLibs.x86.$VCLibsVersion.Desktop.appx"

# Adding AppxPackage and silently continue on error
function Add-AppxPackageSilently($pkg) {
	<#
		.SYNOPSIS
		Adds an AppxPackage to the system and silently continues on error.
		.EXAMPLE
		PS C:\> Add-AppxPackageSilently("https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx")
	#>
	Add-AppxPackage $pkg -ErrorAction SilentlyContinue
}

# Generates a section divider for easy reading of the output.
function Write-Section($text) {
	<#
		.SYNOPSIS
		Prints a section divider for easy reading of the output.
		.EXAMPLE
		PS C:\> Write-Section("Downloading Files...")
	#>
	Write-Host ""
	Write-Host ("#" * ($text.Length + 4))
	Write-Host "# $text #"
	Write-Host ("#" * ($text.Length + 4))
	Write-Host ""
}

function Get-NewestLink($match) {
	<#
	.SYNOPSIS
		This function fetches the newest link for a specified match from the GitHub API.
	.EXAMPLE
		Get-NewestLink("msixbundle")
	#>
	[CmdletBinding()]
	$uri = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
	Write-Verbose "[$((Get-Date).TimeofDay)] Getting information from $uri"
	$get = Invoke-RestMethod -uri $uri -Method Get -ErrorAction stop
	Write-Verbose "[$((Get-Date).TimeofDay)] Getting latest release..."
	$data = $get.assets | Where-Object name -Match $match
	return $data.browser_download_url
}

# Using temp directory for downloads
$tempFolder = [System.IO.Path]::GetTempPath()

# Determine architecture
$arch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }

try {

	# Download XAML nupkg and extract appx file
	try {
		Write-Section("Downloading Xaml nupkg file...")
		Write-Host "Downloading: $urlMicrosoftUIXaml"
		$zipFile = Join-Path -Path $tempFolder -ChildPath "Microsoft.UI.Xaml.$MicrosoftUIXamlVersion.nupkg.zip"
		Write-Host "Saving as  : $zipFile`n"
		Invoke-WebRequest -Uri $urlMicrosoftUIXaml -OutFile $zipFile
	} catch {
		Write-Warning "Failed to download $urlMicrosoftUIXaml"
		Write-Warning "Will try again using hardcoded version 2.8.4 (known good)..."
		Write-Warning "Downloading: $urlMicrosoftUIXaml"
		Write-Warning "Saving as  : $zipFile"
		$DownloadURL = "https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.8.4"
		Invoke-WebRequest -Uri $DownloadURL -OutFile $zipFile
	}
	$nupkgFolder = Join-Path -Path $tempFolder -ChildPath "Microsoft.UI.Xaml.$MicrosoftUIXamlVersion"
	Write-Host "Expand into: $nupkgFolder"
	Expand-Archive -Path $zipFile -DestinationPath $nupkgFolder -Force

	# Install VCLibs
	Write-Section("Downloading & installing ${arch} VCLibs...")
	$urlVCLibs = if ($arch -eq "x64") { $urlVCLibsx64 } else { $urlVCLibsx86 }
	Add-AppxPackageSilently $urlVCLibs

	# Install XAML
	Write-Section("Installing ${arch} XAML...")
	$XamlAppxPath = Join-Path -Path $nupkgFolder -ChildPath "tools\AppX\$arch\Release"
	Write-Host "Installing Appx Packages In: $XamlAppxPath"
	
	# For each appx file in the folder, install it
	Get-ChildItem -Path $XamlAppxPath -Filter *.appx | ForEach-Object {
		Write-Host "`nInstalling Appx Package: $_"
		Add-AppxPackageSilently $_.FullName
	}
	Add-AppxPackageSilently $XamlAppxPath

	# Download winget
	Write-Section("Downloading winget...")
	
	Write-Host "Retrieving download URL for winget from GitHub..."
	$wingetUrl = Get-NewestLink("msixbundle")
	$wingetPath = Join-Path -Path $tempFolder -ChildPath "winget.msixbundle"
	$wingetLicenseUrl = Get-NewestLink("License1.xml")
	$wingetLicensePath = Join-Path -Path $tempFolder -ChildPath "license1.xml"

	Write-Host "`nDownloading: $wingetUrl"
	Write-Host "Saving as  : $wingetPath`n"
	Invoke-WebRequest -Uri $wingetUrl -OutFile $wingetPath

	Write-Host "`nDownloading: $wingetLicenseUrl"
	Write-Host "Saving as  : $wingetLicensePath`n"
	Invoke-WebRequest -Uri $wingetLicenseUrl -OutFile $wingetLicensePath

	# Install winget
	Write-Section("Installing winget...")

	Write-Host "wingetPath       : $wingetPath"
	Write-Host "wingetLicensePath: $wingetLicensePath`n"
	Add-AppxProvisionedPackage `
		-Online `
		-PackagePath $wingetPath `
		-LicensePath $wingetLicensePath `
		-ErrorAction SilentlyContinue `
		| Out-Null

	# Adding WindowsApps directory to PATH variable for current user if not already present
	Write-Section("Checking and adding WindowsApps directory to PATH variable for current user if not present...")
	$path = [Environment]::GetEnvironmentVariable("PATH", "User")
	$WindowsAppsPath = [IO.Path]::Combine([Environment]::GetEnvironmentVariable("LOCALAPPDATA"), "Microsoft", "WindowsApps")
	if (!$path.Contains($WindowsAppsPath)) {
		Write-Host "Adding $WindowsAppsPath to PATH variable for current user..."
		$path = $path + ";" + $WindowsAppsPath
		[Environment]::SetEnvironmentVariable("PATH", $path, "User")
	} else {
		Write-Host "$WindowsAppsPath already present in PATH variable for current user, skipping."
	}

	# Cleanup
	Write-Section("Cleaning up...")
	Remove-Item -Path $zipFile
	Remove-Item -Path $nupkgFolder -Recurse
	Remove-Item -Path $wingetPath
	Remove-Item -Path $wingetLicensePath

	# Finished
	Write-Section("Installation complete!")
	Write-Section("Please restart your computer to complete the installation.")
} catch {
	Write-Warning "Something went wrong. Please try again or open an issue at https://github.com/asheroto/winget-install/issues"
	Write-Warning "Line number  : $($_.InvocationInfo.ScriptLineNumber)"
	Write-Warning "Error: $($_.Exception.Message)"
}
