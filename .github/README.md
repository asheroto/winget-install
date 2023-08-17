![winget1](https://github.com/asheroto/winget-install/assets/49938263/dc5d2e94-aa1d-4160-9141-21704ed172f6)

[![GitHub Release Date - Published_At](https://img.shields.io/github/release-date/asheroto/winget-installer)](https://github.com/asheroto/winget-installer/releases)
[![GitHub Downloads - All Releases](https://img.shields.io/github/downloads/asheroto/winget-installer/total)](https://github.com/asheroto/winget-installer/releases)
[![GitHub Sponsor](https://img.shields.io/github/sponsors/asheroto?label=Sponsor&logo=GitHub)](https://github.com/sponsors/asheroto)
[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/asheroto)
# Install winget from PowerShell
- Install [winget-cli](https://github.com/microsoft/winget-cli) straight from PowerShell
- Always gets the latest version of `winget`
- Works on Windows 10, Windows 11, Server 2022
- winget (and therefore this script) requires "Windows 10 version 1809 or newer (LTSC included)"
- Does **not** work on Server 2019

## Script Functionality
- Processor architecture determined for prerequisites (x86/x64 or arm/arm64)
- [VCLibs](https://docs.microsoft.com/en-gb/troubleshoot/developer/visualstudio/cpp/libraries/c-runtime-packages-desktop-bridge#how-to-install-and-update-desktop-framework-packages) is installed straight from the appx package
  - Primary method
    - Uses version 14.00 for compatibility reasons
    - Installs **appx** package using aka.ms URL
  - Alternate method (if primary download URL fails)
    - Determines the direct download URL for the **appx** package
    - Installs **appx** package using direct download URL
- [Xaml](https://www.nuget.org/packages/Microsoft.UI.Xaml/) is installed
  - Primary method
    - Uses version 2.7.3 for compatibility reasons
    - Downloads **nupkg** package using nuget.org URL
    - Extracts **appx** package from **nupkg** package
    - Installs **appx** package using extracted **appx** package
  - Alternate method (if primary download URL fails)
    - Determines the direct download URL for the **appx** package
    - Installs **appx** package using direct download URL
- [winget-cli](https://github.com/microsoft/winget-cli) is then installed using the latest version from GitHub
- Machine & User **PATH** variables are adjusted to include WindowsApps folder if needed

## Setup

### Method 1 - PowerShell Gallery

- In PowerShell, type
```powershell
Install-Script winget-install -Force
```
- answer **Yes** to all prompts if asked
**Note:** `-Force` is optional, but it will force the script to update if it is outdated.

The script is published on [PowerShell Gallery](https://www.powershellgallery.com/packages/winget-install) under `winget-install`.

### Tip - How to trust PSGallery

If you want to trust PSGallery so you aren't prompted each time you run this command, you can type...

```powershell
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
```

### Method 2 - Download Locally and Run

- Download `winget-install.ps1`
- Run the script with `.\winget-install.ps1`

## Usage

In PowerShell, type

```powershell
winget-install
```

## Available Scripts

- **winget-install.ps1**
	- Unsigned script in the repo, signed script in releases

## Troubleshooting

- If you run into an issue, please ensure your system is compatible & fully updated
- Please try [installing winget manually](https://github.com/microsoft/winget-cli#manually-update) to see if the issue exists with winget itself
- If the issue occurs when installing winget manually, please open an [issue on the winget-cli repo](https://github.com/microsoft/winget-cli/issues)
- Check the [winget-cli Troubleshooting Guide](https://github.com/microsoft/winget-cli/blob/master/doc/troubleshooting/README.md)
- If the problem only occurs when using this script, please open an issue here

## Contributing
If you're like to help develop this project: fork the repo. 😊