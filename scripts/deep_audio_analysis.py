"""Deep analysis of flagged audio files — frequency, energy timeline, content quality."""
import json, os, subprocess, struct, wave, tempfile, math

AUDIO_DIR = r"c:\Users\neo31\Hunting_Call\assets\audio"
REF_JSON = r"c:\Users\neo31\Hunting_Call\assets\data\reference_calls.json"

FLAGGED = [
    "bobcat_purr.mp3",
    "gho.mp3",
    "deer_buck_challenge.mp3",
    "deer_dominant_grunt.mp3",
    "deer_tending_grunt.mp3",
    "deer_buck_grunt.mp3",
    "deer_social_grunt.mp3",
    "deer_estrus_bleat.mp3",
    "turkey_purr.mp3",
    "bobcat_growl_v2.mp3",
    "hog_bark.mp3",
    "turkey_hen_yelp.mp3",
]


def load_samples(mp3_path, sr=16000):
    """Convert MP3 to mono WAV and return samples."""
    tmp = tempfile.NamedTemporaryFile(suffix=".wav", delete=False)
    tmp.close()
    try:
        subprocess.run(
            ["ffmpeg", "-y", "-i", mp3_path, "-ac", "1", "-ar", str(sr), tmp.name],
            capture_output=True, timeout=10
        )
        with wave.open(tmp.name, "rb") as w:
            n = w.getnframes()
            raw = w.readframes(n)
        samples = list(struct.unpack(f"<{n}h", raw))
        return samples, sr
    finally:
        os.unlink(tmp.name)


def estimate_freq(samples, sr):
    """Simple zero-crossing frequency estimator."""
    if len(samples) < 100:
        return 0
    crossings = 0
    for i in range(1, len(samples)):
        if (samples[i] >= 0) != (samples[i-1] >= 0):
            crossings += 1
    return (crossings / 2) / (len(samples) / sr)


def analyze_deep(mp3_path, ref_entry, sr=16000):
    """Detailed temporal and frequency analysis."""
    samples, sr = load_samples(mp3_path, sr)
    duration = len(samples) / sr

    if not samples:
        return {"verdict": "DEAD", "reason": "Empty file"}

    # Analyze in 0.25s windows
    win = sr // 4  # 0.25s
    windows = []
    for i in range(0, len(samples) - win, win):
        chunk = samples[i:i + win]
        rms = (sum(s * s for s in chunk) / len(chunk)) ** 0.5
        peak = max(abs(s) for s in chunk)
        freq = estimate_freq(chunk, sr)
        t = i / sr
        windows.append({
            "t": round(t, 2),
            "rms": round(rms),
            "peak": peak,
            "freq": round(freq),
        })

    # Classify windows
    active_threshold = 300  # RMS above this = "active"
    active_windows = [w for w in windows if w["rms"] > active_threshold]
    silent_windows = [w for w in windows if w["rms"] <= 50]
    quiet_windows = [w for w in windows if 50 < w["rms"] <= active_threshold]

    # Get frequency of active content
    if active_windows:
        avg_active_freq = sum(w["freq"] for w in active_windows) / len(active_windows)
        avg_active_rms = sum(w["rms"] for w in active_windows) / len(active_windows)
        max_rms = max(w["rms"] for w in active_windows)
    else:
        avg_active_freq = 0
        avg_active_rms = 0
        max_rms = 0

    # Identify call bursts (consecutive active windows)
    bursts = []
    current_burst = []
    for w in windows:
        if w["rms"] > active_threshold:
            current_burst.append(w)
        else:
            if current_burst:
                bursts.append(current_burst)
                current_burst = []
    if current_burst:
        bursts.append(current_burst)

    burst_durations = [len(b) * 0.25 for b in bursts]

    # Check for noise vs signal
    # Real calls have clear peaks and valleys; noise has flat RMS
    if active_windows:
        rms_values = [w["rms"] for w in active_windows]
        rms_mean = sum(rms_values) / len(rms_values)
        rms_variance = sum((r - rms_mean) ** 2 for r in rms_values) / len(rms_values)
        rms_cv = (rms_variance ** 0.5) / rms_mean if rms_mean > 0 else 0
    else:
        rms_cv = 0

    # Expected frequency from reference
    expected_freq = ref_entry.get("idealPitchHz", 0) if ref_entry else 0

    # Build timeline visualization
    timeline = ""
    for w in windows:
        if w["rms"] > 2000:
            timeline += "█"
        elif w["rms"] > 1000:
            timeline += "▓"
        elif w["rms"] > active_threshold:
            timeline += "▒"
        elif w["rms"] > 50:
            timeline += "░"
        else:
            timeline += " "

    return {
        "duration": round(duration, 1),
        "total_windows": len(windows),
        "active_windows": len(active_windows),
        "quiet_windows": len(quiet_windows),
        "silent_windows": len(silent_windows),
        "active_pct": round(len(active_windows) / max(len(windows), 1) * 100, 1),
        "avg_active_freq": round(avg_active_freq),
        "expected_freq": expected_freq,
        "avg_active_rms": round(avg_active_rms),
        "max_rms": max_rms,
        "num_bursts": len(bursts),
        "burst_durations": [round(d, 2) for d in burst_durations],
        "rms_cv": round(rms_cv, 2),
        "timeline": timeline,
    }


