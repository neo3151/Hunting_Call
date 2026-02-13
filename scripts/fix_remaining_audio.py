"""
Advanced audio processing for the 6 remaining files that need work.
Uses ffmpeg filters: highpass, lowpass, noise gate, non-local means denoising.
"""
import subprocess, shutil, json
from pathlib import Path

audio_dir = Path(r"c:\Users\neo31\Hunting_Call\assets\audio")
backup_dir = audio_dir / "_backup"
backup_dir.mkdir(exist_ok=True)

def get_dur(p):
    r = subprocess.run(["ffprobe","-v","quiet","-show_entries","format=duration","-of","csv=p=0",str(p)],
                       capture_output=True, text=True, timeout=5)
    try: return round(float(r.stdout.strip()), 2)
    except: return None

def backup(f):
    bp = backup_dir / f"fix_{f.name}"
    if not bp.exists() and f.exists():
        shutil.copy2(str(f), str(bp))

def process(src, dst, af_chain):
    """Run ffmpeg with the given audio filter chain."""
    r = subprocess.run([
        "ffmpeg", "-y", "-i", str(src),
        "-af", af_chain,
        "-ac", "1", "-ar", "44100", "-b:a", "192k", str(dst)
    ], capture_output=True, text=True, timeout=30)
    if not Path(dst).exists() or Path(dst).stat().st_size < 500:
        print(f"    WARN: filter failed, stderr: {r.stderr[-200:]}")
        return False
    return True

results = {}
tmp = audio_dir / "_tmp_fix.mp3"

print("=" * 60)
print("ADVANCED AUDIO FIXES — 6 files")
print("=" * 60)

# ============================================================
# 1. PINTAIL — remove other bird sounds
#    Strategy: bandpass filter for pintail frequency range (1-4kHz),
#    noise gate to kill quiet background birds, then normalize
# ============================================================
print("\n1. pintail.mp3 — removing background bird sounds")
src = audio_dir / "pintail.mp3"
backup(src)
af = (
    "highpass=f=800,"          # cut low rumble
    "lowpass=f=5000,"          # cut high-freq bird chirps
    "agate=threshold=0.02:ratio=3:attack=5:release=50,"  # gate out quiet sounds
    "loudnorm=I=-16:TP=-1:LRA=11"
)
if process(src, tmp, af):
    shutil.move(str(tmp), str(src))
    results["pintail.mp3"] = get_dur(str(src))
    print(f"    Done: {results['pintail.mp3']}s")
else:
    print("    FAILED — keeping original")

# ============================================================
# 2. MOOSE COW CALL — denoise
#    Strategy: non-local means denoising + gentle highpass + normalize
# ============================================================
print("\n2. moose_cow_call.mp3 — denoising")
src = audio_dir / "moose_cow_call.mp3"
backup(src)
af = (
    "highpass=f=100,"          # remove low rumble/wind
    "lowpass=f=3000,"          # moose calls are low freq, cut high noise
    "anlmdn=s=7:p=0.002:r=0.002:m=15,"  # non-local means denoise
    "agate=threshold=0.015:ratio=2:attack=10:release=100,"
    "loudnorm=I=-16:TP=-1:LRA=11"
)
if process(src, tmp, af):
    shutil.move(str(tmp), str(src))
    results["moose_cow_call.mp3"] = get_dur(str(src))
    print(f"    Done: {results['moose_cow_call.mp3']}s")
else:
    print("    FAILED — keeping original")

# ============================================================
# 3. MOOSE BULL GRUNT — denoise
#    Strategy: same as cow call but tighter bandpass for grunt freq
# ============================================================
print("\n3. moose_grunt.mp3 — denoising")
src = audio_dir / "moose_grunt.mp3"
backup(src)
af = (
    "highpass=f=80,"
    "lowpass=f=2500,"
    "anlmdn=s=7:p=0.002:r=0.002:m=15,"
    "agate=threshold=0.015:ratio=2:attack=10:release=100,"
    "loudnorm=I=-16:TP=-1:LRA=11"
)
if process(src, tmp, af):
    shutil.move(str(tmp), str(src))
    results["moose_grunt.mp3"] = get_dur(str(src))
    print(f"    Done: {results['moose_grunt.mp3']}s")
