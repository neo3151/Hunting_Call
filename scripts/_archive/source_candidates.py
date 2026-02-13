"""
Search xeno-canto and Cornell ML for replacement candidates.
Downloads multiple options per species for user to audition.
"""
import os, subprocess, json, sys

AUDIO = r"c:\Users\neo31\Hunting_Call\assets\audio"
CANDIDATES = os.path.join(AUDIO, "_candidates")
os.makedirs(CANDIDATES, exist_ok=True)


def xc_search(query, limit=5):
    """Search xeno-canto API and return recordings."""
    url = f"https://xeno-canto.org/api/2/recordings?query={query}"
    r = subprocess.run(["curl", "-s", "-L", url], capture_output=True, text=True, timeout=15)
    if r.returncode != 0:
        return []
    try:
        data = json.loads(r.stdout)
        return data.get("recordings", [])[:limit]
    except:
        return []


def xc_download(rec, out_path):
    """Download a xeno-canto recording."""
    dl_url = rec.get("file", "")
    if not dl_url:
        return False
    if not dl_url.startswith("http"):
        dl_url = "https:" + dl_url
    r = subprocess.run(["curl", "-L", "-f", "-o", out_path, dl_url], 
                       capture_output=True, timeout=30)
    return os.path.exists(out_path) and os.path.getsize(out_path) > 5000


def ml_download(asset_id, out_path):
    """Download from Cornell Macaulay Library."""
    url = f"https://cdn.download.ams.birds.cornell.edu/api/v2/asset/{asset_id}/mp3"
    r = subprocess.run(["curl", "-L", "-f", "-o", out_path,
                        "-H", "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)", url],
                       capture_output=True, timeout=30)
    if os.path.exists(out_path) and os.path.getsize(out_path) > 5000:
        return True
    if os.path.exists(out_path):
        os.unlink(out_path)
    return False


def process(raw_path, out_path, max_dur=10, highpass=80, denoise=-25):
    """Process: trim, filter, normalize."""
    # Get duration
    r = subprocess.run(
        ["ffprobe", "-v", "quiet", "-show_entries", "format=duration", "-of", "csv=p=0", raw_path],
        capture_output=True, text=True, timeout=5)
    dur = float(r.stdout.strip()) if r.stdout.strip() else 0
    
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
        r2 = subprocess.run(
            ["ffprobe", "-v", "quiet", "-show_entries", "format=duration", "-of", "csv=p=0", out_path],
            capture_output=True, text=True, timeout=5)
        return round(float(r2.stdout.strip()), 1)
    return None


