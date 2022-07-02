<#PSScriptInfo

.VERSION 0.0.4

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

#>

<#
.SYNOPSIS
    Downloads the latest version of Winget, its dependencies, and installs everything. PATH variable is adjusted after installation. Reboot required after installation.
.DESCRIPTION
    Downloads the latest version of Winget, its dependencies, and installs everything. PATH variable is adjusted after installation. Reboot required after installation.
.EXAMPLE
    winget-install
.NOTES
    Version      : 0.0.4
    Created by   : asheroto
.LINK
    Project Site: https://github.com/asheroto/winget-installer
#>


function getNewestLink($match) {
	$uri = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
	Write-Verbose "[$((Get-Date).TimeofDay)] Getting information from $uri"
	$get = Invoke-RestMethod -uri $uri -Method Get -ErrorAction stop
	Write-Verbose "[$((Get-Date).TimeofDay)] getting latest release"
	$data = $get[0].assets | Where-Object name -Match $match
	return $data.browser_download_url
}

$wingetUrl = getNewestLink("msixbundle")
$wingetLicenseUrl = getNewestLink("License1.xml")

function section($text) {
	<#
        .SYNOPSIS
        Prints a section divider for easy reading of the output.

        .DESCRIPTION
        Prints a section divider for easy reading of the output.
    #>
	Write-Output "###################################"
	Write-Output "# $text"
	Write-Output "###################################"
}

# Add AppxPackage and silently continue on error
function AAP($pkg) {
	<#
        .SYNOPSIS
        Adds an AppxPackage to the system.

        .DESCRIPTION
        Adds an AppxPackage to the system.
    #>
	Add-AppxPackage $pkg -ErrorAction SilentlyContinue
}

# Download XAML nupkg and extract appx file
section("Downloading Xaml nupkg file... (19000000ish bytes)")
$url = "https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.7.1"
$nupkgFolder = "Microsoft.UI.Xaml.2.7.1.nupkg"
$zipFile = "Microsoft.UI.Xaml.2.7.1.nupkg.zip"
Invoke-WebRequest -Uri $url -OutFile $zipFile
section("Extracting appx file from nupkg file...")
Expand-Archive $zipFile

# Determine architecture
if ([Environment]::Is64BitOperatingSystem) {
	section("64-bit OS detected")

	# Install x64 VCLibs
	section("Downloading & installing x64 VCLibs... (21000000ish bytes)")
	AAP("https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx")

	# Install x64 XAML
	section("Installing x64 XAML...")
	AAP("Microsoft.UI.Xaml.2.7.1.nupkg\tools\AppX\x64\Release\Microsoft.UI.Xaml.2.7.appx")
} else {
	section("32-bit OS detected")

	# Install x86 VCLibs
	section("Downloading & installing x86 VCLibs... (21000000ish bytes)")
	AAP("https://aka.ms/Microsoft.VCLibs.x86.14.00.Desktop.appx")

	# Install x86 XAML
	section("Installing x86 XAML...")
	AAP("Microsoft.UI.Xaml.2.7.1.nupkg\tools\AppX\x86\Release\Microsoft.UI.Xaml.2.7.appx")
}

# Finally, install winget
section("Downloading winget... (21000000ish bytes)")
$wingetPath = "winget.msixbundle"
Invoke-WebRequest -Uri $wingetUrl -OutFile $wingetPath
$wingetLicensePath = "license1.xml"
Invoke-WebRequest -Uri $wingetLicenseUrl -OutFile $wingetLicensePath
section("Installing winget...")
Add-AppxProvisionedPackage -Online -PackagePath $wingetPath -LicensePath $wingetLicensePath -ErrorAction SilentlyContinue

# Adding WindowsApps directory to PATH variable for current user
section("Adding WindowsApps directory to PATH variable for current user...")
$path = [Environment]::GetEnvironmentVariable("PATH", "User")
$path = $path + ";" + [IO.Path]::Combine([Environment]::GetEnvironmentVariable("LOCALAPPDATA"), "Microsoft", "WindowsApps")
[Environment]::SetEnvironmentVariable("PATH", $path, "User")

# Cleanup
section("Cleaning up...")
Remove-Item $zipFile
Remove-Item $nupkgFolder -Recurse
Remove-Item $wingetPath
Remove-Item $wingetLicensePath

# Finished
section("Installation complete!")
section("Please restart your computer to complete the installation.")