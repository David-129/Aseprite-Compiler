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

echo WARNING: This script will DELETE build folders.
echo DO NOT run outside its own directory.

:: ==== Check Internet Connection ====
powershell -Command "try { Invoke-WebRequest -Uri 'https://github.com' -UseBasicParsing -TimeoutSec 5 } catch { exit 1 }" >nul 2>nul || (
    echo [!] No Internet. Cannot continue.
    pause
    exit /b
)

:: ==== Configuration ====
setlocal enabledelayedexpansion

:: Get latest version (using PowerShell)
for /f "delims=" %%i in ('powershell -Command "(Invoke-WebRequest -UseBasicParsing https://api.github.com/repos/aseprite/aseprite/releases/latest).Content | ConvertFrom-Json | Select-Object -ExpandProperty tag_name"') do (
    set "ASEPRITE_VERSION=%%i"
)

if not defined ASEPRITE_VERSION (
    echo [!] Failed to retrieve Aseprite version! Network or GitHub API might be down.
    pause
    exit /b
)

:: ==== Path Configuration ====
set ROOT=%~dp0
cd /d "%ROOT%"
set "ASEPRITE_DIR=%ROOT_DIR%\aseprite"
set "BUILD_DIR=%ROOT_DIR%\build"
set "SKIA_DIR=%ROOT_DIR%\skia"
set "INSTALLER_DIR=%ROOT_DIR%\installer"
set "ISS_FILE=%ROOT_DIR%\aseprite_installer.iss"

set /p CONFIRM=Type YES to continue: 
if /I not "%CONFIRM%"=="YES" exit

echo === Controlled clean: selected folders and files only ===

:: ==== Clean folders ====
for %%D in (
    "%ASEPRITE_DIR%"
    "%SKIA_DIR%"
    "%BUILD_DIR%"
    "%INSTALLER_DIR%"
    "%CMAKE_DIR%"
    "%NINJA_DIR%"
    "%ROOT_DIR%\innosetup"
) do (
    if exist "%%~D" (
        echo Deleting folder: %%~D
        rd /s /q "%%~D"
    )
)

:: ==== Clean Aseprite versioned ZIPs ====
for %%F in ("%ROOT_DIR%\Aseprite-*-Source.zip") do (
    echo Deleting Aseprite source zip: %%~nxF
    del /f /q "%%~F"
)

:: ==== Clean CMake zip ====
for %%F in ("%ROOT_DIR%\cmake-*.zip") do (
    echo Deleting CMake zip: %%~nxF
    del /f /q "%%~F"
)

:: ==== Clean Ninja zip ====
for %%F in ("%ROOT_DIR%\ninja-win.zip") do (
    echo Deleting Ninja zip: %%~nxF
    del /f /q "%%~F"
)

:: ==== Clean Skia zip ====
if exist "%SKIA_ZIP%" (
    echo Deleting Skia zip: %SKIA_ZIP%
    del /f /q "%SKIA_ZIP%"
)

:: ==== Clean Inno Setup installer ====
if exist "%INNO_EXE%" (
    echo Deleting Inno Setup installer: %INNO_EXE%
    del /f /q "%INNO_EXE%"
)

:: ==== Clean old Inno Setup script ====
if exist "%ISS_FILE%" (
    echo Deleting old Inno Setup script: %ISS_FILE%
    del /f /q "%ISS_FILE%"
)

echo === Creating clean folders ===
mkdir "%BUILD_DIR%" 2>nul
mkdir "%INSTALLER_DIR%" 2>nul

echo ==== Retrieved version successfully: %ASEPRITE_VERSION% ====

echo === Locating Visual Studio ===

set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"

if not exist "%VSWHERE%" (
    echo [!] vswhere.exe not found. Trying to download...
    set "VSWHERE_ZIP=%ROOT_DIR%\vswhere.zip"
    powershell -Command "Invoke-WebRequest -Uri https://github.com/microsoft/vswhere/releases/latest/download/vswhere.exe -OutFile '%ROOT_DIR%\vswhere.exe'" || (
        echo [!] Failed to download vswhere.exe!
        pause
        exit /b
    )
    set "VSWHERE=%ROOT_DIR%\vswhere.exe"
)

