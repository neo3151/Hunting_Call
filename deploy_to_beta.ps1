$ErrorActionPreference = "Stop"

Write-Host "`n[██████████] Phase 1/2: Building Release AAB..." -ForegroundColor Magenta
.\scripts\build_app_windows.ps1

Write-Host "`n[██████████] Phase 2/2: Using CLI Play Console Publisher..." -ForegroundColor Magenta

$aabPath = "build\app\outputs\bundle\release\app-release.aab"
$keyPath = "scripts\service-account.json"
$releaseName = "Serverless AI Coaching & Animal Library Updates"
$releaseNotes = "- Serverless Upgrades: The ML bird identification and Gemini AI Coaching now run blazing-fast directly on your device, no cloud backend required!`n- App Optimization: Call logic was patched to correctly sync visual progress meters to audio.`n- Library Curation: Added missing Cougar and new Great Horned Owl tracks, and removed dropped wildlife entries."

if (-Not (Test-Path $aabPath)) {
    Write-Host "[ERROR] Could not find built AAB at $aabPath" -ForegroundColor Red
    exit 1
}

Write-Host "Invoking upload_to_play_store.py..." -ForegroundColor Cyan
python scripts\upload_to_play_store.py --track beta --aab $aabPath --key $keyPath --name $releaseName --notes $releaseNotes

Write-Host "`n[██████████] Done! Beta release 2.2.2 successfully distributed CLI bounds.`n" -ForegroundColor Green
