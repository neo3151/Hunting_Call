import json
import os
import sys

# Attempt to import mutagen. If missing, handle it gracefully.
try:
    from mutagen.mp3 import MP3
    from mutagen.wave import WAVE
except ImportError:
    print("Error: The 'mutagen' Python library is required to check audio durations.")
    print("Please install it by running:")
    print("  pip install mutagen")
    sys.exit(1)

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REF_FILE = os.path.join(BASE, 'assets', 'data', 'reference_calls.json')

if not os.path.exists(REF_FILE):
    print(f"Error: Could not find reference_calls.json at {REF_FILE}")
    sys.exit(1)

with open(REF_FILE, 'r', encoding='utf-8') as f:
    data = json.load(f)

calls = data.get('calls', [])
print(f"Scanning {len(calls)} calls in the library for duration accuracy...\n")

flaws = []
for c in calls:
    call_id = c['id']
    asset_path = c.get('audioAssetPath')
    ideal_dur = c.get('idealDurationSec')
    
    if not asset_path or ideal_dur is None:
        continue
        
    full_path = os.path.join(BASE, asset_path)
    if not os.path.exists(full_path):
        print(f"Warning: Audio file does not exist for {call_id}: {asset_path}")
        continue
        
    try:
        # Check audio type and read duration
        ext = os.path.splitext(full_path)[1].lower()
        actual_dur = None
        
        if ext == '.mp3':
            audio = MP3(full_path)
            actual_dur = audio.info.length
        elif ext == '.wav':
            audio = WAVE(full_path)
            actual_dur = audio.info.length
        else:
            print(f"Skipping unsupported audio format for {call_id}: {ext}")
            continue
        
        diff = abs(actual_dur - ideal_dur)
        
        # We use a 0.05 seconds (50ms) tolerance as the threshold for an "flaw"
        if diff > 0.05:
            flaws.append({
                'id': call_id,
                'path': asset_path,
                'json_duration': ideal_dur,
                'actual_duration': actual_dur,
                'diff': diff
            })
    except Exception as e:
        print(f"Error reading audio file for {full_path}: {e}")

# Sort by severity of discrepancy
flaws.sort(key=lambda x: x['diff'], reverse=True)

if not flaws:
    print("[+] All audio durations are perfectly accurate (within 50ms tolerance)! No flaws found.")
else:
    print(f"[-] Found {len(flaws)} duration discrepancies (>50ms difference):")
    print("-" * 65)
    for f in flaws:
        print(f"ID: {f['id']}")
        print(f"  JSON Record: {f['json_duration']:.3f} s")
        print(f"  True Length: {f['actual_duration']:.3f} s")
        print(f"  Discrepancy: {f['diff']:.3f} s")
        print("-" * 65)
        
    print("\nIf you want, I can write a follow-up script to automatically patch reference_calls.json with the true lengths.")
