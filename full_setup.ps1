Write-Host "[██░░░░░░░░] 20% | 1/5 Starting AI Backend..."
Set-Location "C:\Users\neo31\Hunting_Call_AI_Backend"
.\manage-backend.ps1 start

Write-Host "[████░░░░░░] 40% | 2/5 Starting Mailstorm web & Once Upon a Day..."
Start-Process -FilePath "npm.cmd" -ArgumentList "run dev" -WorkingDirectory "C:\Users\neo31\Mailstorm\web" -WindowStyle Minimized
Start-Process -FilePath "firebase.cmd" -ArgumentList "serve" -WorkingDirectory "C:\Users\neo31\Playground\once-upon-a-day" -WindowStyle Minimized

Write-Host "[██████░░░░] 60% | 3/5 Building Hunting Call Dev APK..."
Set-Location "C:\Users\neo31\Hunting_Call"
flutter build apk --debug --split-per-abi --target-platform android-arm64

Write-Host "[████████░░] 80% | 4/5 Renaming APK..."
$apkPath = "build\app\outputs\flutter-apk\app-arm64-v8a-debug.apk"
$newName = "HuntingCall-Dev-v2.1.0_102.apk"
$newPath = "build\app\outputs\flutter-apk\$newName"
if (Test-Path $apkPath) {
    Copy-Item $apkPath $newPath -Force
    Write-Host "Renamed to $newName"
} else {
    Write-Error "Failed to find built APK at $apkPath"
    exit 1
}

Write-Host "[██████████] 100% | 5/5 Uploading to GDrive..."
rclone copyto $newPath "gdrive:OUTCALL/dev-builds/$newName" --progress --drive-chunk-size 64M --no-check-dest --stats 5s

Write-Host "All tasks completed successfully!"
