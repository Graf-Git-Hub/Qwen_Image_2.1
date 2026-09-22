@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
title Qwen Image 2.1 - Smart Installer / Updater

set "REPO_RAW=https://raw.githubusercontent.com/Graf-Git-Hub/Qwen_Image_2.1/main"
set "TARGET="
set "SILENT=0"
set "NOSTART=0"
set "PYEXE="

:args
if "%~1"=="" goto :args_done
if /I "%~1"=="/silent" set "SILENT=1"
if /I "%~1"=="/nostart" set "NOSTART=1"
if /I "%~1"=="/target" (
  shift
  set "TARGET=%~1"
)
shift
goto :args

:args_done

rem ------------------------------------------------------------
rem Installationsordner bestimmen.
rem 1) /target
rem 2) Installer liegt bereits in einer Installation
rem 3) bekannte bestehende Installation
rem 4) LOCALAPPDATA als portable Standardwahl
rem ------------------------------------------------------------
if not defined TARGET if exist "%~dp0qwen_app.py" set "TARGET=%~dp0"
if not defined TARGET if exist "K:\Paschy_Tools_und_Projekte\Qwen_image2.1\Qwen-Image-2.1-Standalone\qwen_app.py" set "TARGET=K:\Paschy_Tools_und_Projekte\Qwen_image2.1\Qwen-Image-2.1-Standalone"
if not defined TARGET if exist "%LOCALAPPDATA%\Qwen-Image-2.1-Standalone\qwen_app.py" set "TARGET=%LOCALAPPDATA%\Qwen-Image-2.1-Standalone"
if not defined TARGET set "TARGET=%LOCALAPPDATA%\Qwen-Image-2.1-Standalone"
for %%I in ("%TARGET%") do set "ROOT=%%~fI"

set "LOG=%ROOT%\INSTALL_UPDATE.log"
set "TMP=%TEMP%\Qwen_Image_2_1_Install_%RANDOM%_%RANDOM%"
if not exist "%TMP%" mkdir "%TMP%" >nul 2>&1
if not exist "%ROOT%" mkdir "%ROOT%" >nul 2>&1
if not exist "%ROOT%\outputs" mkdir "%ROOT%\outputs" >nul 2>&1
if not exist "%ROOT%\hf_cache" mkdir "%ROOT%\hf_cache" >nul 2>&1

> "%LOG%" echo Qwen Image 2.1 Installer/Updater %DATE% %TIME%

if "%SILENT%"=="0" (
  echo ============================================================
  echo   Qwen Image 2.1 - SMART INSTALLER / UPDATER
  echo ============================================================
  echo.
  echo Ziel:
  echo   %ROOT%
  echo.
  echo Vorhandene Modelle, Outputs, venv und Einstellungen bleiben erhalten.
  echo.
)

echo [1/8] Aktuelle Programmdateien von GitHub laden ...
call :download "qwen_app.py.gz" "%TMP%\qwen_app.py.gz" || goto :fail
powershell -NoProfile -ExecutionPolicy Bypass -Command "$in=[IO.File]::OpenRead('%TMP%\qwen_app.py.gz');$gz=New-Object IO.Compression.GzipStream($in,[IO.Compression.CompressionMode]::Decompress);$out=[IO.File]::Create('%ROOT%\qwen_app.py');$gz.CopyTo($out);$out.Dispose();$gz.Dispose();$in.Dispose()" >> "%LOG%" 2>&1
if errorlevel 1 goto :fail
call :download "START_QWEN_IMAGE_2_1.cmd" "%ROOT%\START_QWEN_IMAGE_2_1.cmd" || goto :fail
call :download "loading_matrix.mp4" "%ROOT%\loading_matrix.mp4" || goto :fail
call :download "queue_wait.webp" "%ROOT%\queue_wait.webp" || goto :fail
call :download "VERSION.txt" "%ROOT%\VERSION.txt" || goto :fail
copy /Y "%~f0" "%ROOT%\INSTALL_QWEN_IMAGE_2_1.cmd" >nul 2>&1
if not exist "%ROOT%\OLLAMA_URL.txt" > "%ROOT%\OLLAMA_URL.txt" echo http://127.0.0.1:11434
if not exist "%ROOT%\PROMPT_AI_MODEL.txt" > "%ROOT%\PROMPT_AI_MODEL.txt" echo.

echo [2/8] NVIDIA pruefen ...
where nvidia-smi >nul 2>&1
if errorlevel 1 (
  echo [WARNUNG] nvidia-smi nicht gefunden. NVIDIA-Treiber pruefen.
) else (
  nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader
)

