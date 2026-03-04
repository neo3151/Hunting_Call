import os
import urllib.request
import json
import urllib.parse

SAVE_DIR = r"c:\Users\neo31\Hunting_Call\assets\audio"
HEADERS = {
    'User-Agent': 'HuntingCallAppBot/1.0 (neo3151@gmail.com)'
}

def search_and_download_audio(query, filename, keywords=None):
    print(f"Searching for {query}...")
    encoded_query = urllib.parse.quote(query)
    search_url = f"https://commons.wikimedia.org/w/api.php?action=query&format=json&generator=search&gsrnamespace=6&gsrsearch={encoded_query}&gsrlimit=10&prop=imageinfo&iiprop=url|extmetadata|mime"
    
    try:
        req = urllib.request.Request(search_url, headers=HEADERS)
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode())
            
        pages = data.get('query', {}).get('pages', {})
        if not pages:
            print(f"No results found for {query}")
            return False
            
        for page_id in pages:
            page = pages[page_id]
            title = page.get('title', '').lower()
            image_info = page.get('imageinfo', [])[0]
            url = image_info.get('url')
            mime = image_info.get('mime', '')
            
            print(f"Checking: {title} ({mime})")
            
            if 'audio' in mime or url.endswith(('.ogg', '.mp3', '.wav', '.flac')):
                print(f"Found audio candidate: {url}")
                
                # Check keywords if provided
                if keywords:
                    if not any(k in title for k in keywords):
                        print(f"Skipping {title} - missing keywords {keywords}")
                        continue

                print(f"Downloading {url} to {filename}...")
                filepath = os.path.join(SAVE_DIR, filename)
                req = urllib.request.Request(url, headers=HEADERS)
                with urllib.request.urlopen(req) as response:
                    with open(filepath, 'wb') as f:
                        f.write(response.read())
                print(f"Successfully downloaded {filename}")
                return True
        
        print(f"No suitable audio found for {query}")
        return False

    except Exception as e:
        print(f"Error: {e}")
        return False

# Search for Mule Deer (Broad)
search_and_download_audio("Odocoileus hemionus", "mule_deer_broad.ogg", ["sound", "audio", "call", "voice", "grunt"])

# Search for Wolf Howl
search_and_download_audio("Canis lupus howl", "wolf_howl_candidate.ogg", ["howl", "call", "voice"])

