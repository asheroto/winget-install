# Install WinGet with one command

- Works on Windows 10 (1809 or newer, LTSC included), Windows 11, Server 2019/2022
- Always gets the latest version of winget

## How to use 

- Open Windows PowerShell as administrator
- Paste this command:

```
Invoke-WebRequest https://raw.githubusercontent.com/asheroto/winget-installer/master/winget-install.ps1 -UseBasicParsing | iex
```

### Method 2 - Fetch from PSGallery

- In PowerShell, type `Install-Script -Name winget-install` and answer yes to any prompts
- Then type `winget-install`
- If you want to trust PSGallery so you aren't prompted each time you run this command, you can type...

    `Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted`

### Method 3 - download file locally and run

- Download `winget-install.ps1` or `winget-install-signed.zip` (and extract the inner PS1 script)
- Run the script with `.\winget-install.ps1`

---

![image](https://user-images.githubusercontent.com/49938263/164990481-a82586ac-db45-42b1-b543-c3756eafe045.png)

## Available Scripts

-  **winget-install.ps1**
	- Unsigned script

-  **winget-install-signed.zip**

	- Signed script
	- Compressed for transport and to retain signature
	- Uncompress to use
	- For use if you do not want to enable unsigned script execution in PowerShell

## Script Functionality

- [VCLibs](https://docs.microsoft.com/en-gb/troubleshoot/developer/visualstudio/cpp/libraries/c-runtime-packages-desktop-bridge#how-to-install-and-update-desktop-framework-packages) and [Xaml](https://www.nuget.org/packages/Microsoft.UI.Xaml/) are installed first

- Processor architecture is determined for prerequisites

- [VCLibs](https://docs.microsoft.com/en-gb/troubleshoot/developer/visualstudio/cpp/libraries/c-runtime-packages-desktop-bridge#how-to-install-and-update-desktop-framework-packages) is installed straight from the appx package

- [Xaml](https://www.nuget.org/packages/Microsoft.UI.Xaml/) is installed by downloading the **nupkg**, extracting it, and installing the **appx** package

- [winget-cli](https://github.com/microsoft/winget-cli) is then installed

- User **PATH** variable is adjusted to include WindowsApps folder

- Grabs the latest version of winget on each run

  

## Note

- If you receive an error message about the Appx module not being loaded, try using a different version of PowerShell (version 6 and 7 seem to be buggy still, but the native PowerShell version in Windows works)