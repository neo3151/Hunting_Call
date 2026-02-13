import json
import os
import glob

def normalize_path(p):
    return os.path.normpath(p).lower()

def main():
    # Load used files from JSON
    with open('assets/data/reference_calls.json', 'r') as f:
        data = json.load(f)

    used_files = set()
    for call in data['calls']:
        path = call.get('audioAssetPath')
        if path:
            used_files.add(normalize_path(path))
            # Also keep images just in case, though we are focusing on audio
            img = call.get('imageUrl')
            if img:
                 used_files.add(normalize_path(img))

    # Scan audio directory
    extensions = ['*.mp3', '*.wav', '*.ogg', '*.m4a']
    all_files = []
    base_dir = os.path.join('assets', 'audio')
    
    for ext in extensions:
        all_files.extend(glob.glob(os.path.join(base_dir, ext)))

    unused = []
    for f in all_files:
        norm_f = normalize_path(f)
        if norm_f not in used_files:
            unused.append(f)

    print(json.dumps(unused, indent=2))

if __name__ == '__main__':
    main()
