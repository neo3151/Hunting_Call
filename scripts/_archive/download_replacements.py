"""
Download and process replacement audio for 4 rejected files.

Targets:
  1. crow.mp3         — American ndard caw
  2. red_stag_roar.mp3 — Red Deer stag roar/bellow
  3. bobcat_growl_v2.mp3 — Bobcat deep growl
  4. bobcat_howl.mp3   — Bobcat howl

Sources: Cornell Macaulay Library (direct MP4 audio stream)
Processing: trim → denoise → normalize → export MP3
"""
import os, subprocess, tempfile, json, sys

AUDIO = r"c:\Users\neo31\Hunting_Call\assets\audio"
RAW = os.path.join(AUDIO, "_raw_downloads")
os.makedirs(RAW, exist_ok=True)

# Cornell Macaulay Library asset IDs — high-rated, isolated recordings
# Format: (asset_id, output_filename, description, trim_start, trim_end, target_dur)
SOURCES = [
    # American Crow — ML25988861 (5.0★, two birds calling from treetops)
    ("25988861", "crow.mp3", "American Crow — Standard Caw", 0, 12, 10),
    # Red Deer — ML204638 (classic stag roar)
    ("204638", "red_stag_roar.mp3", "Red Stag — Roar", 0, 15, 10),
    # Bobcat — ML176488 (growl vocalization)
    ("176488", "bobcat_growl_v2.mp3", "Bobcat — Deep Growl", 0, 10, 5),
    # Bobcat — ML345925 (howl/yowl)
    ("345925", "bobcat_howl.mp3", "Bobcat — Howl", 0, 10, 5),
]

# Alternate sources in case primaries fail
ALT_SOURCES = {
    "crow.mp3": [
        ("13123", "American Crow — Caw notes (alt)"),
        ("620335621", "American Crow — Caw (alt2)"),
    ],
    "red_stag_roar.mp3": [
        ("135022", "Red Deer — Roar (alt)"),
        ("204709", "Red Deer — Bellowing (alt2)"),
    ],
    "bobcat_growl_v2.mp3": [
        ("82694", "Bobcat — Vocalization (alt)"),
    ],
    "bobcat_howl.mp3": [
        ("82694", "Bobcat — Vocalization (alt)"),
    ],
}


def download_ml_audio(asset_id, out_path):
    """Download audio from Cornell Macaulay Library."""
    # ML serves audio via their CDN
    url = f"https://cdn.download.ams.birds.cornell.edu/api/v2/asset/{asset_id}/mp3"
    print(f"  Downloading ML{asset_id} from {url}")
    
    result = subprocess.run([
        "curl", "-L", "-f", "-o", out_path,
        "-H", "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
        url
    ], capture_output=True, text=True, timeout=30)
    
    if result.returncode != 0:
        # Try alternate URL format
        url2 = f"https://cdn.download.ams.birds.cornell.edu/api/v1/asset/{asset_id}"
        print(f"  Trying alternate URL: {url2}")
        result = subprocess.run([
            "curl", "-L", "-f", "-o", out_path,
            "-H", "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
            url2
        ], capture_output=True, text=True, timeout=30)
    
    if os.path.exists(out_path) and os.path.getsize(out_path) > 5000:
        sz = os.path.getsize(out_path) // 1024
        print(f"  Downloaded: {sz}KB")
        return True
    
    # Clean up failed download
    if os.path.exists(out_path):
        os.unlink(out_path)
    print(f"  FAILED to download ML{asset_id}")
    return False


def process_audio(raw_path, out_path, trim_start, trim_end, target_dur, description):
    """Process raw audio: trim, denoise, normalize, export as MP3."""
    print(f"\n  Processing: {description}")
    
    # Get duration of raw file
    result = subprocess.run(
        ["ffprobe", "-v", "quiet", "-show_entries", "format=duration", "-of", "csv=p=0", raw_path],
        capture_output=True, text=True, timeout=5
    )
    raw_dur = float(result.stdout.strip()) if result.stdout.strip() else 0
    print(f"  Raw duration: {raw_dur:.1f}s")
    
    # Build filter chain
    filters = []
    
    # Trim
    actual_end = min(trim_end, raw_dur) if trim_end else raw_dur
    actual_end = min(actual_end, trim_start + target_dur)
    if trim_start > 0 or actual_end < raw_dur:
        filters.append(f"atrim={trim_start}:{actual_end}")
        filters.append("asetpts=PTS-STARTPTS")
    
    # High-pass to remove rumble
    filters.append("highpass=f=80")
    
    # Light denoise 
    filters.append("afftdn=nf=-25")
    
    # Normalize loudness
    filters.append("loudnorm=I=-16:TP=-1:LRA=11")
    
    filter_str = ",".join(filters)
    
    result = subprocess.run([
        "ffmpeg", "-y", "-i", raw_path,
        "-af", filter_str,
        "-ac", "1", "-ar", "44100", "-b:a", "192k",
        out_path
    ], capture_output=True, text=True, timeout=30)
    
    if os.path.exists(out_path) and os.path.getsize(out_path) > 1000:
        # Get output duration
        r2 = subprocess.run(
            ["ffprobe", "-v", "quiet", "-show_entries", "format=duration", "-of", "csv=p=0", out_path],
            capture_output=True, text=True, timeout=5
        )
        new_dur = round(float(r2.stdout.strip()), 1)
        sz = os.path.getsize(out_path) // 1024
        print(f"  OUTPUT: {new_dur}s ({sz}KB)")
        return new_dur
    
    print(f"  FAILED processing")
    return None


