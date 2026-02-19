#!/usr/bin/env python3
"""
Re-extract waveform envelopes from reference audio files.
Applies: noise gating, peak normalization, and light smoothing.
Updates reference_calls.json with cleaner waveform data.
"""

import json
import subprocess
import struct
import os
import sys
import math

AUDIO_DIR = "assets/audio"
JSON_PATH = "assets/data/reference_calls.json"
TARGET_SAMPLES = 80  # Number of waveform data points per call
NOISE_FLOOR = 0.08   # Amplitudes below this become 0 (silence gaps)
SMOOTH_WINDOW = 3    # Moving average window for smoothing

def extract_raw_pcm(audio_path: str) -> list[float]:
    """Use ffmpeg to decode audio to raw PCM float32, then extract peak envelope."""
    if not os.path.exists(audio_path):
        print(f"  ⚠️  File not found: {audio_path}")
        return []

    # Decode to mono float32 PCM via stdout
    cmd = [
        "ffmpeg", "-y", "-i", audio_path,
        "-ac", "1",          # mono
        "-ar", "8000",       # 8kHz is enough for envelope
        "-f", "f32le",       # raw float32 little-endian
        "-acodec", "pcm_f32le",
        "pipe:1"
    ]
    try:
        result = subprocess.run(cmd, capture_output=True, timeout=15)
        raw = result.stdout
    except Exception as e:
        print(f"  ⚠️  ffmpeg error: {e}")
        return []

    if not raw or len(raw) < 8:
        print(f"  ⚠️  No audio data from {audio_path}")
        return []

    # Parse float32 samples
    num_samples = len(raw) // 4
    samples = list(struct.unpack(f"<{num_samples}f", raw))

    return samples


def compute_envelope(samples: list[float], target_points: int) -> list[float]:
    """Compute amplitude envelope with target number of output points."""
    if not samples:
        return []

    # Split into windows and take peak of each
    window_size = max(1, len(samples) // target_points)
    envelope = []

    for i in range(0, len(samples), window_size):
        window = samples[i:i + window_size]
        peak = max(abs(s) for s in window)
        envelope.append(peak)

    # Trim to target
    if len(envelope) > target_points:
        envelope = envelope[:target_points]

    return envelope


def normalize(envelope: list[float]) -> list[float]:
    """Peak normalize to 0-1 range."""
    if not envelope:
        return []
    peak = max(envelope)
    if peak < 0.001:
        return [0.0] * len(envelope)
    return [v / peak for v in envelope]


def noise_gate(envelope: list[float], floor: float) -> list[float]:
    """Zero out values below the noise floor for cleaner silence gaps."""
    return [v if v >= floor else 0.0 for v in envelope]


def smooth(envelope: list[float], window: int) -> list[float]:
    """Simple moving average smoothing."""
    if window < 2 or len(envelope) < window:
        return envelope
    half = window // 2
    result = []
    for i in range(len(envelope)):
        start = max(0, i - half)
        end = min(len(envelope), i + half + 1)
        avg = sum(envelope[start:end]) / (end - start)
        result.append(avg)
    return result


def round_values(envelope: list[float], decimals: int = 3) -> list[float]:
    """Round to N decimal places for clean JSON."""
    return [round(v, decimals) for v in envelope]


def process_waveform(audio_path: str) -> list[float]:
    """Full pipeline: extract → envelope → normalize → gate → smooth → round."""
    samples = extract_raw_pcm(audio_path)
    if not samples:
        return []

    envelope = compute_envelope(samples, TARGET_SAMPLES)
    envelope = normalize(envelope)
    envelope = noise_gate(envelope, NOISE_FLOOR)
    # Re-normalize after gating (so peaks are still 1.0)
    envelope = normalize(envelope)
    envelope = smooth(envelope, SMOOTH_WINDOW)
    envelope = round_values(envelope)

    return envelope


def main():
    # Load existing JSON
    with open(JSON_PATH, "r") as f:
        data = json.load(f)

    calls = data["calls"]
    updated = 0
    failed = 0

    print(f"Processing {len(calls)} reference calls...")
    print(f"Settings: {TARGET_SAMPLES} points, noise floor={NOISE_FLOOR}, smooth={SMOOTH_WINDOW}")
    print("─" * 60)

    for call in calls:
        call_id = call["id"]
        audio_path = call.get("audioAssetPath", "")

        if not audio_path:
            print(f"  ⏭️  {call_id}: no audio path, skipping")
            continue

        print(f"  🎵  {call_id}...", end=" ", flush=True)

        waveform = process_waveform(audio_path)

        if waveform:
            old_len = len(call.get("waveform", []))
            call["waveform"] = waveform
            updated += 1
            # Quick stats
            peaks = sum(1 for v in waveform if v > 0.5)
            silences = sum(1 for v in waveform if v == 0.0)
            print(f"✅ {len(waveform)} pts (was {old_len}), {peaks} peaks, {silences} silences")
        else:
            failed += 1
            print("❌ failed")

    # Write back
    with open(JSON_PATH, "w") as f:
        json.dump(data, f, indent=2)

    print("─" * 60)
    print(f"Done! Updated: {updated}, Failed: {failed}")
    print(f"Written to: {JSON_PATH}")


if __name__ == "__main__":
    main()
