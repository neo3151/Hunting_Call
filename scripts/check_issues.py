import json

with open('assets/data/reference_calls_test.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

lines = []
for c in data['calls']:
    if c['animalName'] == 'Cougar':
        lines.append(f"Cougar: '{c['callType']}' -> {c['audioAssetPath']}")
    if 'Fulvous' in c['animalName']:
        lines.append(f"Fulvous: '{c['callType']}' -> {c['audioAssetPath']}")
    if 'Egyptian Goose' in c['animalName']:
        lines.append(f"Egyptian: '{c['id']}'")
    if 'Badger' in c['animalName']:
        lines.append(f"Badger: '{c['id']}' -> {c['callType']}")
    if 'Awebo' in c['animalName']:
        lines.append(f"Awebo: image -> {c.get('imageUrl')}")

with open('issues2.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))
