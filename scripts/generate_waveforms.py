#!/usr/bin/env python3
"""Pre-compute RMS waveforms for all reference calls and embed in reference_calls.json.

Uses ffmpeg to decode MP3→raw PCM, then computes 100-point RMS waveform
with sqrt normalization (same algorithm as ComprehensiveAudioAnalyzer._extractWaveform).

Usage:
    python3 scripts/generate_waveforms.py
"""

import json
import math
import os
import struct
import subprocess
import sys
import tempfile

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
JSON_PATH = os.path.join(PROJECT_DIR, "assets", "data", "reference_calls.json")
WAVEFORM_POINTS = 100


def decode_audio_to_pcm(audio_path: str) -> list[float]:
    """Use ffmpeg to decode audio file to raw 16-bit mono PCM, return as float samples."""
    with tempfile.NamedTemporaryFile(suffix=".raw", delete=False) as tmp:
        tmp_path = tmp.name

    try:
        cmd = [
            "ffmpeg", "-y", "-i", audio_path,
            "-f", "s16le",       # raw 16-bit signed little-endian
            "-acodec", "pcm_s16le",
            "-ar", "44100",      # 44.1kHz
            "-ac", "1",          # mono
            tmp_path,
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"  ⚠ ffmpeg error: {result.stderr[:200]}")
            return []

        with open(tmp_path, "rb") as f:
            raw_bytes = f.read()

        num_samples = len(raw_bytes) // 2
        samples = []
        for i in range(num_samples):
            sample = struct.unpack_from("<h", raw_bytes, i * 2)[0]
            samples.append(sample / 32768.0)
        return samples

    finally:
        if os.path.exists(tmp_path):
            os.unlink(tmp_path)


def extract_waveform(samples: list[float], points: int = WAVEFORM_POINTS) -> list[float]:
    """Extract RMS waveform with sqrt normalization (matches Dart implementation)."""
    if not samples:
        return [0.0] * points

    chunk_size = len(samples) // points
    if chunk_size < 1:
        return [abs(s) for s in samples[:points]] + [0.0] * max(0, points - len(samples))

    result = []
    for i in range(points):
        start = i * chunk_size
        end = min(start + chunk_size, len(samples))
        sum_squares = sum(s * s for s in samples[start:end])
        count = end - start
        rms = math.sqrt(sum_squares / count) if count > 0 else 0.0
        result.append(rms)

    # Normalize with sqrt curve
    peak = max(result) if result else 0.0
    if peak > 0:
        result = [math.sqrt(v / peak) for v in result]

    return result


def main():
    if not os.path.exists(JSON_PATH):
        print(f"❌ reference_calls.json not found at {JSON_PATH}")
        sys.exit(1)

    with open(JSON_PATH, "r") as f:
        data = json.load(f)

    calls = data["calls"]
    print(f"📊 Processing {len(calls)} reference calls...\n")

    success = 0
    failed = 0

    for i, call in enumerate(calls):
        call_id = call["id"]
        asset_path = call.get("audioAssetPath", "")

        # Resolve asset path relative to project
        audio_path = os.path.join(PROJECT_DIR, asset_path)

        if not os.path.exists(audio_path):
            print(f"  [{i+1}/{len(calls)}] ❌ {call_id}: file not found ({asset_path})")
            failed += 1
            continue

        # Decode and extract waveform
        samples = decode_audio_to_pcm(audio_path)
        if not samples:
            print(f"  [{i+1}/{len(calls)}] ❌ {call_id}: failed to decode")
            failed += 1
            continue

        waveform = extract_waveform(samples)

        # Round to 3 decimal places to keep JSON compact
        waveform = [round(v, 3) for v in waveform]

        call["waveform"] = waveform

        # Show a mini sparkline
        bars = "".join("▁▂▃▄▅▆▇█"[min(7, int(v * 8))] for v in waveform[:40])
        print(f"  [{i+1}/{len(calls)}] ✅ {call_id}: {bars}...")
        success += 1

    # Write updated JSON
    with open(JSON_PATH, "w") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    print(f"\n🎉 Done! {success} succeeded, {failed} failed.")
    print(f"   Updated: {JSON_PATH}")


if __name__ == "__main__":
    main()
