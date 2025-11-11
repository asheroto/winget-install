$ScriptFailed = $false
# ============================================================================ #
# Define working directory (Program Files\Microsoft\winget)
# ============================================================================ #
$BasePath = [System.IO.Path]::Combine($env:ProgramFiles, "Microsoft", "winget")
Write-Output "Using working directory: $BasePath"

if (-not (Test-Path $BasePath)) {
    New-Item -Path $BasePath -ItemType Directory | Out-Null
    Write-Output "Created folder: $BasePath"
}

# ============================================================================ #
# Ensure modern TLS protocols for Invoke-RestMethod and Invoke-WebRequest
# ============================================================================ #
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor 3072
    Write-Output "Enabled TLS 1.2 support for secure connections."
} catch {
    Write-Warning "Could not enable TLS 1.2. Some HTTPS requests may fail on older systems."
}

# ============================================================================ #
# Download and extract winget-install-assets.zip (aria2 + 7zip)
# ============================================================================ #
$AssetsDir = [System.IO.Path]::Combine($BasePath, "winget-install-assets")
$AssetsZip = [System.IO.Path]::Combine($BasePath, "winget-install-assets.zip")
$AssetsUrl = "https://raw.githubusercontent.com/asheroto/winget-install/f428eb2ea1b62b02ee59a60a8411b423b503fbaf/assets/assets.zip"
$AssetsDownloaded = $false

try {
    if (-not (Test-Path $AssetsDir)) {
        Write-Output "Downloading winget-install-assets.zip from GitHub..."
        Invoke-WebRequest -Uri $AssetsUrl -OutFile $AssetsZip -UseBasicParsing
        Write-Output "Download complete: $AssetsZip"

        Write-Output "Extracting assets.zip to 'winget-install-assets\'..."
        Expand-Archive -Path $AssetsZip -DestinationPath $AssetsDir -Force
        Write-Output "Extraction complete. aria2 and 7zip ready at: $AssetsDir"
        $AssetsDownloaded = $true
        Remove-Item $AssetsZip -Force -ErrorAction SilentlyContinue
    } else {
        Write-Output "winget-install-assets folder already exists. Skipping download."
    }
} catch {
    Write-Warning "✖ Failed to download or extract winget-install-assets: $($_.Exception.Message)"
    $ScriptFailed = $true
}

if ($ScriptFailed) { Read-Host "Press Enter to exit"; return }

# ============================================================================ #
# Paths and expected hashes
# ============================================================================ #
$Aria2Path = [System.IO.Path]::Combine($AssetsDir, "aria2", "aria2c.exe")
$SevenZip = [System.IO.Path]::Combine($AssetsDir, "7zip", "7z.exe")
$FileName = "Microsoft-Windows-Client-Desktop-Required-Package.esd"
$OutputPath = [System.IO.Path]::Combine($BasePath, $FileName)
$DllName = "Windows.Globalization.dll"
$DllPath = [System.IO.Path]::Combine($BasePath, $DllName)

$ExpectedEsdHash = "154AB40E155EC5E86647CC74ACA45F237AA17FB1E8C545B340809233FDE7CCC3"
$ExpectedDllHash = "7C1D656A04E000C16D8AF88601E289E63DE36A51F251F50A2BB759CB0F73942D"
$EsdDownloaded = $false

# ============================================================================ #
# Step 1: Verify DLL first
# ============================================================================ #
if (Test-Path $DllPath) {
    Write-Output "DLL already exists. Verifying hash for: $DllPath"
    $ExistingDllHash = (Get-FileHash -Path $DllPath -Algorithm SHA256).Hash.ToUpper()
    if ($ExistingDllHash -eq $ExpectedDllHash) {
        Write-Output "✔ DLL hash verified successfully. No further action required."
        goto Cleanup
    } else {
        Write-Warning "✖ DLL hash mismatch!"
        Write-Output "Expected: $ExpectedDllHash"
        Write-Output "Actual:   $ExistingDllHash"
        $ScriptFailed = $true
    }
}

if ($ScriptFailed) { Read-Host "Press Enter to exit"; return }

# ============================================================================ #
# Step 2: Verify or download ESD
# ============================================================================ #
if (Test-Path $OutputPath) {
    Write-Output "ESD file already exists. Verifying hash for: $OutputPath"
    $ExistingEsdHash = (Get-FileHash -Path $OutputPath -Algorithm SHA256).Hash.ToUpper()
    if ($ExistingEsdHash -eq $ExpectedEsdHash) {
        Write-Output "✔ ESD hash verified successfully. Skipping download."
        $SkipDownload = $true
    } else {
        Write-Warning "✖ ESD hash mismatch!"
        Write-Output "Expected: $ExpectedEsdHash"
        Write-Output "Actual:   $ExistingEsdHash"
        $ScriptFailed = $true
    }
} else {
    $SkipDownload = $false
}

if ($ScriptFailed) { Read-Host "Press Enter to exit"; return }

