# ============================================================================ #
# Download and Extract Windows.Globalization.dll
# ============================================================================ #

# Paths
$Aria2Path = [System.IO.Path]::Combine($PSScriptRoot, "aria2", "aria2c.exe")
$SevenZip = [System.IO.Path]::Combine($PSScriptRoot, "7zip", "7z.exe")

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
# Step 6: Cleanup (only if ESD was downloaded this run)
# ============================================================================ #
if ($EsdDownloaded) {
    Write-Output "Cleaning up downloaded ESD..."
    if ($Process) {
        try {
            Wait-Process -Id $Process.Id -ErrorAction Stop
        } catch {
            Write-Warning "Could not wait for 7z.exe — it may have already exited."
        }
    }

    try {
        Remove-Item $OutputPath -Force -ErrorAction Stop
        Write-Output "✔ Removed downloaded ESD: $OutputPath"
    } catch {
        Write-Warning "✖ Could not delete downloaded ESD file: $($_.Exception.Message)"
    }
} else {
    Write-Output "Skipping cleanup — ESD was pre-existing and verified."
}

Write-Output "`nAll operations completed successfully."