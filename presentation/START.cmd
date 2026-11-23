@echo off
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-Presentation.ps1"
if errorlevel 1 echo Presentation startup failed. Read the message above.
pause
