$ErrorActionPreference = "Stop"

Write-Host "`n[██░░░░░░░░] 20% | 1/5 done: Starting Flutter APK Build (arm64)..." -ForegroundColor Cyan
Write-Host "This will build a debug APK as per your workflows."
flutter build apk --debug --split-per-abi --target-platform android-arm64

$sourceApk = "build\app\outputs\flutter-apk\app-arm64-v8a-debug.apk"
if (-Not (Test-Path $sourceApk)) {
    Write-Host "`n[ERROR] Could not find built APK at $sourceApk. Check the build logs." -ForegroundColor Red
    exit 1
}

Write-Host "`n[████░░░░░░] 40% | 2/5 done: Flutter build completed." -ForegroundColor Cyan

$dateStamp = Get-Date -Format 'yyyyMMdd_HHmm'
$devApkName = "HuntingCall_Dev_arm64_$dateStamp.apk"
$destApk = "build\app\outputs\flutter-apk\$devApkName"
Rename-Item -Path $sourceApk -NewName $devApkName -Force

Write-Host "`n[██████░░░░] 60% | 3/5 done: Renamed APK to $devApkName" -ForegroundColor Cyan
Write-Host "`n[████████░░] 80% | 4/5 done: Uploading to Google Drive..." -ForegroundColor Cyan

# Approach A: We use your designated rclone workflow for "gdrive:OUTCALL/..." 
# Note: assuming 'gdrive' maps to your pongownsyou@gmail.com account!
$rcloneRemote = "gdrive:OUTCALL/dev-builds/$devApkName"
Write-Host "Executing: rclone copyto `"$destApk`" `"$rcloneRemote`" ..."

try {
    rclone copyto $destApk $rcloneRemote --progress --drive-chunk-size 64M --no-check-dest --stats 5s
} catch {
    Write-Host "`n[WARNING] rclone upload failed or not configured. Falling back to upload_to_drive.py..." -ForegroundColor Yellow
    # Approach B: Fallback to your recently moved python script using local credentials (will prompt browser login to pongownsyou@gmail.com if token is invalid)
    if (Test-Path "credentials.json") {
        python scripts\upload_to_drive.py $destApk credentials.json
    } else {
        Write-Host "No credentials.json found to use python script fallback! Please ensure your rclone 'gdrive' remote is configured to pongownsyou@gmail.com" -ForegroundColor Red
    }
}

Write-Host "`n[██████████] 100% | 5/5 done: Dev APK Built & Uploaded Successfully!" -ForegroundColor Green
Write-Host "You can find your local file at: $destApk"
