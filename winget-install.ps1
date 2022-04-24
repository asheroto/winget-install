# Easily change in the future
$wingetUrl = "https://github.com/microsoft/winget-cli/releases/download/v1.3.431/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
$wingetLicenseUrl = "https://github.com/microsoft/winget-cli/releases/download/v1.3.431/e40f7d30e22c4c0eb9194f5e9aed26b8_License1.xml"

function section($text) {
	Write-Output "###################################"
	Write-Output "# $text"
	Write-Output "###################################"
}

# Add AppxPackage and silently continue on error
function AAP($pkg) {
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
$path = $path + ";" + [IO.Path]::Combine([Environment]::GetEnvironmentVariable("LOCALAPPDATA"),"Microsoft","WindowsApps")
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