import json
import os

app_dir = r"c:\Users\neo31\Hunting_Call"
files = ["assets/data/reference_calls.json", "assets/data/reference_calls_test.json"]

remove_animals = ["Cinnamon Teal", "Bufflehead", "Snow Goose", "American Woodcock", "Woodcock"]

for file in files:
    filepath = os.path.join(app_dir, file)
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    initial_len = len(data['calls'])
    
    data['calls'] = [c for c in data['calls'] if c.get('animalName') not in remove_animals]
    
    removed = initial_len - len(data['calls'])
    if removed > 0:
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2)
        print(f"Removed {removed} calls from {file}")
