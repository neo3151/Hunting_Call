
$mappings = @{
    # Waterfowl
    "duck_mallard_greeting" = "https://xeno-canto.org/1015694/download"
    "wood_duck" = "https://xeno-canto.org/679723/download"
    "wood_duck_sit" = "https://xeno-canto.org/855694/download"
    "goose_cluck" = "https://xeno-canto.org/994513/download"
    "teal" = "https://xeno-canto.org/795949/download"
    "canvasback" = "https://xeno-canto.org/371522/download"
    "pintail" = "https://xeno-canto.org/1045871/download"
    "mallard_hen" = "https://xeno-canto.org/982820/download"

    # Big Game
    "elk_cow_mew" = "https://www.nps.gov/nps-audiovideo/legacy/mp3/imr/avElement/yell-yell_MJ17201103.mp3"
    "deer_buck_grunt" = "https://xeno-canto.org/975498/download"
    "deer_doe_bleat" = "https://xeno-canto.org/975497/download"
    "mule_deer" = "https://xeno-canto.org/961772/download"
    "fallow" = "https://xeno-canto.org/960555/download"
    "pronghorn" = "https://cdn.download.macaulaylibrary.org/api/v1/asset/106577/raw"
    "red_stag_roar" = "https://xeno-canto.org/1071974/download"
    "caribou" = "https://www.adfg.alaska.gov/static/archive/news/pdfs/sounds/sw_woodland_caribou.mp3"
    "hog_grunt" = "https://xeno-canto.org/992312/download"
    "moose_cow_call" = "https://xeno-canto.org/960771/download"
    "moose_grunt" = "https://xeno-canto.org/960770/download"
    "black_bear_bawl" = "https://cdn.download.macaulaylibrary.org/api/v1/asset/55302/raw"

    # Predators
    "cougar" = "https://cdn.download.macaulaylibrary.org/api/v1/asset/110769/raw"
    "fox_scream" = "https://www.nps.gov/nps-audiovideo/legacy/mp3/imr/avElement/yell-YELLMJ23200837redfox.mp3"
    "gray_fox_bark" = "https://xeno-canto.org/1046109/download"
    "coyote_challenge" = "https://xeno-canto.org/1070760/download"
    "bobcat_growl" = "https://cdn.download.macaulaylibrary.org/api/v1/asset/176488/raw"
    "raccoon_squall" = "https://xeno-canto.org/961783/download"
    "wolf_bark" = "https://www.nps.gov/nps-audiovideo/legacy/mp3/imr/avElement/yell-0108wolf_yell.mp3"
    "rabbit_distress" = "https://xeno-canto.org/837134/download"
    "badger" = "https://cdn.download.macaulaylibrary.org/api/v1/asset/55300/raw"

    # Land Birds
    "turkey_gobble" = "https://xeno-canto.org/1019836/download"
    "turkey_purr" = "https://xeno-canto.org/1019832/download"
    "turkey_tree" = "https://xeno-canto.org/680182/download"
    "crow" = "https://xeno-canto.org/1058578/download"
    "crow_fight" = "https://xeno-canto.org/1058578/download"
    "quail" = "https://xeno-canto.org/778483/download"
    "pheasant" = "https://xeno-canto.org/1063697/download"
    "woodcock" = "https://xeno-canto.org/906713/download"
    "dove" = "https://xeno-canto.org/691623/download"
    "gho" = "https://xeno-canto.org/1077982/download"
    "grouse" = "https://www.nps.gov/nps-audiovideo/legacy/mp3/imr/avElement/yell-RuffedGrouse.mp3"
}

$tempDir = "temp_audio"
if (!(Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir }
$audioDir = "assets/audio"

foreach ($id in $mappings.Keys) {
    $url = $mappings[$id]
    $tempFile = "$tempDir/$id.mp3"
    $targetFile = "$audioDir/$id.wav"

    Write-Host "Downloading $id..."
    try {
        Invoke-WebRequest -Uri $url -OutFile $tempFile -UserAgent "Mozilla/5.0" -ErrorAction Stop
    } catch {
        Write-Warning "Failed to download ${id}: $($_.Exception.Message)"
        continue
    }

    Write-Host "Normalizing $id..."
    & ffmpeg.exe -y -i $tempFile -af "loudnorm=I=-16:TP=-1.5:LRA=11" -ac 1 -ar 44100 $targetFile 2>$null
    
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Failed to normalize $id"
    }
}

Write-Host "Cleaning up..."
Remove-Item -Recurse -Force $tempDir
Write-Host "Batch 2 Complete."
