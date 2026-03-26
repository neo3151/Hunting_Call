"""Merge new call entries into the existing reference_calls.json."""
import json
import os
import sys

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REF_FILE = os.path.join(BASE, 'assets', 'data', 'reference_calls.json')
NEW_FILE = os.path.join(BASE, 'scripts', 'new_calls_entries.json')

# Load existing
with open(REF_FILE, 'r', encoding='utf-8') as f:
    data = json.load(f)

existing_ids = {c['id'] for c in data['calls']}
print(f"Existing calls: {len(data['calls'])}")

# Load new
with open(NEW_FILE, 'r', encoding='utf-8') as f:
    new_entries = json.load(f)

print(f"New entries to merge: {len(new_entries)}")

# Merge (skip duplicates)
added = 0
skipped = 0
for entry in new_entries:
    if entry['id'] in existing_ids:
        print(f"  SKIP (duplicate): {entry['id']}")
        skipped += 1
    else:
        data['calls'].append(entry)
        existing_ids.add(entry['id'])
        added += 1

# Sort by category, then animalName, then callType
data['calls'].sort(key=lambda c: (c.get('category', ''), c.get('animalName', ''), c.get('callType', '')))

# Write back
with open(REF_FILE, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

total = len(data['calls'])
print(f"\nDone! Added {added}, skipped {skipped}. Total calls: {total}")

# Verify
with open(REF_FILE, 'r', encoding='utf-8') as f:
    verify = json.load(f)
print(f"Verification: JSON valid, {len(verify['calls'])} calls parsed OK")
