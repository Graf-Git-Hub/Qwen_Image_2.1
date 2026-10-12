@echo off
setlocal
chcp 65001 >nul
title Qwen Image 2.1 Turbo GPU - Installation
echo.
echo  Qwen Image 2.1 Turbo GPU - Installation
echo  =======================================
echo  Waehle gleich den Installationsordner aus.
echo  Danach werden die Programmdateien installiert und
echo  eine Desktop-Verknuepfung erstellt.
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue'; Add-Type -AssemblyName System.Windows.Forms; $dialog=New-Object System.Windows.Forms.FolderBrowserDialog; $dialog.Description='Ordner fuer Qwen Image 2.1 Turbo GPU waehlen'; $dialog.SelectedPath=[Environment]::GetFolderPath('LocalApplicationData'); $dialog.ShowNewFolderButton=$true; if($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK){Write-Host 'Installation abgebrochen.';exit 0}; $dir=Join-Path $dialog.SelectedPath 'Qwen-Image-2.1-Turbo-GPU'; New-Item -ItemType Directory -Force -Path $dir | Out-Null; $base='https://raw.githubusercontent.com/Graf-Git-Hub/Qwen_Image_2.1/main/local-gpu'; foreach($f in @('local_gpu.py','setup_gpu.ps1','START_GPU.cmd')){Write-Host ('Lade '+$f+' ...'); Invoke-WebRequest -UseBasicParsing -Uri ($base+'/'+$f+'?t='+[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()) -OutFile (Join-Path $dir $f)}; $shell=New-Object -ComObject WScript.Shell; $link=$shell.CreateShortcut((Join-Path ([Environment]::GetFolderPath('Desktop')) 'Qwen Image 2.1 Turbo GPU.lnk')); $link.TargetPath=Join-Path $dir 'START_GPU.cmd'; $link.WorkingDirectory=$dir; $link.Description='Lokale Qwen Image 2.1 Turbo GPU-Oberflaeche'; $link.Save(); Write-Host ('Installiert unter: '+$dir); Write-Host 'Starte Einrichtung und Modell-Download ...'; & (Join-Path $dir 'setup_gpu.ps1'); if($LASTEXITCODE -ne 0){exit 1}"
if errorlevel 1 (
  echo.
  echo Installation fehlgeschlagen. Bitte den Fehler fotografieren.
  pause
)
