#!/usr/bin/env python3
"""
Extract REAL FFT-based spectrogram data from reference audio files.
Produces a 2D matrix (time × frequency) stored in reference_calls.json.
"""

import json
import subprocess
import struct
import os
import sys
import numpy as np

AUDIO_DIR = "assets/audio"
JSON_PATH = "assets/data/reference_calls.json"

# Spectrogram parameters
TIME_COLS = 48        # Number of time slices
FREQ_BANDS = 16       # Number of frequency bands
SAMPLE_RATE = 16000   # Hz, good balance of detail vs size
FFT_SIZE = 1024       # FFT window size
HOP_SIZE = None       # Auto-calculated per file

def extract_pcm(audio_path: str) -> np.ndarray:
    """Decode audio to mono PCM float32 using ffmpeg."""
    if not os.path.exists(audio_path):
        print(f"  ⚠️  Not found: {audio_path}")
        return np.array([])

    cmd = [
        "ffmpeg", "-y", "-i", audio_path,
        "-ac", "1",
        "-ar", str(SAMPLE_RATE),
        "-f", "f32le",
        "-acodec", "pcm_f32le",
        "pipe:1"
    ]
    try:
        result = subprocess.run(cmd, capture_output=True, timeout=15)
        raw = result.stdout
    except Exception as e:
        print(f"  ⚠️  ffmpeg error: {e}")
        return np.array([])

    if not raw or len(raw) < FFT_SIZE * 4:
        print(f"  ⚠️  Audio too short: {audio_path}")
        return np.array([])

    num_samples = len(raw) // 4
    return np.array(struct.unpack(f"<{num_samples}f", raw), dtype=np.float32)


def compute_spectrogram(samples: np.ndarray) -> list[list[float]]:
    """
    Compute a real spectrogram using STFT.
    Returns a 2D list: [TIME_COLS][FREQ_BANDS]
    Each value is 0.0-1.0 representing spectral energy.
    """
    if len(samples) < FFT_SIZE:
        return []

    # Calculate hop size to get exactly TIME_COLS frames
    total_frames = len(samples) - FFT_SIZE
    hop = max(1, total_frames // (TIME_COLS - 1))

    # Hanning window for smooth spectral analysis
    window = np.hanning(FFT_SIZE)

    # Compute STFT
    spectrogram_frames = []
    for col in range(TIME_COLS):
        start = col * hop
        if start + FFT_SIZE > len(samples):
            break

        frame = samples[start:start + FFT_SIZE] * window
        fft_result = np.fft.rfft(frame)
        magnitude = np.abs(fft_result)

        # Convert to dB scale (more perceptually accurate)
        magnitude_db = 20 * np.log10(magnitude + 1e-10)

        spectrogram_frames.append(magnitude_db)

    if not spectrogram_frames:
        return []

    # Stack into 2D array: (time, frequency_bins)
    spec = np.array(spectrogram_frames)

    # Only use lower half of spectrum (most audio content is below 4kHz)
    max_bin = FFT_SIZE // 4  # Up to ~4kHz at 16kHz sample rate
    spec = spec[:, 1:max_bin + 1]  # Skip DC component

    # Group frequency bins into FREQ_BANDS
    bins_per_band = spec.shape[1] // FREQ_BANDS
    banded = np.zeros((spec.shape[0], FREQ_BANDS))

    for band in range(FREQ_BANDS):
        start_bin = band * bins_per_band
        end_bin = start_bin + bins_per_band
        # Use max energy in each band (peak-hold) for clearer visualization
        banded[:, band] = np.max(spec[:, start_bin:end_bin], axis=1)

    # Normalize to 0-1 range across the entire spectrogram
    # Use percentile-based normalization to avoid outlier sensitivity
    vmin = np.percentile(banded, 5)
    vmax = np.percentile(banded, 99)

    if vmax - vmin < 1.0:
        vmax = vmin + 1.0

    banded = (banded - vmin) / (vmax - vmin)
    banded = np.clip(banded, 0.0, 1.0)

    # Apply noise floor — values below 0.08 become 0
    banded[banded < 0.08] = 0.0

    # Pad or trim to exactly TIME_COLS
    if banded.shape[0] < TIME_COLS:
        padding = np.zeros((TIME_COLS - banded.shape[0], FREQ_BANDS))
        banded = np.vstack([banded, padding])
    elif banded.shape[0] > TIME_COLS:
        banded = banded[:TIME_COLS]

    # Round for clean JSON
    result = [[round(float(v), 3) for v in row] for row in banded]
    return result


def main():
    with open(JSON_PATH, "r") as f:
        data = json.load(f)

    calls = data["calls"]
    updated = 0
    failed = 0

    print(f"Extracting REAL spectrograms for {len(calls)} calls...")
    print(f"Settings: {TIME_COLS} time cols × {FREQ_BANDS} freq bands, FFT={FFT_SIZE}, SR={SAMPLE_RATE}Hz")
    print("─" * 60)

    for call in calls:
        call_id = call["id"]
        audio_path = call.get("audioAssetPath", "")

        if not audio_path:
            print(f"  ⏭️  {call_id}: no audio path")
            continue

        print(f"  🎵  {call_id}...", end=" ", flush=True)

        samples = extract_pcm(audio_path)
        if len(samples) == 0:
            failed += 1
            print("❌ no audio")
            continue

        spec = compute_spectrogram(samples)
        if not spec:
            failed += 1
            print("❌ FFT failed")
            continue

        call["spectrogram"] = spec
        updated += 1

        # Quick stats
        total_cells = sum(1 for row in spec for v in row if v > 0)
        hot_cells = sum(1 for row in spec for v in row if v > 0.7)
        print(f"✅ {len(spec)}×{len(spec[0])}, {total_cells} active cells, {hot_cells} hot")

    # Write back
    with open(JSON_PATH, "w") as f:
        json.dump(data, f, indent=2)

    print("─" * 60)
    print(f"Done! Updated: {updated}, Failed: {failed}")
    print(f"Written to: {JSON_PATH}")


if __name__ == "__main__":
    main()