def verdict(stats):
    """Final verdict for this file."""
    active_pct = stats["active_pct"]
    num_bursts = stats["num_bursts"]
    max_rms = stats["max_rms"]
    rms_cv = stats["rms_cv"]

    issues = []
    positives = []

    if active_pct < 5:
        issues.append("Almost entirely silence — barely any audible content")
    elif active_pct < 15:
        issues.append("Very sparse — only brief moments of sound")

    if num_bursts == 0:
        issues.append("No distinct call bursts detected")
    elif num_bursts >= 3:
        positives.append(f"{num_bursts} distinct call bursts")

    if max_rms > 3000:
        positives.append(f"Strong signal (peak RMS {max_rms})")
    elif max_rms < 500:
        issues.append(f"Very weak signal (peak RMS {max_rms})")

    if rms_cv > 0.3:
        positives.append("Good dynamic range (natural variation)")

    # For grunts/purrs naturally quiet is OK
    if max_rms > 1000 and num_bursts >= 1:
        label = "LEGIT"
        if active_pct < 20:
            label = "LEGIT (sparse but real)"
    elif max_rms > 500 and num_bursts >= 1:
        label = "WEAK but present"
    elif max_rms < 300:
        label = "QUESTIONABLE"
    else:
        label = "MARGINAL"

    return label, issues, positives


def main():
    with open(REF_JSON, "r", encoding="utf-8") as f:
        ref_data = json.load(f)

    ref_by_file = {}
    for call in ref_data["calls"]:
        fname = os.path.basename(call["audioAssetPath"])
        ref_by_file[fname] = call

    print("DEEP AUDIO ANALYSIS — 12 FLAGGED FILES")
    print("=" * 80)

    for mp3 in FLAGGED:
        path = os.path.join(AUDIO_DIR, mp3)
        ref = ref_by_file.get(mp3, {})
        animal = ref.get("animalName", "?")
        call_type = ref.get("callType", "?")

        stats = analyze_deep(path, ref)
        label, issues, positives = verdict(stats)

        print(f"\n{'─' * 70}")
        print(f"  {mp3} — {animal} / {call_type}")
        print(f"  VERDICT: {label}")
        print(f"{'─' * 70}")
        print(f"  Duration: {stats['duration']}s | Active: {stats['active_pct']}% "
              f"({stats['active_windows']}/{stats['total_windows']} windows)")
        print(f"  Call bursts: {stats['num_bursts']} | Burst durations: {stats['burst_durations']}")
        print(f"  Avg active freq: {stats['avg_active_freq']} Hz (expected: {stats['expected_freq']} Hz)")
        print(f"  Avg active RMS: {stats['avg_active_rms']} | Peak RMS: {stats['max_rms']} | Dynamic range CV: {stats['rms_cv']}")
        print(f"  Timeline: |{stats['timeline']}|")
        if positives:
            print(f"  (+) {'; '.join(positives)}")
        if issues:
            print(f"  (-) {'; '.join(issues)}")


if __name__ == "__main__":
    main()
