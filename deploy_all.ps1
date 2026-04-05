$PushLocation = Get-Location

Write-Host "`n[██████░░░░] 33% | Synchronizing updated audio to Firebase Storage..."
gsutil rsync -r assets/audio gs://hunting-call-perfection.firebasestorage.app/audio/calls/

Write-Host "`n[████████░░] 66% | Committing changes to GitHub..."
.\auto_sync.ps1

Write-Host "`n[██████████] 100% | Launching App Environment Servers..."
# auto_sync.ps1 changes the directory, so we bounce back to the root before the final step
Set-Location $PushLocation
.\full_setup.ps1
