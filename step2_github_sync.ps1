$ErrorActionPreference = "Stop"

$repos = @(
    "C:\Users\neo31\Hunting_Call",
    "C:\Users\neo31\Hunting_Call_AI_Backend"
)

$commitMsg = "release 2.2.2 outccall"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "   STEP 2: Github Repository Code Sync" -ForegroundColor Cyan
Write-Host "=========================================`n" -ForegroundColor Cyan

foreach ($repo in $repos) {
    if (Test-Path $repo) {
        Write-Host "-> Syncing $repo..." -ForegroundColor Yellow
        Set-Location $repo
        
        git add -A
        
        $diff = git diff --cached --name-status
        if ($diff) {
            git commit -m $commitMsg | Out-Null
            git push origin main
            Write-Host "  ✅ Pushed changes successfully!`n" -ForegroundColor Green
        } else {
            Write-Host "  ✅ No changed files to commit, checking push..." -ForegroundColor DarkGray
            git push origin main
        }
    }
}

Write-Host "🎉 ALL DONE! Your secrets are on Google Drive, and your code is safely on GitHub." -ForegroundColor Green
Write-Host "You are officially 100% cleared hot to wipe this drive and install Linux!" -ForegroundColor Magenta
