![winget1](https://github.com/asheroto/winget-install/assets/49938263/352cc28f-7665-4618-b85f-68bded893bca)

[![GitHub Release Date - Published_At](https://img.shields.io/github/release-date/asheroto/winget-installer)](https://github.com/asheroto/winget-installer/releases)
[![GitHub Downloads - All Releases](https://img.shields.io/github/downloads/asheroto/winget-installer/total)](https://github.com/asheroto/winget-installer/releases)
[![GitHub Sponsor](https://img.shields.io/github/sponsors/asheroto?label=Sponsor&logo=GitHub)](https://github.com/sponsors/asheroto)
[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/asheroto)

# Install winget from PowerShell

**winget, a command line package manager, doesn't have a command line installer? 🤣 Now it does! 😊**

-   Install [winget-cli](https://github.com/microsoft/winget-cli) straight from PowerShell
-   Always gets the latest version of `winget`
-   Works on Windows 10, Windows 11, Server 2022
-   winget (and therefore this script) requires "Windows 10 version 1809 or newer (LTSC included)"
-   Does **not** work on Server 2019
-   Script automatically determines if your OS version is compatible
-   Script automatically determines which version of the prerequisites to install based on your OS version

## Script Functionality

-   Processor architecture determined for prerequisites (x86/x64 or arm/arm64)
-   Windows OS version determined to confirm compatibility (Windows 10, Windows 11, Server 2022)
-   If Windows 10, release ID determined to confirm compatibility (1809 or newer)
-   [VCLibs](https://docs.microsoft.com/en-gb/troubleshoot/developer/visualstudio/cpp/libraries/c-runtime-packages-desktop-bridge#how-to-install-and-update-desktop-framework-packages) is installed straight from the appx package
    -   Primary method
        -   If Windows 10 or Server 2022, alternate method is forced so that older version of prerequisite is used
        -   Determines the direct download URL for the **appx** package
        -   Installs **appx** package using direct download URL
    -   Alternate method (if primary download URL fails)
        -   Uses version 14.00 for compatibility reasons
        -   Installs **appx** package using aka.ms URL
-   [Xaml](https://www.nuget.org/packages/Microsoft.UI.Xaml/) is installed
    -   Primary method
        -   If Windows 10 or Server 2022, alternate method is forced so that older version of prerequisite is used
        -   Determines the direct download URL for the **appx** package
        -   Installs **appx** package using direct download URL
    -   Alternate method (if primary download URL fails)
        -   Uses version 2.7.3 for compatibility reasons
        -   Downloads **nupkg** package using nuget.org URL
        -   Extracts **appx** package from **nupkg** package
        -   Installs **appx** package using extracted **appx** package
-   [winget-cli](https://github.com/microsoft/winget-cli) is then installed using the latest version from GitHub
-   Machine & User **PATH** variables are adjusted to include WindowsApps folder if needed

## Setup

### Method 1 - PowerShell Gallery

**Note:** please use the latest version using Install-Script or the PS1 file from Releases, the version on GitHub itself may be under development and not work properly.

-   In PowerShell, type

```powershell
Install-Script winget-install -Force
```

-   answer **Yes** to all prompts if asked
    **Note:** `-Force` is optional, but it will force the script to update if it is outdated.

The script is published on [PowerShell Gallery](https://www.powershellgallery.com/packages/winget-install) under `winget-install`.

### Tip - How to trust PSGallery

If you want to trust PSGallery so you aren't prompted each time you run this command, you can type...

```powershell
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
```

### Method 2 - Download Locally and Run

-   Download `winget-install.ps1`
-   Run the script with `.\winget-install.ps1`

## Usage

In PowerShell, type

```powershell
winget-install
```

## Available Scripts

-   **winget-install.ps1**
    -   Unsigned script in the repo but may be under development
    -   It is recommended that you use the file in Releases or use Install-Script and do not use the file in the repo directly

## Troubleshooting

-   If you run into an issue, please ensure your system is compatible & fully updated
-   Try running `winget-install` again, sometimes the script will fail due to a temporary issue with the prerequisite server URLs
-   Try [installing winget manually](https://github.com/microsoft/winget-cli#manually-update) to see if the issue exists with winget itself
-   If the issue occurs when installing winget manually, please open an [issue on the winget-cli repo](https://github.com/microsoft/winget-cli/issues) (unrelated to this script)
-   Check the [winget-cli Troubleshooting Guide](https://github.com/microsoft/winget-cli/blob/master/doc/troubleshooting/README.md)
-   If the problem **only** occurs when using this script, please open an issue here

## Contributing

If you're like to help develop this project: fork the repo. 😊