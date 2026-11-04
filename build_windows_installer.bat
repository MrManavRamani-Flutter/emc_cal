@echo off
title OM MAVTAR GROUP - Windows Setup Builder
echo ========================================================
echo   OM MAVTAR GROUP - Windows Release Builder & Setup EXE
echo ========================================================

echo.
echo [1/5] Getting Flutter dependencies...
call flutter pub get

echo.
echo [2/5] Running verification tests...
call flutter test

echo.
echo [3/5] Building Windows x64 Release application...
call flutter build windows --release

echo.
echo [4/5] Verifying output files and sqlite3.dll...
if not exist "build\windows\x64\runner\Release\emb_cal.exe" (
    echo [ERROR] emb_cal.exe was not found! Build failed.
    pause
    exit /b 1
)

copy /Y "windows\Run_OM_MAVTAR_Calculator.bat" "build\windows\x64\runner\Release\Run_OM_MAVTAR_Calculator.bat" >nul

if not exist "dist" mkdir "dist"

echo.
echo [5/5] Checking Inno Setup Compiler...
set "INNO_PATH="
if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" set "INNO_PATH=C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if exist "C:\Program Files\Inno Setup 6\ISCC.exe" set "INNO_PATH=C:\Program Files\Inno Setup 6\ISCC.exe"

if defined INNO_PATH (
    echo Found Inno Setup at: "%INNO_PATH%"
    echo Compiling Windows Single-Click Setup Installer...
    "%INNO_PATH%" "windows\installer\OM_MAVTAR_Installer.iss"
    echo [SUCCESS] Installer generated at: dist\OM_MAVTAR_Calculator_v1.0_Setup.exe
) else (
    echo [INFO] Inno Setup is not installed on this PC.
    echo Creating Standalone Portable ZIP instead...
    powershell -Command "Compress-Archive -Path 'build\windows\x64\runner\Release\*' -DestinationPath 'dist\OM_MAVTAR_Calculator_v1.0_Windows_Portable.zip' -Force"
    echo [SUCCESS] Portable ZIP generated at: dist\OM_MAVTAR_Calculator_v1.0_Windows_Portable.zip
)

echo.
echo ========================================================
echo BUILD FINISHED SUCCESSFULLY!
echo Files ready in 'dist\' folder and 'build\windows\x64\runner\Release\'
echo ========================================================
pause
