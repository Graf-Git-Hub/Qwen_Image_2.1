@echo off
setlocal EnableExtensions
chcp 65001 >nul

set "REPO_RAW=https://raw.githubusercontent.com/Graf-Git-Hub/Qwen_Image_2.1/main"
set "APPROOT="

rem ------------------------------------------------------------
rem Installation finden. Diese Startdatei darf entweder direkt
rem im App-Ordner ODER eine Ebene darueber liegen.
rem ------------------------------------------------------------
if exist "%~dp0qwen_app.py" set "APPROOT=%~dp0"
if not defined APPROOT if exist "%~dp0qwen_v7.py" set "APPROOT=%~dp0"
if not defined APPROOT if exist "%~dp0Qwen-Image-2.1-Standalone\" set "APPROOT=%~dp0Qwen-Image-2.1-Standalone"
if not defined APPROOT if exist "K:\Paschy_Tools_und_Projekte\Qwen_image2.1\Qwen-Image-2.1-Standalone\" set "APPROOT=K:\Paschy_Tools_und_Projekte\Qwen_image2.1\Qwen-Image-2.1-Standalone"
if not defined APPROOT if exist "%LOCALAPPDATA%\Qwen-Image-2.1-Standalone\" set "APPROOT=%LOCALAPPDATA%\Qwen-Image-2.1-Standalone"
if not defined APPROOT set "APPROOT=%~dp0"

for %%I in ("%APPROOT%") do set "APPROOT=%%~fI"

if /I "%~1"=="/skipupdate" goto :launch
if /I "%~1"=="/worker" (
  set "APPROOT=%~2"
  goto :worker
)

rem ------------------------------------------------------------
rem Update-Check aus TEMP-Kopie, damit Launcher selbst ersetzt
rem werden kann, waehrend er gerade laeuft.
rem ------------------------------------------------------------
set "WORKER=%TEMP%\Qwen_Image_2_1_Launcher_%RANDOM%_%RANDOM%.cmd"
copy /Y "%~f0" "%WORKER%" >nul 2>&1
if errorlevel 1 goto :launch
call "%WORKER%" /worker "%APPROOT%"
del "%WORKER%" >nul 2>&1
exit /b

:worker
set "REMOTE_VERSION_FILE=%TEMP%\Qwen_Image_2_1_remote_version_%RANDOM%.txt"
set "REMOTE_INSTALLER=%TEMP%\Qwen_Image_2_1_latest_installer_%RANDOM%.cmd"
set "LOCAL_VERSION=0"
set "REMOTE_VERSION=0"

if exist "%APPROOT%\VERSION.txt" set /p LOCAL_VERSION=<"%APPROOT%\VERSION.txt"

echo ============================================================
echo   Qwen Image 2.1 - Update Check
echo ============================================================
echo Installationsordner:
echo   %APPROOT%
echo.
echo Installiert: %LOCAL_VERSION%
echo Pruefe GitHub ...

powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue';try{Invoke-WebRequest -UseBasicParsing -Uri '%REPO_RAW%/VERSION.txt?ts=%RANDOM%' -OutFile '%REMOTE_VERSION_FILE%' -TimeoutSec 12;exit 0}catch{exit 1}" >nul 2>&1
if errorlevel 1 (
  echo GitHub gerade nicht erreichbar. Starte vorhandene Version.
  goto :worker_launch
)

set /p REMOTE_VERSION=<"%REMOTE_VERSION_FILE%"
del "%REMOTE_VERSION_FILE%" >nul 2>&1
echo Aktuell:     %REMOTE_VERSION%

if /I "%LOCAL_VERSION%"=="%REMOTE_VERSION%" (
  echo Kein Update vorhanden.
  goto :worker_launch
)

echo.
echo Update gefunden: %LOCAL_VERSION% -^> %REMOTE_VERSION%
echo Lade aktuellen Installer ...

powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue';try{Invoke-WebRequest -UseBasicParsing -Uri '%REPO_RAW%/INSTALL_QWEN_IMAGE_2_1.cmd?ts=%RANDOM%' -OutFile '%REMOTE_INSTALLER%' -TimeoutSec 30;exit 0}catch{exit 1}" >nul 2>&1
if errorlevel 1 (
  echo Update-Installer konnte nicht geladen werden. Starte vorhandene Version.
  goto :worker_launch
)

call "%REMOTE_INSTALLER%" /silent /nostart /target "%APPROOT%"
if errorlevel 1 (
  echo Update fehlgeschlagen. Starte vorhandene Version.
) else (
  echo Update abgeschlossen.
)
del "%REMOTE_INSTALLER%" >nul 2>&1

:worker_launch
if exist "%APPROOT%\START_QWEN_IMAGE_2_1.cmd" (
  call "%APPROOT%\START_QWEN_IMAGE_2_1.cmd" /skipupdate
  exit /b
)

goto :launch

:launch
cd /d "%APPROOT%"
title Qwen Image 2.1 Standalone
set "PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True"
set "HF_HOME=%APPROOT%\hf_cache"

if not exist "%APPROOT%\venv\Scripts\python.exe" (
  echo [FEHLER] Installation unvollstaendig.
  echo Bitte INSTALL_QWEN_IMAGE_2_1.cmd erneut starten.
  pause
  exit /b 1
)

if not exist "%APPROOT%\qwen_app.py" (
  echo [FEHLER] Neue App-Datei qwen_app.py fehlt.
  echo Die vorhandene alte Installation wurde noch nicht aktualisiert.
  echo Bitte INSTALL_QWEN_IMAGE_2_1.cmd einmal starten.
  pause
  exit /b 1
)

echo ============================================================
echo   QWEN IMAGE 2.1
if exist "%APPROOT%\VERSION.txt" set /p QWEN_VER=<"%APPROOT%\VERSION.txt"
if defined QWEN_VER echo   Version %QWEN_VER%
echo   http://127.0.0.1:7862
echo ============================================================
echo.

"%APPROOT%\venv\Scripts\python.exe" "%APPROOT%\qwen_app.py"
echo.
pause
