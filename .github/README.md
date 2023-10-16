![winget Windows 10](https://github.com/asheroto/winget-install/assets/49938263/f2fa626b-c4b6-4bd4-871c-814754d8ca0e)
[![GitHub Release Date - Published_At](https://img.shields.io/github/release-date/asheroto/winget-installer)](https://github.com/asheroto/winget-installer/releases)
[![GitHub Downloads - All Releases](https://img.shields.io/github/downloads/asheroto/winget-installer/total)](https://github.com/asheroto/winget-installer/releases)
[![GitHub Sponsor](https://img.shields.io/github/sponsors/asheroto?label=Sponsor&logo=GitHub)](https://github.com/sponsors/asheroto)
<a href="https://ko-fi.com/asheroto"><img src="https://ko-fi.com/img/githubbutton_sm.svg" alt="Ko-Fi Button" height="20px"></a>

# Install winget from PowerShell

**winget, a command line package manager, doesn't have a command line installer? 🤣 Now it does! 😊**

## Requirements

-   Requires PowerShell running with Administrator rights
-   Compatible with:
    -   Windows 10 (Version 1809 or higher)
    -   Windows 11
    -   Server 2022
-   Not compatible with:
    -   Server 2019 (winget not supported)

## Features

-   Installs [winget-cli](https://github.com/microsoft/winget-cli) directly from PowerShell
-   Always fetches the latest `winget` version
-   Automatically verifies OS compatibility
-   Determines and installs the appropriate prerequisites based on OS version
-   Updates existing prerequisites to their latest versions
-   Supports x86/x64 and arm/arm64 architectures
-   Allows bypassing of existing `winget` installation verification through `$Force` session variable or `-Force` parameter

## Script Functionality

-   Identifies processor architecture to decide which prerequisites are needed (x86/x64 or arm/arm64)
-   Checks Windows OS version for compatibility (Windows 10, Windows 11, Server 2022)
-   Verifies Windows 10 release ID for compatibility (must be 1809 or newer)
-   Manages prerequisite versions based on OS:
    -   Forces older versions on Windows 10 and Server 2022
    -   Uses latest versions from Microsoft Store on Windows 11
-   Executes winget registration command on Windows 10
-   [VCLibs](https://docs.microsoft.com/en-gb/troubleshoot/developer/visualstudio/cpp/libraries/c-runtime-packages-desktop-bridge#how-to-install-and-update-desktop-framework-packages) is installed straight from the appx package
    -   Primary method
        -   If Windows 10 or Server 2022, alternate method is forced so that older version of prerequisite is used (newer version is not compatible)
        -   Determines the direct download URL for the **appx** package
        -   Installs **appx** package using direct download URL
    -   Alternate method (if primary download URL fails)
        -   Uses version 14.00 for compatibility reasons
        -   Installs **appx** package using aka.ms URL
-   [UI.Xaml](https://www.nuget.org/packages/Microsoft.UI.Xaml/) is installed
    -   Primary method
        -   If Windows 10 or Server 2022, alternate method is forced so that older version of prerequisite is used (newer version is not compatible)
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

Open PowerShell as Administrator and type

```powershell
Install-Script winget-install -Force
```

Follow the prompts to complete the installation (you can tap `A` to accept all prompts or `Y` to select them individually.

**Note:** `-Force` is optional but recommended, as it will force the script to update if it is outdated. If you do not use `-Force`, it will *not* overwrite the script if outdated.

#### Usage

```powershell
winget-install
```

The script is published on [PowerShell Gallery](https://www.powershellgallery.com/packages/winget-install) under `winget-install`.

#### Tip - How to trust PSGallery

If you want to trust PSGallery so you aren't prompted each time you run this command, or if you're scripting this and want to ensure the script isn't interrupted the first time it runs...

```powershell
Install-PackageProvider -Name "NuGet" -Force
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
```

### Method 2 - One Line Command

This is the fastest method, **but is not recommended** because the code that runs is not able to be viewed before running. If you're okay with that, you can run the following command in PowerShell as Administrator.

```powershell
irm asheroto.com/winget | iex
```

If PowerShell exits immediately, that means winget is already installed. You can force the script to run again by setting the session variable `$Force` to `$true` before running the command.

```powershell
$Force = $true
irm asheroto.com/winget | iex
```

### Method 3 - Download Locally and Run

-   Download the latest [winget-install.ps1](https://github.com/asheroto/winget-install/releases/latest/download/winget-install.ps1) from [Releases](https://github.com/asheroto/winget-install/releases)
-   Run the script with `.\winget-install.ps1`

## Parameters

No parameters are required to run the script, but there are some optional parameters to use if needed.

| Parameter         | Required | Description                                                                   |
| ----------------- | -------- | ----------------------------------------------------------------------------- |
| `-DebugMode`      | No       | Enables debug mode, which shows additional information for debugging.         |
| `-DisableCleanup` | No       | Disables cleanup of the script and prerequisites after installation.          |
| `-Force`          | No       | Ensures installation of winget and its dependencies, even if already present. |
| `-CheckForUpdate` | No       | Checks if there is an update available for the script.                        |
| `-Version`        | No       | Displays the version of the script.                                           |
| `-Help`           | No       | Displays the full help information for the script.                            |

## Troubleshooting

-   Before releasing a new version, the script is tested on a clean install of Windows 10 22H2, Server 2022 21H2, and Windows 11 22H2.
-   If you run into an issue, please ensure your system is compatible & fully updated
-   Try running `winget-install` again, sometimes the script will fail due to a temporary issue with the prerequisite server URLs
-   Try using the `-DebugMode` and `-DisableCleanup` parameters to see if it provides any additional information
-   Try [installing winget manually](https://github.com/microsoft/winget-cli#manually-update) to see if the issue exists with winget itself
-   If the issue occurs when installing winget manually, please open an [issue on the winget-cli repo](https://github.com/microsoft/winget-cli/issues) (unrelated to this script)
-   Check the [winget-cli Troubleshooting Guide](https://github.com/microsoft/winget-cli/blob/master/doc/troubleshooting/README.md)
-   If the problem **only** occurs when using this script, please open an issue here

## Contributing

If you're like to help develop this project: fork the repo. 😊