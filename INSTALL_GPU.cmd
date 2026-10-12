@echo off
setlocal
chcp 65001 >nul
title Qwen Image 2.1 Turbo GPU - Installation
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $base='https://raw.githubusercontent.com/Graf-Git-Hub/Qwen_Image_2.1/main/local-gpu'; $dir=Join-Path $env:LOCALAPPDATA 'Qwen-Image-2.1-Turbo-GPU'; New-Item -ItemType Directory -Force -Path $dir | Out-Null; foreach($f in @('local_gpu.py','setup_gpu.ps1','START_GPU.cmd')) { Invoke-WebRequest -UseBasicParsing -Uri ($base+'/'+$f+'?t='+[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()) -OutFile (Join-Path $dir $f) }; Start-Process -FilePath (Join-Path $dir 'START_GPU.cmd') -WorkingDirectory $dir -Wait"
if errorlevel 1 (
  echo Installation fehlgeschlagen. Bitte Fehler fotografieren.
  pause
)
