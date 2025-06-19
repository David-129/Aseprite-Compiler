:: ===============================================
:: Build Script for Aseprite
:: Copyright (c) 2025 David 129
:: Licensed under custom MIT-style license
:: Redistribution of Aseprite binaries is prohibited.
:: See LICENSE for details.
:: ===============================================

@echo off
setlocal enabledelayedexpansion
title Build Aseprite - Clean Rebuild

:: ==== Configuration ====
setlocal enabledelayedexpansion

:: Get latest version (using PowerShell)
for /f "delims=" %%i in ('powershell -Command "(Invoke-WebRequest -UseBasicParsing https://api.github.com/repos/aseprite/aseprite/releases/latest).Content | ConvertFrom-Json | Select-Object -ExpandProperty tag_name"') do (
    set "ASEPRITE_VERSION=%%i"
)

:: Path Configuration
set ROOT_DIR=D:\Project\aseprite_builder
set ASEPRITE_DIR=%ROOT_DIR%\aseprite
set BUILD_DIR=%ROOT_DIR%\build
set SKIA_DIR=%ROOT_DIR%\skia
set SKIA_ZIP_FILENAME=Skia-Windows-Release-x64.zip
set SKIA_ZIP=%ROOT_DIR%\%SKIA_ZIP_FILENAME%
set SKIA_ZIP_URL=https://github.com/aseprite/skia/releases/latest/download/%SKIA_ZIP_FILENAME%
set INSTALLER_DIR=%ROOT_DIR%\installer
set ISS_FILE=%ROOT_DIR%\aseprite_installer.iss

echo ==== Retrieved version successfully: %ASEPRITE_VERSION% ====

:: ==== Load Visual Studio environment ====
CALL "D:\vst_tools\VC\Auxiliary\Build\vcvars64.bat" >nul 2>nul
if %errorlevel% neq 0 (
    echo [!] Error: Unable to call vcvars64.bat
    pause
    exit /b
)

:: ==== Checking CMake and Ninja ====
where cmake >nul 2>nul || (
    echo [!] Cmake not found. Download from https://cmake.org/
    pause
    exit /b
)

where ninja >nul 2>nul || (
    echo [!] ninja not found. Download from https://ninja-build.org/
    pause
    exit /b
)

:: ==== Clean previous data ====
echo === Cleaning old data ===
rd /s /q "%ASEPRITE_DIR%" 2>nul
rd /s /q "%SKIA_DIR%" 2>nul
rd /s /q "%BUILD_DIR%" 2>nul
rd /s /q "%INSTALLER_DIR%" 2>nul

mkdir "%BUILD_DIR%" 2>nul
mkdir "%INSTALLER_DIR%" 2>nul

:: ==== Download And Extract Aseprite ====
echo === Downloading Aseprite Source ===
powershell -Command "Invoke-WebRequest -Uri 'https://github.com/aseprite/aseprite/releases/download/%ASEPRITE_VERSION%/Aseprite-%ASEPRITE_VERSION%-Source.zip' -OutFile '%ROOT_DIR%\aseprite.zip'" || (
    echo [!] Error downloading Aseprite source ZIP
    pause
    exit /b
)

echo === Extracting Aseprite Source ===

:: Create aseprite folder if not exists
mkdir "%ASEPRITE_DIR%" >nul 2>nul

:: Extract to correct folder
powershell -Command "Expand-Archive -Force '%ROOT_DIR%\aseprite.zip' '%ASEPRITE_DIR%'" || (
    echo [!] Error extracting Aseprite!
    pause
    exit /b
)

:: ===  Rename extracted folder to 'aseprite' ===
ren "%ROOT_DIR%\Aseprite-%ASEPRITE_VERSION%-Source" aseprite
 
:: ==== Extract Skia ====
if not exist "%SKIA_ZIP%" (
    echo === Downloading Skia ===
    powershell -Command "Invoke-WebRequest -Uri '%SKIA_ZIP_URL%' -OutFile '%SKIA_ZIP%'" || (
        echo [!] Error downloading Skia ZIP!
        pause
        exit /b
    )
)

echo === Extracting Skia ===
powershell -Command "Expand-Archive -Force '%SKIA_ZIP%' '%SKIA_DIR%'"

:: ==== Configure with CMake ====
echo === Configuring with CMake ===
pushd "%BUILD_DIR%"
cmake -G Ninja ^
  -DCMAKE_BUILD_TYPE=RelWithDebInfo ^
  -DLAF_BACKEND=skia ^
  -DSKIA_DIR="%SKIA_DIR%" ^
  -DSKIA_LIBRARY_DIR="%SKIA_DIR%\out\Release-x64" ^
  -DSKIA_LIBRARY="%SKIA_DIR%\out\Release-x64\skia.lib" ^
  -DPIXMAN_INCLUDE_DIR="%ASEPRITE_DIR%\third_party\pixman\pixman" ^
  -DENABLE_UPDATER=OFF ^
  -DHAVE_VERSION_PROPERTIES=ON ^
  -DVERSION_PROPERTIES_FILE="%ASEPRITE_DIR%\version.properties" ^
  -DVERSION_OVERRIDE="%ASEPRITE_VERSION%" ^
  "%ASEPRITE_DIR%"

if %errorlevel% neq 0 (
    echo [!] Error running CMake!
    popd
    pause
    exit /b
)

:: ==== Build ====
echo === Building with Ninja ===
ninja
if not exist "%BUILD_DIR%\bin\aseprite.exe" (
    echo [!] Build failed!
    popd
    pause
    exit /b
)
popd
echo === Build successful ===

:: ==== Create Inno Setup (.iss) file ====
echo === Creating Inno Setup (.iss) file ===

:: Delete old ISS file if exists
if exist "%ISS_FILE%" del /f /q "%ISS_FILE%"

:: Write new ISS file
> "%ISS_FILE%" (
    echo [Setup]
    echo AppName=Aseprite
    echo AppVersion=%ASEPRITE_VERSION%
    echo DefaultDirName={autopf}\Aseprite
    echo DefaultGroupName=Aseprite
    echo OutputBaseFilename=aseprite-setup-%ASEPRITE_VERSION%
    echo OutputDir=%INSTALLER_DIR%
    echo Compression=lzma
    echo SolidCompression=yes
    echo ; comment to prevent "echo is off" error
    echo [Files]
    echo Source: "%BUILD_DIR%\bin\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
    echo ; comment to prevent "echo is off" error
    echo [Icons]
    echo Name: "{group}\Aseprite"; Filename: "{app}\aseprite.exe"
    echo Name: "{group}\Uninstall Aseprite"; Filename: "{uninstallexe}"
)

:: ==== Check ISCC ====
where ISCC >nul 2>nul || (
    echo [!] ISCC not found. Please install Inno Setup and add ISCC to PATH.
    pause
    exit /b
)

:: ==== Create setup file ====
echo === Creating installer ===
ISCC "%ISS_FILE%" || (
    echo [!] Error building installer!
    pause
    exit /b
)

echo.
echo === COMPLETED: %INSTALLER_DIR%\aseprite-setup-%ASEPRITE_VERSION%.exe ===
pause
endlocal
