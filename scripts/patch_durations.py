import json
import os
import sys

# Attempt to import mutagen
try:
    from mutagen.mp3 import MP3
    from mutagen.wave import WAVE
except ImportError:
    print("Error: The 'mutagen' Python library is required. Please run: pip install mutagen")
    sys.exit(1)

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REF_FILE = os.path.join(BASE, 'assets', 'data', 'reference_calls.json')

if not os.path.exists(REF_FILE):
    print(f"Error: Could not find reference_calls.json at {REF_FILE}")
    sys.exit(1)

# Read the current JSON structure
print(f"Loading {REF_FILE}...")
with open(REF_FILE, 'r', encoding='utf-8') as f:
    data = json.load(f)

calls = data.get('calls', [])
patched_count = 0

print(f"Checking {len(calls)} calls to patch duration inaccuracies...")

for c in calls:
    call_id = c['id']
    asset_path = c.get('audioAssetPath')
    recorded_dur = c.get('idealDurationSec')
    
    if not asset_path:
        continue
        
    full_path = os.path.join(BASE, asset_path)
    if not os.path.exists(full_path):
        continue
        
    try:
        ext = os.path.splitext(full_path)[1].lower()
        true_dur = None
        
        if ext == '.mp3':
            audio = MP3(full_path)
            true_dur = audio.info.length
        elif ext == '.wav':
            audio = WAVE(full_path)
            true_dur = audio.info.length
            
        if true_dur is not None:
            # If the recorded duration is None or differs by more than 1 millisecond, patch it
            if recorded_dur is None or abs(true_dur - recorded_dur) > 0.001:
                # We round to 3 decimal places to keep the JSON clean and precise
                c['idealDurationSec'] = round(true_dur, 3)
                patched_count += 1
                
    except Exception as e:
        print(f"Error reading audio file for {full_path}: {e}")

# If we made edits, save the file back!
if patched_count > 0:
    print(f"\n[!] Writing updates to {REF_FILE}...")
    with open(REF_FILE, 'w', encoding='utf-8') as f:
        # Standard indent of 2 for flutter json datasets
        json.dump(data, f, indent=2, ensure_ascii=False)
    # Add a newline at EOF
    with open(REF_FILE, 'a', encoding='utf-8') as f:
        f.write("\n")
    print(f"[+] Successfully patched {patched_count} exact audio lengths to the library!")
else:
    print("\n[+] Checked all items. No durations required patching.")
