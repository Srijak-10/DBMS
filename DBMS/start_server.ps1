# PowerShell Launcher for Vehicle Spare Parts & Inventory Management Web Server
$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "  VEHICLE SPARE PARTS AND INVENTORY MANAGEMENT SYSTEM (VSP-IMS)      " -ForegroundColor Yellow
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host ""

$pythonExe = $null
$defaultPath = "C:\Users\DELL\AppData\Local\Programs\Python\Python311\python.exe"

if (Test-Path $defaultPath) {
    $pythonExe = $defaultPath
} else {
    $cmd = Get-Command python -ErrorAction SilentlyContinue
    if ($cmd) {
        $pythonExe = "python"
    } else {
        $pyCmd = Get-Command py -ErrorAction SilentlyContinue
        if ($pyCmd) {
            $pythonExe = "py"
        }
    }
}

if (-not $pythonExe) {
    Write-Host "[ERROR] Python 3 executable could not be found." -ForegroundColor Red
    Write-Host "Please ensure Python 3 is installed." -ForegroundColor Red
    pause
    exit 1
}

Write-Host "[INFO] Detected Python runtime: $pythonExe" -ForegroundColor Green
Write-Host "[INFO] Starting Flask Server on http://127.0.0.1:5000 ..." -ForegroundColor Green
Write-Host "[INFO] Opening web browser..." -ForegroundColor Gray
Write-Host "[INFO] Press Ctrl+C in this console to terminate the server." -ForegroundColor Yellow
Write-Host ""

Start-Process "http://127.0.0.1:5000"

& $pythonExe app.py
