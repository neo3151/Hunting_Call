"""Verify reference_calls.json integrity and asset existence."""
import json
import os

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REF_FILE = os.path.join(BASE, 'assets', 'data', 'reference_calls.json')

with open(REF_FILE, 'r', encoding='utf-8') as f:
    data = json.load(f)

calls = data['calls']
print(f"Total calls: {len(calls)}")

# Check for duplicate IDs
ids = [c['id'] for c in calls]
dupes = [x for x in ids if ids.count(x) > 1]
if dupes:
    print(f"DUPLICATE IDs: {set(dupes)}")
else:
    print("No duplicate IDs")

# Check audio files exist
missing_audio = []
for c in calls:
    path = os.path.join(BASE, c['audioAssetPath'])
    if not os.path.exists(path):
        missing_audio.append(f"  {c['id']}: {c['audioAssetPath']}")

print(f"Missing audio files: {len(missing_audio)}")
for m in missing_audio[:10]:
    print(m)

# Check image files
missing_img = []
for c in calls:
    img = c.get('imageUrl', '')
    if img and not img.startswith('http'):
        path = os.path.join(BASE, img)
        if not os.path.exists(path):
            missing_img.append(f"  {c['id']}: {img}")

print(f"Missing image files: {len(missing_img)}")
for m in missing_img[:10]:
    print(m)

# Category breakdown
cats = {}
for c in calls:
    cat = c.get('category', 'Unknown')
    cats[cat] = cats.get(cat, 0) + 1
print("Category breakdown:")
for k, v in sorted(cats.items()):
    print(f"  {k}: {v}")

# Verify required fields
required = ['id', 'animalName', 'callType', 'category', 'difficulty',
            'idealPitchHz', 'idealDurationSec', 'audioAssetPath']
missing_fields = []
for c in calls:
    for field in required:
        if field not in c or c[field] is None:
            missing_fields.append(f"  {c.get('id','?')}: missing {field}")

print(f"Missing required fields: {len(missing_fields)}")
for m in missing_fields[:10]:
    print(m)

# Verify waveform/spectrogram
no_waveform = [c['id'] for c in calls if not c.get('waveform')]
no_spectro = [c['id'] for c in calls if not c.get('spectrogram')]
print(f"Calls without waveform: {len(no_waveform)}")
print(f"Calls without spectrogram: {len(no_spectro)}")

print("\nVerification complete!")
