import requests
import re
import os

AUDIO_DIR = "assets/audio"

FILES = {
    "turkey_hen_yelp.ogg": "https://commons.wikimedia.org/wiki/File:Meleagris_gallopavo_-_Wild_Turkey_-_XC134155.ogg",
    "owl_barred_hoot.ogg": "https://commons.wikimedia.org/wiki/File:Barred_Owl_(Strix_varia)_(W1CDR0000351_BD27).ogg",
    "coyote_howl.ogg": "https://commons.wikimedia.org/wiki/File:Pack_of_coyotes_howling.ogg",
    "duck_mallard_greeting.ogg": "https://commons.wikimedia.org/wiki/File:Anas_platyrhynchos_-_Mallard_-_XC62258.ogg",
    "elk_bull_bugle.ogg": "https://commons.wikimedia.org/wiki/File:Elkbellow.ogg",
    "goose_canadian_honk.ogg": "https://commons.wikimedia.org/wiki/File:Branta_canadensis.ogg",
    # Add others as found
}

def get_download_url(page_url):
    try:
        headers = {'User-Agent': 'HuntingCallApp/1.0 (context: educational)'}
        response = requests.get(page_url, headers=headers)
        response.raise_for_status()
        
        # Look for the original file upload URL
        # <a href="https://upload.wikimedia.org/wikipedia/commons/e/e1/File.ogg"
        match = re.search(r'href="(https://upload\.wikimedia\.org/wikipedia/commons/[^"]+\.ogg)"', response.text)
        if match:
            return match.group(1)
            
        # Try mp3 transcode if ogg original not found or logic differs
        match_mp3 = re.search(r'href="(https://upload\.wikimedia\.org/wikipedia/commons/transcoded/[^"]+\.mp3)"', response.text)
        if match_mp3:
            return match_mp3.group(1)
            
        return None
    except Exception as e:
        print(f"Error fetching {page_url}: {e}")
        return None

def download_file(url, filename):
    path = os.path.join(AUDIO_DIR, filename)
    try:
        headers = {'User-Agent': 'HuntingCallApp/1.0'}
        r = requests.get(url, headers=headers, stream=True)
        r.raise_for_status()
        with open(path, 'wb') as f:
            for chunk in r.iter_content(chunk_size=8192):
                f.write(chunk)
        print(f"Downloaded {filename}")
    except Exception as e:
        print(f"Failed to download {filename}: {e}")

def main():
    if not os.path.exists(AUDIO_DIR):
        os.makedirs(AUDIO_DIR)
        
    for filename, page_url in FILES.items():
        print(f"Processing {filename}...")
        dl_url = get_download_url(page_url)
        if dl_url:
            print(f"Found URL: {dl_url}")
            download_file(dl_url, filename)
        else:
            print(f"Could not find download URL for {filename}")

if __name__ == "__main__":
    main()
