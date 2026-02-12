import json, os

data = json.load(open('assets/data/reference_calls.json', encoding='utf-8'))
calls = data['calls']

cats = {}
for c in calls:
    cat = c['category']
    if cat not in cats:
        cats[cat] = []
    cats[cat].append(c)

# Check which audio files exist
audio_dir = os.path.join('assets', 'audio')

lines = []
lines.append('# Hunting Call - Complete Sound Library')
lines.append('')
lines.append(f'**Total Calls: {len(calls)}**')
lines.append('')

for cat in ['Waterfowl', 'Big Game', 'Predators', 'Land Birds']:
    items = cats.get(cat, [])
    lines.append(f'---')
    lines.append(f'')
    lines.append(f'## {cat} ({len(items)} calls)')
    lines.append(f'')
    
    # Group by animal
    animals = {}
    for c in items:
        a = c['animalName']
        if a not in animals:
            animals[a] = []
        animals[a].append(c)
    
    for animal, acalls in animals.items():
        sci = acalls[0].get('scientificName', '')
        lines.append(f'### {animal}')
        if sci:
            lines.append(f'*{sci}*')
        lines.append('')
        lines.append('| Call Type | Difficulty | Duration | Pitch | Description | Pro Tips | Audio File | Exists |')
        lines.append('|-----------|-----------|----------|-------|-------------|----------|-----------|--------|')
        for c in acalls:
            af = c['audioAssetPath']
            exists = 'YES' if os.path.exists(af) else 'NO'
            d = c['difficulty']
            dur = c['idealDurationSec']
            pitch = c['idealPitchHz']
            desc = c['description']
            tips = c['proTips']
            basename = os.path.basename(af)
            lines.append(f'| {c["callType"]} | {d} | {dur}s | {pitch} Hz | {desc} | {tips} | {basename} | {exists} |')
        lines.append('')

output = '\n'.join(lines)
out_path = os.path.join(os.environ.get('APPDATA', '.'), '..', '.gemini', 'antigravity', 'brain', '2b39fd71-fd88-4cd3-b41a-164936a82bfd', 'call_library.md')
# Just print it
print(output)
