# DFI 7-Zip Folder Compressor

A clean, reliable PowerShell tool designed specifically for **digital forensics and archival workflows**.

It automatically compresses every direct subfolder into its own archive, with optional SHA-256 hashing, verification, and the ability to keep originals.

### Features
- Simple double-click usage
- Live scrolling output (you can see 7-Zip working in real time)
- Optional: Keep original folders
- Optional: Create SHA-256 hash files (forensic integrity)
- Optional: Verify archives after creation
- Clean final summary table with compression ratios
- Full logging with timestamps
- Works great on network drives

### Requirements
- Windows
- [7-Zip](https://www.7-zip.org/) installed (default path)

### How to Use
1. Copy `Compress-Folders.ps1` into the folder that contains your subfolders.
2. Double-click the script (or right-click → "Run with PowerShell").
3. Answer the simple prompts (or just press Enter for defaults).

### Live Monitoring (Recommended)
While the script is running, open a **second PowerShell window** in the same folder and run this command to watch the archive grow in real time:

```powershell
while ($true) {
    Clear-Host
    Write-Host "=== CURRENTLY COMPRESSING ===" -ForegroundColor Cyan
    $archive = Get-ChildItem -Path . -Filter "*.7z" -Recurse | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($archive) {
        $sizeGB = [math]::Round($archive.Length / 1GB, 2)
        $sizeMB = [math]::Round($archive.Length / 1MB, 0)
        Write-Host "Archive : $($archive.Name)" -ForegroundColor White
        Write-Host "Size    : $sizeGB GB ($sizeMB MB)" -ForegroundColor White
        Write-Host "Updated : $($archive.LastWriteTime)" -ForegroundColor White
    } else {
        Write-Host "Waiting for first archive to appear..." -ForegroundColor Yellow
    }
    Write-Host "=============================" -ForegroundColor Cyan
    Start-Sleep -Seconds 2
}