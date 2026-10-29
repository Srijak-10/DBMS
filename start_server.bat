@echo off
title Vehicle Spare Parts and Inventory Management System - Web Server
cd /d "%~dp0"

echo =====================================================================
echo   VEHICLE SPARE PARTS AND INVENTORY MANAGEMENT SYSTEM (VSP-IMS)
echo =====================================================================
echo.

set PYTHON_EXE=
if exist "C:\Users\DELL\AppData\Local\Programs\Python\Python311\python.exe" (
    set "PYTHON_EXE=C:\Users\DELL\AppData\Local\Programs\Python\Python311\python.exe"
) else (
    where python >nul 2>&1
    if %errorlevel% equ 0 (
        set "PYTHON_EXE=python"
    ) else (
        where py >nul 2>&1
        if %errorlevel% equ 0 (
            set "PYTHON_EXE=py"
        )
    )
)

if "%PYTHON_EXE%"=="" (
    echo [ERROR] Python 3 was not found on your system!
    echo Please ensure Python is installed and added to PATH.
    pause
    exit /b 1
)

echo [INFO] Using Python: %PYTHON_EXE%
echo [INFO] Starting Web Server on http://127.0.0.1:5000 ...
echo [INFO] Press Ctrl+C in this window anytime to stop the server.
echo.

start "" "http://127.0.0.1:5000"

"%PYTHON_EXE%" app.py

pause
