"""Search Wikimedia Commons for correct filenames for remaining animals."""
import urllib.request
import json
import os
import time

IMG_DIR = r'c:\Users\neo31\Hunting_Call\assets\images\animals'

# Animals still needing images - use search terms
REMAINING = {
    'wood_duck.jpg': 'Aix sponsa wood duck male',
    'teal.jpg': 'Blue-winged teal Spatula discors',
    'specklebelly_goose.jpg': 'greater white-fronted goose Anser albifrons',
    'turkey.jpg': 'wild turkey Meleagris gallopavo',
    'barred_owl.jpg': 'barred owl Strix varia',
    'mule_deer.jpg': 'mule deer Odocoileus hemionus',
    'pintail.jpg': 'northern pintail Anas acuta',
    'canvasback.jpg': 'canvasback Aythya valisineria',
    'badger.jpg': 'American badger Taxidea taxus',
    'wild_hog.jpg': 'wild boar Sus scrofa',
    'crow.jpg': 'American crow Corvus brachyrhynchos',
}


def search_wikimedia(query, limit=5):
    """Search Wikimedia Commons for images matching query."""
    params = urllib.request.quote(query)
    url = (
        f'https://commons.wikimedia.org/w/api.php?'
        f'action=query&list=search&srnamespace=6&srsearch={params}'
        f'&srinfo=&srprop=snippet&srlimit={limit}&format=json'
    )
    req = urllib.request.Request(url, headers={
        'User-Agent': 'HuntingCallApp/1.0 (contact@benchmarkappsllc.com)'
    })
    resp = urllib.request.urlopen(req, timeout=15)
    data = json.loads(resp.read().decode('utf-8'))
    results = []
    for item in data.get('query', {}).get('search', []):
        title = item['title']
        # Only include actual image files
        if any(title.lower().endswith(ext) for ext in ['.jpg', '.jpeg', '.png', '.svg']):
            results.append(title)
    return results


def get_image_url(title):
    """Get download URL for a Wikimedia file."""
    encoded = urllib.request.quote(title)
    url = (
        f'https://commons.wikimedia.org/w/api.php?'
        f'action=query&titles={encoded}&prop=imageinfo&iiprop=url|size&format=json'
    )
    req = urllib.request.Request(url, headers={
        'User-Agent': 'HuntingCallApp/1.0 (contact@benchmarkappsllc.com)'
    })
    resp = urllib.request.urlopen(req, timeout=15)
    data = json.loads(resp.read().decode('utf-8'))
    pages = data['query']['pages']
    for pid, pdata in pages.items():
        if 'imageinfo' in pdata:
            info = pdata['imageinfo'][0]
            return info['url'], info.get('width', 0), info.get('height', 0)
    return None, 0, 0


def download_image(url, path):
    req = urllib.request.Request(url, headers={
        'User-Agent': 'HuntingCallApp/1.0 (contact@benchmarkappsllc.com)'
    })
    resp = urllib.request.urlopen(req, timeout=60)
    data = resp.read()
    with open(path, 'wb') as f:
        f.write(data)
    return len(data)


def main():
    success = 0
    failed = []
    
    for local_name, search_query in REMAINING.items():
        local_path = os.path.join(IMG_DIR, local_name)
        print(f'\n  [{local_name}] Searching: "{search_query}"')
        
        try:
            results = search_wikimedia(search_query)
            if not results:
                # Try simpler search
                simple = search_query.split()[0] + ' ' + search_query.split()[1]
                results = search_wikimedia(simple)
            
            if not results:
                print(f'    No results found!')
                failed.append(local_name)
                continue
            
            # Try each result until we get a good image
            downloaded = False
            for title in results:
                img_url, w, h = get_image_url(title)
                if img_url and w >= 400:
                    print(f'    Found: {title} ({w}x{h})')
                    size = download_image(img_url, local_path)
                    print(f'    Downloaded: {size // 1024}KB')
                    success += 1
                    downloaded = True
                    break
                time.sleep(0.3)
            
            if not downloaded:
                print(f'    No suitable image found in results')
                failed.append(local_name)
            
            time.sleep(0.5)
        except Exception as e:
            print(f'    ERROR: {e}')
            failed.append(local_name)
    
    print(f'\n\nDone: {success} replaced, {len(failed)} failed')
    if failed:
        print(f'Failed: {", ".join(failed)}')


if __name__ == '__main__':
    main()
