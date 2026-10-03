@echo off
REM Double-click or run from cmd: scripts\launch-drc.bat
cd /d "%~dp0.."
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0launch-drc.ps1"
if errorlevel 1 pause