# ============================================================================ #
# Step 3: Download ESD if needed
# ============================================================================ #
if (-not $SkipDownload) {
    try {
        Write-Output "Fetching metadata from UUP Dump API..."
        $Id = "b9f1ddc0-255a-43e5-b7a4-baf4e12ffabe"
        $ApiUrl = "https://api.uupdump.net/get.php?id=$Id"
        $response = Invoke-RestMethod -Uri $ApiUrl -UseBasicParsing

        Write-Output "Downloading ESD from Microsoft servers..."
        $DownloadUrl = $response.response.files.$FileName.url
        & $Aria2Path `
            --disable-ipv6=true `
            --dir="$BasePath" `
            --out="$FileName" `
            --max-connection-per-server=4 `
            --split=8 `
            --min-split-size=1M `
            "$DownloadUrl"

        $EsdDownloaded = $true
        Write-Output "Download complete: $OutputPath"

        Write-Output "Verifying downloaded ESD hash..."
        $ActualEsdHash = (Get-FileHash -Path $OutputPath -Algorithm SHA256).Hash.ToUpper()
        if ($ActualEsdHash -ne $ExpectedEsdHash) {
            Write-Warning "✖ ESD hash mismatch after download!"
            Write-Output "Expected: $ExpectedEsdHash"
            Write-Output "Actual:   $ActualEsdHash"
            $ScriptFailed = $true
        } else {
            Write-Output "✔ ESD hash verified successfully."
        }
    } catch {
        Write-Warning "✖ Error during ESD download: $($_.Exception.Message)"
        $ScriptFailed = $true
    }
}

if ($ScriptFailed) { Read-Host "Press Enter to exit"; return }

# ============================================================================ #
# Step 4: Extract DLL
# ============================================================================ #
Write-Output "Extracting Windows.Globalization.dll from ESD..."

# Temp extraction folder
$TempExtract = [System.IO.Path]::Combine($BasePath, "extract-temp")
if (-not (Test-Path $TempExtract)) { New-Item -Path $TempExtract -ItemType Directory | Out-Null }

try {
    Start-Process -FilePath $SevenZip -ArgumentList @(
        "e",
        "`"$OutputPath`"",
        "amd64_microsoft-windows-globalization*\Windows.Globalization.dll",
        "-o`"$TempExtract`"",
        "-r",
        "-y"
    ) -Wait

    # Check if DLL extracted
    $ExtractedDll = Get-ChildItem -Path $TempExtract -Recurse -Filter "Windows.Globalization.dll" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $ExtractedDll) {
        Move-Item -Path $ExtractedDll.FullName -Destination $DllPath -Force
        Write-Output "✔ Extracted Windows.Globalization.dll to: $DllPath"
    } else {
        Write-Warning "✖ DLL not found in extracted files!"
        $ScriptFailed = $true
    }

    # Clean up temp folder
    Remove-Item $TempExtract -Recurse -Force -ErrorAction SilentlyContinue
} catch {
    Write-Warning "✖ 7-Zip extraction failed: $($_.Exception.Message)"
    $ScriptFailed = $true
}

# ============================================================================ #
# Step 5: Verify DLL hash
# ============================================================================ #
Write-Output "Verifying extracted DLL hash..."
if (Test-Path $DllPath) {
    $ActualDllHash = (Get-FileHash -Path $DllPath -Algorithm SHA256).Hash.ToUpper()
    if ($ActualDllHash -ne $ExpectedDllHash) {
        Write-Warning "✖ DLL hash mismatch after extraction!"
        Write-Output "Expected: $ExpectedDllHash"
        Write-Output "Actual:   $ActualDllHash"
        $ScriptFailed = $true
    } else {
        Write-Output "✔ DLL hash verified successfully."
    }
} else {
    Write-Warning "✖ DLL not found after extraction!"
    $ScriptFailed = $true
}

if ($ScriptFailed) { Read-Host "Press Enter to exit"; return }

# ============================================================================ #
# Fail-safe cleanup if script fails early
# ============================================================================ #
function Cleanup-Temp {
    param([switch]$Force)

    if (Test-Path $TempExtract) {
        try {
            Remove-Item $TempExtract -Recurse -Force -ErrorAction Stop
            Write-Output "✔ Removed temp extraction folder."
        } catch {
            Write-Warning "✖ Could not remove temp extraction folder: $($_.Exception.Message)"
        }
    }

    if (($AssetsDownloaded -or $Force) -and (Test-Path $AssetsDir)) {
        try {
            Remove-Item $AssetsDir -Recurse -Force -ErrorAction Stop
            Write-Output "✔ Removed winget-install-assets folder (cleanup on failure)."
        } catch {
            Write-Warning "✖ Could not remove winget-install-assets folder: $($_.Exception.Message)"
        }
    }
}

# ============================================================================ #
# Failure handling
# ============================================================================ #
if ($ScriptFailed) {
    Write-Warning "✖ Script failed. Performing cleanup..."
    Cleanup-Temp -Force
    Read-Host "Press Enter to exit"
    return
}

# ============================================================================ #
# Step 6: Cleanup (normal success)
# ============================================================================ #
:Cleanup
if ($EsdDownloaded) {
    Write-Output "Cleaning up downloaded ESD..."
    try {
        Remove-Item $OutputPath -Force -ErrorAction Stop
        Write-Output "✔ Removed downloaded ESD: $OutputPath"
    } catch {
        Write-Warning "✖ Could not delete downloaded ESD: $($_.Exception.Message)"
    }
}

if ($AssetsDownloaded -and (Test-Path $AssetsDir)) {
    Write-Output "Removing winget-install-assets folder..."
    try {
        Remove-Item $AssetsDir -Recurse -Force -ErrorAction Stop
        Write-Output "✔ Removed winget-install-assets folder."
    } catch {
        Write-Warning "✖ Could not delete winget-install-assets folder: $($_.Exception.Message)"
    }
}

Write-Output "`nAll operations completed successfully."
Read-Host "Press Enter to close"