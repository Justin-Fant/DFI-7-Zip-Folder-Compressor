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
