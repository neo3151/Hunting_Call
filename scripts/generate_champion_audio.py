import json
import os
import math
import wave
import struct
import numpy as np

# Base paths
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
JSON_PATH = os.path.join(BASE_DIR, 'assets', 'data', 'reference_calls.json')
AUDIO_OUT_DIR = os.path.join(BASE_DIR, 'assets', 'audio')

# Ensure output directory exists
os.makedirs(AUDIO_OUT_DIR, exist_ok=True)

def generate_tone(call_data, sample_rate=44100):
    """
    Generates a pure mathematical 'Studio Champion' reference track.
    Instead of dirty wild audio, we create a precise bio-acoustic sine/sawtooth 
    composite based on the animal's exact frequency and temporal profile.
    """
    duration = call_data.get('idealDurationSec', 3.0)
    base_freq = call_data.get('idealPitchHz', 440.0)
    category = call_data.get('category', '').lower()
    waveform_env = call_data.get('waveform', [])
    
    num_samples = int(duration * sample_rate)
    audio = np.zeros(num_samples)
    
    # 1. Base Synthesis (Timbre based on animal class)
    t = np.linspace(0, duration, num_samples, endpoint=False)
    
    if 'waterfowl' in category:
        # Ducks/Geese: Raspy, complex reed harmonics
        signal = 0.5 * np.sin(2 * np.pi * base_freq * t)
        signal += 0.3 * signal * np.sin(2 * np.pi * (base_freq * 2) * t) # First harmonic
        # Add "rasp" (amplitude modulation)
        rasp = 0.5 * (1 + np.sin(2 * np.pi * 50 * t)) 
        signal = signal * (0.5 + 0.5 * rasp)
        
    elif 'elk' in category:
        # Elk bugle: Deep guttural start sweeping up to a piercing whistle
        # Dynamic frequency sweep
        sweep_freq = np.linspace(base_freq, min(base_freq * 10, 3000), num_samples)
        phase = np.cumsum(2 * np.pi * sweep_freq / sample_rate)
        signal = 0.8 * np.sin(phase)
        
    elif 'turkey' in category:
        # Turkey Yelps/Cuts: Sharp, rhythmic, percussive pulses. We use a sawtooth for edge.
        from scipy import signal as sp_signal
        # Use modulo arithmetic to create a fast pulsed sawtooth
        fast_pulse_rate = 6.0 # pulses per second
        pulse_envelope = 0.5 * (1 + np.sin(2 * np.pi * fast_pulse_rate * t))
        
        # Complex dual-tone (biphonation often found in turkey calls)
        tone1 = np.sin(2 * np.pi * base_freq * t)
        tone2 = np.sin(2 * np.pi * (base_freq * 1.5) * t) # Dissonant overtone
        signal = (0.6 * tone1 + 0.4 * tone2) * pulse_envelope
        
    elif 'predator' in category or 'deer' in category:
        # Coyotes/Deer: Sweeping howls and bleats
        mod_rate = 2.0
        fm = np.sin(2 * np.pi * mod_rate * t)
        inst_freq = base_freq + (base_freq * 0.2) * fm
        phase = np.cumsum(2 * np.pi * inst_freq / sample_rate)
        signal = np.sin(phase)
        
    else:
        # Default pure tone with slight vibrato
        vibrato = np.sin(2 * np.pi * 5 * t) * (base_freq * 0.05)
        phase = np.cumsum(2 * np.pi * (base_freq + vibrato) / sample_rate)
        signal = np.sin(phase)

    # 2. Apply Custom Temporal Envelope from the JSON (if available)
    # This aligns the synthesized sound PERFECTLY to the expected DTW rhythm matrix.
    if len(waveform_env) > 0:
        # Interpolate the low-res JSON envelope to match the high-res audio samples
        x_old = np.linspace(0, 1, len(waveform_env))
        x_new = np.linspace(0, 1, num_samples)
        interpolated_env = np.interp(x_new, x_old, waveform_env)
        
        # Apply the envelope
        signal = signal * interpolated_env
    else:
        # Basic Attack/Decay if no JSON envelope
        attack = min(0.1, duration / 10)
        decay = min(0.2, duration / 5)
        attack_samples = int(attack * sample_rate)
        decay_samples = int(decay * sample_rate)
        
        env = np.ones(num_samples)
        env[:attack_samples] = np.linspace(0, 1, attack_samples)
        env[-decay_samples:] = np.linspace(1, 0, decay_samples)
        signal = signal * env

    # Normalize to 16-bit PCM integer
    max_amp = np.max(np.abs(signal))
    if max_amp > 0:
        signal = signal / max_amp
        
    # Apply a hard limit just in case to prevent clipping
    signal = signal * 0.9 
    
    # Convert float [-1.0, 1.0] to int16 [-32767, 32767]
    audio_int16 = np.int16(signal * 32767)
    return audio_int16

def main():
    print(f"Loading calls from {JSON_PATH}...")
    
    with open(JSON_PATH, 'r') as f:
        data = json.load(f)
        
    calls = data.get('calls', [])
    print(f"Found {len(calls)} call profiles. Synthesizing Champion Tracks...")
    
    for call in calls:
        call_id = call.get('id', 'unknown')
        animal_name = call.get('animalName', 'Unknown')
        call_type = call.get('callType', 'Call')
        
        print(f"  Synthesizing {animal_name} - {call_type} ({call_id})...")
        
        
        orig_path = call.get('audioAssetPath', '')
        
        # Generate raw audio
        audio_data = generate_tone(call)
        
        # Write to WAV file
        new_path = orig_path.replace('.mp3', '_diagnostic.wav')
        call['diagnosticAudioAssetPath'] = new_path
        file_name = new_path.split('/')[-1]
        out_filepath = os.path.join(AUDIO_OUT_DIR, file_name)

        with wave.open(out_filepath, 'w') as wav_file:
            wav_file.setnchannels(1) # Mono
            wav_file.setsampwidth(2) # 16-bit
            wav_file.setframerate(44100)
            wav_file.writeframes(audio_data.tobytes())
            
    # Save the updated JSON (pointing to the new .wav paths)
    with open(JSON_PATH, 'w') as f:
        json.dump(data, f, indent=2)
        
    print(f"\\nSuccessfully generated {len(calls)} Studio Champion tracks.")
    print("Pre-calculated waveforms from the JSON were used to perfectly align the temporal envelopes.")

if __name__ == '__main__':
    main()
