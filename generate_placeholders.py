import wave
import math
import struct
import os
import random

# Configuration
SAMPLE_RATE = 44100
AUDIO_DIR = "assets/audio"

def save_wav(filename, samples):
    path = os.path.join(AUDIO_DIR, filename)
    with wave.open(path, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(SAMPLE_RATE)
        for s in samples:
            # Clamp to 16-bit range
            val = max(-32767, min(32767, int(s)))
            wav_file.writeframesraw(struct.pack('<h', val))
    print(f"Generated {path}")

def generate_silence(duration):
    return [0] * int(SAMPLE_RATE * duration)

def generate_tone(frequency, duration, amplitude=8000):
    samples = []
    num_samples = int(SAMPLE_RATE * duration)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        val = amplitude * math.sin(2 * math.pi * frequency * t)
        samples.append(val)
    return samples

def generate_noise(duration, amplitude=5000):
    return [random.uniform(-amplitude, amplitude) for _ in range(int(SAMPLE_RATE * duration))]

def envelope(samples, attack, decay):
    # Simple AD envelope
    num_samples = len(samples)
    attack_samples = int(attack * SAMPLE_RATE)
    decay_samples = int(decay * SAMPLE_RATE)
    
    processed = []
    for i, s in enumerate(samples):
        env = 1.0
        if i < attack_samples:
            env = i / attack_samples
        elif i > num_samples - decay_samples:
            env = (num_samples - i) / decay_samples
        processed.append(s * env)
    return processed

# --- Animal Specific Generators ---

def generate_duck_mallard_greeting():
    # Quack: Short bursts of saw-like wave with filtering (approximated by clipped sine)
    samples = []
    quack_duration = 0.2
    for _ in range(4): # 4 quacks
        # Sawtooth-ish approximation
        chunk = []
        freq = 300
        for i in range(int(SAMPLE_RATE * quack_duration)):
            t = i / SAMPLE_RATE
            # Add harmonics
            val = 8000 * (math.sin(2*math.pi*freq*t) + 0.5*math.sin(2*math.pi*freq*2*t))
            val = val * (1 - (i / (SAMPLE_RATE * quack_duration))) # Decay
            chunk.append(val)
        samples.extend(chunk)
        samples.extend(generate_silence(0.1))
    return samples

def generate_elk_bull_bugle():
    # Bugle: Starts low, sweeps high (whistle), drops low
    samples = []
    duration = 3.0
    num_samples = int(SAMPLE_RATE * duration)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # Freq sweep: 500 -> 1200 -> 500
        if t < 0.5:
            freq = 500 + (700 * (t/0.5))
        elif t < 2.5:
            freq = 1200
        else:
            freq = 1200 - (700 * ((t-2.5)/0.5))
        
        val = 10000 * math.sin(2 * math.pi * freq * t)
        samples.append(val)
    return samples

def generate_deer_buck_grunt():
    # Grunt: Short, low frequency, guttural (noise modulated)
    samples = []
    duration = 0.5
    num_samples = int(SAMPLE_RATE * duration)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 80
        # AM modulation for guttural sound
        mod = math.sin(2 * math.pi * 30 * t) 
        val = 15000 * math.sin(2 * math.pi * freq * t) * (1 + 0.5 * mod)
        # Apply short envelope
        if t < 0.1: val *= (t/0.1)
        if t > 0.3: val *= (0.5 - t)/0.2
        samples.append(val)
    return samples

def generate_turkey_hen_yelp():
    # Yelp: Series of distinct high-pitch pulses
    samples = []
    yelp_duration = 0.35
    for _ in range(3):
        chunk = []
        for i in range(int(SAMPLE_RATE * yelp_duration)):
            t = i / SAMPLE_RATE
            freq = 800
            val = 8000 * math.sin(2 * math.pi * freq * t)
            # Volume envelope: rise and fall
            env = math.sin(math.pi * (t / yelp_duration))
            chunk.append(val * env)
        samples.extend(chunk)
        samples.extend(generate_silence(0.1))
    return samples

def generate_coyote_howl():
    # Howl: Long, sliding pitch, some vibrato
    samples = []
    duration = 4.0
    num_samples = int(SAMPLE_RATE * duration)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # Slide up then down
        base_freq = 600
        if t < 1.0:
            freq = base_freq + (400 * t)
        elif t < 3.0:
            freq = 1000
        else:
            freq = 1000 - (400 * (t-3.0))
            
        # Vibrato
        vibrato = 10 * math.sin(2 * math.pi * 6 * t)
        val = 9000 * math.sin(2 * math.pi * (freq + vibrato) * t)
        samples.append(val)
    return samples

def generate_goose_canadian_honk():
    # Honk: Two tones quickly shifting
    samples = []
    duration = 0.4
    num_samples = int(SAMPLE_RATE * duration)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # Break in voice
        freq = 400 if t < 0.2 else 600
        val = 12000 * math.sin(2 * math.pi * freq * t)
        # Roughness
        val *= (1 + 0.3 * math.sin(2 * math.pi * 50 * t))
        samples.append(val)
    return samples

def generate_owl_barred_hoot():
    # Rhythm: "Who cooks for you" - 4 distinct hoots
    samples = []
    rhythm = [0.4, 0.4, 0.4, 0.8] # Duration of notes
    gaps = [0.1, 0.1, 0.1, 0.5]
    
    for j, dur in enumerate(rhythm):
        chunk = []
        num = int(SAMPLE_RATE * dur)
        for i in range(num):
            t = i / SAMPLE_RATE
            freq = 500
            val = 10000 * math.sin(2 * math.pi * freq * t)
            # Tremolo
            val *= (1 + 0.2 * math.sin(2 * math.pi * 8 * t))
            # Envelope
            if t < 0.1: val *= (t/0.1)
            elif t > dur - 0.1: val *= (dur - t)/0.1
            chunk.append(val)
        samples.extend(chunk)
        if j < len(gaps):
            samples.extend(generate_silence(gaps[j]))
    return samples

def main():
    if not os.path.exists(AUDIO_DIR):
        os.makedirs(AUDIO_DIR)

    save_wav("duck_mallard_greeting.wav", generate_duck_mallard_greeting())
    save_wav("elk_bull_bugle.wav", generate_elk_bull_bugle())
    save_wav("deer_buck_grunt.wav", generate_deer_buck_grunt())
    save_wav("turkey_hen_yelp.wav", generate_turkey_hen_yelp())
    save_wav("coyote_howl.wav", generate_coyote_howl())
    save_wav("goose_canadian_honk.wav", generate_goose_canadian_honk())
    save_wav("owl_barred_hoot.wav", generate_owl_barred_hoot())

if __name__ == "__main__":
    main()
