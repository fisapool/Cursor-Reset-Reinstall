# Enable debug mode
$DebugPreference = 'Continue'
$VerbosePreference = 'Continue'

# Script metadata
$ScriptVersion = "1.0.0"
$LogDir = Join-Path $env:USERPROFILE "AppData\Local\Cursor\Logs"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LogFile = Join-Path $LogDir "cursor_debug_$timestamp.log"

# Ensure log directory exists
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

# Simple banner function
function Show-Banner {
    Clear-Host
    $banner = @"
================================================
           FISAMY CURSOR RESET TOOL
           Version: $ScriptVersion
================================================
"@
    Write-Host $banner -ForegroundColor Cyan
    Write-Host ""
}

function Show-Menu {
    Write-Host "Available Options:" -ForegroundColor Yellow
    Write-Host "A) Reset Cursor" -ForegroundColor Green
    Write-Host "B) Quit" -ForegroundColor Red
    Write-Host ""
    $choice = Read-Host "Enter your choice (A or B)"
    return $choice
}

# Request password function
function Request-Password {
    $secure = Read-Host "Please enter your administrator password" -AsSecureString
    $cred = New-Object System.Management.Automation.PSCredential "Administrator", $secure
    return $cred
}

# Set execution policy with bypass
function Set-PolicyBypass {
    Write-Host "`nSetting execution policy to Bypass..." -ForegroundColor Yellow
    try {
        Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -Confirm:$false
        Write-Host "Execution policy set to Bypass" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Failed to set execution policy: $_" -ForegroundColor Red
        return $false
    }
}

