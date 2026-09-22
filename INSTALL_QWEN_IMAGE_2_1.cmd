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
rem Bestehende Installation finden.
rem Wichtig fuer alte V7-Installationen, bei denen qwen_app.py
rem noch nicht existiert.
rem ------------------------------------------------------------
if not defined TARGET if exist "%~dp0qwen_app.py" set "TARGET=%~dp0"
if not defined TARGET if exist "%~dp0qwen_v7.py" set "TARGET=%~dp0"
if not defined TARGET if exist "%~dp0venv\Scripts\python.exe" if exist "%~dp0model\" set "TARGET=%~dp0"

if not defined TARGET if exist "%~dp0Qwen-Image-2.1-Standalone\" set "TARGET=%~dp0Qwen-Image-2.1-Standalone"

if not defined TARGET if exist "K:\Paschy_Tools_und_Projekte\Qwen_image2.1\Qwen-Image-2.1-Standalone\" set "TARGET=K:\Paschy_Tools_und_Projekte\Qwen_image2.1\Qwen-Image-2.1-Standalone"
if not defined TARGET if exist "%LOCALAPPDATA%\Qwen-Image-2.1-Standalone\" set "TARGET=%LOCALAPPDATA%\Qwen-Image-2.1-Standalone"
if not defined TARGET set "TARGET=%LOCALAPPDATA%\Qwen-Image-2.1-Standalone"

for %%I in ("%TARGET%") do set "ROOT=%%~fI"
for %%I in ("%~dp0.") do set "SOURCE_DIR=%%~fI"
for %%I in ("%ROOT%\..") do set "ROOT_PARENT=%%~fI"

set "LOG=%ROOT%\INSTALL_UPDATE.log"
set "WORKTMP=%TEMP%\Qwen_Image_2_1_Install_%RANDOM%_%RANDOM%"

if not exist "%WORKTMP%" mkdir "%WORKTMP%" >nul 2>&1
if not exist "%ROOT%" mkdir "%ROOT%" >nul 2>&1
if not exist "%ROOT%\outputs" mkdir "%ROOT%\outputs" >nul 2>&1
if not exist "%ROOT%\hf_cache" mkdir "%ROOT%\hf_cache" >nul 2>&1

> "%LOG%" echo Qwen Image 2.1 Installer/Updater %DATE% %TIME%
>> "%LOG%" echo Ziel: %ROOT%

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
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue';" ^
  "$base=$env:REPO_RAW;" ^
  "$items=@(" ^
  "  @{r='qwen_app.py.gz';d=(Join-Path $env:WORKTMP 'qwen_app.py.gz')}," ^
  "  @{r='START_QWEN_IMAGE_2_1.cmd';d=(Join-Path $env:ROOT 'START_QWEN_IMAGE_2_1.cmd')}," ^
  "  @{r='loading_matrix.mp4';d=(Join-Path $env:ROOT 'loading_matrix.mp4')}," ^
  "  @{r='queue_wait.webp';d=(Join-Path $env:ROOT 'queue_wait.webp')}," ^
  "  @{r='VERSION.txt';d=(Join-Path $env:ROOT 'VERSION.txt')}" ^
  ");" ^
  "foreach($x in $items){" ^
  "  $ok=$false;" ^
  "  for($i=1;$i -le 3;$i++){" ^
  "    try{Invoke-WebRequest -UseBasicParsing -Uri ($base+'/'+$x.r+'?ts='+[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()) -OutFile $x.d -TimeoutSec 120; $ok=$true; break}" ^
  "    catch{Start-Sleep -Seconds 2}" ^
  "  };" ^
  "  if(-not $ok){throw ('Download fehlgeschlagen: '+$x.r)}" ^
  "}" >> "%LOG%" 2>&1
if errorlevel 1 goto :fail

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "$in=[IO.File]::OpenRead((Join-Path $env:WORKTMP 'qwen_app.py.gz'));" ^
  "$gz=New-Object IO.Compression.GzipStream($in,[IO.Compression.CompressionMode]::Decompress);" ^
  "$out=[IO.File]::Create((Join-Path $env:ROOT 'qwen_app.py'));" ^
  "$gz.CopyTo($out);$out.Dispose();$gz.Dispose();$in.Dispose()" >> "%LOG%" 2>&1
if errorlevel 1 goto :fail

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

echo [3/8] Python-Umgebung pruefen ...
if exist "%ROOT%\venv\Scripts\python.exe" (
  set "VPY=%ROOT%\venv\Scripts\python.exe"
  echo Vorhandene venv wird weiterverwendet.
  goto :venv_ready
)

