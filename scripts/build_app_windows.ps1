$ErrorActionPreference = "Stop"

Write-Host "[██░░░░░░░░] 20% | 1/5 Cleaning project..."
flutter clean

Write-Host "[████░░░░░░] 40% | 2/5 Getting dependencies..."
flutter pub get

Write-Host "[██████░░░░] 60% | 3/5 Building Android App Bundle (AAB) with Obfuscation..."
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols

Write-Host "[████████░░] 80% | 4/5 Packaging Debug Symbols..."
# Zip Dart symbols
$dartSymbolsDir = "build/app/outputs/symbols"
$dartZip = "build/app/outputs/dart-debug-symbols.zip"
if (Test-Path $dartZip) { Remove-Item $dartZip }
if (Test-Path $dartSymbolsDir) {
    Compress-Archive -Path "$dartSymbolsDir\*" -DestinationPath $dartZip -Force
}

# Zip Native symbols if they exist
$nativeSymbolsDir = "build\app\intermediates\merged_native_libs\release\mergeReleaseNativeLibs\out\lib"
$nativeZip = "build\app\outputs\native-debug-symbols.zip"
if (Test-Path $nativeZip) { Remove-Item $nativeZip }
if (Test-Path $nativeSymbolsDir) {
    Compress-Archive -Path "$nativeSymbolsDir\*" -DestinationPath $nativeZip -Force
}

Write-Host "[██████████] 100% | 5/5 Build Complete!"
Write-Host "Android AAB: build\app\outputs\bundle\release\app-release.aab"
Write-Host "Native Symbols: $nativeZip"
Write-Host "Dart Symbols: $dartZip"