# Main menu loop
function Start-MainMenu {
    while ($true) {
        Show-Banner
        $choice = Show-Menu
        
        switch ($choice.ToUpper()) {
            'A' {
                Write-Host "`nStarting Cursor Reset Process..." -ForegroundColor Cyan
                
                # Request credentials
                $credentials = Request-Password
                Write-Host "Password received. Proceeding with elevated privileges..." -ForegroundColor Yellow
                
                # Set execution policy
                if (-not (Set-PolicyBypass)) {
                    Write-Host "Failed to set execution policy. Cannot continue." -ForegroundColor Red
                    Start-Sleep -Seconds 3
                    continue
                }
                
                # Automatically respond Yes to All for prompts
                $confirmPreference = "None"
                $ConfirmPreference = "None"
                $WhatIfPreference = $false
                
                Write-Host "Configuration complete. Starting reset process..." -ForegroundColor Green
                Start-Sleep -Seconds 2
                return $true
            }
            'B' {
                Write-Host "`nExiting..." -ForegroundColor Yellow
                Start-Sleep -Seconds 1
                return $false
            }
            default {
                Write-Host "`nInvalid choice. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    }
}

function Write-Log {
    param(
        [string]$Message,
        [string]$Type = "INFO",
        [string]$ForegroundColor = "White"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Type] $Message"
    
    # Write to console with color
    Write-Host "[$Type] " -ForegroundColor $ForegroundColor -NoNewline
    Write-Host $Message
    
    # Write to log file
    try {
        $logMessage | Out-File -FilePath $LogFile -Append -Encoding UTF8
    } catch {
        Write-Host "Failed to write to log file: $_" -ForegroundColor Red
    }
}

function Test-AdminPrivileges {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-CursorProcessInfo {
    Write-Log "Checking Cursor processes..." -Type "DEBUG" -ForegroundColor Blue
    $cursorProcesses = Get-Process "Cursor" -ErrorAction SilentlyContinue
    
    if ($cursorProcesses) {
        foreach ($proc in $cursorProcesses) {
            Write-Log "Found Cursor process: PID=$($proc.Id), StartTime=$($proc.StartTime), CPU=$($proc.CPU)" -Type "DEBUG" -ForegroundColor Blue
        }
        return $cursorProcesses
    } else {
        Write-Log "No Cursor processes found" -Type "DEBUG" -ForegroundColor Blue
        return $null
    }
}

function Test-CursorPaths {
    Write-Log "Validating Cursor paths..." -Type "DEBUG" -ForegroundColor Blue
    
    $paths = @{
        Storage = "$env:APPDATA\Cursor\User\globalStorage\storage.json"
        Executable = "${env:LOCALAPPDATA}\Programs\Cursor\Cursor.exe"
        UserData = "$env:APPDATA\Cursor"
    }
    
    $results = @{}
    
    foreach ($key in $paths.Keys) {
        $path = $paths[$key]
        $exists = Test-Path $path
        $results[$key] = @{
            Path = $path
            Exists = $exists
            IsAccessible = $false
            LastWriteTime = $null
        }
        
        if ($exists) {
            try {
                $item = Get-Item $path
                $results[$key].IsAccessible = $true
                $results[$key].LastWriteTime = $item.LastWriteTime
                Write-Log "Path '$key' exists and is accessible: $path" -Type "DEBUG" -ForegroundColor Blue
            } catch {
                Write-Log "Path '$key' exists but is not accessible: $path" -Type "DEBUG" -ForegroundColor Blue
            }
        } else {
            Write-Log "Path '$key' does not exist: $path" -Type "DEBUG" -ForegroundColor Blue
        }
    }
    
    return $results
}

function Get-CursorSystemInfo {
    Write-Log "Gathering system information..." -Type "DEBUG" -ForegroundColor Blue
    
    $info = @{
        OS = [System.Environment]::OSVersion.ToString()
        PowerShell = $PSVersionTable.PSVersion.ToString()
        Architecture = if ([System.Environment]::Is64BitOperatingSystem) { "64-bit" } else { "32-bit" }
        Username = [System.Environment]::UserName
        ComputerName = [System.Environment]::MachineName
        SystemDirectory = [System.Environment]::SystemDirectory
    }
    
    foreach ($key in $info.Keys) {
        Write-Log "$key`: $($info[$key])" -Type "DEBUG" -ForegroundColor Blue
    }
    
    return $info
}

function Stop-CursorProcesses {
    Write-Log "Attempting to stop all Cursor processes..." -Type "DEBUG" -ForegroundColor Blue
    $cursorProcesses = Get-Process "Cursor" -ErrorAction SilentlyContinue
    
    if ($cursorProcesses) {
        foreach ($proc in $cursorProcesses) {
            try {
                $proc | Stop-Process -Force
                Write-Log "Successfully terminated process ID: $($proc.Id)" -Type "SUCCESS" -ForegroundColor Green
            } catch {
                Write-Log "Failed to terminate process ID: $($proc.Id)" -Type "ERROR" -ForegroundColor Red
            }
        }
        Start-Sleep -Seconds 2 # Wait for processes to fully terminate
        return $true
    } else {
        Write-Log "No Cursor processes found to terminate" -Type "INFO" -ForegroundColor Yellow
        return $true
    }
}

function Uninstall-Cursor {
    Write-Log "Preparing to uninstall Cursor..." -Type "DEBUG" -ForegroundColor Blue
    
    $uninstallPath = "${env:LOCALAPPDATA}\Programs\Cursor\Uninstall Cursor.exe"
    if (Test-Path $uninstallPath) {
        try {
            Start-Process -FilePath $uninstallPath -ArgumentList "/S" -Wait
            Write-Log "Uninstall process completed" -Type "SUCCESS" -ForegroundColor Green
            Start-Sleep -Seconds 2 # Wait for uninstall to complete
            return $true
        } catch {
            Write-Log "Failed to uninstall: $_" -Type "ERROR" -ForegroundColor Red
            return $false
        }
    } else {
        Write-Log "Uninstaller not found at: $uninstallPath" -Type "ERROR" -ForegroundColor Red
        return $false
    }
}

function Download-NewCursor {
    param (
        [string]$OutputPath = "$env:TEMP\CursorSetup.exe",
        [string]$Version = "latest"
    )
    
    Write-Log "Downloading new Cursor version..." -Type "DEBUG" -ForegroundColor Blue
    
    # Define available versions
    $versions = @{
        "250207" = "https://downloader.cursor.sh/builds/250207y6nbaw5qc/windows/nsis/x64"
        "250103" = "https://downloader.cursor.sh/builds/250103fqxdt5u9z/windows/nsis/x64"
        "latest" = "https://downloader.cursor.sh/builds/250207y6nbaw5qc/windows/nsis/x64"  # Set latest to 250207
    }
    
    try {
        # Select download URL based on version
        $downloadUrl = $versions[$Version]
        if (-not $downloadUrl) {
            Write-Log "Invalid version specified. Using latest version." -Type "WARN" -ForegroundColor Yellow
            $downloadUrl = $versions["latest"]
            $Version = "latest"
        }
        
        Write-Log "Selected version: $Version" -Type "INFO" -ForegroundColor Green
        Write-Log "Using download URL: $downloadUrl" -Type "DEBUG" -ForegroundColor Blue
        
        # Configure security protocol to use TLS 1.2
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        # Create web client with timeout and user agent
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "PowerShell/CursorDebugTool")
        
        # Download with progress
        Write-Log "Starting download..." -Type "DEBUG" -ForegroundColor Blue
        $webClient.DownloadFile($downloadUrl, $OutputPath)
        
        if (Test-Path $OutputPath) {
            $fileSize = (Get-Item $OutputPath).Length / 1MB
            Write-Log "Download completed successfully: $OutputPath (Size: $([math]::Round($fileSize, 2)) MB)" -Type "SUCCESS" -ForegroundColor Green
            return $OutputPath
        } else {
            Write-Log "Download failed: File not found after download" -Type "ERROR" -ForegroundColor Red
            return $null
        }
    } catch {
        Write-Log "Download failed with error: $($_.Exception.Message)" -Type "ERROR" -ForegroundColor Red
        
        # Additional error details for debugging
        if ($_.Exception.Response) {
            Write-Log "Response Status Code: $($_.Exception.Response.StatusCode.value__)" -Type "DEBUG" -ForegroundColor Blue
            Write-Log "Response Status Description: $($_.Exception.Response.StatusDescription)" -Type "DEBUG" -ForegroundColor Blue
        }
        
        # Try the alternative version if the first one fails
        if ($Version -eq "250207") {
            Write-Log "Attempting download with alternative version..." -Type "INFO" -ForegroundColor Yellow
            try {
                $alternativeUrl = $versions["250103"]
                Write-Log "Using alternative URL: $alternativeUrl" -Type "DEBUG" -ForegroundColor Blue
                $webClient.DownloadFile($alternativeUrl, $OutputPath)
                
                if (Test-Path $OutputPath) {
                    $fileSize = (Get-Item $OutputPath).Length / 1MB
                    Write-Log "Alternative version download successful: $OutputPath (Size: $([math]::Round($fileSize, 2)) MB)" -Type "SUCCESS" -ForegroundColor Green
                    return $OutputPath
                }
            } catch {
                Write-Log "Alternative version download also failed: $($_.Exception.Message)" -Type "ERROR" -ForegroundColor Red
            }
        }
        
        return $null
    } finally {
        if ($webClient) {
            $webClient.Dispose()
        }
    }
}

function Install-Cursor {
    param (
        [string]$InstallerPath
    )
    
    Write-Log "Starting Cursor installation..." -Type "DEBUG" -ForegroundColor Blue
    
    if (-not (Test-Path $InstallerPath)) {
        Write-Log "Installer not found at: $InstallerPath" -Type "ERROR" -ForegroundColor Red
        return $false
    }
    
    try {
        # Start installation with silent parameters
        Write-Log "Running installer: $InstallerPath" -Type "DEBUG" -ForegroundColor Blue
        $process = Start-Process -FilePath $InstallerPath -ArgumentList "/S" -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Log "Installation completed successfully" -Type "SUCCESS" -ForegroundColor Green
            
            # Wait for installation to settle
            Start-Sleep -Seconds 5
            
            # Verify installation
            $cursorExe = "${env:LOCALAPPDATA}\Programs\Cursor\Cursor.exe"
            if (Test-Path $cursorExe) {
                Write-Log "Verified Cursor executable at: $cursorExe" -Type "SUCCESS" -ForegroundColor Green
                return $true
            } else {
                Write-Log "Installation succeeded but executable not found" -Type "ERROR" -ForegroundColor Red
                return $false
            }
        } else {
            Write-Log "Installation failed with exit code: $($process.ExitCode)" -Type "ERROR" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Log "Installation failed with error: $($_.Exception.Message)" -Type "ERROR" -ForegroundColor Red
        return $false
    }
}

function Start-CursorDebug {
    param(
        [string]$Version = "latest",
        [switch]$AutoInstall = $true
    )

    Write-Host "=== Cursor Debug Tool ===" -ForegroundColor Cyan
    Write-Host "Version: $ScriptVersion"
    Write-Host "Log File: $LogFile"
    Write-Host ""
    
    # Display available versions
    Write-Host "Available Cursor Versions:" -ForegroundColor Cyan
    Write-Host "1. Build 250207 (Latest)" -ForegroundColor Yellow
    Write-Host "2. Build 250103" -ForegroundColor Yellow
    Write-Host ""
    
    # Version selection if not specified
    if ($Version -eq "latest") {
        $versionChoice = Read-Host "Select version (1-2, default=1)"
        switch ($versionChoice) {
            "2" { $Version = "250103" }
            default { $Version = "250207" }
        }
    }
    
    # Set execution policy again after version selection
    Write-Host "Setting execution policy to Bypass for process..." -ForegroundColor Yellow
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -Confirm:$false
    
    # Respond Yes to All
    Write-Host "Auto-answering 'Yes to All' for any prompts..." -ForegroundColor Yellow
    $ConfirmPreference = "None"
    
    # Step 1: Check admin privileges
    Write-Log "Step 1/8: Checking administrator privileges..." -Type "INFO" -ForegroundColor Green
    if (-not (Test-AdminPrivileges)) {
        Write-Log "This script requires administrator privileges" -Type "ERROR" -ForegroundColor Red
        Write-Host "Please run PowerShell as Administrator and try again"
        return
    }
    Write-Log "Administrator privileges confirmed" -Type "SUCCESS" -ForegroundColor Green
    
    # Step 2: Force Close Cursor
    Write-Log "Step 2/8: Force closing Cursor processes..." -Type "INFO" -ForegroundColor Green
    if (Stop-CursorProcesses) {
        Write-Log "All Cursor processes terminated" -Type "SUCCESS" -ForegroundColor Green
    } else {
        Write-Log "Failed to terminate all Cursor processes" -Type "ERROR" -ForegroundColor Red
        return
    }
    
    # Step 3: Uninstall Current Version
    Write-Log "Step 3/8: Uninstalling current Cursor version..." -Type "INFO" -ForegroundColor Green
    if (Uninstall-Cursor) {
        Write-Log "Cursor uninstalled successfully" -Type "SUCCESS" -ForegroundColor Green
    } else {
        Write-Log "Failed to uninstall Cursor" -Type "ERROR" -ForegroundColor Red
        return
    }
    
    # Step 4: Download New Version
    Write-Log "Step 4/8: Downloading new Cursor version..." -Type "INFO" -ForegroundColor Green
    $installerPath = Download-NewCursor -Version $Version
    if ($installerPath) {
        Write-Log "New version downloaded successfully" -Type "SUCCESS" -ForegroundColor Green
    } else {
        Write-Log "Failed to download new version" -Type "ERROR" -ForegroundColor Red
        return
    }
    
    # Step 5: Install New Version (if AutoInstall is enabled)
    Write-Log "Step 5/8: Installing new Cursor version..." -Type "INFO" -ForegroundColor Green
    if ($AutoInstall) {
        if (Install-Cursor -InstallerPath $installerPath) {
            Write-Log "New version installed successfully" -Type "SUCCESS" -ForegroundColor Green
        } else {
            Write-Log "Failed to install new version" -Type "ERROR" -ForegroundColor Red
            return
        }
    } else {
        Write-Log "Skipping automatic installation" -Type "INFO" -ForegroundColor Yellow
    }
    
    # Step 6: System Information
    Write-Log "Step 6/8: Gathering system information..." -Type "INFO" -ForegroundColor Green
    $sysInfo = Get-CursorSystemInfo
    Write-Log "System information collected successfully" -Type "SUCCESS" -ForegroundColor Green
    
    # Step 7: Path Validation
    Write-Log "Step 7/8: Validating Cursor paths..." -Type "INFO" -ForegroundColor Green
    $pathResults = Test-CursorPaths
    Write-Log "Path validation completed" -Type "SUCCESS" -ForegroundColor Green
    
    # Step 8: Generate Report
    Write-Log "Step 8/8: Generating debug report..." -Type "INFO" -ForegroundColor Green
    $report = @"
=== Cursor Debug Report ===
Generated: $(Get-Date)

System Information:
$($sysInfo | ConvertTo-Json)

Path Validation Results:
$($pathResults | ConvertTo-Json)

Actions Performed:
- Forced close of Cursor processes
- Uninstalled previous version
- Downloaded new version to: $installerPath
- Auto-installation: $(if ($AutoInstall) { "Completed" } else { "Skipped" })
"@
    
    $reportPath = Join-Path $LogDir "cursor_debug_report.txt"
    $report | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Log "Debug report generated successfully" -Type "SUCCESS" -ForegroundColor Green
    
    # Finalize
    Write-Log "Debug report saved to: $reportPath" -Type "SUCCESS" -ForegroundColor Green
    Write-Log "Log file saved to: $LogFile" -Type "SUCCESS" -ForegroundColor Green
    Write-Log "Process completed successfully" -Type "SUCCESS" -ForegroundColor Green
    
    if ($AutoInstall) {
        Write-Host "`nInstallation Complete!" -ForegroundColor Cyan
        Write-Host "Please restart your computer to complete the setup." -ForegroundColor Yellow
    } else {
        Write-Host "`nNext Steps:" -ForegroundColor Cyan
        Write-Host "1. Run the installer: $installerPath" -ForegroundColor Yellow
        Write-Host "2. After installation, restart your computer" -ForegroundColor Yellow
    }
}

# Modify the main execution block
try {
    # Show menu and get user choice
    $proceed = Start-MainMenu
    
    if (-not $proceed) {
        exit 0
    }
    
    # Force Set Execution Policy
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -Confirm:$false
    
    # Get version from command line argument if provided
    $version = "latest"
    $autoInstall = $true
    
    # Parse command line arguments
    for ($i = 0; $i -lt $args.Count; $i++) {
        switch ($args[$i]) {
            "-Version" {
                $i++
                if ($i -lt $args.Count) {
                    $version = $args[$i]
                }
            }
            "-NoAutoInstall" {
                $autoInstall = $false
            }
        }
    }
    
    # Ensure Yes to All is set
    $ConfirmPreference = "None"
    $confirmPreference = "None"
    $WhatIfPreference = $false
    
    # Start the debug process
    Start-CursorDebug -Version $version -AutoInstall $autoInstall
} catch {
    Write-Log "An error occurred: $_" -Type "ERROR" -ForegroundColor Red
    Write-Log "Stack Trace: $($_.ScriptStackTrace)" -Type "ERROR" -ForegroundColor Red
    exit 1
} finally {
    # Reset execution policy to default if needed
    try {
        Set-ExecutionPolicy -ExecutionPolicy Restricted -Scope Process -Force -Confirm:$false -ErrorAction SilentlyContinue
    } catch {
        # Ignore errors when resetting policy
    }
    
    Write-Host "`nPress Enter to exit..." -ForegroundColor Cyan
    Read-Host
    exit 0
} 