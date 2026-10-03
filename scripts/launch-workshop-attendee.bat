@echo off
REM Workshop attendee launcher (Windows) — free tier
cd /d "%~dp0.."
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0launch-workshop-attendee.ps1"
if errorlevel 1 pause
