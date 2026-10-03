# Dr.C Standalone — workshop launch (Windows). Pro+ defaults.
#   powershell -ExecutionPolicy Bypass -File scripts\launch-drc.ps1

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\workshop-path.ps1"

if (-not $env:DRC_PRO_PLUS) { $env:DRC_PRO_PLUS = "1" }
if (-not $env:DRC_WORKSHOP_LITE) { $env:DRC_WORKSHOP_LITE = "0" }

$Root = Split-Path $PSScriptRoot -Parent
Set-Location $Root

if (-not (Get-Command csound -ErrorAction SilentlyContinue)) {
    Write-Host "Csound not found on PATH."
    Write-Host "Install Csound 7 from https://csound.com/download.html"
    Write-Host "Then reopen this launcher."
    Read-Host "Press Enter to close"
    exit 1
}

Write-Host "Dr.C Standalone (Csound 7) — tier: $($env:DRC_PRO_PLUS) Pro+"
Write-Host "Csound: $((csound --version 2>&1 | Select-Object -First 1))"
Write-Host ""

if (-not (Test-Path "node_modules")) {
    Write-Host "Run first: npm install"
    Read-Host "Press Enter to close"
    exit 1
}

# Free port 5173 if a stale dev server is running
$on5173 = Get-NetTCPConnection -LocalPort 5173 -ErrorAction SilentlyContinue
if ($on5173) {
    Write-Host "Closing previous session on port 5173..."
    Stop-Process -Id $on5173.OwningProcess -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
}

npm run dev
