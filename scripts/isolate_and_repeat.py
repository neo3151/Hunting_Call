"""
Isolate specific calls within recordings, then repeat the isolated call.

Method:
  1. Convert to WAV, analyze energy in 50ms windows
  2. Find energy bursts (individual calls) using adaptive thresholding 
  3. Extract the strongest/best burst as "the call"
  4. Repeat the isolated call with a brief gap
  5. Normalize and export as MP3

Each file gets custom settings based on user's review notes.
"""
import os, subprocess, shutil, struct, wave, math, tempfile, json

AUDIO = r"c:\Users\neo31\Hunting_Call\assets\audio"


def analyze_energy(wav_path, window_ms=50):
    """Analyze energy in windows, return list of (time_sec, rms) tuples."""
    with wave.open(wav_path, "rb") as w:
        n = w.getnframes()
        raw = w.readframes(n)
        sr = w.getframerate()
        ch = w.getnchannels()
    
    samples = list(struct.unpack("<" + str(n * ch) + "h", raw))
    if ch == 2:
        samples = [(samples[i] + samples[i+1]) // 2 for i in range(0, len(samples), 2)]
    
    window = int(sr * window_ms / 1000)
    energies = []
    for i in range(0, len(samples), window):
        chunk = samples[i:i + window]
        if len(chunk) < window // 2:
            break
        rms = math.sqrt(sum(s * s for s in chunk) / len(chunk))
        t = i / sr
        energies.append((t, rms))
    
    return energies, sr, len(samples) / sr


def find_bursts(energies, threshold_ratio=0.2, min_gap_sec=0.15):
    """Find energy bursts (individual call events). Returns list of (start_sec, end_sec, peak_rms)."""
    if not energies:
        return []
    
    peak = max(e[1] for e in energies)
    threshold = peak * threshold_ratio
    
    bursts = []
    in_burst = False
    burst_start = 0
    burst_peak = 0
    
    for t, rms in energies:
        if rms >= threshold:
            if not in_burst:
                burst_start = t
                in_burst = True
                burst_peak = rms
            else:
                burst_peak = max(burst_peak, rms)
        else:
            if in_burst:
                bursts.append((burst_start, t, burst_peak))
                in_burst = False
    
    if in_burst:
        bursts.append((burst_start, energies[-1][0], burst_peak))
    
    # Merge bursts that are very close together (< min_gap_sec apart)
    if len(bursts) > 1:
        merged = [bursts[0]]
        for b in bursts[1:]:
            prev = merged[-1]
            if b[0] - prev[1] < min_gap_sec:
                merged[-1] = (prev[0], b[1], max(prev[2], b[2]))
            else:
                merged.append(b)
        bursts = merged
    
    return bursts


def pick_best_burst(bursts, min_dur=0.1, prefer_longest=False):
    """Pick the most prominent burst. Returns (start, end)."""
    valid = [(s, e, p) for s, e, p in bursts if (e - s) >= min_dur]
    if not valid:
        return bursts[0][:2] if bursts else (0, 1)
    
    if prefer_longest:
        valid.sort(key=lambda x: x[1] - x[0], reverse=True)
    else:
        # Prefer highest energy
        valid.sort(key=lambda x: x[2], reverse=True)
    
    return valid[0][0], valid[0][1]


def isolate_and_repeat(filename, skip_start=0, skip_end=None, 
                        threshold_ratio=0.2, min_burst_dur=0.1,
                        repeat_count=1, gap_sec=0.4, 
                        pad_before=0.1, pad_after=0.15,
                        use_all_bursts=False, prefer_longest=False,
                        highpass=0, denoise=0, description=""):
    """Isolate the call from a recording and repeat it."""
    src = os.path.join(AUDIO, filename)
    if not os.path.exists(src):
        print(f"  SKIP: {filename} not found")
        return None
    
    print(f"\n{'─'*60}")
    print(f"  {filename}: {description}")
    
    # Convert to WAV
    tmp_wav = tempfile.NamedTemporaryFile(suffix=".wav", delete=False).name
    subprocess.run([
        "ffmpeg", "-y", "-i", src, "-ac", "1", "-ar", "44100", "-acodec", "pcm_s16le", tmp_wav
    ], capture_output=True, timeout=15)
    
    # Analyze energy
    energies, sr, total_dur = analyze_energy(tmp_wav)
    
    # Optionally skip beginning/end of recording
    if skip_start > 0 or skip_end:
        end_t = skip_end if skip_end else total_dur
        energies = [(t, r) for t, r in energies if t >= skip_start and t <= end_t]
    
    # Find bursts
    bursts = find_bursts(energies, threshold_ratio=threshold_ratio, min_gap_sec=0.1)
    
    print(f"  Total: {total_dur:.1f}s | {len(bursts)} burst(s) found")
    for i, (s, e, p) in enumerate(bursts):
        print(f"    Burst {i+1}: {s:.2f}s-{e:.2f}s ({e-s:.2f}s) peak={p:.0f}")
    
    if not bursts:
        print(f"  ERROR: No bursts found")
        os.unlink(tmp_wav)
        return None
    
    # Pick the call region
    if use_all_bursts:
        # Use entire region spanning all bursts
        call_start = max(0, bursts[0][0] - pad_before)
        call_end = min(total_dur, bursts[-1][1] + pad_after)
    else:
        # Pick the single best burst
        cs, ce = pick_best_burst(bursts, min_dur=min_burst_dur, prefer_longest=prefer_longest)
        call_start = max(0, cs - pad_before)
        call_end = min(total_dur, ce + pad_after)
    
    call_dur = call_end - call_start
    print(f"  Isolated call: {call_start:.2f}s-{call_end:.2f}s ({call_dur:.2f}s)")
    
    # Extract the isolated call
    isolated_wav = tempfile.NamedTemporaryFile(suffix=".wav", delete=False).name
    extract_filters = [f"atrim={call_start}:{call_end}", "asetpts=PTS-STARTPTS"]
    if highpass > 0:
        extract_filters.append(f"highpass=f={highpass}")
    if denoise != 0:
        extract_filters.append(f"afftdn=nf={denoise}")
    
    subprocess.run([
        "ffmpeg", "-y", "-i", tmp_wav,
        "-af", ",".join(extract_filters),
        "-ac", "1", "-ar", "44100", "-acodec", "pcm_s16le", isolated_wav
    ], capture_output=True, timeout=15)
    
    # Build output: isolated call repeated with gaps
    # Create silence gap
    silence_wav = tempfile.NamedTemporaryFile(suffix=".wav", delete=False).name
    subprocess.run([
        "ffmpeg", "-y", "-f", "lavfi", "-i", f"anullsrc=r=44100:cl=mono",
        "-t", str(gap_sec), "-acodec", "pcm_s16le", silence_wav
    ], capture_output=True, timeout=10)
    
    # Create concat list
    concat_list = tempfile.NamedTemporaryFile(suffix=".txt", delete=False, mode="w")
    concat_list.write(f"file '{isolated_wav}'\n")
    for _ in range(repeat_count):
        concat_list.write(f"file '{silence_wav}'\n")
        concat_list.write(f"file '{isolated_wav}'\n")
    concat_list.close()
    
    # Concatenate and normalize
    out_mp3 = os.path.join(AUDIO, filename)
    subprocess.run([
        "ffmpeg", "-y", "-f", "concat", "-safe", "0", "-i", concat_list.name,
        "-af", "loudnorm=I=-16:TP=-1:LRA=11",
        "-ac", "1", "-ar", "44100", "-b:a", "192k", out_mp3
    ], capture_output=True, timeout=30)
    
    # Cleanup
    for f in [tmp_wav, isolated_wav, silence_wav, concat_list.name]:
        try:
            os.unlink(f)
        except:
            pass
    
    if os.path.exists(out_mp3):
        r = subprocess.run(
            ["ffprobe", "-v", "quiet", "-show_entries", "format=duration", "-of", "csv=p=0", out_mp3],
            capture_output=True, text=True, timeout=5
        )
        new_dur = round(float(r.stdout.strip()), 1)
        sz = os.path.getsize(out_mp3) // 1024
        print(f"  OUTPUT: {new_dur}s ({sz}KB) — {repeat_count+1} repetitions")
        return new_dur
    else:
        print(f"  FAILED")
        return None


def simple_trim(filename, trim_start=None, trim_end=None, description=""):
    """Just trim start/end of a file. For files that only need cutting."""
    src = os.path.join(AUDIO, filename)
    if not os.path.exists(src):
        print(f"  SKIP: {filename} not found")
        return None
    
    print(f"\n{'─'*60}")
    print(f"  {filename}: {description}")
    
    filters = []
    if trim_start is not None and trim_end is not None:
        filters.append(f"atrim={trim_start}:{trim_end}")
    elif trim_start is not None:
        filters.append(f"atrim=start={trim_start}")
    elif trim_end is not None:
        filters.append(f"atrim=end={trim_end}")
    filters.append("asetpts=PTS-STARTPTS")
    filters.append("loudnorm=I=-16:TP=-1:LRA=11")
    
    tmp = os.path.join(AUDIO, f"_tmp_{filename}")
    subprocess.run([
        "ffmpeg", "-y", "-i", src,
        "-af", ",".join(filters),
        "-ac", "1", "-ar", "44100", "-b:a", "192k", tmp
    ], capture_output=True, timeout=30)
    
    if os.path.exists(tmp) and os.path.getsize(tmp) > 1000:
        os.replace(tmp, src)
        r = subprocess.run(
            ["ffprobe", "-v", "quiet", "-show_entries", "format=duration", "-of", "csv=p=0", src],
            capture_output=True, text=True, timeout=5
        )
        new_dur = round(float(r.stdout.strip()), 1)
        sz = os.path.getsize(src) // 1024
        print(f"  OUTPUT: {new_dur}s ({sz}KB)")
        return new_dur
    else:
        if os.path.exists(tmp):
            os.unlink(tmp)
        print(f"  FAILED")
        return None


def main():
    print("=" * 60)
    print("CALL ISOLATION & REPEAT — Proper method")
    print("=" * 60)
    
    results = {}
    
    # ─── SIMPLE TRIMS (these were fine before, don't need isolation) ──
    print("\n══ SIMPLE TRIMS ══")
    
    # duck_mallard_feed.mp3 — just drop first 2s (already a Cornell processed file)
    results["duck_mallard_feed.mp3"] = simple_trim(
        "duck_mallard_feed.mp3", trim_start=2, description="Drop first 2s")
    
    # bobcat_hiss.mp3 — drop last 2s
    results["bobcat_hiss.mp3"] = simple_trim(
        "bobcat_hiss.mp3", trim_end=3, description="Drop last 2s")
    
    # wolf_yelp.mp3 — cut last 2s
    results["wolf_yelp.mp3"] = simple_trim(
        "wolf_yelp.mp3", trim_end=5, description="Cut last 2s")
    
    # wolf_growl.mp3 — cut 1s off front
    results["wolf_growl.mp3"] = simple_trim(
        "wolf_growl.mp3", trim_start=1, description="Cut 1s off front")
    
    # ─── ISOLATE + REPEAT ─────────────────────────────────────────────
    print("\n══ ISOLATE CALL + REPEAT ══")
    
    # mallard_hen.mp3 (3s) — the hen call decrescendo is the target. 
    # Drop first ~1s, find the quack, repeat
    results["mallard_hen.mp3"] = isolate_and_repeat(
        "mallard_hen.mp3", skip_start=0.5,
        threshold_ratio=0.25, use_all_bursts=True,
        repeat_count=1, gap_sec=0.3,
        description="Isolate lonesome hen call, repeat 1x")
    
    # crow.mp3 (12s) — find the caw within, isolate, repeat
    results["crow.mp3"] = isolate_and_repeat(
        "crow.mp3", skip_start=2,
        threshold_ratio=0.3, prefer_longest=True,
        repeat_count=1, gap_sec=0.5,
        description="Drop first 2s, isolate caw, repeat 1x")
    
    # pheasant.mp3 (7.2s) — find the rooster crow, isolate, repeat
    results["pheasant.mp3"] = isolate_and_repeat(
        "pheasant.mp3", skip_start=2,
        threshold_ratio=0.3, prefer_longest=True,
        repeat_count=1, gap_sec=0.5,
        description="Drop first 2s, isolate crow, repeat 1x")
    
    # red_stag_roar.mp3 (11.9s) — find the roar, isolate, repeat
    results["red_stag_roar.mp3"] = isolate_and_repeat(
        "red_stag_roar.mp3", skip_start=2,
        threshold_ratio=0.25, prefer_longest=True,
        repeat_count=1, gap_sec=0.5,
        pad_before=0.2, pad_after=0.3,
        description="Drop first 2s, isolate roar, repeat 1x")
    
    # hog_bark.mp3 (6s) — cut first 2s, find bark, isolate, repeat
    results["hog_bark.mp3"] = isolate_and_repeat(
        "hog_bark.mp3", skip_start=2,
        threshold_ratio=0.3,
        repeat_count=1, gap_sec=0.4,
        description="Cut first 2s, isolate bark, repeat 1x")
    
    # turkey_gobble.mp3 (12s) — find the gobble, isolate, repeat
    results["turkey_gobble.mp3"] = isolate_and_repeat(
        "turkey_gobble.mp3",
        threshold_ratio=0.3, prefer_longest=True,
        repeat_count=1, gap_sec=0.6,
        pad_before=0.15, pad_after=0.2,
        description="Isolate gobble, repeat 1x")
    
    # badger.mp3 (2s) — the whole thing is basically the growl, repeat it
    results["badger.mp3"] = isolate_and_repeat(
        "badger.mp3",
        threshold_ratio=0.2, use_all_bursts=True,
        repeat_count=1, gap_sec=0.3,
        description="Isolate growl, repeat 1x")
    
    # gho.mp3 (12s) — find the hoot pattern, isolate, repeat
    results["gho.mp3"] = isolate_and_repeat(
        "gho.mp3",
        threshold_ratio=0.15, use_all_bursts=True,
        repeat_count=1, gap_sec=0.8,
        pad_before=0.2, pad_after=0.3,
        description="Isolate hoot, repeat 1x")
    
    # bobcat_growl_v2.mp3 (5s) — find the growl, isolate, repeat
    results["bobcat_growl_v2.mp3"] = isolate_and_repeat(
        "bobcat_growl_v2.mp3",
        threshold_ratio=0.25, prefer_longest=True,
        repeat_count=1, gap_sec=0.4,
        description="Isolate deep growl, repeat 1x")
    
    # bobcat_howl.mp3 (5s) — find the howl, isolate, repeat
    results["bobcat_howl.mp3"] = isolate_and_repeat(
        "bobcat_howl.mp3",
        threshold_ratio=0.25, prefer_longest=True,
        repeat_count=1, gap_sec=0.4,
        highpass=100, denoise=-30,
        description="Isolate howl, denoise, repeat 1x")
    
    # ─── SUMMARY ──────────────────────────────────────────────────────
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
    
    # Save duration map for JSON update
    dur_map = {k: v for k, v in results.items() if v is not None}
    with open(os.path.join(AUDIO, "_new_durations.json"), "w") as f:
        json.dump(dur_map, f, indent=2)


if __name__ == "__main__":
    main()
