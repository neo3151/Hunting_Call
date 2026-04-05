$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "   CRITICAL PRE-LINUX SECRETS BACKUP" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "IMPORTANT: Your auto_sync script beautifully backs up all your code to GitHub."
Write-Host "HOWEVER, your `.gitignore` is EXCLUDING your signing keys and API secrets!"
Write-Host "If you wipe this drive without backing them up, you will PERMANENTLY LOSE the ability to update Hunting Call on the Play Store!`n" -ForegroundColor Red

$backupZip = "C:\Users\neo31\HuntingCall_SECRETS_BACKUP.zip"
if (Test-Path $backupZip) { Remove-Item $backupZip }

$filesToBackup = @(
    "android\upload-keystore.jks",
    "android\key.properties",
    "android\local.properties",
    "google-services.json",
    "credentials.json",
    "token.json",
    ".env",
    "scripts\service-account.json",
    "scripts\play-store-key.json",
    "scripts\gdrive_credentials.json",
    "scripts\gdrive_token.json",
    "scripts\gmail_token.json",
    "scripts\play_token.json"
)

# Also capture any client_secrets in android
$clientSecrets = Get-ChildItem -Path "android" -Filter "client_secret_*.json" -ErrorAction SilentlyContinue

$archiveItems = @()
foreach ($file in $filesToBackup) {
    if (Test-Path $file) {
        $archiveItems += $file
        Write-Host "  [FOUND] $file" -ForegroundColor Green
    } else {
        Write-Host "  [SKIPPED] $file (Not found)" -ForegroundColor DarkGray
    }
}

foreach ($secret in $clientSecrets) {
    $archiveItems += $secret.FullName
    Write-Host "  [FOUND] $($secret.Name)" -ForegroundColor Green
}

if ($archiveItems.Count -gt 0) {
    Compress-Archive -Path $archiveItems -DestinationPath $backupZip -Force
    Write-Host "`n[SUCCESS] Secured your unversioned keys into a ZIP file!" -ForegroundColor Green
    Write-Host "-> $backupZip" -ForegroundColor Yellow
    Write-Host "CRITICAL: Upload this ZIP to Google Drive or drag it onto a USB thumbstick BEFORE installing Linux!`n" -ForegroundColor Red
} else {
    Write-Host "No files found to backup."
}
