import os
import urllib.request
import urllib.parse

import json
import time

SAVE_DIR = r"c:\Users\neo31\Hunting_Call\assets\images\animals"
HEADERS = {
    'User-Agent': 'HuntingCallAppBot/1.0 (neo3151@gmail.com)'
}

def search_and_download(query, filename):
    print(f"Searching for {query}...")
    encoded_query = urllib.parse.quote(query)
    search_url = f"https://commons.wikimedia.org/w/api.php?action=query&format=json&generator=search&gsrnamespace=6&gsrsearch=filetype:bitmap|drawing%20{encoded_query}&gsrlimit=5&prop=imageinfo&iiprop=url|extmetadata"
    
    try:
        req = urllib.request.Request(search_url, headers=HEADERS)
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode())
            
        pages = data.get('query', {}).get('pages', {})
        if not pages:
            print(f"No results found for {query}")
            return False
            
        # Sort by index or just take the first good one
        # We want to avoid "egg" for teal and ensure "black" for bear
        best_url = None
        
        for page_id in pages:
            page = pages[page_id]
            image_info = page.get('imageinfo', [])[0]
            url = image_info.get('url')
            desc = image_info.get('extmetadata', {}).get('ObjectName', {}).get('value', '').lower()
            title = page.get('title', '').lower()
            
            print(f"Checking: {title}")
            
            if "teal" in query.lower():
                if "egg" in title or "egg" in desc:
                    print("Skipping egg image")
                    continue
                if "drawing" in title or "plate" in title:
                     print("Skipping drawing")
                     continue
            
            if "black bear" in query.lower():
                # Try to avoid brown bears if possible, though 'cinnamon' black bears exist.
                # Let's prefer 'black' in the description or title if possible
                if "grizzly" in title or "brown" in title:
                    print("Skipping grizzly/brown bear")
                    continue
            
            best_url = url
            break
        
        if best_url:
            print(f"Downloading {best_url} to {filename}...")
            filepath = os.path.join(SAVE_DIR, filename)
            req = urllib.request.Request(best_url, headers=HEADERS)
            with urllib.request.urlopen(req) as response:
                with open(filepath, 'wb') as f:
                    f.write(response.read())
            print(f"Successfully downloaded {filename}")
            return True
        else:
             print(f"No suitable image found for {query} after filtering")
             return False

    except Exception as e:
        print(f"Error downloading {filename}: {e}")
        return False

# Fix Teal - search specifically for the bird
search_and_download("Anas crecca male", "teal.jpg") # Green-winged teal male is colorful

# Fix Black Bear - search for Ursus americanus with black fur
search_and_download("Ursus americanus black", "black_bear.jpg")

print("Done.")
