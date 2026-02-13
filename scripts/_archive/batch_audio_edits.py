"""
Batch audio edits for the 16 files that need trim/repeat/cleanup.
Plus the puma → cougar swap.

Each edit uses ffmpeg filter chains. Files are edited in-place
(with backup to _backup/ first).
"""
import os, subprocess, shutil, tempfile, struct, wave, math

AUDIO = r"c:\Users\neo31\Hunting_Call\assets\audio"
BACKUP = os.path.join(AUDIO, "_backup")
os.makedirs(BACKUP, exist_ok=True)


def ffmpeg_edit(filename, filters, description):
    """Apply ffmpeg filter chain to a file, replacing it in-place."""
    src = os.path.join(AUDIO, filename)
    if not os.path.exists(src):
        print(f"  SKIP: {filename} not found")
        return False

    # Backup original
    backup_path = os.path.join(BACKUP, filename)
    if not os.path.exists(backup_path):
        shutil.copy2(src, backup_path)

    # Process to temp file
    tmp = os.path.join(AUDIO, f"_tmp_{filename}")
    cmd = [
        "ffmpeg", "-y", "-i", src,
        "-af", filters,
        "-ac", "1", "-ar", "44100", "-b:a", "192k",
        tmp
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)

    if os.path.exists(tmp) and os.path.getsize(tmp) > 1000:
        os.replace(tmp, src)
        # Get new duration
        r = subprocess.run(
            ["ffprobe", "-v", "quiet", "-show_entries", "format=duration", "-of", "csv=p=0", src],
            capture_output=True, text=True, timeout=5
        )
        new_dur = round(float(r.stdout.strip()), 1)
        sz = os.path.getsize(src) // 1024
        print(f"  OK  {filename:30s} -> {new_dur}s ({sz}KB) | {description}")
        return True
    else:
        if os.path.exists(tmp):
            os.unlink(tmp)
        print(f"  FAIL {filename:30s} | {description}")
        if result.stderr:
            errs = [l for l in result.stderr.split("\n") if "error" in l.lower()]
            for e in errs[:2]:
                print(f"       {e.strip()}")
        return False


def concat_with_self(filename, description, trim_start=None, trim_end=None, gap_sec=0.3):
    """Trim file optionally, then concatenate it with itself (repeat 1x) with a small gap."""
    src = os.path.join(AUDIO, filename)
    if not os.path.exists(src):
        print(f"  SKIP: {filename} not found")
        return False

    # Backup
    backup_path = os.path.join(BACKUP, filename)
    if not os.path.exists(backup_path):
        shutil.copy2(src, backup_path)

    # Step 1: Make trimmed version if needed
    trimmed = os.path.join(AUDIO, f"_trimmed_{filename}")
    if trim_start is not None or trim_end is not None:
        trim_filter = []
        if trim_start is not None:
            trim_filter.append(f"atrim=start={trim_start}")
        if trim_end is not None:
            # atrim end is relative to original
            if trim_start:
                trim_filter.append(f"atrim=end={trim_end - (trim_start or 0)}")
            else:
                trim_filter.append(f"atrim=end={trim_end}")
        trim_filter.append("asetpts=PTS-STARTPTS")
        subprocess.run([
            "ffmpeg", "-y", "-i", src,
            "-af", ",".join(trim_filter),
            "-ac", "1", "-ar", "44100", "-b:a", "192k", trimmed
        ], capture_output=True, timeout=15)
    else:
        shutil.copy2(src, trimmed)

    # Step 2: Create silence gap
    silence = os.path.join(AUDIO, "_silence.mp3")
    subprocess.run([
        "ffmpeg", "-y", "-f", "lavfi", "-i", f"anullsrc=r=44100:cl=mono",
        "-t", str(gap_sec), "-b:a", "192k", silence
    ], capture_output=True, timeout=10)

    # Step 3: Concat: trimmed + silence + trimmed
    concat_list = os.path.join(AUDIO, "_concat.txt")
    with open(concat_list, "w") as f:
        f.write(f"file '{trimmed}'\n")
        f.write(f"file '{silence}'\n")
        f.write(f"file '{trimmed}'\n")

    tmp_out = os.path.join(AUDIO, f"_concat_{filename}")
    subprocess.run([
        "ffmpeg", "-y", "-f", "concat", "-safe", "0", "-i", concat_list,
        "-af", "loudnorm=I=-16:TP=-1:LRA=11",
        "-ac", "1", "-ar", "44100", "-b:a", "192k", tmp_out
    ], capture_output=True, timeout=30)

    # Cleanup
    for f in [trimmed, silence, concat_list]:
        if os.path.exists(f):
            os.unlink(f)

    if os.path.exists(tmp_out) and os.path.getsize(tmp_out) > 1000:
        os.replace(tmp_out, src)
        r = subprocess.run(
            ["ffprobe", "-v", "quiet", "-show_entries", "format=duration", "-of", "csv=p=0", src],
            capture_output=True, text=True, timeout=5
        )
        new_dur = round(float(r.stdout.strip()), 1)
        sz = os.path.getsize(src) // 1024
        print(f"  OK  {filename:30s} -> {new_dur}s ({sz}KB) | {description}")
        return True
    else:
        if os.path.exists(tmp_out):
            os.unlink(tmp_out)
        print(f"  FAIL {filename:30s} | {description}")
        return False


