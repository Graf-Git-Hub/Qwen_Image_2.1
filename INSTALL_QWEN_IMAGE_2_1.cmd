@echo off
setlocal EnableExtensions
chcp 65001 >nul
title Qwen Image 2.1 - Installer

set "RAW=https://raw.githubusercontent.com/Graf-Git-Hub/Qwen_Image_2.1/main"
set "PS1=%TEMP%\Qwen_Image_2_1_install_%RANDOM%_%RANDOM%.ps1"

echo ============================================================
echo   Qwen Image 2.1 - EIN-KLICK INSTALLER
echo ============================================================
echo.
echo Lade den aktuellen Installer von GitHub ...

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue';try{Invoke-WebRequest -UseBasicParsing -Uri '%RAW%/install.ps1?ts=%RANDOM%' -OutFile '%PS1%' -TimeoutSec 60;exit 0}catch{Write-Host $_.Exception.Message;exit 1}"
if errorlevel 1 goto :fail

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
set "RC=%ERRORLEVEL%"
del "%PS1%" >nul 2>&1
if not "%RC%"=="0" goto :fail

exit /b 0

:fail
echo.
echo ============================================================
echo   INSTALLATION FEHLGESCHLAGEN
echo ============================================================
echo.
echo Bitte dieses Fenster fotografieren oder den Fehlertext schicken.
echo.
pause
exit /b 1