for /f "delims=" %%P in ('py -3.11 -c "import sys;print(sys.executable)" 2^>nul') do set "PYEXE=%%P"
if not defined PYEXE if exist "%LocalAppData%\Programs\Python\Python311\python.exe" set "PYEXE=%LocalAppData%\Programs\Python\Python311\python.exe"

if not defined PYEXE (
  where winget >nul 2>&1
  if errorlevel 1 goto :pythonfail
  echo Python 3.11 wird installiert ...
  winget install --id Python.Python.3.11 -e --scope user --silent --accept-package-agreements --accept-source-agreements >> "%LOG%" 2>&1
  if exist "%LocalAppData%\Programs\Python\Python311\python.exe" set "PYEXE=%LocalAppData%\Programs\Python\Python311\python.exe"
)
if not defined PYEXE goto :pythonfail

"%PYEXE%" -m venv "%ROOT%\venv" >> "%LOG%" 2>&1
if errorlevel 1 goto :fail
set "VPY=%ROOT%\venv\Scripts\python.exe"

:venv_ready
echo [4/8] Python-Pakete pruefen ...
"%VPY%" -c "import torch,fastapi,uvicorn;from PIL import Image;from diffusers import QwenImage21Pipeline;import transformers,accelerate,huggingface_hub" >nul 2>&1
if errorlevel 1 (
  echo Fehlende Pakete werden installiert ...
  "%VPY%" -m pip install --upgrade pip setuptools wheel >> "%LOG%" 2>&1
  if errorlevel 1 goto :fail
  "%VPY%" -m pip install --upgrade torch torchvision --index-url https://download.pytorch.org/whl/cu126 >> "%LOG%" 2>&1
  if errorlevel 1 goto :fail
  "%VPY%" -m pip install --upgrade "transformers>=5.17" accelerate pillow fastapi uvicorn python-multipart huggingface_hub hf_xet safetensors sentencepiece >> "%LOG%" 2>&1
  if errorlevel 1 goto :fail
  "%VPY%" -m pip install --upgrade "https://github.com/huggingface/diffusers/archive/refs/heads/main.zip" >> "%LOG%" 2>&1
  if errorlevel 1 goto :fail
) else (
  echo Vorhandene funktionierende Pakete werden wiederverwendet.
)

echo [5/8] App pruefen ...
"%VPY%" -m py_compile "%ROOT%\qwen_app.py" >> "%LOG%" 2>&1
if errorlevel 1 goto :fail

echo [6/8] Qwen-Image-2.1 Modell pruefen ...
if exist "%ROOT%\model\model_index.json" (
  echo Modell bereits vorhanden.
) else (
  echo Grosser Modell-Download startet. Abgebrochene Downloads koennen fortgesetzt werden.
  "%VPY%" -c "from huggingface_hub import snapshot_download;snapshot_download(repo_id='Qwen/Qwen-Image-2.1',local_dir=r'%ROOT%\model')" >> "%LOG%" 2>&1
  if errorlevel 1 goto :fail
)

echo [7/8] Startdateien aktualisieren ...
rem Wenn der Installer direkt neben dem vorhandenen Standalone-Ordner
rem liegt, wird auch der Launcher in diesem Elternordner aktualisiert.
if /I "%SOURCE_DIR%"=="%ROOT_PARENT%" (
  copy /Y "%ROOT%\START_QWEN_IMAGE_2_1.cmd" "%SOURCE_DIR%\START_QWEN_IMAGE_2_1.cmd" >nul 2>&1
)

echo [8/8] Desktop-Verknuepfung erstellen ...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$d=[Environment]::GetFolderPath('Desktop');" ^
  "$w=New-Object -ComObject WScript.Shell;" ^
  "$s=$w.CreateShortcut((Join-Path $d 'Qwen Image 2.1.lnk'));" ^
  "$s.TargetPath=(Join-Path $env:ROOT 'START_QWEN_IMAGE_2_1.cmd');" ^
  "$s.WorkingDirectory=$env:ROOT;" ^
  "$s.Save()" >> "%LOG%" 2>&1

rmdir /S /Q "%WORKTMP%" >nul 2>&1

echo.
echo ============================================================
echo   QWEN IMAGE 2.1 IST AKTUELL
if exist "%ROOT%\VERSION.txt" set /p INSTALLED_VERSION=<"%ROOT%\VERSION.txt"
if defined INSTALLED_VERSION echo   Version %INSTALLED_VERSION%
echo ============================================================
echo.

if "%NOSTART%"=="0" call "%ROOT%\START_QWEN_IMAGE_2_1.cmd" /skipupdate
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
powershell -NoProfile -Command "if(Test-Path '%LOG%'){Get-Content '%LOG%' -Tail 40}" 2>nul
if "%SILENT%"=="0" pause
exit /b 1
