# ============================================
# Hunting Calls Perfection - Windows Build Script (PowerShell)
# ============================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " HUNTING CALLS PERFECTION" -ForegroundColor Cyan
Write-Host " Windows Build Script (PowerShell)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Check if Flutter is installed
$flutterPath = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterPath) {
    Write-Host "[ERROR] Flutter is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Flutter from: https://docs.flutter.dev/get-started/install/windows" -ForegroundColor Yellow
    Read-Host "`nPress Enter to exit"
    exit 1
}

Write-Host "[1/7] Checking Flutter installation..." -ForegroundColor Green
flutter --version
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Flutter command failed" -ForegroundColor Red
    Read-Host "`nPress Enter to exit"
    exit 1
}
Write-Host "[OK] Flutter found`n" -ForegroundColor Green

Write-Host "[2/7] Running Flutter Doctor..." -ForegroundColor Green
flutter doctor
Write-Host ""

Write-Host "[3/7] Enabling Windows desktop support..." -ForegroundColor Green
flutter config --enable-windows-desktop
Write-Host "[OK] Windows support enabled`n" -ForegroundColor Green

Write-Host "[4/7] Cleaning previous builds..." -ForegroundColor Green
flutter clean
Write-Host "[OK] Clean complete`n" -ForegroundColor Green

Write-Host "[5/7] Getting dependencies..." -ForegroundColor Green
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to get dependencies" -ForegroundColor Red
    Read-Host "`nPress Enter to exit"
    exit 1
}
Write-Host "[OK] Dependencies installed`n" -ForegroundColor Green

Write-Host "[6/7] Generating code (JSON serialization)..." -ForegroundColor Green
flutter pub run build_runner build --delete-conflicting-outputs
if ($LASTEXITCODE -ne 0) {
    Write-Host "[WARNING] Code generation had issues, continuing anyway..." -ForegroundColor Yellow
}
Write-Host "[OK] Code generation complete`n" -ForegroundColor Green

Write-Host "[7/7] Building Windows Release..." -ForegroundColor Green
Write-Host "This may take several minutes...`n" -ForegroundColor Yellow
flutter build windows --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[ERROR] Build failed!" -ForegroundColor Red
    Write-Host "`nCommon issues:" -ForegroundColor Yellow
    Write-Host "- Visual Studio not installed or C++ tools missing" -ForegroundColor Yellow
    Write-Host "- Run: flutter doctor -v to see detailed requirements`n" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host " BUILD SUCCESSFUL!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

$releasePath = "build\windows\x64\runner\Release"
Write-Host "Your application has been built!" -ForegroundColor Cyan
Write-Host "`nLocation: $releasePath`n" -ForegroundColor Cyan

if (Test-Path $releasePath) {
    Write-Host "Files created:" -ForegroundColor Cyan
    Get-ChildItem $releasePath | Select-Object Name, Length | Format-Table -AutoSize
    
    Write-Host "`nMain executable: hunting_calls_perfection.exe" -ForegroundColor Green
    Write-Host "`nTo run the app, navigate to the Release folder and run:" -ForegroundColor Yellow
    Write-Host "  .\hunting_calls_perfection.exe" -ForegroundColor White
    Write-Host "`nTo create a distributable package:" -ForegroundColor Yellow
    Write-Host "  Copy the entire Release folder with all DLLs and data folder" -ForegroundColor White
}

Read-Host "`nPress Enter to exit"
