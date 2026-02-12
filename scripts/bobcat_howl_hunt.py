"""
Focused bobcat howl search.
Strategy: 
  1. Extract multiple segments from the best ML recordings at different timestamps
  2. Try ML recordings that are specifically tagged as bobcat vocalizations
  3. Search for lynx/wildcat howl recordings as alternatives
"""
import os, subprocess, json, struct, wave, math, tempfile

AUDIO = r"c:\Users\neo31\Hunting_Call\assets\audio"
CANDIDATES = os.path.join(AUDIO, "_candidates")
RAW = os.path.join(AUDIO, "_raw_downloads")
os.makedirs(CANDIDATES, exist_ok=True)


def get_duration(path):
    r = subprocess.run(
        ["ffprobe", "-v", "quiet", "-show_entries", "format=duration", "-of", "csv=p=0", path],
        capture_output=True, text=True, timeout=5)
    return float(r.stdout.strip()) if r.stdout.strip() else 0


def ml_download(asset_id, out_path):
    url = f"https://cdn.download.ams.birds.cornell.edu/api/v2/asset/{asset_id}/mp3"
    r = subprocess.run(["curl", "-L", "-f", "-o", out_path,
                        "-H", "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)", url],
                       capture_output=True, timeout=30)
    return os.path.exists(out_path) and os.path.getsize(out_path) > 5000


def download(url, out_path):
    r = subprocess.run(["curl", "-L", "-f", "-o", out_path,
                        "-H", "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)", url],
                       capture_output=True, timeout=30)
    return os.path.exists(out_path) and os.path.getsize(out_path) > 3000


def analyze_energy(path, window_sec=0.5):
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
    filters = [
        f"atrim={start}:{end}", "asetpts=PTS-STARTPTS",
        f"highpass=f={highpass}", f"afftdn=nf={denoise}",
        "loudnorm=I=-16:TP=-1:LRA=11"
    ]
    subprocess.run([
        "ffmpeg", "-y", "-i", src, "-af", ",".join(filters),
        "-ac", "1", "-ar", "44100", "-b:a", "192k", out
    ], capture_output=True, timeout=30)
    
    if os.path.exists(out) and os.path.getsize(out) > 1000:
        return round(get_duration(out), 1)
    return None


def find_top_segments(sections, total_dur, num=5, seg_dur=5, min_skip=5):
    """Find the top N non-overlapping 5-second segments by energy."""
    # Calculate energy for each possible 5s window
    windows = []
    for i, (t, rms) in enumerate(sections):
        if t < min_skip or t + seg_dur > total_dur:
            continue
        energy = sum(r for tt, r in sections if tt >= t and tt < t + seg_dur)
        windows.append((t, energy))
    
    windows.sort(key=lambda x: x[1], reverse=True)
    
    # Pick non-overlapping
    picked = []
    for t, energy in windows:
        if all(abs(t - pt) >= seg_dur for pt, _ in picked):
            picked.append((t, energy))
        if len(picked) >= num:
            break
    
    return picked


def main():
    print("=" * 60)
    print("BOBCAT HOWL HUNT")
    print("=" * 60)
    
    candidates = []
    
    # ---- Strategy 1: Multiple segments from best ML recordings ----
    # ML217641 was 20.5s and had strong energy at 12s - short recording, likely clean
    # ML80695 was 85s with peaks at 29s, 49s, 37s
    # ML80697 was 105s with peaks at 46s, 15s, 60s
    # ML176490 was 254s with peaks throughout
    
    priority_recordings = {
        "ML217641": os.path.join(RAW, "ML217641.mp3"),
        "ML80695": os.path.join(RAW, "ML80695.mp3"),
        "ML80697": os.path.join(RAW, "ML80697.mp3"),
        "ML176490": os.path.join(RAW, "ML176490.mp3"),
        "ML176491": os.path.join(RAW, "ML176491.mp3"),
        "ML98712": os.path.join(RAW, "ML98712.mp3"),
        "ML98713": os.path.join(RAW, "ML98713.mp3"),
    }
    
    option_num = 1
    
    for label, raw_path in priority_recordings.items():
        if not os.path.exists(raw_path):
            continue
        
        dur = get_duration(raw_path)
        print(f"\n  {label}: {dur:.1f}s")
        
        sections = analyze_energy(raw_path, window_sec=0.5)
        if not sections:
            continue
        
        # Find the top 3 non-overlapping 5s segments (skip first 5s for voice intros)
        top_segments = find_top_segments(sections, dur, num=3, seg_dur=5, min_skip=5)
        
        for seg_start, energy in top_segments:
            out_name = f"howl_option{option_num}.mp3"
            out_path = os.path.join(CANDIDATES, out_name)
            d = extract_segment(raw_path, out_path, seg_start, seg_start + 5)
            if d:
                print(f"    Option {option_num}: {seg_start:.0f}-{seg_start+5:.0f}s (energy={energy:.0f}) -> {d}s")
                candidates.append((out_name, label, f"{seg_start:.0f}-{seg_start+5:.0f}s", d))
                option_num += 1
            
            if option_num > 12:
                break
        
        if option_num > 12:
            break
    
    # ---- Strategy 2: Try Canada Lynx recordings (close relative) ----
    print("\n--- Trying Canada Lynx ML recordings ---")
    lynx_ids = ["217643", "217644", "80698", "80699"]
    for ml_id in lynx_ids:
        raw_path = os.path.join(RAW, f"ML{ml_id}.mp3")
        print(f"  ML{ml_id}: ", end="", flush=True)
        if not os.path.exists(raw_path):
            if not ml_download(ml_id, raw_path):
                print("FAILED")
                continue
        
        dur = get_duration(raw_path)
        print(f"OK ({dur:.1f}s)")
        
        sections = analyze_energy(raw_path, window_sec=0.5)
        if not sections:
            continue
        
        top_segments = find_top_segments(sections, dur, num=2, seg_dur=5, min_skip=3)
        
        for seg_start, energy in top_segments:
            out_name = f"howl_option{option_num}.mp3"
            out_path = os.path.join(CANDIDATES, out_name)
            d = extract_segment(raw_path, out_path, seg_start, seg_start + 5)
            if d:
                print(f"    Option {option_num}: {seg_start:.0f}-{seg_start+5:.0f}s -> {d}s")
                candidates.append((out_name, f"Lynx ML{ml_id}", f"{seg_start:.0f}-{seg_start+5:.0f}s", d))
                option_num += 1
        
        if option_num > 16:
            break
    
    # ---- BUILD PLAYER ----
    print(f"\n{'='*60}")
    print(f"Total howl candidates: {len(candidates)}")
    
    html = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Bobcat Howl Candidates</title>
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
    </style>
</head>
<body>
    <h1>Bobcat Howl - Pick One</h1>
    <p class="subtitle">Extracted from multiple ML recordings at peak energy points</p>
    <div class="section">
        <h2>Howl Candidates</h2>
"""
    
    for i, (fname, source, note, dur) in enumerate(candidates):
        html += f"""        <div class="card">
            <div class="num">{i+1}</div>
            <div class="info">
                <div class="name">Option {i+1}</div>
                <div class="detail">{source} | {note} | {dur}s</div>
            </div>
            <audio controls preload="none" src="_candidates/{fname}"></audio>
        </div>\n"""
    
    html += "    </div>\n</body>\n</html>"
    
    with open(os.path.join(AUDIO, "player.html"), "w", encoding="utf-8") as f:
        f.write(html)
    
    print("Player ready!")


if __name__ == "__main__":
    main()
