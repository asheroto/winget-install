<#PSScriptInfo

.VERSION 1.0.1

.GUID 3b581edb-5d90-4fa1-ba15-4f2377275463

.AUTHOR asherto, 1ckov

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

#>

<#
.SYNOPSIS
    Downloads the latest version of Winget, its dependencies, and installs everything. PATH variable is adjusted after installation. Reboot required after installation.
.DESCRIPTION
    Downloads the latest version of Winget, its dependencies, and installs everything. PATH variable is adjusted after installation. Reboot required after installation.
.EXAMPLE
    Install-Winget
.NOTES
    Version      : 1.0.1
    Created by   : asheroto
.LINK
    Project Site: https://github.com/asheroto/winget-installer
#>

# Versions
$VCLibsVersion = "14.00"
$ProgressPreference = 'SilentlyContinue' # Suppress progress bar (makes downloading super fast)

# Get latest version of Microsoft.UI.Xaml
function Get-LatestMicrosoftUIXamlVersion() {
	$url = "https://api.nuget.org/v3-flatcontainer/Microsoft.UI.Xaml/index.json"
	$json = Invoke-RestMethod -Method Get -Uri $url
	# The versions are in reverse chronological order, so the first one is the latest
	$latestVersion = $json.versions[-1]
	return $latestVersion
}

# Initialize Microsoft.UI.Xaml version
$MicrosoftUIXamlVersion = Get-LatestMicrosoftUIXamlVersion

# URLs
$urlMicrosoftUIXaml = "https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/$MicrosoftUIXamlVersion"
$urlVCLibsx64 = "https://aka.ms/Microsoft.VCLibs.x64.$VCLibsVersion.Desktop.appx"
$urlVCLibsx86 = "https://aka.ms/Microsoft.VCLibs.x86.$VCLibsVersion.Desktop.appx"

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
	Write-Output ("#" * 50)
	Write-Output "# $text"
	Write-Output ("#" * 50)
	Write-Output ""
}

function Get-NewestLink($match) {
	<#
    .SYNOPSIS
        This function fetches the newest link for a specified match from the GitHub API.
    .EXAMPLE
        PS C:\> Get-NewestLink("msixbundle")
    #>
	$uri = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
	Write-Verbose "[$((Get-Date).TimeofDay)] Getting information from $uri"
	$get = Invoke-RestMethod -uri $uri -Method Get -ErrorAction stop
	Write-Verbose "[$((Get-Date).TimeofDay)] getting latest release"
	$data = $get.assets | Where-Object name -Match $match
	return $data.browser_download_url
}

# Using temp directory for downloads
$tempFolder = [System.IO.Path]::GetTempPath()

# Determine architecture
$arch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }

# Download XAML nupkg and extract appx file
Write-Output ""
Write-Section("Downloading Xaml nupkg file...")
$zipFile = Join-Path -Path $tempFolder -ChildPath "Microsoft.UI.Xaml.$MicrosoftUIXamlVersion.nupkg.zip"
Invoke-WebRequest -Uri $urlMicrosoftUIXaml -OutFile $zipFile
$nupkgFolder = Join-Path -Path $tempFolder -ChildPath "Microsoft.UI.Xaml.$MicrosoftUIXamlVersion"
Expand-Archive -Path $zipFile -DestinationPath $nupkgFolder -Force

# Install VCLibs
Write-Section("Downloading & installing ${arch} VCLibs...")
$urlVCLibs = if ($arch -eq "x64") { $urlVCLibsx64 } else { $urlVCLibsx86 }
Add-AppxPackageSilently $urlVCLibs

# Install XAML
Write-Section("Installing ${arch} XAML...")
$XamlAppxPath = Join-Path -Path $nupkgFolder -ChildPath "tools\AppX\$arch\Release\Microsoft.UI.Xaml.$MicrosoftUIXamlVersion.appx"
Add-AppxPackageSilently $XamlAppxPath

# Finally, install winget
$wingetUrl = Get-NewestLink("msixbundle")
$wingetPath = Join-Path -Path $tempFolder -ChildPath "winget.msixbundle"
$wingetLicenseUrl = Get-NewestLink("License1.xml")
$wingetLicensePath = Join-Path -Path $tempFolder -ChildPath "license1.xml"
Write-Section("Downloading winget...")
Invoke-WebRequest -Uri $wingetUrl -OutFile $wingetPath
Invoke-WebRequest -Uri $wingetLicenseUrl -OutFile $wingetLicensePath
Write-Section("Installing winget...")
Add-AppxProvisionedPackage -Online -PackagePath $wingetPath -LicensePath $wingetLicensePath -ErrorAction SilentlyContinue | Out-Null

# Adding WindowsApps directory to PATH variable for current user if not already present
Write-Section("Checking and adding WindowsApps directory to PATH variable for current user if not present...")
$path = [Environment]::GetEnvironmentVariable("PATH", "User")
$WindowsAppsPath = [IO.Path]::Combine([Environment]::GetEnvironmentVariable("LOCALAPPDATA"), "Microsoft", "WindowsApps")
if (!$path.Contains($WindowsAppsPath)) {
	$path = $path + ";" + $WindowsAppsPath
	[Environment]::SetEnvironmentVariable("PATH", $path, "User")
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