"""
Process Cornell Macaulay Library recordings into production-ready audio.

Pipeline per file:
  1. Analyze: find energy timeline, detect call onset/offset
  2. Trim: cut to just the active vocalization region
  3. Denoise: FFT-based noise reduction using noise profile from quiet sections
  4. Remove silence: strip leading/trailing dead air
  5. Normalize: EBU R128 loudness normalization
  6. Final export: MP3 192kbps, mono, 44.1kHz
"""
import os, subprocess, json, struct, wave, tempfile, math

IN_DIR  = r"c:\Users\neo31\Hunting_Call\assets\audio\replacements"
OUT_DIR = r"c:\Users\neo31\Hunting_Call\assets\audio\replacements\processed"
os.makedirs(OUT_DIR, exist_ok=True)


def analyze_wav(wav_path):
    """Analyze WAV file: return samples, sample rate, and energy timeline."""
    with wave.open(wav_path, "rb") as w:
        n = w.getnframes()
        raw = w.readframes(n)
        sr = w.getframerate()
        ch = w.getnchannels()

    samples = list(struct.unpack("<" + str(n * ch) + "h", raw))

    # If stereo, mix to mono
    if ch == 2:
        samples = [(samples[i] + samples[i+1]) / 2 for i in range(0, len(samples), 2)]

    # Energy timeline in 100ms windows
    window = sr // 10  # 100ms
    energies = []
    for i in range(0, len(samples), window):
        chunk = samples[i:i+window]
        if chunk:
            rms = math.sqrt(sum(s*s for s in chunk) / len(chunk))
            energies.append(rms)
        else:
            energies.append(0)

    return samples, sr, energies


def find_call_region(energies, threshold_ratio=0.15):
    """Find the start and end of the active call region.
    Returns (start_idx, end_idx) in terms of 100ms windows."""
    if not energies:
        return 0, 0

    peak = max(energies)
    threshold = peak * threshold_ratio

    # Find first window above threshold
    start = 0
    for i, e in enumerate(energies):
        if e > threshold:
            start = max(0, i - 2)  # Back up 200ms for attack
            break

    # Find last window above threshold
    end = len(energies) - 1
    for i in range(len(energies) - 1, -1, -1):
        if energies[i] > threshold:
            end = min(len(energies) - 1, i + 2)  # Add 200ms for release
            break

    return start, end


def get_noise_profile_rms(samples, sr, quiet_start_sec=0, quiet_dur_sec=0.5):
    """Estimate noise floor RMS from a quiet section."""
    start = int(quiet_start_sec * sr)
    end = int((quiet_start_sec + quiet_dur_sec) * sr)
    end = min(end, len(samples))
    if end <= start:
        return 100
    chunk = samples[start:end]
    return math.sqrt(sum(s*s for s in chunk) / len(chunk))


