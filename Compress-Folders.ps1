<#
.SYNOPSIS
    7-Zip Folder Compressor - DFI Edition
    ========================================================
    WHAT THIS SCRIPT DOES:
    - Takes every subfolder inside the folder where you put this script
    - Compresses each one into its own archive
    - Keeps original folders only if you choose Yes
    - Creates a SHA-256 hash file next to each archive (optional)
    - Verification is optional

    HOW TO USE IT:
    1. Copy this file into the folder you want to compress
    2. Double-click it (or right-click → Run with PowerShell)

.NOTES
    Author: Justin P. Fant
    Version: 14.4
    Purpose: Digital Forensics / Archival Tool
    Requires: 7-Zip installed
#>
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# ================================================
# ONLY CHANGE THESE LINES IF YOU WANT TO
# ================================================
$DefaultCompressionLevel = "High"
$DefaultFormat = "7z"
$SevenZipPath = "C:\Program Files\7-Zip\7z.exe"
# ================================================
# DO NOT CHANGE ANYTHING BELOW THIS LINE
# ================================================

try {
    $Source = $PSScriptRoot
    $StartTime = Get-Date

    if (-not (Test-Path $SevenZipPath)) {
        Write-Host "ERROR: 7-Zip was not found!" -ForegroundColor Red
        Write-Host "Please install 7-Zip from https://www.7-zip.org" -ForegroundColor Yellow
        pause
        exit 1
    }

    $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $LogFile = Join-Path $Source "Compression_Log_${Timestamp}.txt"
    Start-Transcript -Path $LogFile -Force | Out-Null

    Write-Host "`n=====================================================" -ForegroundColor Cyan
    Write-Host "7-ZIP COMPRESSOR STARTED" -ForegroundColor Cyan
    Write-Host "Version 14.4" -ForegroundColor Cyan
    Write-Host "Folder being compressed : $Source" -ForegroundColor Cyan
    Write-Host "Log file : $LogFile" -ForegroundColor Cyan
    Write-Host "=====================================================`n" -ForegroundColor Cyan

    Write-Host "IMPORTANT - PLEASE READ:" -ForegroundColor Red
    Write-Host "DO NOT close this window while running!" -ForegroundColor Red
    Write-Host "To stop safely → Press Ctrl + C" -ForegroundColor Yellow
    Write-Host "=====================================================`n" -ForegroundColor Cyan

    Write-Host "Now let's set your options (just press Enter for defaults):" -ForegroundColor Cyan

    # 1. Compression Level
    Write-Host "`nCompression Level:" -ForegroundColor Yellow
    Write-Host "   Low / Medium / High (RECOMMENDED) / Ultra"
    $compInput = Read-Host "Choose one [High]"
    if ($compInput -eq "") { $compInput = "High" }

    switch ($compInput) {
        "Low"    { $mxLevel = 3 }
        "Medium" { $mxLevel = 5 }
        "High"   { $mxLevel = 7 }
        "Ultra"  { $mxLevel = 9 }
        default  { $mxLevel = 7 }
    }

    # 2. Archive Format
    Write-Host "`nArchive Format:" -ForegroundColor Yellow
    Write-Host "   7z   = Best compression & smallest files (RECOMMENDED - default)"
    Write-Host "   zip  = Most compatible"
    Write-Host "   tar / xz / bz2 / gz / wim = other options"
    $formatInput = Read-Host "Choose one [7z]"
    if ($formatInput -eq "") { $formatInput = "7z" }
    $Format = $formatInput
    $Extension = $Format.ToLower()

    # 3. Keep original folders
    Write-Host "`nKeep original folders after compression?" -ForegroundColor Yellow
    Write-Host "   Yes = Keep the original folders (do not delete)"
    Write-Host "   No  = Delete originals after successful compression (default)"
    $KeepInput = Read-Host "Keep originals? (Y/N) [N]"
    $KeepOriginals = ($KeepInput -match '^[Yy]$')

    # 4. Verify Archives
    Write-Host "`nVerify archives after creation?" -ForegroundColor Yellow
    Write-Host "   Yes = Check every archive (takes extra time)"
    Write-Host "   No  = Skip verification (default - faster)"
    $VerifyInput = Read-Host "Verify? (Y/N) [N]"
    $VerifyArchives = ($VerifyInput -match '^[Yy]$')

    # 5. Create SHA-256 Hash
    Write-Host "`nCreate SHA-256 hash files?" -ForegroundColor Yellow
    Write-Host "   Yes = Create a .sha256 file next to each archive"
    Write-Host "   No  = Skip hash creation (default - faster)"
    $HashInput = Read-Host "Create hash? (Y/N) [N]"
    $CreateHashFiles = ($HashInput -match '^[Yy]$')

    Write-Host "`nStarting compression at $(Get-Date)`n" -ForegroundColor Green

    $Subfolders = Get-ChildItem -Path $Source -Directory
    $totalFolders = $Subfolders.Count

    if ($totalFolders -eq 0) {
        Write-Host "No subfolders found." -ForegroundColor Yellow
        Stop-Transcript | Out-Null
        pause
        exit 0
    }

    Write-Host "Found $totalFolders subfolders to process." -ForegroundColor Green

    $Results = @()

    foreach ($Folder in $Subfolders) {
        $FolderName = $Folder.Name
        $ArchivePath = Join-Path $Source "$FolderName.$Extension"
        $FolderFullPath = $Folder.FullName

        Write-Host "`n[$((Get-Date).ToString('HH:mm:ss'))] Compressing `"$FolderName`" ..." -ForegroundColor White

        if (Test-Path $ArchivePath) {
            Write-Host "   Skipping - already exists" -ForegroundColor Yellow
        } else {
            $CommandArgs = @("a", "-t$Format", "-mx=$mxLevel", "-mmt=on", "-ms=on", "-m0=lzma2", "`"$ArchivePath`"", "`"$FolderFullPath\`"")
            & $SevenZipPath $CommandArgs

            if ($LASTEXITCODE -ge 2) {
                Write-Host "   ERROR during compression of `"$FolderName`"" -ForegroundColor Red
            } else {
                Write-Host "   SUCCESS: $FolderName.$Extension created" -ForegroundColor Green

                $ArchiveSize = 0
                if (Test-Path $ArchivePath) { $ArchiveSize = (Get-Item $ArchivePath).Length }

                $OriginalSize = 0
                try { $OriginalSize = (Get-ChildItem $FolderFullPath -Recurse -File | Measure-Object -Property Length -Sum).Sum } catch { }

                $Ratio = if ($OriginalSize -gt 0) { [math]::Round((1 - $ArchiveSize / $OriginalSize) * 100, 1) } else { 0 }

                $Results += [PSCustomObject]@{
                    Folder       = $FolderName
                    OriginalGB   = [math]::Round($OriginalSize / 1GB, 3)
                    CompressedGB = [math]::Round($ArchiveSize / 1GB, 3)
                    RatioPercent = $Ratio
                }

                if ($CreateHashFiles -and (Test-Path $ArchivePath)) {
                    Write-Host "   Creating SHA-256 hash..." -NoNewline
                    $Hash = Get-FileHash -Path $ArchivePath -Algorithm SHA256
                    "$($Hash.Hash)  $FolderName.$Extension" | Out-File -FilePath "$ArchivePath.sha256" -Encoding utf8 -Force
                    Write-Host " DONE" -ForegroundColor Cyan
                }

                if ($VerifyArchives -and (Test-Path $ArchivePath)) {
                    Write-Host "   Verifying archive..." -NoNewline
                    & $SevenZipPath t "`"$ArchivePath`"" | Out-Null
                    if ($LASTEXITCODE -eq 0) { Write-Host " OK" -ForegroundColor Green } else { Write-Host " FAILED" -ForegroundColor Red }
                }

                if (-not $KeepOriginals) {
                    Remove-Item -Path $FolderFullPath -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }

    $EndTime = Get-Date
    $TotalTime = $EndTime - $StartTime

    Write-Host "`n=====================================================" -ForegroundColor Cyan
    Write-Host "ALL DONE at $(Get-Date)" -ForegroundColor Green
    Write-Host "Total time taken : $($TotalTime.ToString('hh\:mm\:ss'))" -ForegroundColor Green
    Write-Host "Full log saved here: $LogFile" -ForegroundColor Cyan
    Write-Host "=====================================================`n" -ForegroundColor Cyan

    if ($Results.Count -gt 0) {
        Write-Host "SUMMARY TABLE" -ForegroundColor Cyan
        $Results | Format-Table -AutoSize -Property `
            @{Name="Folder"; Expression={$_.Folder}},
            @{Name="Original (GB)"; Expression={$_.OriginalGB}; Alignment="Right"},
            @{Name="Compressed (GB)"; Expression={$_.CompressedGB}; Alignment="Right"},
            @{Name="Ratio %"; Expression={$_.RatioPercent}; Alignment="Right"}
    }

    Write-Host "`n=====================================================" -ForegroundColor Cyan

} catch {
    Write-Host "`nERROR: Something went wrong!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
} finally {
    Stop-Transcript | Out-Null
    pause
}