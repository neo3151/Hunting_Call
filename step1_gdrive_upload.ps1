$ErrorActionPreference = "Stop"

Write-Host "`n[████░░░░░░] Step 1/3: Staging your workspace (excluding massive build caches)..." -ForegroundColor Cyan

$tempDir = "C:\Users\neo31\WorkspaceStaging"
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
New-Item -ItemType Directory -Path $tempDir | Out-Null

# Robocopy perfectly copies all hidden files/secrets, but we tell it to exclude LITERALLY ONLY 
# the auto-generated SDK/build caches so your computer doesn't crash trying to zip 10GB of junk.
robocopy "C:\Users\neo31\Hunting_Call" "$tempDir\Hunting_Call" /E /XD "build" ".dart_tool" "android\.gradle" "linux" "macos" "windows" "ios\Pods" /NFL /NDL /NJH /NJS /nc /ns /np
robocopy "C:\Users\neo31\Hunting_Call_AI_Backend" "$tempDir\Hunting_Call_AI_Backend" /E /NFL /NDL /NJH /NJS /nc /ns /np

Write-Host "`n[████████░░] Step 2/3: Zipping absolutely LITERALLY EVERYTHING into one file..." -ForegroundColor Cyan
$zPath = "C:\Users\neo31\Hunting_Call\workspace_cleanup.zip"
if (Test-Path $zPath) { Remove-Item $zPath -Force }

Compress-Archive -Path "$tempDir\*" -DestinationPath $zPath -Force

Write-Host "`n[██████████] Step 3/3: Uploading ZIP to Google Drive..." -ForegroundColor Cyan
# Execute your python script
cd C:\Users\neo31\Hunting_Call
python scripts\upload_workspace.py

# Cleanup temp staging
Remove-Item $tempDir -Recurse -Force

Write-Host "`n✅ Master Google Drive Backup Complete!" -ForegroundColor Green
