"""
Fix the 4 files — restore from backup, isolate optimal call segment,
repeat it enough times to make a useful reference clip.

Tuned parameters based on analysis of the backup files:
- turkey_gobble: 0.7s gobble, repeat 4x -> ~4.5s 
- pheasant: 0.6s crow, repeat 3x -> ~3.5s
- gho: hoot pattern, use all bursts with lower threshold, repeat 3x -> ~5-8s
- hog_bark: 0.4s bark, repeat 4x -> ~3s
"""
import os, subprocess, shutil, struct, wave, math, tempfile, json

AUDIO = r"c:\Users\neo31\Hunting_Call\assets\audio"
BACKUP = os.path.join(AUDIO, "_backup")


def get_duration(path):
    r = subprocess.run(
        ["ffprobe", "-v", "quiet", "-show_entries", "format=duration", "-of", "csv=p=0", path],
        capture_output=True, text=True, timeout=5
    )
    try:
        return round(float(r.stdout.strip()), 2)
    except:
        return None


def analyze_energy(wav_path, window_ms=50):
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
    # Merge close bursts
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


def isolate_and_repeat(filename, skip_start=0, skip_end=None,
                        threshold_ratio=0.2, min_burst_dur=0.1,
                        repeat_count=1, gap_sec=0.4,
                        pad_before=0.1, pad_after=0.15,
                        use_all_bursts=False, prefer_longest=False,
                        highpass=0, denoise=0, description=""):
    src = os.path.join(AUDIO, filename)
    backup = os.path.join(BACKUP, filename)

    # Restore from backup first
    if os.path.exists(backup):
        shutil.copy2(backup, src)
        print(f"  Restored from backup ({get_duration(backup)}s)")

    if not os.path.exists(src):
        print(f"  SKIP: {filename} not found")
        return None

    print(f"\n{'-'*60}")
    print(f"  {filename}: {description}")

    # Convert to WAV
    tmp_wav = tempfile.NamedTemporaryFile(suffix=".wav", delete=False).name
    subprocess.run([
        "ffmpeg", "-y", "-i", src, "-ac", "1", "-ar", "44100", "-acodec", "pcm_s16le", tmp_wav
    ], capture_output=True, timeout=15)

    energies, sr, total_dur = analyze_energy(tmp_wav)

    if skip_start > 0 or skip_end:
        end_t = skip_end if skip_end else total_dur
        energies = [(t, r) for t, r in energies if t >= skip_start and t <= end_t]

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
        call_start = max(0, bursts[0][0] - pad_before)
        call_end = min(total_dur, bursts[-1][1] + pad_after)
    else:
        valid = [(s, e, p) for s, e, p in bursts if (e - s) >= min_burst_dur]
        if not valid:
            valid = bursts
        if prefer_longest:
            valid.sort(key=lambda x: x[1] - x[0], reverse=True)
        else:
            valid.sort(key=lambda x: x[2], reverse=True)
        cs, ce = valid[0][0], valid[0][1]
        call_start = max(0, cs - pad_before)
        call_end = min(total_dur, ce + pad_after)

    call_dur = call_end - call_start
    print(f"  Isolated call: {call_start:.2f}s-{call_end:.2f}s ({call_dur:.2f}s)")

    # Extract isolated call
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

    # Build concat: call + (gap + call) x repeat_count
    silence_wav = tempfile.NamedTemporaryFile(suffix=".wav", delete=False).name
    subprocess.run([
        "ffmpeg", "-y", "-f", "lavfi", "-i", "anullsrc=r=44100:cl=mono",
        "-t", str(gap_sec), "-acodec", "pcm_s16le", silence_wav
    ], capture_output=True, timeout=10)

    concat_list = tempfile.NamedTemporaryFile(suffix=".txt", delete=False, mode="w")
    concat_list.write(f"file '{isolated_wav}'\n")
    for _ in range(repeat_count):
        concat_list.write(f"file '{silence_wav}'\n")
        concat_list.write(f"file '{isolated_wav}'\n")
    concat_list.close()

    out_mp3 = os.path.join(AUDIO, filename)
    subprocess.run([
        "ffmpeg", "-y", "-f", "concat", "-safe", "0", "-i", concat_list.name,
        "-af", "loudnorm=I=-16:TP=-1:LRA=11",
        "-ac", "1", "-ar", "44100", "-b:a", "192k", out_mp3
    ], capture_output=True, timeout=30)

    for f in [tmp_wav, isolated_wav, silence_wav, concat_list.name]:
        try:
            os.unlink(f)
        except:
            pass

    if os.path.exists(out_mp3):
        new_dur = get_duration(out_mp3)
        sz = os.path.getsize(out_mp3) // 1024
        total_reps = repeat_count + 1
        print(f"  [OK] {new_dur}s ({sz}KB) -- {total_reps} repetitions of {call_dur:.1f}s call")
        return new_dur
    else:
        print(f"  [FAIL]")
        return None


def main():
    print("=" * 60)
    print("ISOLATE OPTIMAL CALL + REPEAT (v2 - tuned)")
    print("=" * 60)

    results = {}

    # turkey_gobble.mp3 (12s backup)
    # Gobble is ~0.7s. Repeat 4x = 5 total instances -> ~5s clip
    results["turkey_gobble.mp3"] = isolate_and_repeat(
        "turkey_gobble.mp3",
        threshold_ratio=0.25, use_all_bursts=True,
        repeat_count=4, gap_sec=0.5,
        pad_before=0.15, pad_after=0.2,
        description="Isolate gobble pattern, repeat 4x")

    # pheasant.mp3 (7.24s backup)
    # Crow is ~0.6s. Repeat 3x = 4 total -> ~4s clip
    results["pheasant.mp3"] = isolate_and_repeat(
        "pheasant.mp3", skip_start=2,
        threshold_ratio=0.25, use_all_bursts=True,
        repeat_count=3, gap_sec=0.5,
        pad_before=0.15, pad_after=0.2,
        description="Drop first 2s, isolate crow pattern, repeat 3x")

    # gho.mp3 (12s backup)
    # GHO has very soft hoots scattered through 12s. Lower threshold to 0.05
    # to capture the full "hoo-hoo-hoo-hoo" pattern, repeat 2x
    results["gho.mp3"] = isolate_and_repeat(
        "gho.mp3",
        threshold_ratio=0.05, use_all_bursts=True,
        repeat_count=2, gap_sec=1.0,
        pad_before=0.3, pad_after=0.4,
        description="Isolate full hoot pattern (low threshold), repeat 2x")

    # hog_bark.mp3 (6s backup)
    # Bark is ~0.4s. Repeat 5x = 6 total -> ~4s clip
    results["hog_bark.mp3"] = isolate_and_repeat(
        "hog_bark.mp3", skip_start=2,
        threshold_ratio=0.25, use_all_bursts=True,
        repeat_count=5, gap_sec=0.3,
        pad_before=0.1, pad_after=0.15,
        description="Cut first 2s, isolate bark group, repeat 5x")

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

    dur_map = {k: v for k, v in results.items() if v is not None}
    with open(os.path.join(AUDIO, "_fix_durations.json"), "w") as f:
        json.dump(dur_map, f, indent=2)


if __name__ == "__main__":
    main()
