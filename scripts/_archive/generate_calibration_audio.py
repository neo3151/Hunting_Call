import numpy as np
from scipy.io import wavfile
import os

# Target specifications from reference_calls.json
SAMPLE_RATE = 44100
DURATION_SEC = 11.0
FUNDAMENTAL_FREQ = 331.1

def generate_perfect_call(filename):
    print(f"Generating perfect calibration file: {filename}")
    
    # 1. Create the time array
    t = np.linspace(0, DURATION_SEC, int(SAMPLE_RATE * DURATION_SEC), False)
    
    # 2. Generate the waveform with strong biological harmonics
    # Real animal calls are never pure sine waves, they have rich harmonics.
    # We add 6 harmonics to ensure 'harmonicRichness' and 'toneClarity' score 100%.
    waveform = np.sin(FUNDAMENTAL_FREQ * 2 * np.pi * t)           # Fundamental
    waveform += 0.5 * np.sin(2 * FUNDAMENTAL_FREQ * 2 * np.pi * t) # H2
    waveform += 0.3 * np.sin(3 * FUNDAMENTAL_FREQ * 2 * np.pi * t) # H3
    waveform += 0.2 * np.sin(4 * FUNDAMENTAL_FREQ * 2 * np.pi * t) # H4
    waveform += 0.1 * np.sin(5 * FUNDAMENTAL_FREQ * 2 * np.pi * t) # H5
    waveform += 0.05 * np.sin(6 * FUNDAMENTAL_FREQ * 2 * np.pi * t) # H6
    
    # Create a flat envelope for perfect volume consistency (non-pulsed call reference)
    envelope = np.ones_like(t)
    
    # Apply envelope to the continuous tone
    waveform = waveform * envelope
    
    # Normalize to an ideal RMS volume (~0.2 RMS)
    current_rms = np.sqrt(np.mean(waveform**2))
    target_rms = 0.2
    waveform = waveform * (target_rms / current_rms)
    
    # Convert to 16-bit PCM integer
    audio_data = np.int16(waveform * 32767)
    
    # Save the file
    filepath = os.path.join(os.path.dirname(os.path.abspath(__file__)), filename)
    wavfile.write(filepath, SAMPLE_RATE, audio_data)
    print(f"Saved to: {filepath}")

if __name__ == "__main__":
    generate_perfect_call("perfect_mallard.wav")
