import json, os

p = r'C:\Users\neo31\Hunting_Call\assets\data\reference_calls.json'
with open(p, encoding='utf-8') as f:
    d = json.load(f)

valid = []
for c in d['calls']:
    path_suffix = c['audioAssetPath'].replace('/', '\\')
    full_path = os.path.join(r'C:\Users\neo31\Hunting_Call', path_suffix)
    if os.path.exists(full_path):
        valid.append(c)

d['calls'] = valid
with open(p, 'w', encoding='utf-8') as f:
    json.dump(d, f, indent=2)

print(f"References filtered! Remaining calls: {len(valid)}")
