"""Download correct animal images from Wikimedia Commons for all wrong images."""
import urllib.request
import json
import os
import time

IMG_DIR = r'c:\Users\neo31\Hunting_Call\assets\images\animals'

# Map: local filename -> Wikimedia Commons filename (known good images)
# These are all CC/public domain images from Wikimedia Commons
REPLACEMENTS = {
    'wood_duck.jpg': 'Aix_sponsa_-_Hillsborough_River_State_Park.jpg',
    'teal.jpg': 'Blue-Winged_Teal_(Anas_discors)_RWD3.jpg',
    'specklebelly_goose.jpg': 'Anser_albifrons_albifrons_1.jpg',
    'whitetail_buck.jpg': 'White-tailed_deer.jpg',
    'coyote.jpg': 'Coyote_Yellowstone.jpg',
    'raccoon.jpg': 'Procyon_lotor_(Common_raccoon).jpg',
    'turkey.jpg': 'Gall-dansen.jpg',  # Wild turkey display
    'barred_owl.jpg': 'Barred_Owl_Strix_varia.jpg',
    'quail.jpg': 'Virginiawachtel_2007-06-16_065.jpg',
    'pheasant.jpg': 'Phasianus_colchicus_2_tom_(Lukasz_Lukasik).jpg',
    'fallow_deer.jpg': 'Dama_dama8.JPG',
    'mule_deer.jpg': 'Mule_Deer_at_Clearwater_Pass.jpg',
    'pintail.jpg': 'Northern_Pintails_(Male_%26_Female)_I_IMG_0911.jpg',
    'woodcock.jpg': 'Woodcock_earthworm.jpg',
    'mourning_dove.jpg': 'Mourning_Dove_2006.jpg',
    'canvasback.jpg': 'Canvasback_drake_on_Chesapeake_Bay.jpg',
    'badger.jpg': 'Taxidea_taxus_-_Sycamore_Canyon,_Arizona,_USA_02.jpg',
    'great_horned_owl.jpg': 'Bubo_virginianus_06.jpg',
    'wild_hog.jpg': 'Wildschein,_sus_scrofa.jpg',
    'crow.jpg': 'Corvus_brachyrhynchos_30196.jpg',
}


def get_wiki_image_url(wiki_filename):
    """Get the direct download URL for a Wikimedia Commons file."""
    api_url = (
        'https://commons.wikimedia.org/w/api.php?'
        'action=query&titles=File:{}&prop=imageinfo&iiprop=url&format=json'
    ).format(urllib.request.quote(wiki_filename))
    
    req = urllib.request.Request(api_url, headers={
        'User-Agent': 'HuntingCallApp/1.0 (contact@benchmarkappsllc.com)'
    })
    resp = urllib.request.urlopen(req, timeout=15)
    data = json.loads(resp.read().decode('utf-8'))
    
    pages = data['query']['pages']
    for page_id, page_data in pages.items():
        if 'imageinfo' in page_data:
            return page_data['imageinfo'][0]['url']
    return None


def download_image(url, local_path):
    """Download an image from URL to local path."""
    req = urllib.request.Request(url, headers={
        'User-Agent': 'HuntingCallApp/1.0 (contact@benchmarkappsllc.com)'
    })
    resp = urllib.request.urlopen(req, timeout=30)
    data = resp.read()
    with open(local_path, 'wb') as f:
        f.write(data)
    return len(data)


def main():
    success = 0
    failed = []
    
    for local_name, wiki_name in REPLACEMENTS.items():
        local_path = os.path.join(IMG_DIR, local_name)
        print(f'  [{local_name}] Looking up {wiki_name}...', end=' ')
        
        try:
            url = get_wiki_image_url(wiki_name)
            if not url:
                print('FAILED - no URL found')
                failed.append(local_name)
                continue
            
            size = download_image(url, local_path)
            print(f'OK ({size // 1024}KB)')
            success += 1
            time.sleep(0.5)  # Be polite to Wikimedia
        except Exception as e:
            print(f'ERROR: {e}')
            failed.append(local_name)
    
    print(f'\nDone: {success} replaced, {len(failed)} failed')
    if failed:
        print(f'Failed: {", ".join(failed)}')


if __name__ == '__main__':
    main()
