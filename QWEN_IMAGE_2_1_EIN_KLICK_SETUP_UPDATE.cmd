@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
title Qwen Image 2.1 - Ein-Klick Setup / Update

set "REPO_RAW=https://raw.githubusercontent.com/Graf-Git-Hub/Qwen_Image_2.1/main"
set "KNOWN_ROOT=K:\Paschy_Tools_und_Projekte\Qwen_image2.1\Qwen-Image-2.1-Standalone"
set "TARGET="
set "TMP=%TEMP%\Qwen_Image_2_1_Setup_%RANDOM%_%RANDOM%"
set "REMOTE_VER_FILE=%TMP%\VERSION.txt"
set "LATEST_INSTALLER=%TMP%\INSTALL_QWEN_IMAGE_2_1.cmd"
set "LATEST_STARTER=%TMP%\START_QWEN_IMAGE_2_1.cmd"

if not exist "%TMP%" mkdir "%TMP%" >nul 2>&1

echo ============================================================
echo   Qwen Image 2.1 - EIN-KLICK SETUP / UPDATE
echo ============================================================
echo.

rem ------------------------------------------------------------
rem Installationsordner automatisch finden
rem ------------------------------------------------------------
if exist "%KNOWN_ROOT%\" set "TARGET=%KNOWN_ROOT%"
if not defined TARGET if exist "%~dp0Qwen-Image-2.1-Standalone\" set "TARGET=%~dp0Qwen-Image-2.1-Standalone"
if not defined TARGET if exist "%LOCALAPPDATA%\Qwen-Image-2.1-Standalone\" set "TARGET=%LOCALAPPDATA%\Qwen-Image-2.1-Standalone"
if not defined TARGET (
  if exist "K:\" (
    set "TARGET=%KNOWN_ROOT%"
  ) else (
    set "TARGET=%LOCALAPPDATA%\Qwen-Image-2.1-Standalone"
  )
)

for %%I in ("%TARGET%") do set "TARGET=%%~fI"

echo Installationsordner:
echo   %TARGET%
echo.

echo [1/5] Pruefe aktuelle GitHub-Version ...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ProgressPreference='SilentlyContinue';try{Invoke-WebRequest -UseBasicParsing -Uri '%REPO_RAW%/VERSION.txt?ts=%RANDOM%' -OutFile '%REMOTE_VER_FILE%' -TimeoutSec 20;exit 0}catch{exit 1}" >nul 2>&1
if errorlevel 1 goto :network_fail

set "REMOTE_VERSION=0"
set /p REMOTE_VERSION=<"%REMOTE_VER_FILE%"
set "LOCAL_VERSION=0"
if exist "%TARGET%\VERSION.txt" set /p LOCAL_VERSION=<"%TARGET%\VERSION.txt"

echo Lokal:   %LOCAL_VERSION%
echo GitHub:  %REMOTE_VERSION%
echo.

set "NEEDS_INSTALL=0"
if /I not "%LOCAL_VERSION%"=="%REMOTE_VERSION%" set "NEEDS_INSTALL=1"
if not exist "%TARGET%\qwen_app.py" set "NEEDS_INSTALL=1"
if not exist "%TARGET%\venv\Scripts\python.exe" set "NEEDS_INSTALL=1"
if not exist "%TARGET%\model\model_index.json" set "NEEDS_INSTALL=1"
if not exist "%TARGET%\START_QWEN_IMAGE_2_1.cmd" set "NEEDS_INSTALL=1"

if "%NEEDS_INSTALL%"=="1" (
  echo [2/5] Installation oder Update notwendig.
  echo Lade aktuellen Smart-Installer ...
  powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ProgressPreference='SilentlyContinue';try{Invoke-WebRequest -UseBasicParsing -Uri '%REPO_RAW%/INSTALL_QWEN_IMAGE_2_1.cmd?ts=%RANDOM%' -OutFile '%LATEST_INSTALLER%' -TimeoutSec 30;exit 0}catch{exit 1}" >nul 2>&1
  if errorlevel 1 goto :network_fail

  call "%LATEST_INSTALLER%" /nostart /target "%TARGET%"
  if errorlevel 1 goto :install_fail
) else (
  echo [2/5] Installation ist bereits aktuell.
)

echo [3/5] Aktuelle Startdatei sicherstellen ...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ProgressPreference='SilentlyContinue';try{Invoke-WebRequest -UseBasicParsing -Uri '%REPO_RAW%/START_QWEN_IMAGE_2_1.cmd?ts=%RANDOM%' -OutFile '%LATEST_STARTER%' -TimeoutSec 30;exit 0}catch{exit 1}" >nul 2>&1
if errorlevel 1 goto :network_fail

copy /Y "%LATEST_STARTER%" "%TARGET%\START_QWEN_IMAGE_2_1.cmd" >nul 2>&1
if errorlevel 1 goto :install_fail

echo [4/5] Desktop-Verknuepfung mit Symbol erstellen ...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$desktop=[Environment]::GetFolderPath('Desktop');" ^
  "$shell=New-Object -ComObject WScript.Shell;" ^
  "$lnk=$shell.CreateShortcut((Join-Path $desktop 'Qwen Image 2.1.lnk'));" ^
  "$lnk.TargetPath='%TARGET%\START_QWEN_IMAGE_2_1.cmd';" ^
  "$lnk.WorkingDirectory='%TARGET%';" ^
  "$lnk.IconLocation=($env:SystemRoot+'\System32\shell32.dll,167');" ^
  "$lnk.Description='Qwen Image 2.1 - startet mit automatischer Update-Pruefung';" ^
  "$lnk.Save()" >nul 2>&1
if errorlevel 1 goto :install_fail

echo [5/5] Abschlusspruefung ...
if not exist "%TARGET%\qwen_app.py" goto :install_fail
if not exist "%TARGET%\venv\Scripts\python.exe" goto :install_fail
if not exist "%TARGET%\model\model_index.json" goto :install_fail
if not exist "%TARGET%\START_QWEN_IMAGE_2_1.cmd" goto :install_fail

echo.
echo ============================================================
echo   FERTIG
echo ============================================================
echo.
echo Qwen Image 2.1 ist installiert und aktuell.
echo.
echo Auf deinem Desktop liegt jetzt:
echo   Qwen Image 2.1
echo.
echo Beim spaeteren Doppelklick passiert automatisch:
echo   1. GitHub auf neue VERSION pruefen
echo   2. Bei Update zuerst aktualisieren
echo   3. Danach Qwen normal starten
echo   4. Ohne Update sofort Qwen starten
echo.
echo Installationsordner:
echo   %TARGET%
echo.

rmdir /S /Q "%TMP%" >nul 2>&1
pause
exit /b 0

:network_fail
echo.
echo ============================================================
echo   GITHUB NICHT ERREICHBAR
echo ============================================================
echo.
echo Die aktuellen Dateien konnten nicht geladen werden.
echo Bitte Internetverbindung pruefen und diese Datei erneut starten.
echo.
rmdir /S /Q "%TMP%" >nul 2>&1
pause
exit /b 1

:install_fail
echo.
echo ============================================================
echo   INSTALLATION / UPDATE FEHLGESCHLAGEN
echo ============================================================
echo.
echo Falls vorhanden, findest du das Log hier:
echo   %TARGET%\INSTALL_UPDATE.log
echo.
rmdir /S /Q "%TMP%" >nul 2>&1
pause
exit /b 1
