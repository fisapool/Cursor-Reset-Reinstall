@echo off
setlocal enabledelayedexpansion
title FISAMY CURSOR RESET TOOL

:: Check for Admin rights
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else (
    goto GotAdmin
)

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    exit /B

:GotAdmin
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
    pushd "%CD%"
    CD /D "%~dp0"

:Initialize
    cls
    set "SCRIPT_DIR=%~dp0"
    set "PS_SCRIPT=%SCRIPT_DIR%cursor_win_debug.ps1"
    set "VERSION=latest"
    set "AUTO_INSTALL=true"

:ShowBanner
    echo.
    echo ================================================
    echo           FISAMY CURSOR RESET TOOL             
    echo           Version: 1.0.0                       
    echo ================================================
    echo.

:ShowMenu
    echo Available Options:
    echo A) Reset Cursor
    echo B) Quit
    echo.
    set /p CHOICE="Enter your choice (A or B): "
    echo.

    if /i "%CHOICE%"=="A" goto StartReset
    if /i "%CHOICE%"=="B" goto Exit
    
    echo Invalid choice. Please try again.
    timeout /t 2 >nul
    goto ShowMenu

:StartReset
    echo.
    echo Starting Cursor Reset Process...
    
    :: Version selection
    echo.
    echo Available Cursor Versions:
    echo 1. Build 250207 (Latest)
    echo 2. Build 250103
    echo.
    set /p VERSION_CHOICE="Select version (1-2, default=1): "
    
    if "%VERSION_CHOICE%"=="2" (
        set "VERSION=250103"
    ) else (
        set "VERSION=250207"
    )
    
    echo.
    echo Selected version: %VERSION%
    echo.
    
    :: Execution options
    echo Preparing to run PowerShell script with administrative privileges...
    
    :: Run the PowerShell script with appropriate parameters
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& '%PS_SCRIPT%' -Version %VERSION% -AutoInstall"
    
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo Error: PowerShell script execution failed with code %ERRORLEVEL%.
        echo Please check the log files for more information.
    ) else (
        echo.
        echo Cursor reset completed successfully.
    )
    
    goto End

:Exit
    echo.
    echo Exiting...
    timeout /t 1 >nul
    goto End

:End
    echo.
    echo Press any key to exit...
    pause >nul
    exit /B 0 