$targetDirs = @("C:\Users\neo31", "C:\Users\neo31\Playground")
$repos = @()

foreach ($dir in $targetDirs) {
    if (Test-Path $dir) {
        $subDirs = Get-ChildItem -Path $dir -Directory
        foreach ($subDir in $subDirs) {
            $gitPath = Join-Path -Path $subDir.FullName -ChildPath ".git"
            if (Test-Path $gitPath) {
                # Ensure no duplicates
                if ($repos -notcontains $subDir.FullName) {
                    $repos += $subDir.FullName
                }
            }
        }
    }
}

$total = $repos.Count
$count = 0
$timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

Write-Host "Found $total repositories to synchronize."

foreach ($repo in $repos) {
    $count++
    $percent = [math]::Round(($count / $total) * 100)
    $bars = [math]::Round($percent / 10)
    $barStr = ("█" * $bars) + ("░" * (10 - $bars))
    
    Write-Host "[$barStr] $percent% | $count/$total done | Syncing $(Split-Path $repo -Leaf)"
    
    Set-Location $repo
    git add -A 2>$null
    
    $diff = git diff --cached --name-status
    if ($diff) {
        $filesChanged = $diff | Out-String
        $fullMsg = "chore: auto-sync $timestamp`n`nChanged Files:`n$filesChanged"
        git commit -m $fullMsg | Out-Null
        git push | Out-Null
        Write-Host "  -> Pushed new changes"
    } else {
        Write-Host "  -> No new changes"
        # Always try a push anyway in case there were unpushed local commits
        $pushResult = git push 2>&1
    }
}
Write-Host "[██████████] 100% | All repositories synchronized!"
