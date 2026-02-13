
import requests
import json
import sys

def probe(url, params):
    print(f"Probing {url} with {params}...")
    try:
        resp = requests.get(url, params=params, headers={
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }, timeout=10)
        print(f"Status: {resp.status_code}")
        if resp.status_code == 200:
            try:
                data = resp.json()
                print("Success! JSON response received.")
                # Save sample
                with open('ml_probe_result.json', 'w') as f:
                    json.dump(data, f, indent=2)
                return True
            except:
                print("Response not JSON:")
                print(resp.text[:200])
        else:
            print(f"Error headers: {resp.headers}")
    except Exception as e:
        print(f"Exception: {e}")
    return False

# Try finding Rocky Mountain Elk
# Taxon for Elk (Wapiti) is 'Cervus canadensis' or code 'elk' 
# Valid eBird/ML codes often look like 'rooele1' or simple names.
# We'll try general query 'q'.

base_url = "https://search.macaulaylibrary.org/catalog.json"
params = {
    "action": "new_search",
    "searchField": "animals",
    "q": "Elk",
    "mediaType": "a", # Audio
}

if probe(base_url, params):
    print("Found Elk data!")
else:
    print("Trying alternate endpoint...")
    # diverse query
    params['q'] = "Ursus americanus" # Black Bear
    probe(base_url, params)
