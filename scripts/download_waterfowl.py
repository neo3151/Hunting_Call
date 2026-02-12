"""Download curated waterfowl calls from Cornell Macaulay Library.

Each recording is hand-picked: top-rated, isolated, single-species.
Direct CDN download from Cornell Lab of Ornithology.
"""
import os, requests, subprocess, json

OUT_DIR = r"c:\Users\neo31\Hunting_Call\assets\audio\replacements"
AUDIO_DIR = r"c:\Users\neo31\Hunting_Call\assets\audio"
os.makedirs(OUT_DIR, exist_ok=True)

CDN = "https://cdn.download.ams.birds.cornell.edu/api/v1/asset"

# Curated recordings — each is the highest-rated isolated recording
# from the Macaulay Library for the target species and call type.
TARGETS = [
    {
        "file": "duck_mallard_feed.mp3",
        "asset_id": "304089",
        "rating": 5.0,
        "recordist": "Peter Boesman",
        "desc": "Mallard - Female Call (feed chatter)",
        "notes": "Top-rated mallard recording. Female vocalizations.",
        "trim_sec": 12,
    },
    {
        "file": "wood_duck.mp3",
        "asset_id": "179353",
        "rating": 4.69,
        "recordist": "Logan Kahle",
        "desc": "Wood Duck - Call (whistle)",
        "notes": "Juvenile calls. Hi-pass filtered in SoundBlade. Clean.",
        "trim_sec": 10,
    },
    {
        "file": "goose_cluck.mp3",
        "asset_id": "53519641",
        "rating": 5.0,
        "recordist": "Jay McGowan",
        "desc": "Canada Goose - Call (pair on water)",
        "notes": "5-star. Pair on water. Perfect cluck recording.",
        "trim_sec": 12,
    },
    {
        "file": "teal.mp3",
        "asset_id": "159161811",
        "rating": 4.25,
        "recordist": "Kathleen Dvorak",
        "desc": "Blue-Winged Teal - Adult Female Call",
        "notes": "Hen quack. Clear isolated recording.",
        "trim_sec": 12,
    },
    {
        "file": "snow_goose.mp3",
        "asset_id": "387012351",
        "rating": 4.75,
        "recordist": "James (Jim) Holmes",
        "desc": "Snow Goose - Call (bark)",
        "notes": "Clean call recording from Colusa NWR.",
        "trim_sec": 12,
    },
    {
        "file": "specklebelly.mp3",
        "asset_id": "31730051",
        "rating": 4.95,
        "recordist": "Andrew Spencer",
        "desc": "Greater White-fronted Goose - Call (yodel)",
        "notes": "Near-perfect. Pair on ground, calls with takeoff.",
        "trim_sec": 12,
    },
    {
        "file": "wood_duck_sit.mp3",
        "asset_id": "311981581",
        "rating": 4.47,
        "recordist": "Pen Park recording",
        "desc": "Wood Duck - Call (sitting)",
        "notes": "Second-best Wood Duck recording. Perched/sitting.",
        "trim_sec": 12,
    },
    {
        "file": "mallard_hen.mp3",
        "asset_id": "105200981",
        "rating": 4.15,
        "recordist": "Paul Marvin",
        "desc": "Mallard - Female Call (lonesome hen)",
        "notes": "Female mallard call at Riparian Preserve. Decrescendo.",
        "trim_sec": 8,
    },
    {
        "file": "canvasback.mp3",
        "asset_id": "618280036",
        "rating": 4.38,
        "recordist": "Annie Finch",
        "desc": "Canvasback - Adult Female Call (grunt)",
        "notes": "Recent (2024). Female calling. Calgary.",
        "trim_sec": 12,
    },
]

def download_and_process(t):
    """Download from Cornell CDN and normalize to MP3 192kbps."""
    url = f"{CDN}/{t['asset_id']}/audio"
    raw = os.path.join(OUT_DIR, f"_raw_{t['file'].replace('.mp3', '.mp3')}")
    out = os.path.join(OUT_DIR, t["file"])

    print(f"\n{'='*60}")
    print(f"  ML{t['asset_id']} | {t['desc']}")
    print(f"  Rating: {t['rating']}★ | By: {t['recordist']}")
    print(f"  URL: {url}")

    # Download from Cornell CDN
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
        "Accept": "audio/*,*/*",
    }
    r = requests.get(url, headers=headers, timeout=30, stream=True)

    if r.status_code != 200:
        print(f"  ERROR: HTTP {r.status_code}")
        return False

    with open(raw, "wb") as f:
        for chunk in r.iter_content(8192):
            f.write(chunk)

    sz = os.path.getsize(raw)
    ct = r.headers.get("Content-Type", "unknown")
    print(f"  Downloaded: {sz // 1024} KB ({ct})")

    if sz < 1000:
        print(f"  ERROR: File too small, likely blocked")
        os.unlink(raw)
        return False

    # Normalize: loudnorm, mono, 44.1kHz, trim, MP3 192kbps
    trim = t.get("trim_sec", 12)
    result = subprocess.run([
        "ffmpeg", "-y", "-i", raw,
        "-af", f"loudnorm=I=-16:TP=-1:LRA=11,atrim=0:{trim}",
        "-ac", "1", "-ar", "44100", "-b:a", "192k",
        out
    ], capture_output=True, text=True, timeout=30)

    # Cleanup
    try:
        os.unlink(raw)
    except:
        pass

    if os.path.exists(out):
        out_sz = os.path.getsize(out)
        print(f"  Output: {out} ({out_sz // 1024} KB)")
        return True
    else:
        print(f"  ERROR: ffmpeg failed")
        if result.stderr:
            print(f"  {result.stderr[:200]}")
        return False


def main():
    print("=" * 60)
    print("MACAULAY LIBRARY WATERFOWL DOWNLOADER")
    print("Cornell Lab of Ornithology - Curated Recordings")
    print("=" * 60)

    results = {}
    for t in TARGETS:
        try:
            ok = download_and_process(t)
            results[t["file"]] = {
                "status": "OK" if ok else "FAILED",
                "asset_id": t["asset_id"],
                "rating": t["rating"],
                "recordist": t["recordist"],
            }
        except Exception as e:
            print(f"  EXCEPTION: {e}")
            results[t["file"]] = {"status": f"ERROR: {e}", "asset_id": t["asset_id"]}

    # Summary
    print(f"\n{'='*60}")
    print("DOWNLOAD RESULTS")
    print(f"{'='*60}")
    ok_count = 0
    for fname, info in results.items():
        icon = "✓" if info["status"] == "OK" else "✗"
        print(f"  {icon} {fname:30s} ML{info['asset_id']:12s} {info.get('rating', '?')}★ {info['status']}")
        if info["status"] == "OK":
            ok_count += 1
    print(f"\n{ok_count}/{len(results)} downloaded successfully")

    # Save manifest
    manifest_path = os.path.join(OUT_DIR, "manifest.json")
    with open(manifest_path, "w") as f:
        json.dump(results, f, indent=2)
    print(f"\nManifest saved to: {manifest_path}")


if __name__ == "__main__":
    main()
