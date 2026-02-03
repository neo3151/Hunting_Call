@echo off
REM ============================================
REM Hunting Calls Perfection - Windows Build Script
REM ============================================

echo.
echo ========================================
echo  HUNTING CALLS PERFECTION
echo  Windows Build Script
echo ========================================
echo.

REM Check if Flutter is installed
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Flutter is not installed or not in PATH
    echo Please install Flutter from: https://docs.flutter.dev/get-started/install/windows
    echo.
    pause
    exit /b 1
)

echo [1/7] Checking Flutter installation...
flutter --version
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Flutter command failed
    pause
    exit /b 1
)
echo [OK] Flutter found
echo.

echo [2/7] Running Flutter Doctor...
flutter doctor
echo.

echo [3/7] Enabling Windows desktop support...
flutter config --enable-windows-desktop
echo [OK] Windows support enabled
echo.

echo [4/7] Cleaning previous builds...
flutter clean
echo [OK] Clean complete
echo.

echo [5/7] Getting dependencies...
flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to get dependencies
    pause
    exit /b 1
)
echo [OK] Dependencies installed
echo.

echo [6/7] Generating code (JSON serialization)...
flutter pub run build_runner build --delete-conflicting-outputs
if %ERRORLEVEL% NEQ 0 (
    echo [WARNING] Code generation had issues, continuing anyway...
)
echo [OK] Code generation complete
echo.

echo [7/7] Building Windows Release...
echo This may take several minutes...
flutter build windows --release
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Build failed!
    echo.
    echo Common issues:
    echo - Visual Studio not installed or C++ tools missing
    echo - Run: flutter doctor -v to see detailed requirements
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo  BUILD SUCCESSFUL!
echo ========================================
echo.
echo Your application has been built!
echo.
echo Location: build\windows\x64\runner\Release\
echo.
echo Files created:
dir /b build\windows\x64\runner\Release\
echo.
echo Main executable: hunting_calls_perfection.exe
echo.
echo To run the app, navigate to the Release folder and run:
echo   hunting_calls_perfection.exe
echo.
echo To create a distributable package, copy the entire Release folder.
echo All DLL files and data folder are required.
echo.
pause
