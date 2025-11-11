# ============================================================================ #
# Download and extract assets.zip (aria2 + 7zip)
# ============================================================================ #

# Paths
$AssetsDir = [System.IO.Path]::Combine($PSScriptRoot, "assets")
$AssetsZip = [System.IO.Path]::Combine($PSScriptRoot, "assets.zip")

# GitHub raw URL (direct binary download)
$AssetsUrl = "https://github.com/asheroto/winget-install/raw/master/assets/assets.zip"

$AssetsDownloaded = $false

# Download if not already present
if (-not (Test-Path $AssetsDir)) {
    Write-Output "Downloading assets.zip from GitHub..."
    Invoke-WebRequest -Uri $AssetsUrl -OutFile $AssetsZip -UseBasicParsing
    Write-Output "Download complete: $AssetsZip"

    Write-Output "Extracting assets.zip to 'assets\'..."
    Expand-Archive -Path $AssetsZip -DestinationPath $AssetsDir -Force
    Write-Output "Extraction complete. aria2 and 7zip ready at: $AssetsDir"
    $AssetsDownloaded = $true

    # Remove zip file after extraction
    Remove-Item $AssetsZip -Force -ErrorAction SilentlyContinue
} else {
    Write-Output "Assets folder already exists. Skipping download."
}

# ============================================================================ #
# Download and Extract Windows.Globalization.dll
# ============================================================================ #

# Paths to executables inside assets folder
$Aria2Path = [System.IO.Path]::Combine($AssetsDir, "aria2", "aria2c.exe")
$SevenZip = [System.IO.Path]::Combine($AssetsDir, "7zip", "7z.exe")

# File names and paths
$FileName = "Microsoft-Windows-Client-Desktop-Required-Package.esd"
$OutputPath = Join-Path $PSScriptRoot $FileName
$DllName = "Windows.Globalization.dll"
$DllPath = Join-Path $PSScriptRoot $DllName

# Expected SHA256 hashes
$ExpectedEsdHash = "154AB40E155EC5E86647CC74ACA45F237AA17FB1E8C545B340809233FDE7CCC3"
$ExpectedDllHash = "7C1D656A04E000C16D8AF88601E289E63DE36A51F251F50A2BB759CB0F73942D"

$EsdDownloaded = $false

# ============================================================================ #
# Step 1: Verify existing DLL first (goal file)
# ============================================================================ #
if (Test-Path $DllPath) {
    Write-Output "DLL already exists. Verifying hash for: $DllPath"
    $ExistingDllHash = (Get-FileHash -Path $DllPath -Algorithm SHA256).Hash.ToUpper()
    if ($ExistingDllHash -eq $ExpectedDllHash) {
        Write-Output "✔ DLL hash verified successfully. No further action required."

        # Clean up assets if freshly downloaded
        if ($AssetsDownloaded -and (Test-Path $AssetsDir)) {
            Write-Output "Removing assets folder..."
            try {
                Remove-Item $AssetsDir -Recurse -Force -ErrorAction Stop
                Write-Output "✔ Removed assets folder."
            } catch {
                Write-Warning "✖ Could not delete assets folder: $($_.Exception.Message)"
            }
        } else {
            Write-Output "Skipping assets cleanup — folder already existed."
        }

        Write-Output "`nAll operations completed successfully."
        exit 0
    } else {
        Write-Warning "✖ DLL hash does not match expected!"
        Write-Output "Expected: $ExpectedDllHash"
        Write-Output "Actual:   $ExistingDllHash"
        Write-Warning "Please delete the existing DLL before running this script again."
        exit 1
    }
}

