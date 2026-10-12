@echo off
setlocal
chcp 65001 >nul
title Qwen Image 2.1 Turbo - lokale GPU
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_gpu.ps1"
if errorlevel 1 pause
