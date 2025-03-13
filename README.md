# FISACursor Reset Tool - User Guide

## Overview

The Cursor Reset Tool is a powerful utility designed to help you completely reset and reinstall the Cursor application when you encounter issues such as:

- Trial account limitations
- Performance problems
- Installation corruption
- Version compatibility issues

This tool provides a user-friendly interface to safely uninstall your current Cursor installation and install a fresh copy with your preferred version.

## Files Included

This package contains two essential files:

1. **cursor_reset.bat** - The main launcher with a user-friendly interface
2. **cursor_win_debug.ps1** - The PowerShell script that performs the actual reset operations

## Requirements

- Windows 10 or Windows 11
- Administrator privileges
- Internet connection (for downloading Cursor)
- PowerShell 5.1 or higher

## Installation

1. Create a new folder on your PC (e.g., "CursorTools")
2. Copy both `cursor_reset.bat` and `cursor_win_debug.ps1` to this folder
3. Ensure both files are in the same directory

## Usage Instructions

### Method 1: Using the Batch File (Recommended)

1. **Close Cursor Application**
   - Ensure all Cursor processes are completely closed before proceeding

2. **Run as Administrator**
   - Right-click on `cursor_reset.bat`
   - Select "Run as administrator"
   - If prompted by User Account Control (UAC), click "Yes"

3. **Follow the Menu Prompts**
   - The tool will display a simple menu interface
   - Select option "A" to reset Cursor

4. **Choose Cursor Version**
   - Select your preferred Cursor version:
     - Option 1: Build 250207 (Latest)
     - Option 2: Build 250103 (Stable)

5. **Wait for Completion**
   - The tool will:
     - Force close any running Cursor processes
     - Uninstall the current Cursor version
     - Download the selected version
     - Install the fresh copy
     - Generate a detailed debug report

6. **Restart Your Computer**
   - For best results, restart your computer after the installation completes

### Method 2: Direct PowerShell Execution

Advanced users can run the PowerShell script directly:

1. Open PowerShell as Administrator
2. Navigate to the script directory:
   ```powershell
   cd "path\to\your\folder"
   ```
3. Set execution policy:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
   ```
4. Run the script with parameters:
   ```powershell
   .\cursor_win_debug.ps1 -Version "250207" -AutoInstall
   ```

## Parameters

The PowerShell script supports the following parameters:

- **-Version**: Specifies the Cursor version to install
  - "250207" - Latest version (default)
  - "250103" - Stable version
  - "latest" - Always uses the most recent version

- **-AutoInstall**: Controls automatic installation
  - $true - Automatically installs Cursor (default)
  - $false - Downloads only, manual installation required

## Troubleshooting

If you encounter issues:

1. **Script Won't Run**
   - Ensure you're running as Administrator
   - Try setting the execution policy: `Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process`

2. **Download Fails**
   - Check your internet connection
   - Try the alternative version (250103)
   - Verify firewall/antivirus isn't blocking the download

3. **Installation Errors**
   - Check the log file in `%USERPROFILE%\AppData\Local\Cursor\Logs`
   - Ensure no Cursor processes are running
   - Try manual installation with the downloaded file

## Log Files

The tool generates detailed logs to help diagnose issues:

- Debug logs: `%USERPROFILE%\AppData\Local\Cursor\Logs\cursor_debug_[timestamp].log`
- Debug report: `%USERPROFILE%\AppData\Local\Cursor\Logs\cursor_debug_report.txt`

## Safety Features

This tool includes several safety measures:

- Automatic administrator privilege verification
- Process termination confirmation
- Error handling with detailed logging
- Version fallback if download fails

## Additional Notes

- The tool will automatically respond "Yes to All" to any prompts during execution
- After installation, you may need to sign in with your Cursor account
- For best results, use this tool in conjunction with the Cursor ID Reset Tool if you're experiencing trial limitations

## Support

If you encounter any issues or have questions, please:

1. Check the log files for error details
2. Refer to the main project repository for updates
3. Submit issues through the project's issue tracker

# FISAMY

![License: Proprietary](https://img.shields.io/badge/License-FISAMY%20Proprietary-red.svg)

🔒 **FISAMY PROPRIETARY SOFTWARE**
©️ 2025 All Rights Reserved


⚠️ **IMPORTANT**: This is proprietary software. No permission is granted for:
- Copying
- Modification
- Distribution
- Commercial use

without explicit written permission from FISAMY.

For licensing inquiries, contact: open@fisamy.work
