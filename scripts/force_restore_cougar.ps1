$ErrorActionPreference = "SilentlyContinue"
Write-Host "Attempting native Git history restore..." -ForegroundColor Cyan

# The commit we identified earlier where it was last touched (likely deleted)
$commit = "258652a4372343702e139d49bcc91b5cd5164dfa"

# Method 1: Tilde syntax avoids the Windows CMD caret (^) escape bug
git checkout "$commit~1" -- assets/audio/cougar_scream.mp3 2>$null

if (Test-Path "assets/audio/cougar_scream.mp3") {
    Write-Host "`n[+] SUCCESS! File 'cougar_scream.mp3' cleanly recovered from git history." -ForegroundColor Green
} else {
    Write-Host "`n[-] Standard checkout failed. Commencing deep-dive into orphan Git object blobs..." -ForegroundColor Yellow
    
    # Method 2: Extract directly from the raw Git internal blob storage
    $rawLine = git rev-list --all --objects | Select-String "cougar_scream.mp3" | Select-Object -First 1
    
    if ($rawLine) {
        # The line looks like: "ae837... cougar_scream.mp3"
        $blobHash = ($rawLine -split ' ')[0]
        Write-Host "[!] Found raw blob hash: $blobHash" -ForegroundColor Cyan
        Write-Host "[!] Ripping audio file from internal git storage..." -ForegroundColor Cyan
        
        git show $blobHash > assets/audio/cougar_scream.mp3
        
        if ((Get-Item "assets/audio/cougar_scream.mp3").Length -gt 100) {
            Write-Host "`n[+] SUCCESS! Hard-extracted the audio from git blob storage." -ForegroundColor Green
        } else {
            Write-Host "`n[-] Blob extraction resulted in an empty or corrupted file." -ForegroundColor Red
        }
    } else {
        Write-Host "`n[FATAL] The file cougar_scream.mp3 is completely wiped from all local Git history." -ForegroundColor Red
        Write-Host "This usually means it was never committed in the first place, or you'll need to pull it from your cloud backup."
    }
}
