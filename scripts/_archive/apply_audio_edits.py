"""
Apply audio edits from the review session.
Trims, repeats, and cuts audio files, then updates reference_calls.json.
"""
import subprocess, shutil, json
from pathlib import Path

audio_dir = Path(r"c:\Users\neo31\Hunting_Call\assets\audio")
backup_dir = audio_dir / "_backup"
backup_dir.mkdir(exist_ok=True)

def get_dur(path):
    r = subprocess.run(
        ["ffprobe", "-v", "quiet", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
        capture_output=True, text=True, timeout=5
    )
    try:
        return round(float(r.stdout.strip()), 2)
    except:
        return None

def trim(src, dst, start, end):
    """Trim audio to [start, end] seconds and normalize."""
    af = f"atrim={start}:{end},asetpts=PTS-STARTPTS,loudnorm=I=-16:TP=-1:LRA=11"
    subprocess.run(
        ["ffmpeg", "-y", "-i", str(src), "-af", af, "-ac", "1", "-ar", "44100", "-b:a", "192k", str(dst)],
        capture_output=True, timeout=30
    )
    if not Path(dst).exists() or Path(dst).stat().st_size < 500:
        print(f"    WARNING: trim produced bad output for {src}")
        return False
    return True

def repeat_file(src, dst):
    """Concatenate file with itself (repeat once) then normalize."""
    raw = str(dst) + ".raw.mp3"
    subprocess.run([
        "ffmpeg", "-y", "-i", str(src), "-i", str(src),
        "-filter_complex", "[0:a][1:a]concat=n=2:v=0:a=1[out]",
        "-map", "[out]", "-ac", "1", "-ar", "44100", "-b:a", "192k", raw
    ], capture_output=True, timeout=30)

    if not Path(raw).exists() or Path(raw).stat().st_size < 500:
        print(f"    WARNING: concat failed for {src}")
        return False

    # Normalize the concatenated file
    subprocess.run([
        "ffmpeg", "-y", "-i", raw,
        "-af", "loudnorm=I=-16:TP=-1:LRA=11",
        "-ac", "1", "-ar", "44100", "-b:a", "192k", str(dst)
    ], capture_output=True, timeout=30)
    Path(raw).unlink(missing_ok=True)

    if not Path(dst).exists() or Path(dst).stat().st_size < 500:
        print(f"    WARNING: normalize failed for {dst}")
        return False
    return True

def backup(f):
    bp = backup_dir / f"edit_{f.name}"
    if not bp.exists() and f.exists():
        shutil.copy2(str(f), str(bp))

def restore_backup(name):
    """Restore from backup if main file is corrupted."""
    bp = backup_dir / f"edit_{name}"
    target = audio_dir / name
    if bp.exists():
        shutil.copy2(str(bp), str(target))
        return True
    return False


def main():
    results = {}
    tmp = audio_dir / "_tmp_edit.mp3"

    print("=" * 60)
    print("APPLYING AUDIO EDITS")
    print("=" * 60)

    # --- 1. Mallard Feed: drop first ~2s ---
    name = "duck_mallard_feed.mp3"
    src = audio_dir / name
    d = get_dur(str(src))
    if d and d < 3:
        results[name] = d
        print(f"1. {name} - already trimmed: {d}s")
    else:
        print(f"1. {name} - drop first 2s")
        backup(src)
        if trim(src, tmp, 2, d):
            shutil.move(str(tmp), str(src))
            results[name] = get_dur(str(src))
            print(f"   -> {results[name]}s")

    # --- 2. Mallard Hen: drop first 3s, repeat ---
    name = "mallard_hen.mp3"
    src = audio_dir / name
    print(f"2. {name} - drop first 3s, repeat")
    # Restore backup if corrupted
    d = get_dur(str(src))
    if d is None or d < 1:
        print("   Restoring from backup...")
        restore_backup(name)
    d = get_dur(str(src))
    if d is None:
        print("   SKIP: can't get duration")
    else:
        backup(src)
        trim_end = d
        trim_start = min(3, d - 1)  # at least 1s left
        if trim(src, tmp, trim_start, trim_end):
            shutil.move(str(tmp), str(src))
            if repeat_file(src, tmp):
                shutil.move(str(tmp), str(src))
                results[name] = get_dur(str(src))
                print(f"   -> {results[name]}s")
            else:
                results[name] = get_dur(str(src))
                print(f"   -> {results[name]}s (no repeat, trim only)")

    # --- 3. Turkey Gobble: repeat ---
    name = "turkey_gobble.mp3"
    src = audio_dir / name
    print(f"3. {name} - repeat")
    backup(src)
    if repeat_file(src, tmp):
        shutil.move(str(tmp), str(src))
        results[name] = get_dur(str(src))
        print(f"   -> {results[name]}s")

    # --- 4. Pheasant: drop first 3s, repeat ---
    name = "pheasant.mp3"
    src = audio_dir / name
    print(f"4. {name} - drop first 3s, repeat")
    backup(src)
    d = get_dur(str(src))
    if trim(src, tmp, 3, d):
        shutil.move(str(tmp), str(src))
        if repeat_file(src, tmp):
            shutil.move(str(tmp), str(src))
            results[name] = get_dur(str(src))
            print(f"   -> {results[name]}s")

    # --- 5. Badger: repeat ---
    name = "badger.mp3"
    src = audio_dir / name
    print(f"5. {name} - repeat")
    backup(src)
    if repeat_file(src, tmp):
        shutil.move(str(tmp), str(src))
        results[name] = get_dur(str(src))
        print(f"   -> {results[name]}s")

    # --- 6. GHO: repeat ---
    name = "gho.mp3"
    src = audio_dir / name
    print(f"6. {name} - repeat")
    backup(src)
    if repeat_file(src, tmp):
        shutil.move(str(tmp), str(src))
        results[name] = get_dur(str(src))
        print(f"   -> {results[name]}s")

    # --- 7. Bobcat Hiss: drop last 2s ---
    name = "bobcat_hiss.mp3"
    src = audio_dir / name
    print(f"7. {name} - drop last 2s")
    backup(src)
    d = get_dur(str(src))
    end = max(1, d - 2)
    if trim(src, tmp, 0, end):
        shutil.move(str(tmp), str(src))
        results[name] = get_dur(str(src))
        print(f"   -> {results[name]}s")

    # --- 8. Wolf Yelp: cut last 2s ---
    name = "wolf_yelp.mp3"
    src = audio_dir / name
    print(f"8. {name} - cut last 2s")
    backup(src)
    d = get_dur(str(src))
    end = max(1, d - 2)
    if trim(src, tmp, 0, end):
        shutil.move(str(tmp), str(src))
        results[name] = get_dur(str(src))
        print(f"   -> {results[name]}s")

    # --- 9. Wolf Growl: cut 1s off front ---
    name = "wolf_growl.mp3"
    src = audio_dir / name
    print(f"9. {name} - cut 1s off front")
    backup(src)
    d = get_dur(str(src))
    if trim(src, tmp, 1, d):
        shutil.move(str(tmp), str(src))
        results[name] = get_dur(str(src))
        print(f"   -> {results[name]}s")

    # --- 10. Hog Bark: cut first 2s, repeat ---
    name = "hog_bark.mp3"
    src = audio_dir / name
    print(f"10. {name} - cut first 2s, repeat")
    backup(src)
    d = get_dur(str(src))
    if trim(src, tmp, 2, d):
        shutil.move(str(tmp), str(src))
        if repeat_file(src, tmp):
            shutil.move(str(tmp), str(src))
            results[name] = get_dur(str(src))
            print(f"   -> {results[name]}s")

    # ====== Update reference_calls.json ======
    print()
    print("Updating reference_calls.json...")
    ref_path = Path(r"c:\Users\neo31\Hunting_Call\assets\data\reference_calls.json")
    with open(ref_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    updated = 0
    for call in data["calls"]:
        ap = call.get("audioAssetPath", "")
        fn = ap.split("/")[-1]
        if fn in results and results[fn] is not None:
            old = call.get("idealDurationSec", 0)
            call["idealDurationSec"] = results[fn]
            print(f"  {call['id']}: {old}s -> {results[fn]}s")
            updated += 1

    with open(ref_path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=4, ensure_ascii=False)

    print()
    print(f"Done! {len(results)} files edited, {updated} JSON entries updated")
    for k, v in sorted(results.items()):
        print(f"  {k}: {v}s")

    # Cleanup temp files
    for tmp_file in audio_dir.glob("_tmp_*"):
        tmp_file.unlink(missing_ok=True)


if __name__ == "__main__":
    main()
