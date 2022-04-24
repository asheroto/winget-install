# Install winget-cli from PowerShell
- Install [winget-cli](https://github.com/microsoft/winget-cli) straight from PowerShell
- Works on Windows 10, Windows 11, Server 2019/2022
- Easily adjust URLs when updates occur

# Available Scripts
- **winget-install.ps1** - unsigned script
- **winget-install-signed.ps1** - signed script (for use if you do not want to enable unsigned script execution in PowerShell)

## Script Functionality

- **VCLibs** and **Xaml** are installed first
- Processor architecture is determined for prerequisites
- **VCLibs** is installed straight from the appx package
- **Xaml** is installed by downloading the **nupkg**, extracting it, and installing the **appx** package
- **Winget** is then installed
- User **PATH** variable is adjusted to include WindowsApps folder
- Easily adjust **winget** and **winget license URLs** at top of script when updates occur

## Note

- If you receive an error message about the Appx module not being loaded, try using a different version of PowerShell (version 6 and 7 seem to be buggy still, but the native PowerShell version in Windows works)