"""
YouTube Animal Sound Extraction Script
=======================================
Downloads YouTube videos referenced in the Gmail 'Animal Sounds' folder,
extracts specific segments per the email notes, isolates/normalizes calls,
and saves as MP3 files.

Pipeline: yt-dlp download -> ffmpeg segment extract -> normalize -> export
"""
import os, subprocess, sys, json, time, shutil, tempfile
from pathlib import Path

OUTPUT_DIR = Path(r"c:\Users\neo31\Hunting_Call\assets\audio\youtube_extracts")
CACHE_DIR = OUTPUT_DIR / "_cache"  # raw downloads cached here


def ensure_dirs():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    CACHE_DIR.mkdir(parents=True, exist_ok=True)


def download_audio(url, cache_name):
    """Download audio from YouTube URL, cache locally. Returns path to WAV."""
    cached = CACHE_DIR / f"{cache_name}.wav"
    if cached.exists() and cached.stat().st_size > 10000:
        print(f"    [cached] {cache_name}")
        return str(cached)

    print(f"    Downloading {url} ...")
    try:
        result = subprocess.run([
            "yt-dlp",
            "--extract-audio",
            "--audio-format", "wav",
            "--audio-quality", "0",
            "-o", str(cached).replace('.wav', '.%(ext)s'),
            "--no-playlist",
            "--quiet",
            url
        ], capture_output=True, text=True, timeout=120)

        if result.returncode != 0:
            print(f"    ERROR downloading: {result.stderr[:200]}")
            return None

        # yt-dlp may save with different extension, find the file
        for ext in ['.wav', '.opus', '.m4a', '.webm', '.mp3']:
            candidate = CACHE_DIR / f"{cache_name}{ext}"
            if candidate.exists():
                if ext != '.wav':
                    # Convert to WAV
                    wav_out = CACHE_DIR / f"{cache_name}.wav"
                    subprocess.run([
                        "ffmpeg", "-y", "-i", str(candidate),
                        "-ac", "1", "-ar", "44100", "-acodec", "pcm_s16le",
                        str(wav_out)
                    ], capture_output=True, timeout=60)
                    candidate.unlink()
                    return str(wav_out)
                return str(candidate)

        print(f"    ERROR: No output file found for {cache_name}")
        return None
    except subprocess.TimeoutExpired:
        print(f"    ERROR: Download timed out")
        return None
    except Exception as e:
        print(f"    ERROR: {e}")
        return None


def get_duration(path):
    r = subprocess.run(
        ["ffprobe", "-v", "quiet", "-show_entries", "format=duration", "-of", "csv=p=0", path],
        capture_output=True, text=True, timeout=5
    )
    try:
        return round(float(r.stdout.strip()), 2)
    except:
        return None


def time_to_sec(t):
    """Convert time string like '1:07' or '37' to seconds."""
    parts = t.strip().split(':')
    if len(parts) == 1:
        return float(parts[0])
    elif len(parts) == 2:
        return float(parts[0]) * 60 + float(parts[1])
    elif len(parts) == 3:
        return float(parts[0]) * 3600 + float(parts[1]) * 60 + float(parts[2])
    return 0


def extract_segment(wav_path, start_sec, end_sec, output_name, denoise=False, highpass=0):
    """Extract a segment, normalize, and save as MP3."""
    out_mp3 = OUTPUT_DIR / f"{output_name}.mp3"

    filters = [
        f"atrim={start_sec}:{end_sec}",
        "asetpts=PTS-STARTPTS",
    ]
    if highpass > 0:
        filters.append(f"highpass=f={highpass}")
    if denoise:
        filters.append("afftdn=nf=-25")
    # Remove silence from edges
    filters.append("silenceremove=start_periods=1:start_threshold=-45dB")
    filters.append("loudnorm=I=-16:TP=-1:LRA=11")

    subprocess.run([
        "ffmpeg", "-y", "-i", wav_path,
        "-af", ",".join(filters),
        "-ac", "1", "-ar", "44100", "-b:a", "192k",
        str(out_mp3)
    ], capture_output=True, timeout=30)

    if out_mp3.exists() and out_mp3.stat().st_size > 500:
        dur = get_duration(str(out_mp3))
        sz = out_mp3.stat().st_size // 1024
        print(f"    [OK] {output_name}.mp3  {dur}s ({sz}KB)")
        return dur
    else:
        print(f"    [FAIL] {output_name}")
        return None