for /f "tokens=*" %%i in ('"%VSWHERE%" -latest -products * -requires Microsoft.Component.MSBuild -property installationPath') do (
    set "VS_INSTALL_DIR=%%i"
)

if not defined VS_INSTALL_DIR (
    echo [!] Visual Studio not found! Please install it first.
    pause
    exit /b
)

echo === Calling vcvars64.bat ===
CALL "%VS_INSTALL_DIR%\VC\Auxiliary\Build\vcvars64.bat" >nul 2>nul
if %errorlevel% neq 0 (
    echo [!] Error: Unable to call vcvars64.bat
    pause
    exit /b
)

:: ==== Checking CMake and Ninja ====
:: ==== Check and auto-install the latest version of CMake ====

:: Define folders for download and extraction
set "CMAKE_DIR=%ROOT_DIR%\cmake"
:: Get file name from URL
for /f %%f in ('powershell -Command "$url = '%CMAKE_ZIP_URL%'; Split-Path -Leaf $url"') do set "CMAKE_ZIP=%ROOT_DIR%\%%f"

:: Get latest CMake version (e.g. v4.0.3)
for /f "delims=" %%v in ('powershell -Command "(Invoke-WebRequest -UseBasicParsing https://api.github.com/repos/Kitware/CMake/releases/latest).Content | ConvertFrom-Json | Select-Object -ExpandProperty tag_name"') do (
    set "CMAKE_VERSION=%%v"
)

:: Remove leading 'v'
set "CMAKE_VERSION_STRIPPED=%CMAKE_VERSION:v=%"

:: Build correct download URL
set "CMAKE_ZIP_URL=https://github.com/Kitware/CMake/releases/download/%CMAKE_VERSION%/cmake-%CMAKE_VERSION_STRIPPED%-windows-x86_64.zip"

:: Get file name from URL (sau khi URL đã có)
for /f %%f in ('powershell -Command "$url = '%CMAKE_ZIP_URL%'; Split-Path -Leaf $url"') do set "CMAKE_ZIP=%ROOT_DIR%\%%f"

:: Check if cmake is already available in PATH
where cmake >nul 2>nul
if %errorlevel% neq 0 (
    echo [!] CMake not found. Downloading latest version: %CMAKE_VERSION%
    echo === Downloading from: %CMAKE_ZIP_URL%
    powershell -Command "$url = '%CMAKE_ZIP_URL%'; $filename = Split-Path -Leaf $url; Invoke-WebRequest -Uri $url -OutFile (Join-Path '%ROOT_DIR%' $filename)" || (
        echo [!] Failed to download CMake!
        pause
        exit /b
    )

    echo === Extracting CMake ===
    mkdir "%CMAKE_DIR%" >nul 2>nul
    powershell -Command "Expand-Archive -Force '%CMAKE_ZIP%' '%CMAKE_DIR%'" || (
        echo [!] Failed to extract CMake!
        pause
        exit /b
    )

    for /d %%D in ("%CMAKE_DIR%\cmake-*") do (
        set "CMAKE_BIN=%%D\bin"
    )
    set "PATH=!CMAKE_BIN!;%PATH%"
    echo === CMake %CMAKE_VERSION% added to PATH ===
) else (
    echo === CMake is already available ===
)

:: ==== Check and install Ninja ====

:: Setup paths
set "NINJA_URL=https://github.com/ninja-build/ninja/releases/latest/download/ninja-win.zip"
for /f %%f in ('powershell -Command "$url = '%NINJA_URL%'; Split-Path -Leaf $url"') do set "NINJA_ZIP=%ROOT_DIR%\%%f"
set "NINJA_DIR=%ROOT_DIR%\ninja"
set "POWERSHELL_PATH=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"

:: Check if PowerShell exists
if not exist "%POWERSHELL_PATH%" (
    echo [!] PowerShell is missing. Cannot continue.
    pause
    exit /b
)

