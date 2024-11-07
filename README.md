![winget-install screenshot](https://github.com/user-attachments/assets/a0019f96-dae6-4ca5-83b4-6caa10d83294)

[![PowerShell Gallery Downloads](https://img.shields.io/powershellgallery/dt/winget-install?label=PowerShell%20Gallery%20downloads)](https://www.powershellgallery.com/packages/winget-install)
[![GitHub Downloads - All Releases](https://img.shields.io/github/downloads/asheroto/winget-install/total?label=release%20downloads)](https://github.com/asheroto/winget-install/releases)
[![Release](https://img.shields.io/github/v/release/asheroto/winget-install)](https://github.com/asheroto/winget-install/releases)
[![GitHub Release Date - Published_At](https://img.shields.io/github/release-date/asheroto/winget-install)](https://github.com/asheroto/winget-install/releases)

[![GitHub Sponsor](https://img.shields.io/github/sponsors/asheroto?label=Sponsor&logo=GitHub)](https://github.com/sponsors/asheroto?frequency=one-time&sponsor=asheroto)
<a href="https://ko-fi.com/asheroto"><img src="https://ko-fi.com/img/githubbutton_sm.svg" alt="Ko-Fi Button" height="20px"></a>
<a href="https://www.buymeacoffee.com/asheroto"><img src="https://img.buymeacoffee.com/button-api/?text=Buy me a coffee&emoji=&slug=seb6596&button_colour=FFDD00&font_colour=000000&font_family=Lato&outline_colour=000000&coffee_colour=ffffff](https://img.buymeacoffee.com/button-api/?text=Buy%20me%20a%20coffee&emoji=&slug=asheroto&button_colour=FFDD00&font_colour=000000&font_family=Lato&outline_colour=000000&coffee_colour=ffffff)" height="40px"></a>

# Install WinGet from PowerShell

**WinGet, a command line package manager, doesn't have a command line installer? 🤣 Now it does! 😊**

> [!NOTE]  
> **What's New?**
> - Version 5 Released!  
> - In response to the evolving nature of WinGet methods and dependencies, we have updated the installation approach to use `Repair-WinGetPackageManager`, allowing Microsoft to manage these dependencies directly. This will help avoid some of the issues faced when installing WinGet. Server 2019 will continue through the traditional method.
> - Improved exit handling to prevent PowerShell window from closing.

## Table of Contents

-   [Requirements](#requirements)
-   [Features](#features)
-   [Script Functionality](#script-functionality)
-   [Setup](#setup)
    -   [Method 1 - PowerShell Gallery](#method-1---powershell-gallery)
        -   [Usage](#usage)
    -   [Method 2 - One Line Command (Runs Immediately)](#method-2---one-line-command-runs-immediately)
        -   [Option A: asheroto.com short URL](#option-a-asherotocom-short-url)
        -   [Option B: WinGet.pro short URL](#option-b-WinGetpro-short-url)
        -   [Option C: direct release URL](#option-c-direct-release-url)
    -   [Method 3 - Download Locally and Run](#method-3---download-locally-and-run)
-   [Parameters](#parameters)
    -   [Example Parameters Usage](#example-parameters-usage)
-   [Global Variables](#global-variables)
    -   [Example Global Variables Usage](#example-global-variables-usage)
-   [Troubleshooting](#troubleshooting)
-   [Contributing](#contributing)

## Requirements

-   Requires PowerShell running with Administrator rights
    -   WinGet does _not_ officially support installation or use of the [SYSTEM account](https://github.com/microsoft/winget-cli/discussions/962)
-   Compatible with:
    -   Windows 10 (Version 1809 or higher)
    -   Windows 11
    -   Server 2019/2022
    -   Windows Sandbox
-   Not compatible with:
    -   Server 2016 or lower (WinGet not supported)

## Features

-   Installs [WinGet](https://github.com/microsoft/winget-cli) directly from PowerShell
-   Always fetches the latest WinGet version
-   Automatically verifies OS compatibility
-   Determines and installs the appropriate prerequisites based on OS version
-   Supports x86/x64 and arm/arm64 architectures
-   Allows bypassing of existing WinGet installation verification through `-Force` parameter or `$Force` session variable
-   Supports irm/iex one-line command using short URL
-   Supports automatically relaunching in `conhost` and ending active processes associated with WinGet that could interfere with the installation
-   Code is hosted on [PowerShell Gallery](https://www.powershellgallery.com/packages/winget-install)

## Script Functionality

-   Identifies processor architecture to decide which prerequisites are needed (x86/x64 or arm/arm64)
-   Checks Windows OS version for compatibility (Windows 10, Windows 11, Server 2019/2022)
-   If Windows 10, verifies release ID for compatibility (must be 1809 or newer)
-   All OSes except Server 2019
    -   Installs the NuGet package provider (for PowerShell Gallery)
    -   Installs the [Microsoft.WinGet.Client](https://www.powershellgallery.com/packages/Microsoft.WinGet.Client/) from PowerShell Gallery
    -   Runs `Repair-WinGetPackageManager -AllUsers` which actually installs WinGet and its dependencies, fixing any issues along the way
-   Server 2019 only
    -   Uses the UI.Xaml and VCLibs as [recommended by Microsoft](https://learn.microsoft.com/en-us/windows/package-manager/winget/#install-winget-on-windows-sandbox)
    -   The WinGet-cli license is downloaded using the latest version from GitHub
    -   Installs Visual C++ Redistributable if version 14 or higher is not already installed
    -   [WinGet-cli](https://github.com/microsoft/winget-cli) is then installed using the latest version from GitHub
    -   Adjust access rights & PATH environment variable
-   Runs command registration if the WinGet command is not detected at the end of installation

## Setup

### Method 1 - PowerShell Gallery

**This is the recommended method, because it always gets the public release that has been tested, it's easy to remember, and supports all parameters.**

Open PowerShell as Administrator and type

```powershell
Install-Script winget-install -Force
```

Follow the prompts to complete the installation (you can tap `A` to accept all prompts or `Y` to select them individually.

**Note:** `-Force` is optional but recommended, as it will force the script to update if it is outdated. If you do not use `-Force`, it will _not_ overwrite the script if outdated.

#### Usage

```powershell
winget-install
```

If WinGet is already installed, you can use the `-Force` parameter to force the script to run anyway.

The script is published on [PowerShell Gallery](https://www.powershellgallery.com/packages/winget-install) under `winget-install`.

### Method 2 - One Line Command (Runs Immediately)

The URL [asheroto.com/winget](https://asheroto.com/winget) always redirects to the [latest code-signed release](https://github.com/asheroto/winget-install/releases/latest/download/winget-install.ps1) of the script.

If you just need to run the basic script without any parameters, you can use the following one-line command:

#### Option A: asheroto.com short URL

```powershell
irm asheroto.com/winget | iex
```

Due to the nature of how PowerShell works, you won't be able to use any parameters like `-Force` with this command line. You can set the global variable `$Force` to `$true` and the script should pick up on it ([more info](#global-variables)), but if for some reason that doesn't work or you absolutely need to use a one-line command with parameters, you can use the following:

```powershell
&([ScriptBlock]::Create((irm asheroto.com/winget))) -Force
```

#### Option B: WinGet.pro short URL

To make it easier to remember, you can also use the URL [WinGet.pro](https://winget.pro) which redirects to the same URL. This URL is provided courtesy of [Omaha Consulting](https://github.com/omaha-consulting).

```powershell
irm winget.pro | iex
```

Due to the nature of how PowerShell works, you won't be able to use any parameters like `-Force` with this command line. You can set the global variable `$Force` to `$true` and the script should pick up on it ([more info](#global-variables)), but if for some reason that doesn't work or you absolutely need to use a one-line command with parameters, you can use the following:

```powershell
&([ScriptBlock]::Create((irm winget.pro))) -Force
```

#### Option C: direct release URL

Alternatively, you can of course use the latest code-signed release URL directly:

```powershell
irm https://github.com/asheroto/winget-install/releases/latest/download/winget-install.ps1 | iex
```

### Method 3 - Download Locally and Run

As a more conventional approach, download the latest [winget-install.ps1](https://github.com/asheroto/winget-install/releases/latest/download/winget-install.ps1) from [Releases](https://github.com/asheroto/winget-install/releases), then run the script as follows:

```powershell
.\winget-install.ps1
```

You can use the `-Force` or `-ForceClose` parameters if needed, or use `$Force = $true` and `$ForceClose = $true` global session variables if preferred.

> [!TIP]
> If for some reason your PowerShell window closes at the end of the script and you don't want it to, or don't want your other scripts to be interrupted, you can wrap the command in a `powershell "COMMAND HERE"`. For example, `powershell "irm asheroto.com/winget | iex"`.

## Parameters

**No parameters are required** to run the script, but there are some optional parameters to use if needed.

| Parameter         | Description                                                                                                                                                                                                                                                   |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --- |
| `-Debug`          | Enables debug mode, showing additional information for troubleshooting.                                                                                                                                                                                       |
| `-Force`          | Ensures the installation of WinGet and its dependencies, even if they are already present.                                                                                                                                                                    |
| `-ForceClose`     | If Windows Terminal has trouble installing WinGet, use this parameter to relaunch the script in conhost.exe and automatically end any active processes associated with WinGet that could interfere with the installation.                                     |
| `-CheckForUpdate` | Checks if there is an update available for the script.                                                                                                                                                                                                        |
| `-Wait`           | By default, the script exits immediately after completion. Although this is not supposed to close the PowerShell window, sometimes it still occurs. Use this parameter to pause the script for several seconds before exiting to observe the output.          |
| `-NoExit`         | By default, the script exits immediately after completion. Although this is not supposed to close the PowerShell window, sometimes it still occurs. Use this parameter to pause the script indefinitely after execution; pressing Enter will exit the script. |
| `-UpdateSelf`     | Updates the script to the latest version.                                                                                                                                                                                                                     |
| `-Version`        | Displays the version of the script.                                                                                                                                                                                                                           |
| `-Help`           | Displays the full help information for the script.                                                                                                                                                                                                            |     |

### Example Parameters Usage

```powershell
winget-install -Force
```

## Global Variables

Global variables are _optional_ and are only needed if you don't want to use parameters. They can be set before running the script, or you can set them in your PowerShell profile to always use them.

| Variable      | Description                                                                                                                                                                                                                                            |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `$Debug`      | Enables debug mode, which shows additional information for debugging.                                                                                                                                                                                  |
| `$Force`      | Ensures installation of WinGet and its dependencies, even if already present.                                                                                                                                                                          |
| `$ForceClose` | Windows Terminal sometimes has trouble installing WinGet; run the script with the -ForceClose parameter to relaunch the script in conhost.exe and automatically end active processes associated with WinGet that could interfere with the installation |

### Example Global Variables Usage

```powershell
$Force = $true
winget-install
```

## Troubleshooting

-   Before releasing a new version, the script is tested on a clean install of Windows 10 22H2, Server 2022 21H2, and Windows 11 22H2.
-   If you run into an issue, please ensure your system is compatible & fully updated.
-   Sometimes PowerShell closes the window before you can read the output. To prevent this, you can use the `-Wait` parameter to pause the script for a few seconds or the `-NoExit` parameter to keep the window open indefinitely. Improving script exit functionality is on our TODO list.
-   Try running `winget-install` again, sometimes the script will fail due to a temporary issue with the prerequisite server URLs.
-   Try using the `-Debug` parameters to see if it provides any additional information.
-   If you're getting a `resource in use` error message, run the script again with the `-ForceClose` parameter.
-   Try [installing WinGet manually](https://learn.microsoft.com/en-us/windows/package-manager/winget/#install-winget-on-windows-sandbox) to see if the issue exists with WinGet itself.
-   If the issue occurs when installing WinGet manually, please open an [issue on the WinGet-cli repo](https://github.com/microsoft/winget-cli/issues) (unrelated to this script).
-   Check the [WinGet-cli Troubleshooting Guide](https://github.com/microsoft/winget-cli/blob/master/doc/troubleshooting/README.md).
-   Note that WinGet [does not officially support](https://github.com/microsoft/winget-cli/discussions/962) installing or running with the `SYSTEM` account.
-   If the problem **only** occurs when using this script, please open an issue here.

## Contributing

If you'd like to help develop this project: fork the repo, edit the code, then submit a pull request. 😊