def main():
    print("=" * 60)
    print("SOURCING REPLACEMENT CANDIDATES")
    print("=" * 60)
    
    all_candidates = {}
    
    # ---- AMERICAN CROW ----
    print("\n--- American Crow - Standard Caw ---")
    crow_recs = xc_search("Corvus+brachyrhynchos+q:A+type:call", limit=5)
    print(f"  xeno-canto: {len(crow_recs)} quality-A call recordings found")
    
    crow_candidates = []
    for i, rec in enumerate(crow_recs[:3]):
        xc_id = rec.get("id", "?")
        length = rec.get("length", "?")
        loc = rec.get("loc", "?")
        rmk = rec.get("rmk", "")[:60]
        print(f"  XC{xc_id} | {length} | {loc} | {rmk}")
        
        raw = os.path.join(CANDIDATES, f"crow_xc{xc_id}_raw.mp3")
        out = os.path.join(CANDIDATES, f"crow_option{i+1}.mp3")
        if xc_download(rec, raw):
            dur = process(raw, out, max_dur=10)
            if dur:
                crow_candidates.append((f"crow_option{i+1}.mp3", f"XC{xc_id}", loc, dur))
                print(f"    -> crow_option{i+1}.mp3 ({dur}s)")
    
    # Also try ML assets
    ml_crow_ids = ["620335621", "406406431", "195292"]
    for j, ml_id in enumerate(ml_crow_ids):
        raw = os.path.join(CANDIDATES, f"crow_ml{ml_id}_raw.mp3")
        out = os.path.join(CANDIDATES, f"crow_option{len(crow_candidates)+1}.mp3")
        print(f"  Trying ML{ml_id}...")
        if ml_download(ml_id, raw):
            dur = process(raw, out, max_dur=10)
            if dur:
                crow_candidates.append((f"crow_option{len(crow_candidates)+1}.mp3", f"ML{ml_id}", "Cornell", dur))
                print(f"    -> crow_option{len(crow_candidates)}.mp3 ({dur}s)")
        if len(crow_candidates) >= 4:
            break
    
    all_candidates["crow"] = crow_candidates
    
    # ---- RED STAG ROAR ----
    print("\n--- Red Stag - Roar ---")
    stag_recs = xc_search("Cervus+elaphus+q:A", limit=5)
    print(f"  xeno-canto: {len(stag_recs)} quality-A recordings found")
    
    stag_candidates = []
    for i, rec in enumerate(stag_recs[:3]):
        xc_id = rec.get("id", "?")
        length = rec.get("length", "?")
        loc = rec.get("loc", "?")
        rmk = rec.get("rmk", "")[:60]
        print(f"  XC{xc_id} | {length} | {loc} | {rmk}")
        
        raw = os.path.join(CANDIDATES, f"stag_xc{xc_id}_raw.mp3")
        out = os.path.join(CANDIDATES, f"stag_option{i+1}.mp3")
        if xc_download(rec, raw):
            dur = process(raw, out, max_dur=10, highpass=60, denoise=-20)
            if dur:
                stag_candidates.append((f"stag_option{i+1}.mp3", f"XC{xc_id}", loc, dur))
                print(f"    -> stag_option{i+1}.mp3 ({dur}s)")
    
    # ML assets for red deer
    ml_stag_ids = ["204709", "135022", "204637", "135023"]
    for ml_id in ml_stag_ids:
        raw = os.path.join(CANDIDATES, f"stag_ml{ml_id}_raw.mp3")
        out = os.path.join(CANDIDATES, f"stag_option{len(stag_candidates)+1}.mp3")
        print(f"  Trying ML{ml_id}...")
        if ml_download(ml_id, raw):
            dur = process(raw, out, max_dur=10, highpass=60, denoise=-20)
            if dur:
                stag_candidates.append((f"stag_option{len(stag_candidates)+1}.mp3", f"ML{ml_id}", "Cornell", dur))
                print(f"    -> stag_option{len(stag_candidates)}.mp3 ({dur}s)")
        if len(stag_candidates) >= 4:
            break
    
    all_candidates["stag"] = stag_candidates
    
    # ---- BOBCAT DEEP GROWL ----
    print("\n--- Bobcat - Deep Growl ---")
    bobcat_recs = xc_search("Lynx+rufus+q:A", limit=5)
    print(f"  xeno-canto: {len(bobcat_recs)} quality-A recordings found")
    
    bobcat_growl_candidates = []
    for i, rec in enumerate(bobcat_recs[:3]):
        xc_id = rec.get("id", "?")
        length = rec.get("length", "?")
        loc = rec.get("loc", "?")
        rec_type = rec.get("type", "?")
        print(f"  XC{xc_id} | {length} | {rec_type} | {loc}")
        
        raw = os.path.join(CANDIDATES, f"bobcat_growl_xc{xc_id}_raw.mp3")
        out = os.path.join(CANDIDATES, f"bobcat_growl_option{i+1}.mp3")
        if xc_download(rec, raw):
            dur = process(raw, out, max_dur=5, highpass=60, denoise=-20)
            if dur:
                bobcat_growl_candidates.append((f"bobcat_growl_option{i+1}.mp3", f"XC{xc_id}", loc, dur))
                print(f"    -> bobcat_growl_option{i+1}.mp3 ({dur}s)")
    
    # ML assets for bobcat
    ml_bobcat_ids = ["176488", "82694", "345922", "345923", "345924"]
    for ml_id in ml_bobcat_ids:
        raw = os.path.join(CANDIDATES, f"bobcat_growl_ml{ml_id}_raw.mp3")
        out = os.path.join(CANDIDATES, f"bobcat_growl_option{len(bobcat_growl_candidates)+1}.mp3")
        print(f"  Trying ML{ml_id}...")
        if ml_download(ml_id, raw):
            dur = process(raw, out, max_dur=5, highpass=60, denoise=-20)
            if dur:
                bobcat_growl_candidates.append((f"bobcat_growl_option{len(bobcat_growl_candidates)+1}.mp3", f"ML{ml_id}", "Cornell", dur))
                print(f"    -> bobcat_growl_option{len(bobcat_growl_candidates)}.mp3 ({dur}s)")
        if len(bobcat_growl_candidates) >= 4:
            break
    
    all_candidates["bobcat_growl"] = bobcat_growl_candidates
    
    # ---- BOBCAT HOWL ----
    print("\n--- Bobcat - Howl ---")
    # Reuse bobcat xeno-canto results if any, plus different ML assets
    bobcat_howl_candidates = []
    
    # Try broader xeno-canto search
    bobcat_broad = xc_search("Lynx+rufus+q:B", limit=5)
    print(f"  xeno-canto: {len(bobcat_broad)} quality-B recordings found")
    for i, rec in enumerate(bobcat_broad[:2]):
        xc_id = rec.get("id", "?")
        length = rec.get("length", "?")
        loc = rec.get("loc", "?")
        rec_type = rec.get("type", "?")
        print(f"  XC{xc_id} | {length} | {rec_type} | {loc}")
        
        raw = os.path.join(CANDIDATES, f"bobcat_howl_xc{xc_id}_raw.mp3")
        out = os.path.join(CANDIDATES, f"bobcat_howl_option{i+1}.mp3")
        if xc_download(rec, raw):
            dur = process(raw, out, max_dur=5, highpass=60, denoise=-20)
            if dur:
                bobcat_howl_candidates.append((f"bobcat_howl_option{i+1}.mp3", f"XC{xc_id}", loc, dur))
                print(f"    -> bobcat_howl_option{i+1}.mp3 ({dur}s)")
    
    # Different ML assets for howl-like vocalizations
    ml_howl_ids = ["345922", "345923", "345924", "345925", "176489"]
    for ml_id in ml_howl_ids:
        raw = os.path.join(CANDIDATES, f"bobcat_howl_ml{ml_id}_raw.mp3")
        out = os.path.join(CANDIDATES, f"bobcat_howl_option{len(bobcat_howl_candidates)+1}.mp3")
        print(f"  Trying ML{ml_id}...")
        if ml_download(ml_id, raw):
            dur = process(raw, out, max_dur=5, highpass=60, denoise=-20)
            if dur:
                bobcat_howl_candidates.append((f"bobcat_howl_option{len(bobcat_howl_candidates)+1}.mp3", f"ML{ml_id}", "Cornell", dur))
                print(f"    -> bobcat_howl_option{len(bobcat_howl_candidates)}.mp3 ({dur}s)")
        if len(bobcat_howl_candidates) >= 4:
            break
    
    all_candidates["bobcat_howl"] = bobcat_howl_candidates
    
    # ---- BUILD REVIEW PLAYER ----
    print("\n" + "=" * 60)
    print("BUILDING REVIEW PLAYER")
    print("=" * 60)
    
    html = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Audio Candidate Review</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', sans-serif; background: #1a1a2e; color: #eee; padding: 20px; }
        h1 { text-align: center; color: #e94560; margin-bottom: 8px; font-size: 1.6em; }
        .subtitle { text-align: center; color: #888; margin-bottom: 24px; font-size: 0.9em; }
        .section { margin-bottom: 28px; }
        .section h2 { color: #e94560; border-bottom: 1px solid #333; padding-bottom: 6px; margin-bottom: 12px; font-size: 1.1em; }
        .card { background: #16213e; border-radius: 10px; padding: 14px 18px; margin-bottom: 10px;
                display: flex; align-items: center; gap: 16px; border: 1px solid #0f3460; transition: border-color 0.2s; }
        .card:hover { border-color: #e94560; }
        .card .info { flex: 1; }
        .card .name { font-weight: 600; font-size: 0.95em; }
        .card .detail { color: #999; font-size: 0.8em; margin-top: 2px; }
        .card .option-num { background: #e94560; color: #fff; font-weight: 700; font-size: 1.1em;
                           width: 32px; height: 32px; border-radius: 50%; display: flex;
                           align-items: center; justify-content: center; flex-shrink: 0; }
        audio { height: 36px; min-width: 280px; }
        audio::-webkit-media-controls-panel { background: #0f3460; }
        .empty { color: #666; font-style: italic; padding: 10px; }
    </style>
</head>
<body>
    <h1>Pick Your Favorites</h1>
    <p class="subtitle">Multiple candidates per call &mdash; listen and tell me your pick (e.g. "crow option 2, stag option 1")</p>
"""
    
    sections = [
        ("crow", "Crow - Standard Caw"),
        ("stag", "Red Stag - Roar"),
        ("bobcat_growl", "Bobcat - Deep Growl"),
        ("bobcat_howl", "Bobcat - Howl"),
    ]
    
    for key, title in sections:
        candidates = all_candidates.get(key, [])
        html += f'    <div class="section">\n        <h2>{title}</h2>\n'
        if not candidates:
            html += '        <p class="empty">No candidates found</p>\n'
        for i, (fname, source, loc, dur) in enumerate(candidates):
            html += f"""        <div class="card">
            <div class="option-num">{i+1}</div>
            <div class="info">
                <div class="name">Option {i+1}</div>
                <div class="detail">{source} | {loc} | {dur}s</div>
            </div>
            <audio controls preload="none" src="_candidates/{fname}"></audio>
        </div>\n"""
        html += '    </div>\n'
    
    html += "</body>\n</html>"
    
    player_path = os.path.join(AUDIO, "player.html")
    with open(player_path, "w", encoding="utf-8") as f:
        f.write(html)
    
    # Summary
    print("\nCANDIDATES SUMMARY:")
    total = 0
    for key, title in sections:
        candidates = all_candidates.get(key, [])
        print(f"  {title}: {len(candidates)} options")
        total += len(candidates)
    print(f"\nTotal: {total} candidates ready for review")
    print(f"Player: {player_path}")


if __name__ == "__main__":
    main()
