import json, os

p = r'C:\Users\neo31\Hunting_Call\assets\data\reference_calls.json'
with open(p, encoding='utf-8') as f:
    d = json.load(f)

for c in d['calls']:
    if '_v2.' in c['audioAssetPath']:
        c['audioAssetPath'] = c['audioAssetPath'].replace('_v2.', '.')

valid = []
seen_paths = set()
for c in d['calls']:
    path_suffix = c['audioAssetPath'].replace('/', '\\')
    full_path = os.path.join(r'C:\Users\neo31\Hunting_Call', path_suffix)
    if os.path.exists(full_path):
        if c['audioAssetPath'] not in seen_paths:
            valid.append(c)
            seen_paths.add(c['audioAssetPath'])

d['calls'] = valid
with open(p, 'w', encoding='utf-8') as f:
    json.dump(d, f, indent=2)

print(f"Filtered to {len(valid)} completely pure internal references!")
