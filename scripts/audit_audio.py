"""Audit all MP3 audio files for quality — flag anything suspicious."""
import json, os, subprocess, struct, wave, tempfile

AUDIO_DIR = r"c:\Users\neo31\Hunting_Call\assets\audio"
REF_JSON = r"c:\Users\neo31\Hunting_Call\assets\data\reference_calls.json"


def get_audio_stats(mp3_path):
    """Convert MP3 to WAV in memory, analyze RMS, peak, silence ratio, frequency."""
    tmp = tempfile.NamedTemporaryFile(suffix=".wav", delete=False)
    tmp.close()
    try:
        subprocess.run(
            ["ffmpeg", "-y", "-i", mp3_path, "-ac", "1", "-ar", "16000", tmp.name],
            capture_output=True, timeout=10
        )
        with wave.open(tmp.name, "rb") as w:
            sr = w.getframerate()
            n = w.getnframes()
            raw = w.readframes(n)

        samples = list(struct.unpack(f"<{n}h", raw))
        duration = n / sr

        if not samples:
            return {"duration": 0, "rms": 0, "peak": 0, "silence_pct": 100, "issue": "EMPTY"}

        # RMS
        rms = (sum(s * s for s in samples) / len(samples)) ** 0.5

        # Peak
        peak = max(abs(s) for s in samples)

        # Silence ratio (frames below -50dB threshold)
        threshold = 100  # ~-50dB
        silent = sum(1 for s in samples if abs(s) < threshold)
        silence_pct = (silent / len(samples)) * 100

        # Energy in 0.5s windows to check for content variation
        win_size = sr // 2
        windows = []
        for i in range(0, len(samples) - win_size, win_size):
            chunk = samples[i:i + win_size]
            w_rms = (sum(s * s for s in chunk) / len(chunk)) ** 0.5
            windows.append(w_rms)

        # Check for monotone/constant signal (all windows similar RMS)
        if windows:
            avg_rms = sum(windows) / len(windows)
            variation = sum((w - avg_rms) ** 2 for w in windows) / len(windows)
            std_rms = variation ** 0.5
            content_windows = sum(1 for w in windows if w > 200)
        else:
            std_rms = 0
            content_windows = 0

        return {
            "duration": round(duration, 1),
            "rms": round(rms),
            "peak": peak,
            "silence_pct": round(silence_pct, 1),
            "std_rms": round(std_rms),
            "content_windows": content_windows,
            "total_windows": len(windows),
        }
    finally:
        os.unlink(tmp.name)


def classify(stats, ref_entry):
    """Return quality verdict based on stats."""
    issues = []

    if stats.get("issue") == "EMPTY":
        return "BAD", ["File is empty"]

    dur = stats["duration"]
    rms = stats["rms"]
    peak = stats["peak"]
    silence = stats["silence_pct"]
    content_w = stats.get("content_windows", 0)
    total_w = stats.get("total_windows", 1)

    # Very short files
    if dur < 0.3:
        issues.append(f"Very short ({dur}s)")

    # Too quiet
    if rms < 100:
        issues.append(f"Extremely quiet (RMS={rms})")
    elif rms < 300:
        issues.append(f"Very quiet (RMS={rms})")

    # Mostly silence
    if silence > 85:
        issues.append(f"{silence}% silence")
    elif silence > 70:
        issues.append(f"High silence ({silence}%)")

    # No content variation (might be static/noise)
    if total_w > 0 and content_w == 0:
        issues.append("No audible content detected")
    elif total_w > 4 and content_w < 2:
        issues.append(f"Only {content_w}/{total_w} windows have content")

    # Low peak (clipping indicators or very weak signal)
    if peak < 500:
        issues.append(f"Very low peak ({peak})")

    # Duration mismatch with reference
    if ref_entry:
        ideal_dur = ref_entry.get("idealDurationSec", 0)
        if ideal_dur > 0 and dur > 0:
            ratio = dur / ideal_dur
            if ratio < 0.1:
                issues.append(f"Much shorter than expected ({dur}s vs {ideal_dur}s)")

    if not issues:
        return "GOOD", []
    elif any("empty" in i.lower() or "no audible" in i.lower() or "extremely" in i.lower() for i in issues):
        return "BAD", issues
    elif len(issues) >= 2:
        return "SUSPECT", issues
    else:
        return "CHECK", issues


def main():
    # Load reference data
    with open(REF_JSON, "r", encoding="utf-8") as f:
        ref_data = json.load(f)

    ref_by_file = {}
    for call in ref_data["calls"]:
        fname = os.path.basename(call["audioAssetPath"])
        ref_by_file[fname] = call

    mp3_files = sorted(
        [f for f in os.listdir(AUDIO_DIR) if f.endswith(".mp3")]
    )
    print(f"Analyzing {len(mp3_files)} audio files...\n")

    results = {"GOOD": [], "CHECK": [], "SUSPECT": [], "BAD": []}

    for mp3 in mp3_files:
        path = os.path.join(AUDIO_DIR, mp3)
        ref = ref_by_file.get(mp3)
        try:
            stats = get_audio_stats(path)
            verdict, issues = classify(stats, ref)
        except Exception as e:
            verdict = "BAD"
            stats = {"duration": 0, "rms": 0}
            issues = [f"Error: {e}"]

        animal = ref["animalName"] if ref else "?"
        call_type = ref["callType"] if ref else "?"
        results[verdict].append((mp3, animal, call_type, stats, issues))

    # Print report
    print("=" * 80)
    print("AUDIO QUALITY AUDIT REPORT")
    print("=" * 80)

    for category in ["BAD", "SUSPECT", "CHECK", "GOOD"]:
        items = results[category]
        if not items:
            continue
        icon = {"BAD": "X", "SUSPECT": "?!", "CHECK": "?", "GOOD": "OK"}[category]
        print(f"\n[{icon}] {category} ({len(items)} files)")
        print("-" * 60)
        for mp3, animal, call_type, stats, issues in items:
            dur = stats.get("duration", 0)
            rms = stats.get("rms", 0)
            sil = stats.get("silence_pct", 0)
            print(f"  {mp3}")
            print(f"    {animal} - {call_type} | {dur}s | RMS:{rms} | Silence:{sil}%")
            if issues:
                print(f"    Issues: {'; '.join(issues)}")

    total = sum(len(v) for v in results.values())
    print(f"\n{'=' * 80}")
    print(f"SUMMARY: {len(results['GOOD'])} good, {len(results['CHECK'])} check, "
          f"{len(results['SUSPECT'])} suspect, {len(results['BAD'])} bad out of {total}")


if __name__ == "__main__":
    main()
