"""Re-process 3 problem files with tuned parameters."""
import os, subprocess, tempfile, struct, wave, math

IN_DIR  = r"c:\Users\neo31\Hunting_Call\assets\audio\replacements"
OUT_DIR = r"c:\Users\neo31\Hunting_Call\assets\audio\replacements\processed"


def process_custom(filename, trim_start, trim_end, denoise_level, silence_thresh, hp_freq=80):
    """Custom processing with explicit parameters."""
    src = os.path.join(IN_DIR, filename)
    out = os.path.join(OUT_DIR, filename)

    print(f"\n{'='*60}")
    print(f"  Re-processing: {filename}")
    print(f"  Trim: {trim_start}s-{trim_end}s | Denoise: {denoise_level}dB | Silence thresh: {silence_thresh}")

    # Convert to WAV first
    tmp_wav = tempfile.NamedTemporaryFile(suffix=".wav", delete=False).name
    subprocess.run(["ffmpeg", "-y", "-i", src, "-ac", "1", "-ar", "44100", "-acodec", "pcm_s16le", tmp_wav],
                   capture_output=True, timeout=15)

    filters = [
        f"atrim={trim_start}:{trim_end}",
        "asetpts=PTS-STARTPTS",
        f"highpass=f={hp_freq}",
        f"afftdn=nf={denoise_level}",
        f"silenceremove=start_periods=1:start_duration=0.05:start_threshold={silence_thresh}:start_silence=0.05",
        "loudnorm=I=-16:TP=-1:LRA=11",
    ]

    result = subprocess.run([
        "ffmpeg", "-y", "-i", tmp_wav,
        "-af", ",".join(filters),
        "-ac", "1", "-ar", "44100", "-b:a", "192k", out
    ], capture_output=True, text=True, timeout=30)

    os.unlink(tmp_wav)

    if os.path.exists(out):
        # Quick audit
        tmp2 = tempfile.NamedTemporaryFile(suffix=".wav", delete=False).name
        subprocess.run(["ffmpeg", "-y", "-i", out, "-ac", "1", "-ar", "16000", tmp2], capture_output=True, timeout=10)
        with wave.open(tmp2, "rb") as w:
            n = w.getnframes(); raw = w.readframes(n); sr = w.getframerate()
        samp = list(struct.unpack("<" + str(n) + "h", raw))
        dur = n / sr
        rms = int(math.sqrt(sum(s*s for s in samp) / len(samp)))
        silent = sum(1 for s in samp if abs(s) < 100)
        sil_pct = round(silent / len(samp) * 100, 1)
        sz = os.path.getsize(out) // 1024
        os.unlink(tmp2)
        print(f"  OUTPUT: {sz}KB | {dur:.1f}s | RMS: {rms} | Silence: {sil_pct}%")
    else:
        print(f"  FAILED")
        if result.stderr:
            for l in result.stderr.split("\n"):
                if "error" in l.lower():
                    print(f"    {l.strip()}")


# Wood Duck - Flying Whistle (ML179353)
# Problem: noise floor was 6029, so silence removal killed almost everything
# Fix: MUCH higher silence threshold, less aggressive denoise
process_custom("wood_duck.mp3",
    trim_start=0, trim_end=8,
    denoise_level=-40,         # Gentler denoise (was -25)
    silence_thresh=0.08,       # Much higher threshold (was ~0.002)
    hp_freq=200)               # Wood duck whistles are above 200Hz

# Wood Duck Sitting Call (ML311981581)
# Problem: only 2.1s after processing — too short
# Fix: use the whole file, less aggressive silence removal
process_custom("wood_duck_sit.mp3",
    trim_start=0, trim_end=6.6,
    denoise_level=-30,
    silence_thresh=0.04,
    hp_freq=150)

# Specklebelly Yodel (ML31730051)
# Problem: 63% silence — natural pauses between yodels
# Fix: trim tighter around the calls, more aggressive silence removal
process_custom("specklebelly.mp3",
    trim_start=0.5, trim_end=8,
    denoise_level=-20,         # Stronger denoise
    silence_thresh=0.003,      # Keep more aggressive silence removal
    hp_freq=100)

# Also re-check mallard feed — 49% silence is high for a chatter call
process_custom("duck_mallard_feed.mp3",
    trim_start=0, trim_end=10,
    denoise_level=-20,
    silence_thresh=0.005,
    hp_freq=100)

# Goose cluck — 53% silence also high
process_custom("goose_cluck.mp3",
    trim_start=0.5, trim_end=10,
    denoise_level=-20,
    silence_thresh=0.003,
    hp_freq=80)
