"""
Fix 4 audio files that ended up too short after a previous batch edit.
Restores from _backup/, applies correct trim+repeat, normalizes.
"""
import os, subprocess, shutil

AUDIO = r"c:\Users\neo31\Hunting_Call\assets\audio"
BACKUP = os.path.join(AUDIO, "_backup")

# (filename, trim_start_sec or None, description)
EDITS = [
    ("turkey_gobble.mp3", None, "Repeat 1x"),
    ("pheasant.mp3", 2.0, "Drop first 2s, repeat"),
    ("gho.mp3", None, "Repeat sound"),
    ("hog_bark.mp3", 2.0, "Cut first 2s, repeat"),
]

GAP_SEC = 0.3  # silence gap between repeats


def get_duration(path):
    r = subprocess.run(
        ["ffprobe", "-v", "quiet", "-show_entries", "format=duration", "-of", "csv=p=0", path],
        capture_output=True, text=True, timeout=5
    )
    try:
        return round(float(r.stdout.strip()), 2)
    except:
        return None


def fix_file(filename, trim_start, description):
    backup_path = os.path.join(BACKUP, filename)
    final_path = os.path.join(AUDIO, filename)

    if not os.path.exists(backup_path):
        print(f"  SKIP: no backup for {filename}")
        return False

    print(f"\n{'-'*60}")
    print(f"  {filename}: {description}")
    print(f"  Backup duration: {get_duration(backup_path)}s")

    # Step 1: Restore from backup
    shutil.copy2(backup_path, final_path)
    print(f"  Restored from backup")

    # Step 2: Trim if needed, otherwise just copy
    trimmed = os.path.join(AUDIO, f"_fix_trimmed_{filename}")
    if trim_start is not None:
        subprocess.run([
            "ffmpeg", "-y", "-i", final_path,
            "-af", f"atrim=start={trim_start},asetpts=PTS-STARTPTS",
            "-ac", "1", "-ar", "44100", "-b:a", "192k", trimmed
        ], capture_output=True, timeout=15)
        print(f"  Trimmed {trim_start}s from front -> {get_duration(trimmed)}s")
    else:
        shutil.copy2(final_path, trimmed)

    # Step 3: Create silence gap
    silence = os.path.join(AUDIO, "_fix_silence.mp3")
    subprocess.run([
        "ffmpeg", "-y", "-f", "lavfi", "-i", f"anullsrc=r=44100:cl=mono",
        "-t", str(GAP_SEC), "-b:a", "192k", silence
    ], capture_output=True, timeout=10)

    # Step 4: Concat: trimmed + silence + trimmed
    concat_list = os.path.join(AUDIO, "_fix_concat.txt")
    with open(concat_list, "w") as f:
        f.write(f"file '{trimmed}'\n")
        f.write(f"file '{silence}'\n")
        f.write(f"file '{trimmed}'\n")

    tmp_out = os.path.join(AUDIO, f"_fix_out_{filename}")
    subprocess.run([
        "ffmpeg", "-y", "-f", "concat", "-safe", "0", "-i", concat_list,
        "-af", "loudnorm=I=-16:TP=-1:LRA=11",
        "-ac", "1", "-ar", "44100", "-b:a", "192k", tmp_out
    ], capture_output=True, timeout=30)

    # Cleanup temp files
    for tmp in [trimmed, silence, concat_list]:
        if os.path.exists(tmp):
            os.unlink(tmp)

    # Step 5: Replace original with result
    if os.path.exists(tmp_out) and os.path.getsize(tmp_out) > 1000:
        os.replace(tmp_out, final_path)
        new_dur = get_duration(final_path)
        sz = os.path.getsize(final_path) // 1024
        print(f"  [OK]  {new_dur}s ({sz}KB)")
        return True
    else:
        if os.path.exists(tmp_out):
            os.unlink(tmp_out)
        print(f"  [FAIL]")
        return False


def main():
    print("=" * 60)
    print("FIX SHORT AUDIO FILES")
    print("=" * 60)

    ok = 0
    for filename, trim_start, desc in EDITS:
        if fix_file(filename, trim_start, desc):
            ok += 1

    print(f"\n{'='*60}")
    print(f"DONE: {ok}/{len(EDITS)} fixed successfully")
    print(f"{'='*60}")

    # Final duration check
    print(f"\n{'FILE':30s}  {'DURATION':>10s}  {'SIZE':>8s}")
    print("-" * 55)
    for filename, _, _ in EDITS:
        path = os.path.join(AUDIO, filename)
        dur = get_duration(path)
        sz = os.path.getsize(path) // 1024 if os.path.exists(path) else 0
        print(f"{filename:30s}  {dur:>8}s  {sz:>6}KB")


if __name__ == "__main__":
    main()
