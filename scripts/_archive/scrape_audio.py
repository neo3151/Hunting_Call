
import requests
import re
import os
import urllib.parse

CANDIDATES_DIR = r"c:\Users\neo31\Hunting_Call\assets\audio\_candidates"
os.makedirs(CANDIDATES_DIR, exist_ok=True)

SEARCH_TERMS = {
    "elk": ["elk+bugle", "elk+call"],
    "bear": ["black+bear", "bear+growl"],
    "pronghorn": ["pronghorn", "antelope+call"],
    "bobcat": ["bobcat+growl", "bobcat+scream"] # Extra measure
}

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
}

def clean_filename(name):
    return re.sub(r'[\\/*?:"<>|]', "", name)

def download(url, prefix):
    try:
        filename = clean_filename(os.path.basename(urllib.parse.unquote(url)))
        if not filename.endswith('.mp3'): filename += ".mp3"
        filepath = os.path.join(CANDIDATES_DIR, f"{prefix}_{filename}")
        
        if os.path.exists(filepath):
            print(f"Skipping existing: {filename}")
            return
            
        print(f"Downloading {url}...")
        r = requests.get(url, headers=HEADERS, timeout=10)
        if r.status_code == 200:
            with open(filepath, 'wb') as f:
                f.write(r.content)
            print(f"Saved: {filepath}")
        else:
            print(f"Failed {r.status_code}")
    except Exception as e:
        print(f"Error downloading {url}: {e}")

def scrape_findsounds(query, prefix):
    print(f"\n--- Searching FindSounds for '{query}' ---")
    url = f"http://www.findsounds.com/ISAPI/search.dll?keywords={query}&start=1"
    try:
        r = requests.get(url, headers=HEADERS, timeout=10)
        # Find audio links
        # FindSounds links often look like: <a href="http://..." ...>
        # We look for .mp3 or .wav
        links = re.findall(r'href=["\'](http[^"\']+\.(?:mp3|wav))["\']', r.text, re.IGNORECASE)
        print(f"Found {len(links)} links")
        for link in links[:3]: # Top 3
            download(link, prefix)
    except Exception as e:
        print(f"Error scraping findsounds: {e}")

def main():
    for animal, queries in SEARCH_TERMS.items():
        for q in queries:
            scrape_findsounds(q, animal)

if __name__ == "__main__":
    main()
