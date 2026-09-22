@echo off
setlocal EnableExtensions
chcp 65001 >nul

set "REPO_RAW=https://raw.githubusercontent.com/Graf-Git-Hub/Qwen_Image_2.1/main"

if /I "%~1"=="/skipupdate" goto :launch
if /I "%~1"=="/worker" goto :worker

rem ------------------------------------------------------------
rem Die eigentliche Update-Pruefung laeuft aus einer TEMP-Kopie.
rem Dadurch darf ein Update diese Startdatei gefahrlos ersetzen.
rem ------------------------------------------------------------
set "WORKER=%TEMP%\Qwen_Image_2_1_Launcher_%RANDOM%_%RANDOM%.cmd"
copy /Y "%~f0" "%WORKER%" >nul 2>&1
if errorlevel 1 goto :launch
call "%WORKER%" /worker "%~dp0"
del "%WORKER%" >nul 2>&1
exit /b

:worker
set "ROOT=%~2"
if not defined ROOT exit /b 1
set "REMOTE_VERSION_FILE=%TEMP%\Qwen_Image_2_1_remote_version_%RANDOM%.txt"
set "REMOTE_INSTALLER=%TEMP%\Qwen_Image_2_1_latest_installer_%RANDOM%.cmd"
set "LOCAL_VERSION=0"
set "REMOTE_VERSION=0"

if exist "%ROOT%VERSION.txt" set /p LOCAL_VERSION=<"%ROOT%VERSION.txt"

echo ============================================================
echo   Qwen Image 2.1 - Update Check
echo ============================================================
echo Installiert: %LOCAL_VERSION%
echo Pruefe GitHub ...

powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -UseBasicParsing -Uri '%REPO_RAW%/VERSION.txt?ts=%RANDOM%' -OutFile '%REMOTE_VERSION_FILE%' -TimeoutSec 12; exit 0 } catch { exit 1 }" >nul 2>&1
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
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -UseBasicParsing -Uri '%REPO_RAW%/INSTALL_QWEN_IMAGE_2_1.cmd?ts=%RANDOM%' -OutFile '%REMOTE_INSTALLER%' -TimeoutSec 30; exit 0 } catch { exit 1 }" >nul 2>&1
if errorlevel 1 (
  echo Update-Installer konnte nicht geladen werden. Starte vorhandene Version.
  goto :worker_launch
)

call "%REMOTE_INSTALLER%" /silent /nostart /target "%ROOT%"
if errorlevel 1 (
  echo Update fehlgeschlagen. Starte vorhandene Version.
) else (
  echo Update abgeschlossen.
)
del "%REMOTE_INSTALLER%" >nul 2>&1

:worker_launch
if exist "%ROOT%START_QWEN_IMAGE_2_1.cmd" (
  call "%ROOT%START_QWEN_IMAGE_2_1.cmd" /skipupdate
)
exit /b

:launch
cd /d "%~dp0"
title Qwen Image 2.1 Standalone
set "PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True"
set "HF_HOME=%~dp0hf_cache"

if not exist "%~dp0venv\Scripts\python.exe" (
  echo [FEHLER] Installation unvollstaendig.
  echo Bitte INSTALL_QWEN_IMAGE_2_1.cmd erneut starten.
  pause
  exit /b 1
)
if not exist "%~dp0qwen_app.py" (
  echo [FEHLER] qwen_app.py fehlt.
  echo Bitte INSTALL_QWEN_IMAGE_2_1.cmd erneut starten.
  pause
  exit /b 1
)

echo ============================================================
echo   QWEN IMAGE 2.1
if exist "%~dp0VERSION.txt" set /p QWEN_VER=<"%~dp0VERSION.txt"
if defined QWEN_VER echo   Version %QWEN_VER%
echo   http://127.0.0.1:7862
echo ============================================================
echo.

"%~dp0venv\Scripts\python.exe" "%~dp0qwen_app.py"
echo.
pause