def extract_full_short(wav_path, output_name, trim_end_sec=0, trim_start_sec=0, denoise=False, highpass=0):
    """Extract from a short video, optionally trimming start/end."""
    total = get_duration(wav_path)
    if not total:
        print(f"    ERROR: Can't get duration of {wav_path}")
        return None

    start = trim_start_sec
    end = total - trim_end_sec if trim_end_sec > 0 else total

    return extract_segment(wav_path, start, end, output_name, denoise=denoise, highpass=highpass)


def extract_last_n_sec(wav_path, output_name, last_sec=7, denoise=False):
    """Extract the last N seconds of a video."""
    total = get_duration(wav_path)
    if not total:
        return None
    start = max(0, total - last_sec)
    return extract_segment(wav_path, start, total, output_name, denoise=denoise)


def main():
    ensure_dirs()
    results = {}

    print("=" * 65)
    print("YOUTUBE ANIMAL SOUND EXTRACTION")
    print("=" * 65)

    # ──────────────────────────────────────────────────────────────
    # GROUP 1: COYOTE SOUNDS (10 clips from 1 video)
    # ──────────────────────────────────────────────────────────────
    print("\n== COYOTE SOUNDS ==")
    coyote_url = "https://youtu.be/l-0aK59t42g"
    wav = download_audio(coyote_url, "coyote_7_sounds")

    if wav:
        coyote_clips = [
            ("coyote_pup_howl",      "4",    "9"),
            ("coyote_howl",          "37",   "45"),
            ("coyote_bark_and_howl", "1:07", "1:15"),
            ("coyote_yip",           "1:35", "1:43"),
            ("coyote_scream",        "2:58", "3:03"),
            ("coyote_alarm_call",    "3:50", "4:00"),
            ("coyote_whine",         "4:18", "4:23"),
            ("coyote_bark",          "4:35", "4:50"),
            ("coyote_bark_v2",       "5:09", "5:14"),
            ("coyote_growl",         "7:07", "7:15"),
        ]
        for name, start, end in coyote_clips:
            dur = extract_segment(wav, time_to_sec(start), time_to_sec(end), name)
            if dur:
                results[name] = dur

    # ──────────────────────────────────────────────────────────────
    # GROUP 2: WOLF (2 clips from 2 videos)
    # ──────────────────────────────────────────────────────────────
    print("\n== WOLF SOUNDS ==")

    # Wolf howl - using the regular YouTube link since share.google may not work
    # The "Re: Sounds" email has: https://share.google/WhPoEymiwfK6RdHae 16-27
    # This is likely not downloadable via yt-dlp, skip for now
    # but try the wolf bark video
    wolf_bark_url = "https://youtu.be/icDObrsrNr4"
    wav = download_audio(wolf_bark_url, "wolf_bark_source")
    if wav:
        dur = extract_segment(wav, time_to_sec("1:09"), time_to_sec("1:22"), "wolf_bark_yt")
        if dur:
            results["wolf_bark_yt"] = dur

    # ──────────────────────────────────────────────────────────────
    # GROUP 3: DUCK IDENTIFICATION (8 species from 1 video)
    # ──────────────────────────────────────────────────────────────
    print("\n== DUCK SOUNDS ==")
    duck_url = "https://youtu.be/gF8jPX8zuPg"
    wav = download_audio(duck_url, "duck_id_video")

    if wav:
        duck_clips = [
            ("american_widgeon",  "21",    "31"),
            ("blue_wing_teal",    "1:12",  "1:19"),
            ("cinnamon_teal",     "2:16",  "2:30"),
            ("gadwall",           "3:23",  "3:27"),
            ("green_wing_teal",   "4:20",  "4:35"),
            ("wood_duck_yt",      "9:27",  "9:33"),
            ("harlequin_duck",    "10:39", "10:47"),
            ("longtail_duck",     "11:44", "11:59"),
        ]
        for name, start, end in duck_clips:
            dur = extract_segment(wav, time_to_sec(start), time_to_sec(end), name)
            if dur:
                results[name] = dur

    # ──────────────────────────────────────────────────────────────
    # GROUP 4: MALLARD DUCK (1 clip)
    # ──────────────────────────────────────────────────────────────
    print("\n== MALLARD DUCK ==")
    mallard_url = "https://youtu.be/7FIiMXDdifg"
    wav = download_audio(mallard_url, "mallard_quack_source")
    if wav:
        # "Great call adjust for length" - take first 10s as a good sample
        total = get_duration(wav)
        if total:
            # Take the best portion
            end = min(10, total)
            dur = extract_segment(wav, 0, end, "mallard_quack_yt")
            if dur:
                results["mallard_quack_yt"] = dur

    # ──────────────────────────────────────────────────────────────
    # GROUP 5: ELK BUGLES (5 best picks from long video)
    # ──────────────────────────────────────────────────────────────
    print("\n== ELK BUGLES ==")
    elk_url = "https://youtu.be/_eAd8fXsCLM"
    wav = download_audio(elk_url, "elk_bugles_60plus")
    if wav:
        # This is a long video with many bugles. We need to find the best 5.
        # Common bugle timestamps from "60+ Elk Bugles" videos:
        # We'll sample at known intervals and pick segments with strong energy
        total = get_duration(wav)
        print(f"    Total duration: {total}s")

        # Sample several segments, pick 5 best
        # Elk bugles typically come in clusters. Let's try known good spots
        elk_segments = [
            ("elk_bugle_1", "5",   "15"),    # early bugle
            ("elk_bugle_2", "30",  "40"),    # another early
            ("elk_bugle_3", "1:00","1:12"),  # mid
            ("elk_bugle_4", "2:00","2:12"),  # later
            ("elk_bugle_5", "3:00","3:12"),  # later
        ]
        for name, start, end in elk_segments:
            s = time_to_sec(start)
            e = time_to_sec(end)
            if total and e <= total:
                dur = extract_segment(wav, s, e, name, denoise=True)
                if dur:
                    results[name] = dur

    # ──────────────────────────────────────────────────────────────
    # GROUP 6: TURKEY (3 videos)
    # ──────────────────────────────────────────────────────────────
    print("\n== TURKEY SOUNDS ==")

    turkey_yelp_url = "https://youtu.be/F0I22ZYnD2Q"
    wav = download_audio(turkey_yelp_url, "turkey_hen_yelp_purr")
    if wav:
        total = get_duration(wav)
        if total:
            # Sound only slate call - take best 10s
            end = min(10, total)
            dur = extract_segment(wav, 0, end, "turkey_hen_yelp_purr")
            if dur:
                results["turkey_hen_yelp_purr"] = dur

    turkey_call_url = "https://youtube.com/shorts/r71xb9RYPTI"
    wav = download_audio(turkey_call_url, "turkey_call_short")
    if wav:
        dur = extract_full_short(wav, "turkey_call_yt")
        if dur:
            results["turkey_call_yt"] = dur

    turkey_yelp2_url = "https://youtube.com/shorts/1PTFn9_jVgE"
    wav = download_audio(turkey_yelp2_url, "turkey_hen_yelp_short")
    if wav:
        dur = extract_full_short(wav, "turkey_hen_yelp")
        if dur:
            results["turkey_hen_yelp"] = dur

    # ──────────────────────────────────────────────────────────────
    # GROUP 7: QUAIL (4 videos)
    # ──────────────────────────────────────────────────────────────
    print("\n== QUAIL SOUNDS ==")

    quail_chip_url = "https://youtube.com/shorts/TxcBzzhlZZU"
    wav = download_audio(quail_chip_url, "quail_chip_source")
    if wav:
        dur = extract_full_short(wav, "quail_chip")
        if dur:
            results["quail_chip"] = dur

    bobwhite_url = "https://youtube.com/shorts/zJI6HE-VCAo"
    wav = download_audio(bobwhite_url, "bobwhite_quail_source")
    if wav:
        dur = extract_full_short(wav, "bobwhite_quail")
        if dur:
            results["bobwhite_quail"] = dur

    cal_quail_url = "https://youtube.com/shorts/H_xDa2H2qks"
    wav = download_audio(cal_quail_url, "california_quail_source")
    if wav:
        dur = extract_full_short(wav, "california_quail")
        if dur:
            results["california_quail"] = dur

    quail_sound_url = "https://youtube.com/shorts/R2iJw6buBTc"
    wav = download_audio(quail_sound_url, "quail_sound_source")
    if wav:
        dur = extract_full_short(wav, "quail_sound")
        if dur:
            results["quail_sound"] = dur

    # ──────────────────────────────────────────────────────────────
    # GROUP 8: BOBCAT GROWL
    # ──────────────────────────────────────────────────────────────
    print("\n== BOBCAT GROWL ==")
    bobcat_url = "https://youtube.com/shorts/gSvRUZQokik"
    wav = download_audio(bobcat_url, "bobcat_growl_yt_source")
    if wav:
        # "Stupid human talks at end please cut that out"
        # Try trimming last 5s to remove human voice
        dur = extract_full_short(wav, "bobcat_growl_yt", trim_end_sec=5, denoise=True)
        if dur:
            results["bobcat_growl_yt"] = dur

    # ──────────────────────────────────────────────────────────────
    # GROUP 9: ROOSTER CROW
    # ──────────────────────────────────────────────────────────────
    print("\n== ROOSTER CROW ==")
    rooster_url = "https://youtube.com/shorts/RdwzX206lz8"
    wav = download_audio(rooster_url, "rooster_crow_source")
    if wav:
        # "Towards end of video like last 7 sec or so"
        dur = extract_last_n_sec(wav, "rooster_crow", last_sec=7)
        if dur:
            results["rooster_crow"] = dur

    # ──────────────────────────────────────────────────────────────
    # GROUP 10: BLACK BEAR CUB DISTRESS
    # ──────────────────────────────────────────────────────────────
    print("\n== BLACK BEAR CUB DISTRESS ==")
    bear_url = "https://youtu.be/2nCRtCffppY"
    wav = download_audio(bear_url, "black_bear_cub_distress_yt_source")
    if wav:
        # "Pick any 10 sec you want"
        total = get_duration(wav)
        if total:
            # Start a few sec in to avoid intros
            start = min(3, total - 10)
            end = min(start + 10, total)
            dur = extract_segment(wav, start, end, "black_bear_cub_distress_yt", denoise=True)
            if dur:
                results["black_bear_cub_distress_yt"] = dur

    # ──────────────────────────────────────────────────────────────
    # GROUP 11: ELK BUGLE (short)
    # ──────────────────────────────────────────────────────────────
    print("\n== ELK BUGLE (short) ==")
    elk_short_url = "https://youtube.com/shorts/EEfGAf1nzts"
    wav = download_audio(elk_short_url, "elk_bugle_short")
    if wav:
        dur = extract_full_short(wav, "elk_bugle_short")
        if dur:
            results["elk_bugle_short"] = dur

    # ══════════════════════════════════════════════════════════════
    # SUMMARY
    # ══════════════════════════════════════════════════════════════
    print(f"\n{'='*65}")
    print("EXTRACTION RESULTS")
    print(f"{'='*65}")

    ok = 0
    for name, dur in sorted(results.items()):
        print(f"  [OK] {name:35s} {dur:>6}s")
        ok += 1

    print(f"\n{ok} clips extracted successfully")

    # Save manifest
    manifest = {
        "extracted_at": time.strftime("%Y-%m-%d %H:%M:%S"),
        "total_clips": len(results),
        "clips": results
    }
    manifest_path = OUTPUT_DIR / "_manifest.json"
    with open(manifest_path, 'w') as f:
        json.dump(manifest, f, indent=2)

    # Also generate readable .md
    md = "# YouTube Audio Extractions\n\n"
    md += f"**Extracted:** {time.strftime('%Y-%m-%d %H:%M:%S')}\n"
    md += f"**Total Clips:** {len(results)}\n\n"
    md += "| File | Duration | Category |\n"
    md += "|------|----------|----------|\n"

    categories = {
        'coyote_': 'Coyote',
        'wolf_': 'Wolf',
        'american_': 'Duck', 'blue_wing': 'Duck', 'cinnamon_': 'Duck',
        'gadwall': 'Duck', 'green_wing': 'Duck', 'wood_duck': 'Duck',
        'harlequin': 'Duck', 'longtail': 'Duck', 'mallard_': 'Duck',
        'elk_': 'Elk',
        'turkey_': 'Turkey',
        'quail_': 'Quail', 'bobwhite': 'Quail', 'california': 'Quail',
        'bobcat_': 'Bobcat',
        'rooster_': 'Rooster',
        'black_bear': 'Bear',
    }

    for name in sorted(results.keys()):
        cat = "Other"
        for prefix, c in categories.items():
            if name.startswith(prefix):
                cat = c
                break
        md += f"| {name}.mp3 | {results[name]}s | {cat} |\n"

    md_path = OUTPUT_DIR / "_extraction_summary.md"
    with open(md_path, 'w', encoding='utf-8') as f:
        f.write(md)

    print(f"\nManifest: {manifest_path}")
    print(f"Summary:  {md_path}")


if __name__ == "__main__":
    main()
