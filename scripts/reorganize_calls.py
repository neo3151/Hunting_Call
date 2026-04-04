import json
import os

JSON_PATH = "assets/data/reference_calls.json"

def main():
    print("🦆 Hunting Call DB Migration (Lion, Duck, Goose)")
    print("─" * 50)
    
    if not os.path.exists(JSON_PATH):
        print(f"❌ Error: Could not find {JSON_PATH}")
        return

    with open(JSON_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)

    calls = data.get("calls", [])
    new_calls = []
    
    removed_count = 0
    merged_count = 0

    for c in calls:
        animal = str(c.get("animalName", "")).lower()
        c_type = str(c.get("callType", "")).lower()
        c_desc = str(c.get("description", "")).lower()
        c_id = c.get("id", "").lower()
        audio_path = c.get("audioAssetPath", "")

        # 1. Mountain Lion / Puma / Cougar: remove "mountain scream"
        if "cougar" in animal or "puma" in animal or "mountain lion" in animal:
            if "scream" in c_type or "scream" in c_id or "scream" in c_desc:
                print(f"  ❌ Removed Lion/Cougar chunk: {c.get('animalName')} - {c.get('callType')}")
                if os.path.exists(audio_path):
                    os.remove(audio_path)
                removed_count += 1
                continue

        # 2. Whistling duck: remove "clear whistle"
        if "whistling" in animal or "fulvous" in animal or "duck" in animal:
            # Safety check: ensure it's the right duck
            if "fulvous" in animal or "whistling" in animal:
                if "clear" in c_type or "clear" in c_desc or "clear" in c_id:
                    print(f"  ❌ Removed Whistling Duck chunk: {c.get('animalName')} - {c.get('callType')}")
                    if os.path.exists(audio_path):
                        os.remove(audio_path)
                    removed_count += 1
                    continue

        # 3. Specklebelly / White-fronted Goose merge
        if "specklebelly" in animal or "white front" in animal or "white-front" in animal:
            old_name = c.get("animalName")
            if "white front" in animal or "white-front" in animal:
                c["animalName"] = "Specklebelly Goose"
                c["scientificName"] = "Anser albifrons"
                # Consolidate artwork pointer
                c["imageUrl"] = "assets/images/animals/specklebelly.webp"
                print(f"  🦢 Merged '{old_name}' -> 'Specklebelly Goose' [{c.get('callType')}]")
                merged_count += 1
            else:
                c["animalName"] = "Specklebelly Goose"

        new_calls.append(c)

    data["calls"] = new_calls

    with open(JSON_PATH, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)

    print("─" * 50)
    print(f"✅ Finished! Removed: {removed_count} calls, Merged: {merged_count} calls.")

if __name__ == "__main__":
    main()