:: Check if Ninja is available
where ninja >nul 2>nul
if %errorlevel% neq 0 (
    echo [!] Ninja not found. Attempting to download and set up Ninja...
    echo === Downloading Ninja from: %NINJA_URL% ===

    powershell -Command "$url = '%NINJA_URL%'; $filename = Split-Path -Leaf $url; Invoke-WebRequest -Uri $url -OutFile (Join-Path '%ROOT_DIR%' $filename)" || (
        echo [!] Failed to download Ninja!
        pause
        exit /b
    )

if not exist "%NINJA_ZIP%" (
    echo [!] Ninja zip not downloaded correctly!
    pause
    exit /b
)

    echo === Extracting Ninja ===
    mkdir "%NINJA_DIR%" >nul 2>nul
    "%POWERSHELL_PATH%" -Command "Expand-Archive -Force '%NINJA_ZIP%' '%NINJA_DIR%'" || (
        echo [!] Failed to extract Ninja!
        pause
        exit /b
    )

    set "PATH=%NINJA_DIR%;%PATH%"
    echo === Ninja set up successfully and added to PATH ===
) else (
    echo === Ninja is already available ===
)

:: ==== Download and Extract Aseprite ====
echo === Locating correct Aseprite Source ZIP ===

:: Save the correct Aseprite zip URL to a temporary file
echo === Fetching Aseprite source ZIP URL from tag %ASEPRITE_VERSION% ===
powershell -Command "$tag='%ASEPRITE_VERSION%'; $r=Invoke-WebRequest -UseBasicParsing https://api.github.com/repos/aseprite/aseprite/releases/tags/$tag; $json=$r.Content | ConvertFrom-Json; $asset=$json.assets | Where-Object { $_.name -like 'Aseprite-*-Source.zip' } | Select-Object -First 1; if ($asset -ne $null) { $asset.browser_download_url } else { Write-Error 'Asset not found'; exit 1 }" > "%ROOT_DIR%\aseprite_zip_url.txt"

:: Check if PowerShell call failed
if %errorlevel% neq 0 (
    echo [!] PowerShell failed to get Aseprite source ZIP URL
    type "%ROOT_DIR%\aseprite_zip_url.txt"
    pause
    exit /b
)

:: Check if the file is non-empty
if not exist "%ROOT_DIR%\aseprite_zip_url.txt" (
    echo [!] aseprite_zip_url.txt not created!
    pause
    exit /b
)

set /p ASE_ZIP_URL=<"%ROOT_DIR%\aseprite_zip_url.txt"
if not defined ASE_ZIP_URL (
    echo [!] Failed to read URL from aseprite_zip_url.txt
    pause
    exit /b
)

echo === Aseprite ZIP URL: %ASE_ZIP_URL%

:: Validate the URL value
if not defined ASE_ZIP_URL (
    echo [!] Could not read Aseprite ZIP URL
    pause
    exit /b
)

echo === Aseprite ZIP URL: %ASE_ZIP_URL%

:: Extract ZIP file name from the URL
for /f %%f in ('powershell -Command "$url = '%ASE_ZIP_URL%'; Split-Path -Leaf $url"') do set "ASEPRITE_ZIP=%ROOT_DIR%\%%f"

:: Download Aseprite source ZIP
echo === Downloading from: %ASE_ZIP_URL%
powershell -Command "Invoke-WebRequest -Uri '%ASE_ZIP_URL%' -OutFile '%ASEPRITE_ZIP%'" || (
    echo [!] Error downloading Aseprite source ZIP
    pause
    exit /b
)

echo === Extracting Aseprite Source ===

:: Make sure the destination folder is empty (already cleaned earlier)
mkdir "%ASEPRITE_DIR%" >nul 2>nul

:: Extract directly into aseprite folder
powershell -Command "Expand-Archive -Force '%ASEPRITE_ZIP%' '%ASEPRITE_DIR%'" || (
    echo [!] Error extracting Aseprite!
    pause
    exit /b
)

:: ==== Fetch Skia URL from GitHub API ====
echo === Fetching Skia download URL from GitHub API ===

powershell -Command ^
"$r = Invoke-WebRequest -UseBasicParsing https://api.github.com/repos/aseprite/skia/releases/latest; ^
$json = $r.Content | ConvertFrom-Json; ^
$asset = $json.assets | Where-Object { $_.name -like $_.name -like '*x64*.zip' } | Select-Object -First 1; ^
if ($asset -ne $null) { $asset.browser_download_url } else { Write-Error 'Skia asset not found'; exit 1 }" ^
> "%ROOT_DIR%\skia_url.txt"