else:
    print("    FAILED — keeping original")

# ============================================================
# 4. COYOTE LONE HOWL — isolate howl
#    Strategy: bandpass for coyote howl freq (500-5kHz),
#    noise gate to isolate the howl from ambient noise
# ============================================================
print("\n4. coyote_howl.mp3 — isolating howl")
src = audio_dir / "coyote_howl.mp3"
backup(src)
af = (
    "highpass=f=400,"          # cut low rumble
    "lowpass=f=6000,"          # coyote howls are mid-high freq
    "anlmdn=s=5:p=0.002:r=0.002:m=10,"
    "agate=threshold=0.02:ratio=3:attack=5:release=80,"
    "loudnorm=I=-16:TP=-1:LRA=11"
)
if process(src, tmp, af):
    shutil.move(str(tmp), str(src))
    results["coyote_howl.mp3"] = get_dur(str(src))
    print(f"    Done: {results['coyote_howl.mp3']}s")
else:
    print("    FAILED — keeping original")

# ============================================================
# 5. BARRED OWL — isolation & clarifying
#    Strategy: bandpass for owl freq (200-2kHz), denoise, normalize
# ============================================================
print("\n5. owl_barred_hoot.mp3 — isolation & clarifying")
src = audio_dir / "owl_barred_hoot.mp3"
backup(src)
af = (
    "highpass=f=150,"          # owl hoots are low-mid
    "lowpass=f=3000,"
    "anlmdn=s=7:p=0.002:r=0.002:m=15,"
    "agate=threshold=0.01:ratio=2:attack=10:release=150,"
    "loudnorm=I=-16:TP=-1:LRA=11"
)
if process(src, tmp, af):
    shutil.move(str(tmp), str(src))
    results["owl_barred_hoot.mp3"] = get_dur(str(src))
    print(f"    Done: {results['owl_barred_hoot.mp3']}s")
else:
    print("    FAILED — keeping original")

# ============================================================
# 6. WOODCOCK — better isolation
#    Strategy: bandpass for woodcock peent freq (2-7kHz is the nasal peent),
#    aggressive noise gate, denoise
# ============================================================
print("\n6. woodcock.mp3 — better isolation")
src = audio_dir / "woodcock.mp3"
backup(src)
af = (
    "highpass=f=1500,"         # woodcock peent is high-pitched nasal
    "lowpass=f=8000,"
    "anlmdn=s=5:p=0.002:r=0.002:m=10,"
    "agate=threshold=0.025:ratio=4:attack=3:release=50,"
    "loudnorm=I=-16:TP=-1:LRA=11"
)
if process(src, tmp, af):
    shutil.move(str(tmp), str(src))
    results["woodcock.mp3"] = get_dur(str(src))
    print(f"    Done: {results['woodcock.mp3']}s")
else:
    print("    FAILED — keeping original")

# ============================================================
# Update reference_calls.json
# ============================================================
print("\n" + "=" * 60)
print("Updating reference_calls.json...")
ref_path = Path(r"c:\Users\neo31\Hunting_Call\assets\data\reference_calls.json")
with open(ref_path, "r", encoding="utf-8") as f:
    data = json.load(f)

updated = 0
for call in data["calls"]:
    fn = call["audioAssetPath"].split("/")[-1]
    if fn in results and results[fn] is not None:
        call["idealDurationSec"] = results[fn]
        updated += 1

with open(ref_path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=4, ensure_ascii=False)

print(f"Updated {updated} durations")
print(f"\nDone! {len(results)}/6 files processed successfully")

# Cleanup
for t in audio_dir.glob("_tmp_*"):
    t.unlink(missing_ok=True)
