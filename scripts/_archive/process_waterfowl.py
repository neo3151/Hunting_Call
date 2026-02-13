"""Process raw downloaded waterfowl WAV files into normalized MP3 192kbps."""
import os, subprocess

DIR = r"c:\Users\neo31\Hunting_Call\assets\audio\replacements"

TARGETS = [
    {"raw": "_raw_mallard_feed.wav", "out": "duck_mallard_feed.mp3", "trim_start": "0", "trim_end": "10"},
    {"raw": "_raw_wood_duck.wav", "out": "wood_duck.mp3", "trim_start": "0", "trim_end": "7"},
    {"raw": "_raw_goose_cluck.wav", "out": "goose_cluck.mp3", "trim_start": "0", "trim_end": "10"},
    {"raw": "_raw_specklebelly.wav", "out": "specklebelly.mp3", "trim_start": "0", "trim_end": "10"},
    {"raw": "_raw_wood_duck_sit.wav", "out": "wood_duck_sit.mp3", "trim_start": "0", "trim_end": "10"},
    {"raw": "_raw_mallard_hen.wav", "out": "mallard_hen.mp3", "trim_start": "0", "trim_end": "5"},
]

for t in TARGETS:
    raw = os.path.join(DIR, t["raw"])
    out = os.path.join(DIR, t["out"])
    
    if not os.path.exists(raw):
        print(f"SKIP: {t['raw']} not found")
        continue
    
    print(f"Processing: {t['raw']} -> {t['out']}")
    result = subprocess.run([
        "ffmpeg", "-y", "-i", raw,
        "-ss", t["trim_start"], "-to", t["trim_end"],
        "-af", "loudnorm=I=-16:TP=-1:LRA=11",
        "-ac", "1", "-ar", "44100", "-b:a", "192k",
        out
    ], capture_output=True, text=True, timeout=30)
    
    if os.path.exists(out):
        sz = os.path.getsize(out) // 1024
        print(f"  OK: {sz} KB")
    else:
        print(f"  FAILED")
        if result.stderr:
            print(f"  stderr: {result.stderr[:200]}")

# List all final replacement files
print(f"\nFinal replacement files:")
for f in sorted(os.listdir(DIR)):
    if f.endswith(".mp3") and not f.startswith("_"):
        sz = os.path.getsize(os.path.join(DIR, f)) // 1024
        print(f"  {f} ({sz} KB)")