def process_file(filename, target_dur=None):
    """Full processing pipeline for one file."""
    src = os.path.join(IN_DIR, filename)
    out = os.path.join(OUT_DIR, filename)

    if not os.path.exists(src):
        print(f"  SKIP: {filename} not found")
        return False

    print(f"\n{'='*60}")
    print(f"  Processing: {filename}")

    # Step 1: Convert to WAV for analysis
    tmp_wav = tempfile.NamedTemporaryFile(suffix=".wav", delete=False).name
    subprocess.run([
        "ffmpeg", "-y", "-i", src, "-ac", "1", "-ar", "44100", "-acodec", "pcm_s16le", tmp_wav
    ], capture_output=True, timeout=15)

    # Step 2: Analyze
    samples, sr, energies = analyze_wav(tmp_wav)
    total_dur = len(samples) / sr
    peak_rms = max(energies) if energies else 0
    avg_rms = sum(energies) / len(energies) if energies else 0
    noise_rms = get_noise_profile_rms(samples, sr)

    print(f"  Duration: {total_dur:.1f}s | Peak RMS: {peak_rms:.0f} | Avg RMS: {avg_rms:.0f} | Noise floor: {noise_rms:.0f}")

    # Step 3: Find call region
    start_win, end_win = find_call_region(energies)
    call_start = start_win * 0.1  # Convert windows to seconds
    call_end = end_win * 0.1

    # Ensure minimum duration
    if call_end - call_start < 2.0:
        call_start = 0
        call_end = total_dur

    # Apply target duration cap
    if target_dur and (call_end - call_start) > target_dur:
        call_end = call_start + target_dur

    print(f"  Call region: {call_start:.1f}s - {call_end:.1f}s ({call_end - call_start:.1f}s)")

    # Step 4: Build ffmpeg filter chain
    # a) Trim to call region
    # b) Noise gate: suppress very quiet sections (below noise floor)
    # c) High-pass filter to remove low-frequency rumble (below 100Hz for birds)
    # d) Silence removal: strip leading/trailing silence
    # e) Loudness normalization
    noise_gate_threshold = max(noise_rms * 1.5 / 32768.0, 0.002)  # Convert to 0-1 range

    filters = [
        f"atrim={call_start}:{call_end}",              # Trim to call region
        "asetpts=PTS-STARTPTS",                         # Reset timestamps
        "highpass=f=80",                                # Remove sub-bass rumble
        f"afftdn=nf=-25",                              # FFT-based denoising
        f"silenceremove=start_periods=1:start_duration=0.05:start_threshold={noise_gate_threshold}:start_silence=0.1",  # Remove leading silence
        f"silenceremove=stop_periods=-1:stop_duration=0.3:stop_threshold={noise_gate_threshold}:stop_silence=0.15",     # Remove trailing silence  
        "loudnorm=I=-16:TP=-1:LRA=11",                 # EBU R128 normalization
    ]

    filter_str = ",".join(filters)

    # Step 5: Process and export
    result = subprocess.run([
        "ffmpeg", "-y", "-i", tmp_wav,
        "-af", filter_str,
        "-ac", "1", "-ar", "44100", "-b:a", "192k",
        out
    ], capture_output=True, text=True, timeout=30)

    # Cleanup temp
    try:
        os.unlink(tmp_wav)
    except:
        pass

    if os.path.exists(out):
        out_sz = os.path.getsize(out) // 1024

        # Quick analysis of output
        tmp2 = tempfile.NamedTemporaryFile(suffix=".wav", delete=False).name
        subprocess.run(["ffmpeg", "-y", "-i", out, "-ac", "1", "-ar", "16000", tmp2], capture_output=True, timeout=10)
        with wave.open(tmp2, "rb") as w:
            n2 = w.getnframes()
            raw2 = w.readframes(n2)
            sr2 = w.getframerate()
        samp2 = list(struct.unpack("<" + str(n2) + "h", raw2))
        dur2 = n2 / sr2
        rms2 = int(math.sqrt(sum(s*s for s in samp2) / len(samp2)))
        silent2 = sum(1 for s in samp2 if abs(s) < 100)
        sil_pct2 = round(silent2 / len(samp2) * 100, 1)
        os.unlink(tmp2)

        print(f"  OUTPUT: {out_sz}KB | {dur2:.1f}s | RMS: {rms2} | Silence: {sil_pct2}%")
        return True
    else:
        print(f"  FAILED")
        if result.stderr:
            errs = [l for l in result.stderr.split("\n") if "error" in l.lower() or "Error" in l]
            for e in errs[:3]:
                print(f"    {e.strip()}")
        return False


def main():
    print("=" * 60)
    print("CORNELL AUDIO PROCESSING PIPELINE")
    print("Isolate → Trim → Denoise → Normalize")
    print("=" * 60)

    TARGETS = [
        ("duck_mallard_feed.mp3", 10),
        ("wood_duck.mp3", 8),
        ("goose_cluck.mp3", 10),
        ("teal.mp3", 10),
        ("snow_goose.mp3", 10),
        ("specklebelly.mp3", 10),
        ("wood_duck_sit.mp3", 8),
        ("mallard_hen.mp3", 6),
        ("canvasback.mp3", 10),
    ]

    results = {}
    for fname, target_dur in TARGETS:
        ok = process_file(fname, target_dur)
        results[fname] = "OK" if ok else "FAILED"

    # Summary
    print(f"\n{'='*60}")
    print("PROCESSING RESULTS")
    print(f"{'='*60}")
    ok_count = 0
    for fname, status in results.items():
        icon = "OK" if status == "OK" else "XX"
        print(f"  [{icon}] {fname}")
        if status == "OK":
            ok_count += 1
    print(f"\n{ok_count}/{len(results)} processed successfully")


if __name__ == "__main__":
    main()
