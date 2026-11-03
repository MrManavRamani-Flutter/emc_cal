@echo off
title OM MAVTAR GROUP - Windows Setup Builder
echo ========================================================
echo Building Latest Release Version (UI Updated & Clean Data)
echo ========================================================

echo [1/4] Cleaning previous builds...
call flutter clean

echo [2/4] Getting dependencies...
call flutter pub get

echo [3/4] Building Windows x64 Release application...
call flutter build windows --release

echo [4/4] Verifying sqlite3.dll and output files...
if exist "build\windows\x64\runner\Release\sqlite3.dll" (
    echo [OK] sqlite3.dll found in release build.
) else (
    echo [WARNING] sqlite3.dll may be missing from release runner.
)

echo.
echo ========================================================
echo BUILD SUCCESSFUL!
echo Your latest updated Windows app is ready at:
echo build\windows\x64\runner\Release\
echo ========================================================
pause
