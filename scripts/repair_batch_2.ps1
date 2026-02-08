
$mappings = @{
    "caribou"           = "https://xeno-canto.org/984365/download"
    "wolf_bark"         = "https://xeno-canto.org/1074173/download"
    "elk_cow_mew"       = "https://xeno-canto.org/971966/download"
    "black_bear_bawl"   = "https://fromnoisetosound.com/wp-content/uploads/2021/08/large-black-bear-constant-growling-and-roaring-mix-2.mp3"
    "pronghorn"         = "https://xeno-canto.org/106577/download" # Alternate XC link found
    "cougar"            = "https://soundbible.com/grab.php?id=1258&type=mp3" # Verified accessible
    "bobcat_growl"      = "https://fromnoisetosound.com/wp-content/uploads/2021/08/bobcat-growl-1.mp3"
    "badger"            = "https://mingosounds.com/wp-content/uploads/2021/08/badger-growling-sound.mp3"
    "deer_snort_wheeze" = "https://www.hmeproducts.com/wp-content/uploads/sounds/023-Buck%20Snort%20Wheeze.mp3"
}

$tempDir = "temp_audio_repair"
if (!(Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir }
$audioDir = "assets/audio"

foreach ($id in $mappings.Keys) {
    $url = $mappings[$id]
    $tempFile = "$tempDir/$id.mp3"
    $targetFile = "$audioDir/$id.wav"

    Write-Host "Repairing $id..."
    try {
        Invoke-WebRequest -Uri $url -OutFile $tempFile -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36" -ErrorAction Stop
    }
    catch {
        Write-Warning "Failed to download ${id}: $($_.Exception.Message)"
        continue
    }

    Write-Host "Normalizing $id..."
    & ffmpeg.exe -y -i $tempFile -af "loudnorm=I=-16:TP=-1.5:LRA=11" -ac 1 -ar 44100 $targetFile 2>$null
    
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Failed to normalize $id"
    }
}

Remove-Item -Recurse -Force $tempDir
Write-Host "Repair Batch Complete."
