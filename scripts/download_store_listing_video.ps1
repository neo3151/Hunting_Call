$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ProjectRoot = Split-Path -Parent $ScriptDir
$OutputPath = Join-Path $ProjectRoot "play_store\store_listing_video.%(ext)s"
$Url = "https://www.youtube.com/watch?v=JaT8WPmC648"

Write-Host "[█████░░░░░] 50% | 0/1 done - Starting video download..."
yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" -o $OutputPath $Url
Write-Host "[██████████] 100% | 1/1 done - Video downloaded successfully to play_store directory!"
