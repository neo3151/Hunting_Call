$ErrorActionPreference = "Stop"

$workspaceRoot = "c:\Users\neo31\Hunting_Call"
$destDir = Join-Path $workspaceRoot "play_store\screenshots_dark"

Write-Host "Ensuring no previous app instances are running..."
Stop-Process -Name "hunting_calls_perfection" -Force -ErrorAction SilentlyContinue

Write-Host "`n[██░░░░░░░░] 20% | Creating output directories..."
if (!(Test-Path $destDir)) {
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
}

Write-Host "[██████░░░░] 60% | Running unified Python screenshot orchestrator..."
python .\scripts\auto_screenshot_runner.py

Write-Host "`n[██████████] 100% | Process complete! Screenshots saved to $destDir."
