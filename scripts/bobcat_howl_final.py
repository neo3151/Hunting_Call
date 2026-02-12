"""
Focused search for bobcat howl audio from Acoustic Atlas and other clean sources.
"""
import subprocess, os, re, json

AUDIO = r"c:\Users\neo31\Hunting_Call\assets\audio"
CANDS = os.path.join(AUDIO, "_candidates")
RAW = os.path.join(AUDIO, "_raw_downloads")


def download(url, out, insecure=True):
    args = ["curl", "-L", "-f", "-o", out, "-H", "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)", url]
    if insecure:
        args.insert(1, "-k")
    r = subprocess.run(args, capture_output=True, timeout=30)
    ok = os.path.exists(out) and os.path.getsize(out) > 3000
    if not ok and os.path.exists(out):
        os.unlink(out)
    return ok


def get_duration(path):
    r = subprocess.run(
        ["ffprobe", "-v", "quiet", "-show_entries", "format=duration", "-of", "csv=p=0", path],
        capture_output=True, text=True, timeout=5)
    return float(r.stdout.strip()) if r.stdout.strip() else 0


def process(raw, out, max_dur=5):
    dur = get_duration(raw)
    end = min(dur, max_dur)
    filters = [f"atrim=0:{end}", "asetpts=PTS-STARTPTS", 
               "highpass=f=60", "afftdn=nf=-20", "loudnorm=I=-16:TP=-1:LRA=11"]
    subprocess.run([
        "ffmpeg", "-y", "-i", raw, "-af", ",".join(filters),
        "-ac", "1", "-ar", "44100", "-b:a", "192k", out
    ], capture_output=True, timeout=30)
    if os.path.exists(out) and os.path.getsize(out) > 1000:
        return round(get_duration(out), 1)
    return None