echo [3/8] Python 3.11 pruefen ...
for /f "delims=" %%P in ('py -3.11 -c "import sys;print(sys.executable)" 2^>nul') do set "PYEXE=%%P"
if not defined PYEXE if exist "%LocalAppData%\Programs\Python\Python311\python.exe" set "PYEXE=%LocalAppData%\Programs\Python\Python311\python.exe"
if not defined PYEXE (
  where winget >nul 2>&1 || goto :pythonfail
  echo Python 3.11 wird installiert ...
  winget install --id Python.Python.3.11 -e --scope user --silent --accept-package-agreements --accept-source-agreements >> "%LOG%" 2>&1
  if exist "%LocalAppData%\Programs\Python\Python311\python.exe" set "PYEXE=%LocalAppData%\Programs\Python\Python311\python.exe"
)
if not defined PYEXE goto :pythonfail

echo [4/8] Python-Umgebung pruefen ...
if not exist "%ROOT%\venv\Scripts\python.exe" (
  "%PYEXE%" -m venv "%ROOT%\venv" >> "%LOG%" 2>&1 || goto :fail
)
set "VPY=%ROOT%\venv\Scripts\python.exe"

echo [5/8] Python-Pakete pruefen ...
"%VPY%" -c "import torch,fastapi,uvicorn;from PIL import Image;from diffusers import QwenImage21Pipeline;import transformers,accelerate,huggingface_hub" >nul 2>&1
if errorlevel 1 (
  echo Fehlende Pakete werden installiert ...
  "%VPY%" -m pip install --upgrade pip setuptools wheel >> "%LOG%" 2>&1 || goto :fail
  "%VPY%" -m pip install --upgrade torch torchvision --index-url https://download.pytorch.org/whl/cu126 >> "%LOG%" 2>&1 || goto :fail
  "%VPY%" -m pip install --upgrade "transformers>=5.17" accelerate pillow fastapi uvicorn python-multipart huggingface_hub hf_xet safetensors sentencepiece >> "%LOG%" 2>&1 || goto :fail
  "%VPY%" -m pip install --upgrade "https://github.com/huggingface/diffusers/archive/refs/heads/main.zip" >> "%LOG%" 2>&1 || goto :fail
) else (
  echo Vorhandene funktionierende Pakete werden wiederverwendet.
)

echo [6/8] App pruefen ...
"%VPY%" -m py_compile "%ROOT%\qwen_app.py" >> "%LOG%" 2>&1 || goto :fail

echo [7/8] Qwen-Image-2.1 Modell pruefen ...
if exist "%ROOT%\model\model_index.json" (
  echo Modell bereits vorhanden.
) else (
  echo Grosser Modell-Download startet. Abgebrochene Downloads koennen fortgesetzt werden.
  "%VPY%" -c "from huggingface_hub import snapshot_download;snapshot_download(repo_id='Qwen/Qwen-Image-2.1',local_dir=r'%ROOT%\model')" >> "%LOG%" 2>&1 || goto :fail
)

echo [8/8] Desktop-Verknuepfung erstellen ...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$d=[Environment]::GetFolderPath('Desktop');$w=New-Object -ComObject WScript.Shell;$s=$w.CreateShortcut((Join-Path $d 'Qwen Image 2.1.lnk'));$s.TargetPath='%ROOT%\START_QWEN_IMAGE_2_1.cmd';$s.WorkingDirectory='%ROOT%';$s.Save()" >> "%LOG%" 2>&1

rmdir /S /Q "%TMP%" >nul 2>&1

echo.
echo ============================================================
echo   QWEN IMAGE 2.1 IST AKTUELL
if exist "%ROOT%\VERSION.txt" set /p INSTALLED_VERSION=<"%ROOT%\VERSION.txt"
if defined INSTALLED_VERSION echo   Version %INSTALLED_VERSION%
echo ============================================================
echo.

if "%NOSTART%"=="0" call "%ROOT%\START_QWEN_IMAGE_2_1.cmd" /skipupdate
exit /b 0

:download
set "REL=%~1"
set "DEST=%~2"
set "DLTMP=%TMP%\%RANDOM%_%RANDOM%.download"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue';$ErrorActionPreference='Stop';$u='%REPO_RAW%/%REL%?ts=%RANDOM%';for($i=1;$i -le 3;$i++){try{Invoke-WebRequest -UseBasicParsing -Uri $u -OutFile '%DLTMP%' -TimeoutSec 120;exit 0}catch{if($i -eq 3){exit 1};Start-Sleep -Seconds 2}}" >> "%LOG%" 2>&1
if errorlevel 1 exit /b 1
move /Y "%DLTMP%" "%DEST%" >nul 2>&1
if errorlevel 1 exit /b 1
exit /b 0

:pythonfail
echo [FEHLER] Python 3.11 konnte nicht gefunden oder installiert werden.
goto :fail

:fail
echo.
echo ============================================================
echo   INSTALLATION / UPDATE FEHLGESCHLAGEN
echo ============================================================
echo Logdatei:
echo   %LOG%
echo.
powershell -NoProfile -Command "if(Test-Path '%LOG%'){Get-Content '%LOG%' -Tail 35}" 2>nul
if "%SILENT%"=="0" pause
exit /b 1
