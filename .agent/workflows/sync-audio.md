---
description: Synchronize local audio assets to Firebase Storage
---
Here is the command to sync your local audio files to the Cloud. This command only uploads new or modified files.

// turbo-all
```powershell
Write-Host "`n[██████░░░░] 50% | Starting Firebase Sync..."
gsutil rsync -r assets/audio gs://hunting-call-perfection.firebasestorage.app/audio/calls/
Write-Host "[██████████] 100% | Audio Sync Complete!`n"
```