def try_xeno_canto_crow():
    """Try xeno-canto for American Crow as fallback."""
    print("\n  Trying xeno-canto for American Crow...")
    # XC has great bird audio. Search for American Crow
    url = "https://xeno-canto.org/api/2/recordings?query=Corvus+brachyrhynchos+q:A+type:call"
    result = subprocess.run([
        "curl", "-s", "-L", url
    ], capture_output=True, text=True, timeout=15)
    
    if result.returncode == 0 and result.stdout:
        try:
            data = json.loads(result.stdout)
            recordings = data.get("recordings", [])
            # Get first high-quality recording
            for rec in recordings[:5]:
                dl_url = rec.get("file")
                if dl_url:
                    if not dl_url.startswith("http"):
                        dl_url = "https:" + dl_url
                    raw_path = os.path.join(RAW, "crow_xc.mp3")
                    print(f"  Downloading from xeno-canto: {dl_url}")
                    dl = subprocess.run([
                        "curl", "-L", "-f", "-o", raw_path, dl_url
                    ], capture_output=True, timeout=20)
                    if os.path.exists(raw_path) and os.path.getsize(raw_path) > 5000:
                        return raw_path
        except json.JSONDecodeError:
            pass
    return None


def try_xeno_canto_species(species_name, query_extra="q:A", filename_prefix="xc"):
    """Try xeno-canto for any bird species."""
    print(f"\n  Trying xeno-canto for {species_name}...")
    query = species_name.replace(" ", "+") + "+" + query_extra
    url = f"https://xeno-canto.org/api/2/recordings?query={query}"
    result = subprocess.run([
        "curl", "-s", "-L", url
    ], capture_output=True, text=True, timeout=15)
    
    if result.returncode == 0 and result.stdout:
        try:
            data = json.loads(result.stdout)
            recordings = data.get("recordings", [])
            for rec in recordings[:5]:
                dl_url = rec.get("file")
                if dl_url:
                    if not dl_url.startswith("http"):
                        dl_url = "https:" + dl_url
                    raw_path = os.path.join(RAW, f"{filename_prefix}.mp3")
                    print(f"  Downloading: {dl_url}")
                    dl = subprocess.run([
                        "curl", "-L", "-f", "-o", raw_path, dl_url
                    ], capture_output=True, timeout=20)
                    if os.path.exists(raw_path) and os.path.getsize(raw_path) > 5000:
                        return raw_path
        except json.JSONDecodeError:
            pass
    return None


def main():
    print("=" * 60)
    print("REPLACEMENT AUDIO DOWNLOAD & PROCESS")
    print("=" * 60)
    
    results = {}
    
    for asset_id, out_filename, description, trim_start, trim_end, target_dur in SOURCES:
        print(f"\n{'─'*60}")
        print(f"  {out_filename}: {description}")
        
        raw_path = os.path.join(RAW, f"ML{asset_id}.mp3")
        out_path = os.path.join(AUDIO, out_filename)
        
        # Try primary download
        success = download_ml_audio(asset_id, raw_path)
        
        # Try alternates if primary fails
        if not success and out_filename in ALT_SOURCES:
            for alt_id, alt_desc in ALT_SOURCES[out_filename]:
                print(f"\n  Trying alternate: {alt_desc}")
                raw_path = os.path.join(RAW, f"ML{alt_id}.mp3")
                success = download_ml_audio(alt_id, raw_path)
                if success:
                    break
        
        # Try xeno-canto for crow if ML fails
        if not success and out_filename == "crow.mp3":
            xc_path = try_xeno_canto_crow()
            if xc_path:
                raw_path = xc_path
                success = True
        
        if success:
            dur = process_audio(raw_path, out_path, trim_start, trim_end, target_dur, description)
            results[out_filename] = dur
        else:
            print(f"  SKIPPED — no source available")
            results[out_filename] = None
    
    # Summary
    print(f"\n{'='*60}")
    print("RESULTS")
    print(f"{'='*60}")
    ok = 0
    for fname, dur in results.items():
        if dur is not None:
            print(f"  [OK] {fname:30s} {dur}s")
            ok += 1
        else:
            print(f"  [XX] {fname}")
    print(f"\n{ok}/{len(results)} completed")
    
    # Save durations
    dur_map = {k: v for k, v in results.items() if v is not None}
    if dur_map:
        with open(os.path.join(RAW, "_replacement_durations.json"), "w") as f:
            json.dump(dur_map, f, indent=2)
    
    return ok


if __name__ == "__main__":
    sys.exit(0 if main() == len(SOURCES) else 1)