def main():
    print("=" * 70)
    print("BATCH AUDIO EDITS — 16 files + puma swap")
    print("=" * 70)

    results = {}

    # ─── SIMPLE TRIMS ─────────────────────────────────────────────────
    print("\n── Simple Trims ──")

    # 1. duck_mallard_feed.mp3 — drop first ~2s
    results["duck_mallard_feed.mp3"] = ffmpeg_edit(
        "duck_mallard_feed.mp3",
        "atrim=start=2,asetpts=PTS-STARTPTS,loudnorm=I=-16:TP=-1:LRA=11",
        "Drop first 2s"
    )

    # 2. bobcat_hiss.mp3 — drop last 2s (file is 5s, keep 0-3s)
    results["bobcat_hiss.mp3"] = ffmpeg_edit(
        "bobcat_hiss.mp3",
        "atrim=end=3,asetpts=PTS-STARTPTS,loudnorm=I=-16:TP=-1:LRA=11",
        "Drop last 2s"
    )

    # 3. wolf_yelp.mp3 — cut last 2s (file is 7s, keep 0-5s)
    results["wolf_yelp.mp3"] = ffmpeg_edit(
        "wolf_yelp.mp3",
        "atrim=end=5,asetpts=PTS-STARTPTS,loudnorm=I=-16:TP=-1:LRA=11",
        "Cut last 2s"
    )

    # 4. wolf_growl.mp3 — cut 1s off front (file is 7s)
    results["wolf_growl.mp3"] = ffmpeg_edit(
        "wolf_growl.mp3",
        "atrim=start=1,asetpts=PTS-STARTPTS,loudnorm=I=-16:TP=-1:LRA=11",
        "Cut 1s off front"
    )

    # ─── DROP FRONT + REPEAT ──────────────────────────────────────────
    print("\n── Drop Front + Repeat ──")

    # 5. mallard_hen.mp3 — drop first few sec, repeat sound (3s total, drop ~1s)
    results["mallard_hen.mp3"] = concat_with_self(
        "mallard_hen.mp3", "Drop first 1s, repeat", trim_start=1.0
    )

    # 6. crow.mp3 — drop first few sec, repeat 1x (12s, drop 2s)
    results["crow.mp3"] = concat_with_self(
        "crow.mp3", "Drop first 2s, repeat", trim_start=2.0
    )

    # 7. pheasant.mp3 — drop first few sec, repeat (7.2s, drop 2s)
    results["pheasant.mp3"] = concat_with_self(
        "pheasant.mp3", "Drop first 2s, repeat", trim_start=2.0
    )

    # 8. red_stag_roar.mp3 — drop first few sec, repeat (11.9s, drop 2s)
    results["red_stag_roar.mp3"] = concat_with_self(
        "red_stag_roar.mp3", "Drop first 2s, repeat", trim_start=2.0
    )

    # 9. hog_bark.mp3 — cut first 2s, repeat (6s)
    results["hog_bark.mp3"] = concat_with_self(
        "hog_bark.mp3", "Cut first 2s, repeat", trim_start=2.0
    )

    # ─── REPEAT ONLY ──────────────────────────────────────────────────
    print("\n── Repeat Only ──")

    # 10. turkey_gobble.mp3 — repeat 1 more time (12s)
    results["turkey_gobble.mp3"] = concat_with_self(
        "turkey_gobble.mp3", "Repeat 1x"
    )

    # 11. badger.mp3 — repeat 1 more time (2s)
    results["badger.mp3"] = concat_with_self(
        "badger.mp3", "Repeat 1x"
    )

    # 12. gho.mp3 — repeat sound (12s)
    results["gho.mp3"] = concat_with_self(
        "gho.mp3", "Repeat 1x"
    )

    # 13. bobcat_growl_v2.mp3 — repeat sound (5s)
    results["bobcat_growl_v2.mp3"] = concat_with_self(
        "bobcat_growl_v2.mp3", "Repeat 1x"
    )

    # 14. bobcat_howl.mp3 — repeat & iso (5s)
    results["bobcat_howl.mp3"] = concat_with_self(
        "bobcat_howl.mp3", "Repeat & iso"
    )

    # ─── SPECIAL: PUMA → COUGAR SWAP ──────────────────────────────────
    print("\n── Special Actions ──")

    # puma_scream.mp3 is great → copy to cougar.mp3
    puma = os.path.join(AUDIO, "puma_scream.mp3")
    cougar = os.path.join(AUDIO, "cougar.mp3")
    if os.path.exists(puma):
        # Backup old cougar
        cougar_backup = os.path.join(BACKUP, "cougar.mp3")
        if not os.path.exists(cougar_backup):
            shutil.copy2(cougar, cougar_backup)
        shutil.copy2(puma, cougar)
        r = subprocess.run(
            ["ffprobe", "-v", "quiet", "-show_entries", "format=duration", "-of", "csv=p=0", cougar],
            capture_output=True, text=True, timeout=5
        )
        dur = round(float(r.stdout.strip()), 1)
        print(f"  OK  {'cougar.mp3 (from puma)':30s} -> {dur}s | Puma scream replaces mountain lion")
        results["cougar.mp3"] = True
    else:
        print(f"  SKIP: puma_scream.mp3 not found")
        results["cougar.mp3"] = False

    # ─── HOLD FILES (just note them) ──────────────────────────────────
    print("\n── On Hold ──")
    print(f"  HOLD wolf_howl.mp3                    | Tough but could be better — user deciding")
    print(f"  HOLD wood_duck_sit.mp3                | Decent iso — keeping for now")

    # ─── SUMMARY ──────────────────────────────────────────────────────
    print(f"\n{'='*70}")
    print("RESULTS")
    print(f"{'='*70}")
    ok = sum(1 for v in results.values() if v)
    fail = sum(1 for v in results.values() if not v)
    for fname, status in results.items():
        icon = "OK" if status else "XX"
        print(f"  [{icon}] {fname}")
    print(f"\n{ok}/{len(results)} edits completed | {fail} failed | 2 on hold")


if __name__ == "__main__":
    main()
