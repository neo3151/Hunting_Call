# Get SHA-1 Fingerprint Script
# This script finds keytool and extracts the SHA-1 fingerprint

Write-Host "Looking for keytool..." -ForegroundColor Cyan

# Try to find keytool in common locations
$keytoolPaths = @(
    "C:\Program Files\Java\*\bin\keytool.exe",
    "C:\Program Files (x86)\Java\*\bin\keytool.exe",
    "$env:JAVA_HOME\bin\keytool.exe",
    "$env:LOCALAPPDATA\Android\Sdk\*\bin\keytool.exe"
)

$keytool = $null
foreach ($path in $keytoolPaths) {
    $found = Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        $keytool = $found.FullName
        break
    }
}

if (-not $keytool) {
    Write-Host "ERROR: Could not find keytool.exe" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Java JDK or Android Studio" -ForegroundColor Yellow
    Write-Host "Or manually run this command if you know where keytool is:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host '& "C:\Path\To\keytool.exe" -list -v -keystore $env:USERPROFILE\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android' -ForegroundColor White
    exit 1
}

Write-Host "Found keytool at: $keytool" -ForegroundColor Green
Write-Host ""

# Check if debug keystore exists
$keystorePath = "$env:USERPROFILE\.android\debug.keystore"
if (-not (Test-Path $keystorePath)) {
    Write-Host "ERROR: Debug keystore not found at: $keystorePath" -ForegroundColor Red
    Write-Host "Run a Flutter app in debug mode first to generate it" -ForegroundColor Yellow
    exit 1
}

Write-Host "Getting SHA-1 fingerprint..." -ForegroundColor Cyan
Write-Host ""

# Run keytool and extract SHA-1
$output = & $keytool -list -v -keystore $keystorePath -alias androiddebugkey -storepass android -keypass android 2>&1

$sha1 = $output | Select-String -Pattern "SHA1:\s*(.+)" | ForEach-Object { $_.Matches.Groups[1].Value }
$sha256 = $output | Select-String -Pattern "SHA256:\s*(.+)" | ForEach-Object { $_.Matches.Groups[1].Value }

if ($sha1) {
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "SHA-1 Fingerprint (for Firebase):" -ForegroundColor Green
    Write-Host $sha1 -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    
    if ($sha256) {
        Write-Host "SHA-256 Fingerprint:" -ForegroundColor Cyan
        Write-Host $sha256 -ForegroundColor White
        Write-Host ""
    }
    
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Copy the SHA-1 value above" -ForegroundColor White
    Write-Host "2. Go to Firebase Console: https://console.firebase.google.com/" -ForegroundColor White
    Write-Host "3. Select project: hunting-call-perfection" -ForegroundColor White
    Write-Host "4. Project Settings > Your apps > Add fingerprint" -ForegroundColor White
    Write-Host "5. Paste the SHA-1 and save" -ForegroundColor White
    Write-Host "6. Download the updated google-services.json" -ForegroundColor White
} else {
    Write-Host "ERROR: Could not extract SHA-1 from keytool output" -ForegroundColor Red
    Write-Host ""
    Write-Host "Full output:" -ForegroundColor Yellow
    Write-Host $output
}