# ============================================================================ #
# Step 2: Verify or download ESD (only needed if DLL missing)
# ============================================================================ #
if (Test-Path $OutputPath) {
    Write-Output "ESD file already exists. Verifying hash for: $OutputPath"
    $ExistingEsdHash = (Get-FileHash -Path $OutputPath -Algorithm SHA256).Hash.ToUpper()
    if ($ExistingEsdHash -eq $ExpectedEsdHash) {
        Write-Output "✔ ESD hash verified successfully. Skipping download."
        $SkipDownload = $true
    } else {
        Write-Warning "✖ ESD hash does not match expected!"
        Write-Output "Expected: $ExpectedEsdHash"
        Write-Output "Actual:   $ExistingEsdHash"
        Write-Warning "Please delete the existing ESD if you want to re-download it."
        exit 1
    }
} else {
    $SkipDownload = $false
}

# ============================================================================ #
# Step 3: Download ESD (if not verified)
# ============================================================================ #
if (-not $SkipDownload) {
    Write-Output "Fetching metadata from UUP Dump API..."
    $Id = "b9f1ddc0-255a-43e5-b7a4-baf4e12ffabe"
    $ApiUrl = "https://api.uupdump.net/get.php?id=$Id"
    $response = Invoke-RestMethod -Uri $ApiUrl -UseBasicParsing

    Write-Output "Downloading ESD from Microsoft servers..."
    Write-Output "If the download stays at 0B/0B, press Ctrl+C, wait a few minutes and try again. This usually means Microsoft's servers are temporarily throttling requests."

    $DownloadUrl = $response.response.files.$FileName.url
    & $Aria2Path `
        --disable-ipv6=true `
        --dir="$PSScriptRoot" `
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
        Write-Warning "✖ ESD file hash mismatch after download!"
        Write-Output "Expected: $ExpectedEsdHash"
        Write-Output "Actual:   $ActualEsdHash"
        exit 1
    }
    Write-Output "✔ ESD hash verified successfully."
}

# ============================================================================ #
# Step 4: Extract DLL from ESD
# ============================================================================ #
Write-Output "Extracting Windows.Globalization.dll from ESD..."
try {
    $Process = Start-Process -FilePath $SevenZip -ArgumentList @(
        "e",
        $OutputPath,
        "amd64_microsoft-windows-globalization*\Windows.Globalization.dll",
        "-o$($PSScriptRoot)",
        "-r",
        "-y"
    ) -PassThru -Wait
    Write-Output "Extraction complete."
} catch {
    Write-Warning "✖ 7-Zip extraction failed: $($_.Exception.Message)"
    exit 1
}

# ============================================================================ #
# Step 5: Verify DLL hash
# ============================================================================ #
Write-Output "Verifying extracted DLL hash..."
if (Test-Path $DllPath) {
    $ActualDllHash = (Get-FileHash -Path $DllPath -Algorithm SHA256).Hash.ToUpper()
    if ($ActualDllHash -ne $ExpectedDllHash) {
        Write-Warning "✖ Extracted DLL hash mismatch!"
        Write-Output "Expected: $ExpectedDllHash"
        Write-Output "Actual:   $ActualDllHash"
        exit 1
    }
    Write-Output "✔ DLL hash verified successfully."
} else {
    Write-Warning "✖ DLL not found after extraction!"
    exit 1
}

# ============================================================================ #
# Step 6: Cleanup
# ============================================================================ #
if ($EsdDownloaded) {
    Write-Output "Cleaning up downloaded ESD..."
    try {
        Remove-Item $OutputPath -Force -ErrorAction Stop
        Write-Output "✔ Removed downloaded ESD: $OutputPath"
    } catch {
        Write-Warning "✖ Could not delete downloaded ESD file: $($_.Exception.Message)"
    }
} else {
    Write-Output "Skipping ESD cleanup — file was pre-existing and verified."
}

if ($AssetsDownloaded -and (Test-Path $AssetsDir)) {
    Write-Output "Removing assets folder..."
    try {
        Remove-Item $AssetsDir -Recurse -Force -ErrorAction Stop
        Write-Output "✔ Removed assets folder."
    } catch {
        Write-Warning "✖ Could not delete assets folder: $($_.Exception.Message)"
    }
} else {
    Write-Output "Skipping assets cleanup — folder already existed."
}

Write-Output "`nAll operations completed successfully."