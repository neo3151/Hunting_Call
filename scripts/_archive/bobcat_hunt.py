"""
Find bobcat deep growl and howl recordings.
Strategy:
  1. Analyze the raw ML recordings we already downloaded — skip past voice intros
  2. Try Freesound.org API
  3. Try direct downloads from SoundBible / OrangeFreeSounds
"""
import os, subprocess, json, struct, wave, math, tempfile

AUDIO = r"c:\Users\neo31\Hunting_Call\assets\audio"
CANDIDATES = os.path.join(AUDIO, "_candidates")
RAW = os.path.join(AUDIO, "_raw_downloads")


def get_duration(path):
    r = subprocess.run(
        ["ffprobe", "-v", "quiet", "-show_entries", "format=duration", "-of", "csv=p=0", path],
        capture_output=True, text=True, timeout=5)
    return float(r.stdout.strip()) if r.stdout.strip() else 0


def analyze_sections(path, window_sec=1.0):
    """Analyze a recording in 1-second windows to find the loudest sections."""
    # Convert to WAV
    tmp = tempfile.NamedTemporaryFile(suffix=".wav", delete=False).name
    subprocess.run(["ffmpeg", "-y", "-i", path, "-ac", "1", "-ar", "44100", 
                    "-acodec", "pcm_s16le", tmp], capture_output=True, timeout=15)
    
    with wave.open(tmp, "rb") as w:
        n = w.getnframes()
        raw = w.readframes(n)
        sr = w.getframerate()
    
    samples = list(struct.unpack("<" + str(n) + "h", raw))
    window = int(sr * window_sec)
    
    sections = []
    for i in range(0, len(samples) - window, window):
        chunk = samples[i:i + window]
        rms = math.sqrt(sum(s * s for s in chunk) / len(chunk))
        t = i / sr
        sections.append((t, rms))
    
    os.unlink(tmp)
    return sections


def extract_segment(src, out, start, end, highpass=60, denoise=-20):
    """Extract and process a segment from a recording."""
    filters = [
        f"atrim={start}:{end}",
        "asetpts=PTS-STARTPTS",
        f"highpass=f={highpass}",
        f"afftdn=nf={denoise}",
        "loudnorm=I=-16:TP=-1:LRA=11"
    ]
    subprocess.run([
        "ffmpeg", "-y", "-i", src,
        "-af", ",".join(filters),
        "-ac", "1", "-ar", "44100", "-b:a", "192k", out
    ], capture_output=True, timeout=30)
    
    if os.path.exists(out) and os.path.getsize(out) > 1000:
        return get_duration(out)
    return None


def download(url, out_path):
    """Download a file."""
    r = subprocess.run(["curl", "-L", "-f", "-o", out_path,
                        "-H", "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)", url],
                       capture_output=True, timeout=30)
    return os.path.exists(out_path) and os.path.getsize(out_path) > 3000


def ml_download(asset_id, out_path):
    url = f"https://cdn.download.ams.birds.cornell.edu/api/v2/asset/{asset_id}/mp3"
    return download(url, out_path)


def process_full(raw_path, out_path, max_dur=5, highpass=60, denoise=-20):
    """Process: trim, filter, normalize."""
    dur = get_duration(raw_path)
    filters = []
    end = min(dur, max_dur)
    filters.append(f"atrim=0:{end}")
    filters.append("asetpts=PTS-STARTPTS")
    if highpass > 0:
        filters.append(f"highpass=f={highpass}")
    if denoise != 0:
        filters.append(f"afftdn=nf={denoise}")
    filters.append("loudnorm=I=-16:TP=-1:LRA=11")
    
    subprocess.run([
        "ffmpeg", "-y", "-i", raw_path,
        "-af", ",".join(filters),
        "-ac", "1", "-ar", "44100", "-b:a", "192k", out_path
    ], capture_output=True, timeout=30)
    
    if os.path.exists(out_path) and os.path.getsize(out_path) > 1000:
        return round(get_duration(out_path), 1)
    return None


