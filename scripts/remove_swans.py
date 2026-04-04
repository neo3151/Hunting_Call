import json
import os

JSON_PATH = "assets/data/reference_calls.json"

def main():
    print("🦢 Removing Unsatisfactory Swans from DB")
    print("─" * 50)
    
    if not os.path.exists(JSON_PATH):
        print(f"❌ Error: Could not find {JSON_PATH}")
        return

    with open(JSON_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)

    calls = data.get("calls", [])
    new_calls = []
    
    removed_count = 0

    for c in calls:
        animal = str(c.get("animalName", "")).lower()
        audio_path = c.get("audioAssetPath", "")

        # Look for Tundra and Trumpeter/Trumpetter swans
        if "tundra swan" in animal or "trumpeter swan" in animal or "trumpetter swan" in animal:
            print(f"  ❌ Removed Swan entry: {c.get('animalName')} - {c.get('callType')}")
            if os.path.exists(audio_path):
                try:
                    os.remove(audio_path)
                    print(f"     - Deleted audio block: {audio_path}")
                except Exception as e:
                    print(f"     - Audio deletion failed (might be open): {e}")
            removed_count += 1
            continue

        new_calls.append(c)

    data["calls"] = new_calls

    with open(JSON_PATH, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)

    print("─" * 50)
    print(f"✅ Finished! Surgically removed {removed_count} swan calls and their audio files.")

if __name__ == "__main__":
    main()
