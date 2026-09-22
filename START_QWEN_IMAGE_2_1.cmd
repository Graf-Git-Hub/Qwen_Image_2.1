@echo off
setlocal EnableExtensions
chcp 65001 >nul
title Qwen Image 2.1

set "ROOT=%~dp0"
if /I "%~1"=="/skipupdate" (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ROOT%update_and_start.ps1" -Root "%ROOT%" -SkipUpdate
) else (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ROOT%update_and_start.ps1" -Root "%ROOT%"
)

if errorlevel 1 pause
exit /b %ERRORLEVEL%