def main():
    print("=" * 60)
    print("BOBCAT RECORDING HUNT")
    print("=" * 60)
    
    candidates_growl = []
    candidates_howl = []
    
    # ---- Strategy 1: Analyze raw ML recordings, skip to animal sounds ----
    print("\n--- Analyzing raw ML recordings for actual bobcat sounds ---")
    
    raw_files = {
        "ML176488": os.path.join(RAW, "ML176488.mp3"),
        "ML82694": os.path.join(RAW, "ML82694.mp3"),
        "ML176489": os.path.join(RAW, "bobcat_howl_ml176489_raw.mp3"),
    }
    
    # Also try more ML assets we haven't tried yet
    new_ml_ids = ["176490", "176491", "176492", "217640", "217641", "217642",
                  "80695", "80696", "80697", "98712", "98713"]
    
    for ml_id in new_ml_ids:
        raw_path = os.path.join(RAW, f"ML{ml_id}.mp3")
        if not os.path.exists(raw_path):
            print(f"  Downloading ML{ml_id}...")
            if ml_download(ml_id, raw_path):
                raw_files[f"ML{ml_id}"] = raw_path
                print(f"    Downloaded ({os.path.getsize(raw_path)//1024}KB)")
    
    for label, raw_path in raw_files.items():
        if not os.path.exists(raw_path):
            continue
        
        dur = get_duration(raw_path)
        print(f"\n  {label}: {dur:.1f}s total")
        
        # Analyze energy sections
        sections = analyze_sections(raw_path)
        if not sections:
            continue
        
        # Find the loudest sections (likely animal, not human voice)
        peak_rms = max(s[1] for s in sections)
        loud_sections = [(t, rms) for t, rms in sections if rms > peak_rms * 0.3]
        
        print(f"  Energy profile (top sections):")
        for t, rms in sorted(sections, key=lambda x: x[1], reverse=True)[:5]:
            pct = rms / peak_rms * 100
            print(f"    {t:.0f}s: {'#' * int(pct/5)} ({pct:.0f}%)")
        
        # Try extracting from different points - skip first 5-15s (voice intro range)
        for skip in [5, 10, 15, 20]:
            if skip + 5 > dur:
                continue
            
            # Find the loudest 5-second window starting from this skip point
            best_start = skip
            best_energy = 0
            for t, rms in sections:
                if t >= skip and t + 5 <= dur:
                    # Sum energy over 5 seconds
                    window_energy = sum(r for tt, r in sections if tt >= t and tt < t + 5)
                    if window_energy > best_energy:
                        best_energy = window_energy
                        best_start = t
            
            out_name = f"bobcat_{label}_skip{skip}s.mp3"
            out_path = os.path.join(CANDIDATES, out_name)
            
            d = extract_segment(raw_path, out_path, best_start, best_start + 5)
            if d:
                print(f"    Extracted {best_start:.0f}-{best_start+5:.0f}s -> {out_name} ({d:.1f}s)")
                candidates_growl.append((out_name, label, f"skip {skip}s", d))
    
    # ---- Strategy 2: Freesound API ----
    print("\n--- Searching Freesound.org ---")
    # Freesound needs API key, try without
    fs_urls = [
        ("https://freesound.org/apiv2/search/text/?query=bobcat+growl&filter=duration:[1 TO 15]&sort=rating_desc&token=", "Freesound bobcat growl"),
        ("https://freesound.org/apiv2/search/text/?query=bobcat+howl&filter=duration:[1 TO 15]&sort=rating_desc&token=", "Freesound bobcat howl"),
    ]
    print("  (Freesound requires API key - trying direct downloads instead)")
    
    # ---- Strategy 3: Try direct download URLs from known sources ----
    print("\n--- Trying direct download sources ---")
    
    direct_sources = [
        # SoundBible bobcat
        ("https://soundbible.com/grab.php?id=2177&type=mp3", "bobcat_soundbible.mp3", "SoundBible Bobcat"),
        # OrangeFreeSounds
        ("https://orangefreesounds.com/wp-content/uploads/2022/09/Bobcat-sound.mp3", "bobcat_ofs.mp3", "OrangeFreeSounds Bobcat"),
    ]
    
    for url, fname, desc in direct_sources:
        raw_path = os.path.join(RAW, fname)
        print(f"  {desc}: ", end="")
        if download(url, raw_path):
            dur = get_duration(raw_path)
            print(f"OK ({dur:.1f}s)")
            
            # Process for growl candidate
            out = os.path.join(CANDIDATES, f"bobcat_growl_{fname}")
            d = process_full(raw_path, out, max_dur=5)
            if d:
                candidates_growl.append((f"bobcat_growl_{fname}", desc, "direct", d))
            
            # Also process for howl candidate (different section if long enough)
            if dur > 5:
                out2 = os.path.join(CANDIDATES, f"bobcat_howl_{fname}")
                d2 = extract_segment(raw_path, out2, 5, min(dur, 10))
                if d2:
                    candidates_howl.append((f"bobcat_howl_{fname}", desc, "second half", d2))
        else:
            print("FAILED")

    # ---- Strategy 4: Try more Cornell ML with different species/tags ---- 
    print("\n--- Trying additional ML assets ---")
    # Try searching for bobcat-related ML IDs in higher ranges
    extra_ml = ["505544251", "368827681", "308274251", "263148451"]
    for ml_id in extra_ml:
        raw_path = os.path.join(RAW, f"ML{ml_id}.mp3")
        print(f"  ML{ml_id}: ", end="")
        if ml_download(ml_id, raw_path):
            dur = get_duration(raw_path)
            print(f"OK ({dur:.1f}s)")
            
            # Analyze and extract best section
            sections = analyze_sections(raw_path)
            if sections:
                peak_rms = max(s[1] for s in sections)
                # Skip first 3s to avoid any intro
                best_start = 3
                best_energy = 0
                for t, rms in sections:
                    if t >= 3 and t + 5 <= dur:
                        window_energy = sum(r for tt, r in sections if tt >= t and tt < t + 5)
                        if window_energy > best_energy:
                            best_energy = window_energy
                            best_start = t
                
                out = os.path.join(CANDIDATES, f"bobcat_ml{ml_id}.mp3")
                d = extract_segment(raw_path, out, best_start, min(best_start + 5, dur))
                if d:
                    candidates_growl.append((f"bobcat_ml{ml_id}.mp3", f"ML{ml_id}", f"from {best_start:.0f}s", d))
                    print(f"    Extracted -> bobcat_ml{ml_id}.mp3 ({d:.1f}s)")
        else:
            print("FAILED")

    # ---- BUILD PLAYER ----
    print("\n" + "=" * 60)
    print("BUILDING REVIEW PLAYER")
    
    # Deduplicate and take best candidates
    all_growl = candidates_growl[:6]
    all_howl = candidates_howl[:6]
    
    # If we don't have howl-specific candidates, reuse some growl ones
    if not all_howl:
        all_howl = all_growl[len(all_growl)//2:] if len(all_growl) > 2 else all_growl
    
    html = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Bobcat Audio Candidates</title>
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
        .empty { color: #666; font-style: italic; padding: 10px; }
    </style>
</head>
<body>
    <h1>Bobcat Audio Candidates</h1>
    <p class="subtitle">Extracted past voice intros &mdash; pick your favorite for growl and howl</p>
"""
    
    html += '    <div class="section">\n        <h2>Deep Growl Candidates</h2>\n'
    if not all_growl:
        html += '        <p class="empty">No candidates found</p>\n'
    for i, (fname, source, note, dur) in enumerate(all_growl):
        html += f"""        <div class="card">
            <div class="num">{i+1}</div>
            <div class="info">
                <div class="name">Growl Option {i+1}</div>
                <div class="detail">{source} | {note} | {dur}s</div>
            </div>
            <audio controls preload="none" src="_candidates/{fname}"></audio>
        </div>\n"""
    html += '    </div>\n'
    
    html += '    <div class="section">\n        <h2>Howl Candidates</h2>\n'
    if not all_howl:
        html += '        <p class="empty">No candidates found</p>\n'
    for i, (fname, source, note, dur) in enumerate(all_howl):
        html += f"""        <div class="card">
            <div class="num">{i+1}</div>
            <div class="info">
                <div class="name">Howl Option {i+1}</div>
                <div class="detail">{source} | {note} | {dur}s</div>
            </div>
            <audio controls preload="none" src="_candidates/{fname}"></audio>
        </div>\n"""
    html += '    </div>\n'
    
    html += "</body>\n</html>"
    
    with open(os.path.join(AUDIO, "player.html"), "w", encoding="utf-8") as f:
        f.write(html)
    
    print(f"\nGrowl candidates: {len(all_growl)}")
    print(f"Howl candidates: {len(all_howl)}")
    print(f"Player ready!")


if __name__ == "__main__":
    main()
