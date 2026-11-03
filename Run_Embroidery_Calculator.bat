@echo off
title OM MAVTAR GROUP - Embroidery Production Calculator
cd /d "%~dp0"
if exist "emb_cal.exe" (
    start "" "emb_cal.exe"
) else if exist "build\windows\x64\runner\Release\emb_cal.exe" (
    start "" "build\windows\x64\runner\Release\emb_cal.exe"
) else (
    echo Executable emb_cal.exe not found! Please build the project first using build_windows_installer.bat
    pause
)
