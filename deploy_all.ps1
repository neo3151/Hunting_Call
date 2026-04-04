Write-Host "`n[██████░░░░] 33% | Synchronizing updated audio to Firebase Storage..."
gsutil rsync -r assets/audio gs://hunting-call-perfection.firebasestorage.app/audio/calls/

Write-Host "`n[████████░░] 66% | Committing changes to GitHub..."
.\auto_sync.ps1

Write-Host "`n[██████████] 100% | Launching App Environment Servers..."
.\full_setup.ps1