if %errorlevel% neq 0 (
    echo [!] Failed to get Skia download URL!
    type "%ROOT_DIR%\skia_url.txt"
    pause
    exit /b
)

set /p SKIA_ZIP_URL=<"%ROOT_DIR%\skia_url.txt"

if not defined SKIA_ZIP_URL (
    echo [!] Skia URL is empty!
    pause
    exit /b
)

echo === Skia ZIP URL: %SKIA_ZIP_URL%

:: ==== Extract filename from URL ====
for /f %%f in ('powershell -Command "$url = '%SKIA_ZIP_URL%'; Split-Path -Leaf $url"') do (
    set "SKIA_ZIP=%ROOT_DIR%\%%f"
)

:: ==== Download Skia only if not exists ====
if not exist "%SKIA_ZIP%" (
    echo === Downloading Skia from: %SKIA_ZIP_URL%

    powershell -Command ^
    "$url = '%SKIA_ZIP_URL%'; ^
    $filename = Split-Path -Leaf $url; ^
    Invoke-WebRequest -Uri $url -OutFile (Join-Path '%ROOT_DIR%' $filename)" || (
        echo [!] Error downloading Skia ZIP!
        pause
        exit /b
    )
) else (
    echo === Skia already exists, skipping download ===
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

:: ==== Check and auto-install Inno Setup (ISCC) if missing ====
set "INNO_EXE_URL=https://github.com/jrsoftware/issrc/releases/download/is-6_7_1/innosetup-6.7.1.exe"
set "INNO_EXE=%ROOT_DIR%\innosetup-6.7.1.exe"
set "INNO_DIR=%ROOT_DIR%\innosetup"

echo === Checking for Inno Setup (ISCC.exe) ===

:: Search for ISCC.exe in common possible paths
set "ISCC_PATH="
for %%F in (
    "%INNO_DIR%\ISCC.exe"
    "%INNO_DIR%\bin\ISCC.exe"
    "%INNO_DIR%\Output\ISCC.exe"
) do (
    if exist "%%~F" (
        set "ISCC_PATH=%%~F"
        goto found_iscc
    )
)

:: If not found, proceed to download and install
echo [!] ISCC.exe not found. Proceeding to download and install Inno Setup...

powershell -Command "Invoke-WebRequest -Uri '%INNO_EXE_URL%' -OutFile '%INNO_EXE%'" || (
    echo [!] Failed to download Inno Setup installer!
    pause
    exit /b
)

echo === Installing Inno Setup silently to: %INNO_DIR% ===
start "" /wait "%INNO_EXE%" /VERYSILENT /DIR="%INNO_DIR%"

:: Wait for ISCC.exe to appear (max 30 seconds)
echo === Waiting for ISCC.exe to appear ===
set /a wait_count=0
:wait_loop
for %%F in (
    "%INNO_DIR%\ISCC.exe"
    "%INNO_DIR%\bin\ISCC.exe"
    "%INNO_DIR%\Output\ISCC.exe"
) do (
    if exist "%%~F" (
        set "ISCC_PATH=%%~F"
        goto found_iscc
    )
)

set /a wait_count+=1
if !wait_count! gtr 30 (
    echo [!] ISCC.exe not found after waiting 30 seconds!
    pause
    exit /b
)
timeout /t 1 >nul
goto wait_loop

:found_iscc
echo === ISCC found at: !ISCC_PATH!

:: Extract folder from full path
for %%X in ("!ISCC_PATH!") do set "ISCC_DIR=%%~dpX"

set "PATH=!ISCC_DIR!;%PATH%"
echo === ISCC added to PATH ===

:: ==== Create setup file ====
echo === Creating installer ===
ISCC "%ISS_FILE%" || (
    echo [!] Error building installer!
    pause
    exit /b
)

echo.
echo === COMPLETED: %INSTALLER_DIR%\aseprite-setup-%ASEPRITE_VERSION%.exe ===

:: === Pause only when double-clicked (no args passed) ===
if "%~1"=="" (
    echo [i] Press any key to exit...
    pause >nul
)

endlocal