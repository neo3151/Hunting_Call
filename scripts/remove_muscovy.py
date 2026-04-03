import json
import os

app_dir = r"c:\Users\neo31\Hunting_Call"
files = ["assets/data/reference_calls.json", "assets/data/reference_calls_test.json"]

for file in files:
    filepath = os.path.join(app_dir, file)
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    initial_len = len(data['calls'])
    # Remove the call where animalName is Muscovy Duck and callType is Hiss
    data['calls'] = [c for c in data['calls'] if not (c.get('animalName') == 'Muscovy Duck' and 'Hiss' in c.get('callType', ''))]
    
    if len(data['calls']) < initial_len:
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2)
        print(f"Removed Muscovy Hiss from {file}")
