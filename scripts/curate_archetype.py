#!/usr/bin/env python3
"""
Archetype Curation Script
Reads a directory of gold-standard 5-second .wav clips for a specific animal call,
extracts core features (pitch, duration, MFCCs, etc.), and outputs an aggregated
JSON archetype ready to be loaded by the outcall Dart app.

Dependencies:
pip install librosa numpy soundfile
"""

import os
import json
import argparse
import numpy as np
import librosa

def extract_features(file_path):
    print(f"Processing {file_path}...")
    # Load audio
    y, sr = librosa.load(file_path, sr=44100)
    
    # 1. Pitch Extraction (Dominant Frequency)
    # Using piptrack or just simple stft peak finding (simplified here for brevity)
    pitches, magnitudes = librosa.core.piptrack(y=y, sr=sr, fmin=50, fmax=5000)
    # Get mean fundamental frequency
    pitch_values = []
    for t in range(magnitudes.shape[1]):
        index = magnitudes[:, t].argmax()
        pitch = pitches[index, t]
        if pitch > 50: # Ignore low freq noise
            pitch_values.append(pitch)
            
    avg_pitch = np.mean(pitch_values) if pitch_values else 0.0
    
    # 2. Duration
    duration = librosa.get_duration(y=y, sr=sr)
    
    # 3. MFCC (Timbre Profile)
    mfccs = librosa.feature.mfcc(y=y, sr=sr, n_mfcc=13)
    avg_mfccs = np.mean(mfccs, axis=1).tolist()
    
    # 4. Waveform Envelope (Downsampled for DTW rhythm matching)
    # For a real archetype, we'd DTW-align multiple envelopes.
    # Here we just compute a simple RMS envelope.
    rms = librosa.feature.rms(y=y, frame_length=2048, hop_length=512)[0]
    # Downsample to ~100 points
    target_points = 100
    if len(rms) > target_points:
        indices = np.linspace(0, len(rms)-1, target_points).astype(int)
        envelope = rms[indices].tolist()
    else:
        envelope = rms.tolist()
        
    # Scale envelope 0 to 1
    max_env = max(envelope) if envelope else 1.0
    if max_env > 0:
        envelope = [float(e / max_env) for e in envelope]
        
    return {
        "pitch": float(avg_pitch),
        "duration": float(duration),
        "mfccs": avg_mfccs,
        "envelope": envelope
    }

def build_archetype(call_id, directory):
    wav_files = [f for f in os.listdir(directory) if f.endswith('.wav')]
    if not wav_files:
        print(f"No .wav files found in {directory}")
        return None
        
    all_features = [extract_features(os.path.join(directory, f)) for f in wav_files]
    
    # Aggregate
    avg_pitch = np.mean([f['pitch'] for f in all_features])
    pitch_std = np.std([f['pitch'] for f in all_features])
    
    avg_duration = np.mean([f['duration'] for f in all_features])
    dur_std = np.std([f['duration'] for f in all_features])
    
    avg_mfccs = np.mean(np.array([f['mfccs'] for f in all_features]), axis=0).tolist()
    
    # Basic envelope averaging (Needs dynamic time warping for real alignment)
    avg_env = np.mean(np.array([f['envelope'] for f in all_features if len(f['envelope']) == 100]), axis=0).tolist()
    
    # Construct Archetype JSON
    archetype = {
        "callId": call_id,
        "averagePitchHz": avg_pitch,
        "pitchTolerance": max(50.0, pitch_std * 2), # Set a reasonable floor
        "averageDurationSec": avg_duration,
        "durationTolerance": max(0.5, dur_std * 2),
        "harmonicsProfile": {}, # Add harmonic ratio logic here later
        "mfccProfile": avg_mfccs,
        "isPulsed": False, # Manual override later for pulsed calls
        "cadenceBreaks": [],
        "averageWaveform": avg_env
    }
    
    return archetype

def main():
    parser = argparse.ArgumentParser(description="Build Animal Archetype JSON from audio clips")
    parser.add_argument("--call_id", required=True, help="The ID of the reference call (e.g. bugle_elk_1)")
    parser.add_argument("--input_dir", required=True, help="Directory containing .wav clips")
    parser.add_argument("--output", default="archetype.json", help="Output JSON file")
    
    args = parser.parse_args()
    
    archetype = build_archetype(args.call_id, args.input_dir)
    if archetype:
        with open(args.output, 'w') as f:
            json.dump(archetype, f, indent=2)
        print(f"Successfully wrote archetype for {args.call_id} to {args.output}")

if __name__ == "__main__":
    main()
