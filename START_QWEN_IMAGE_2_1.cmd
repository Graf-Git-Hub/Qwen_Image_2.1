@echo off
setlocal EnableExtensions
chcp 65001 >nul
title Qwen Image 2.1

rem %~dp0 endet immer mit einem Backslash. Fuer PowerShell entfernen wir
rem diesen bewusst, damit beim quoted Argument kein ungueltiges Zeichen entsteht.
for %%I in ("%~dp0.") do set "ROOT=%%~fI"

if /I "%~1"=="/skipupdate" (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\update_and_start.ps1" -Root "%ROOT%" -SkipUpdate
) else (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\update_and_start.ps1" -Root "%ROOT%"
)

set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" pause
exit /b %RC%