def main():
    print("=" * 60)
    print("BOBCAT HOWL - FOCUSED SEARCH")
    print("=" * 60)
    
    candidates = []
    
    # ---- 1. Scrape Acoustic Atlas for bobcat MP3 URLs ----
    print("\n--- Acoustic Atlas ---")
    r = subprocess.run(["curl", "-s", "-k", "-L", "https://acousticatlas.org/?s=bobcat",
                        "-H", "User-Agent: Mozilla/5.0"],
                       capture_output=True, text=True, timeout=15)
    if r.returncode == 0 and r.stdout:
        mp3_urls = list(set(re.findall(r'https?://[^"\'\s]+\.mp3', r.stdout)))
        print(f"  Found {len(mp3_urls)} MP3 URLs on Acoustic Atlas")
        for url in mp3_urls:
            fname = "aa_" + url.split("/")[-1]
            out_raw = os.path.join(RAW, fname)
            print(f"  {fname}: ", end="", flush=True)
            if download(url, out_raw):
                dur = get_duration(out_raw)
                print(f"OK ({dur:.1f}s)")
                out_proc = os.path.join(CANDS, fname)
                d = process(out_raw, out_proc, max_dur=7)
                if d:
                    candidates.append((fname, "Acoustic Atlas", url.split("/")[-1], d))
            else:
                print("FAILED")
    else:
        print("  Could not reach Acoustic Atlas")
    
    # Also try specific known Acoustic Atlas bobcat pages
    aa_pages = [
        "https://acousticatlas.org/bobcat-madison-junction-yellowstone-national-park/",
        "https://acousticatlas.org/bobcat-greeting-vocalization-captive/",
        "https://acousticatlas.org/bobcat/",
    ]
    
    for page_url in aa_pages:
        print(f"  Checking page: {page_url.split('/')[-2]}")
        r = subprocess.run(["curl", "-s", "-k", "-L", page_url,
                            "-H", "User-Agent: Mozilla/5.0"],
                           capture_output=True, text=True, timeout=15)
        if r.returncode == 0 and r.stdout:
            mp3s = list(set(re.findall(r'https?://[^"\'\s]+\.mp3', r.stdout)))
            for url in mp3s:
                fname = "aa_page_" + url.split("/")[-1]
                if any(c[0] == fname for c in candidates):
                    continue  # Already have this one
                out_raw = os.path.join(RAW, fname)
                print(f"    {fname}: ", end="", flush=True)
                if download(url, out_raw):
                    dur = get_duration(out_raw)
                    print(f"OK ({dur:.1f}s)")
                    out_proc = os.path.join(CANDS, fname)
                    d = process(out_raw, out_proc, max_dur=7)
                    if d:
                        candidates.append((fname, "Acoustic Atlas", url.split("/")[-1], d))
                else:
                    print("FAILED")
    
    # ---- 2. Try animals-sound-effects.com ----
    print("\n--- Other sources ---")
    other_urls = [
        ("https://www.animal-sounds.org/bobcat-sounds.html", "animal-sounds.org"),
        ("https://www.sigmaoutdoors.com/sounds/bobcat/", "Sigma Outdoors"),
    ]
    for page_url, source in other_urls:
        print(f"  Checking {source}...")
        r = subprocess.run(["curl", "-s", "-L", page_url,
                            "-H", "User-Agent: Mozilla/5.0"],
                           capture_output=True, text=True, timeout=15)
        if r.returncode == 0 and r.stdout:
            audio_urls = list(set(re.findall(r'https?://[^"\'\s]+\.(?:mp3|wav|ogg)', r.stdout)))
            print(f"    Found {len(audio_urls)} audio URLs")
            for url in audio_urls[:3]:
                fname = f"{source.replace(' ', '_')}_{url.split('/')[-1]}"
                out_raw = os.path.join(RAW, fname)
                print(f"    {fname}: ", end="", flush=True)
                if download(url, out_raw, insecure=False):
                    dur = get_duration(out_raw)
                    print(f"OK ({dur:.1f}s)")
                    out_proc = os.path.join(CANDS, fname)
                    d = process(out_raw, out_proc, max_dur=7)
                    if d:
                        candidates.append((fname, source, url.split("/")[-1], d))
                else:
                    print("FAILED")
    
    # ---- 3. Also use the original backup and try to reprocess it ----
    print("\n--- Original backup reprocess ---")
    backup = os.path.join(AUDIO, "_backup", "bobcat_howl.mp3")
    if os.path.exists(backup):
        dur = get_duration(backup)
        print(f"  Original backup: {dur:.1f}s")
        out = os.path.join(CANDS, "original_reprocessed.mp3")
        # Reprocess with different settings - lighter denoise, no highpass
        filters = ["loudnorm=I=-16:TP=-1:LRA=11"]
        subprocess.run([
            "ffmpeg", "-y", "-i", backup, "-af", ",".join(filters),
            "-ac", "1", "-ar", "44100", "-b:a", "192k", out
        ], capture_output=True, timeout=30)
        if os.path.exists(out) and os.path.getsize(out) > 1000:
            d = round(get_duration(out), 1)
            candidates.append(("original_reprocessed.mp3", "Original backup", "reprocessed", d))
            print(f"  Reprocessed: {d}s")
    
    # ---- BUILD PLAYER ----
    print(f"\n{'='*60}")
    print(f"Total candidates: {len(candidates)}")
    
    html = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Bobcat Howl - Final Candidates</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', sans-serif; background: #1a1a2e; color: #eee; padding: 20px; }
        h1 { text-align: center; color: #e94560; margin-bottom: 8px; font-size: 1.6em; }
        .subtitle { text-align: center; color: #888; margin-bottom: 24px; font-size: 0.9em; }
        .section { margin-bottom: 28px; }
        .section h2 { color: #e94560; border-bottom: 1px solid #333; padding-bottom: 6px; margin-bottom: 12px; }
        .card { background: #16213e; border-radius: 10px; padding: 14px 18px; margin-bottom: 10px;
                display: flex; align-items: center; gap: 16px; border: 1px solid #0f3460; }
        .card:hover { border-color: #e94560; }
        .card .info { flex: 1; }
        .card .name { font-weight: 600; font-size: 0.95em; }
        .card .detail { color: #999; font-size: 0.8em; margin-top: 2px; }
        .card .num { background: #e94560; color: #fff; font-weight: 700; font-size: 1.1em;
                     width: 32px; height: 32px; border-radius: 50%; display: flex;
                     align-items: center; justify-content: center; flex-shrink: 0; }
        audio { height: 36px; min-width: 280px; }
        audio::-webkit-media-controls-panel { background: #0f3460; }
        .note { color: #7ec8e3; font-size: 0.85em; text-align: center; margin-bottom: 20px; padding: 10px;
                background: #0f3460; border-radius: 8px; }
    </style>
</head>
<body>
    <h1>Bobcat Howl - Final Round</h1>
    <p class="subtitle">Sources: Acoustic Atlas, other wildlife sound libraries, original backup</p>
    <div class="note">If none of these work, we can keep the original and source this one manually later.</div>
    <div class="section">
        <h2>Candidates</h2>
"""
    
    if not candidates:
        html += '        <p style="color:#666;font-style:italic;padding:10px;">No candidates found from any source</p>\n'
    
    for i, (fname, source, note, dur) in enumerate(candidates):
        html += f"""        <div class="card">
            <div class="num">{i+1}</div>
            <div class="info">
                <div class="name">Option {i+1} - {source}</div>
                <div class="detail">{note} | {dur}s</div>
            </div>
            <audio controls preload="none" src="_candidates/{fname}"></audio>
        </div>\n"""
    
    html += "    </div>\n</body>\n</html>"
    
    with open(os.path.join(AUDIO, "player.html"), "w", encoding="utf-8") as f:
        f.write(html)
    
    print("Player ready!")


if __name__ == "__main__":
    main()
