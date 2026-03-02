#!/usr/bin/env python3
import os
import subprocess
import urllib.request
import urllib.error
import shutil
import time

# Mappings from ID to URL
# Combined from download_batch_2.ps1 and repair_batch_2.ps1
# Repaired versions take precedence
MAPPING = {
    # Waterfowl
    "duck_mallard_greeting": "https://xeno-canto.org/1015694/download",
    "wood_duck": "https://xeno-canto.org/679723/download",
    "wood_duck_sit": "https://xeno-canto.org/855694/download",
    "goose_cluck": "https://xeno-canto.org/994513/download",
    "teal": "https://xeno-canto.org/795949/download",
    "canvasback": "https://xeno-canto.org/371522/download",
    "pintail": "https://xeno-canto.org/1045871/download",
    "mallard_hen": "https://xeno-canto.org/982820/download",

    # Big Game
    "elk_cow_mew": "https://xeno-canto.org/971966/download",
    "deer_buck_grunt": "https://xeno-canto.org/975498/download",
    "deer_doe_bleat": "https://xeno-canto.org/975497/download",
    "mule_deer": "https://xeno-canto.org/961772/download",
    "fallow": "https://xeno-canto.org/960555/download",
    "pronghorn": "https://www.nps.gov/nps-audiovideo/legacy/mp3/imr/avElement/yell-yell_MJ17201103.mp3", # NPS link
    "red_stag_roar": "https://xeno-canto.org/1071974/download",
    "caribou": "https://xeno-canto.org/984365/download",
    "hog_grunt": "https://xeno-canto.org/992312/download",
    "moose_cow_call": "https://xeno-canto.org/960771/download",
    "moose_grunt": "https://xeno-canto.org/960770/download",
    "black_bear_bawl": "https://acousticatlas.org/item/29729/download", # Acoustic Atlas
    "deer_snort_wheeze": "https://www.sigmaoutdoors.com/wp-content/uploads/2016/10/Whitetail-Buck-Snort.mp3", # Sigma Outdoors

    # Predators
    "cougar": "https://soundbible.com/grab.php?id=1258&type=mp3",
    "fox_scream": "https://www.nps.gov/nps-audiovideo/legacy/mp3/imr/avElement/yell-YELLMJ23200837redfox.mp3",
    "gray_fox_bark": "https://xeno-canto.org/1046109/download",
    "coyote_challenge": "https://xeno-canto.org/1070760/download",
    "bobcat_growl": "https://memes.co.in/animal-sounds/bobcat-growls.mp3", # Alternative
    "raccoon_squall": "https://xeno-canto.org/961783/download",
    "wolf_bark": "https://xeno-canto.org/1074173/download",
    "rabbit_distress": "https://xeno-canto.org/837134/download",
    "badger": "https://soundbible.com/grab.php?id=1033&type=mp3", # SoundBible alternative

    # Land Birds
    "turkey_gobble": "https://xeno-canto.org/1019836/download",
    "turkey_purr": "https://xeno-canto.org/1019832/download",
    "turkey_tree": "https://xeno-canto.org/680182/download",
    "crow": "https://xeno-canto.org/1058578/download",
    "crow_fight": "https://xeno-canto.org/1058578/download",
    "quail": "https://xeno-canto.org/778483/download",
    "pheasant": "https://xeno-canto.org/1063697/download",
    "woodcock": "https://xeno-canto.org/906713/download",
    "dove": "https://xeno-canto.org/691623/download",
    "gho": "https://xeno-canto.org/1077982/download",
    "grouse": "https://www.nps.gov/nps-audiovideo/legacy/mp3/imr/avElement/yell-RuffedGrouse.mp3",
}

TEMP_DIR = "temp_audio_dl"
AUDIO_DIR = "assets/audio"

def ensure_dir(path):
    if not os.path.exists(path):
        os.makedirs(path)

def download_file(url, filepath):
    headers = {
        "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Accept": "*/*"
    }
    retries = 3
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, headers=headers)
            with urllib.request.urlopen(req, timeout=30) as response, open(filepath, 'wb') as out_file:
                while True:
                    chunk = response.read(8192)
                    if not chunk:
                        break
                    out_file.write(chunk)
            return True
        except Exception as e:
            print(f"  (Attempt {attempt+1}/{retries}) Error downloading {url}: {e}")
            if attempt < retries - 1:
                time.sleep(1)
    return False

def normalize_audio(input_path, output_path):
    # ffmpeg command to normalize audio
    # loudnorm=I=-16:TP=-1.5:LRA=11
    cmd = [
        "ffmpeg", "-y", "-i", input_path,
        "-af", "loudnorm=I=-16:TP=-1.5:LRA=11",
        "-ac", "1", "-ar", "44100",
        output_path
    ]
    try:
        subprocess.run(cmd, check=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE)
        return True
    except subprocess.CalledProcessError as e:
        print(f"FFmpeg error for {input_path}: {e.stderr.decode()}")
        return False

def main():
    ensure_dir(TEMP_DIR)
    ensure_dir(AUDIO_DIR)

    for key, url in MAPPING.items():
        temp_file = os.path.join(TEMP_DIR, f"{key}.mp3")
        target_file = os.path.join(AUDIO_DIR, f"{key}.wav")

        print(f"Processing {key}...")
        
        if download_file(url, temp_file):
            if normalize_audio(temp_file, target_file):
                print(f"  -> Success: {target_file}")
            else:
                print(f"  -> Failed normalization: {key}")
        else:
            print(f"  -> Failed download: {key}")

    print("Cleaning up...")
    shutil.rmtree(TEMP_DIR)
    print("Done.")

if __name__ == "__main__":
    main()
