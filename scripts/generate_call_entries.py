"""
Analyze new audio files and generate reference_calls.json entries
with waveform and spectrogram data matching the existing format.
"""
import json
import struct
import os
import subprocess
import math
import sys

AUDIO_DIR = r"C:\Users\neo31\Hunting_Call\assets\audio"
OUTPUT_FILE = r"C:\Users\neo31\Hunting_Call\assets\data\new_calls_entries.json"

# Number of waveform samples and spectrogram bins to match existing entries
WAVEFORM_SAMPLES = 80
SPECTROGRAM_TIME_BINS = 40
SPECTROGRAM_FREQ_BINS = 16

# Call definitions: mp3_filename -> metadata
CALL_DEFS = {
    # ── Mallard Duck (existing species) ──
    "mallard_flight_call.mp3": {
        "id": "mallard_flight_call", "animalName": "Mallard Duck", "callType": "Flight Call",
        "category": "Waterfowl", "difficulty": "Intermediate",
        "description": "A sharp, rhythmic series of quacks given by hens while in flight to maintain flock contact.",
        "proTips": "Keep notes quick and crisp. Slightly higher pitch than resting calls.",
        "scientificName": "Anas platyrhynchos",
        "imageUrl": "assets/images/animals/mallard.jpg",
    },
    "mallard_flying_call.mp3": {
        "id": "mallard_flying_call", "animalName": "Mallard Duck", "callType": "Flying Call",
        "category": "Waterfowl", "difficulty": "Intermediate",
        "description": "A continuous calling pattern used during sustained flight, signaling to other ducks below.",
        "proTips": "Maintain a steady rhythm without pausing between quacks.",
        "scientificName": "Anas platyrhynchos",
        "imageUrl": "assets/images/animals/mallard.jpg",
    },
    "mallard_quick_quack.mp3": {
        "id": "mallard_quick_quack", "animalName": "Mallard Duck", "callType": "Quick Quack",
        "category": "Waterfowl", "difficulty": "Easy",
        "description": "A rapid burst of quacks used to grab attention, effective for close-range decoying.",
        "proTips": "Short, punchy quacks — think 'come here NOW.' Don't overdo the volume.",
        "scientificName": "Anas platyrhynchos",
        "imageUrl": "assets/images/animals/mallard.jpg",
    },
    "mallard_long_quack_1.mp3": {
        "id": "mallard_long_quack_1", "animalName": "Mallard Duck", "callType": "Long Quack Series",
        "category": "Waterfowl", "difficulty": "Pro",
        "description": "An extended sequence of decreasing quacks, the classic highball to lonesome hen pattern.",
        "proTips": "Start loud and gradually decrease volume. Each quack should be slightly shorter than the last.",
        "scientificName": "Anas platyrhynchos",
        "imageUrl": "assets/images/animals/mallard.jpg",
    },
    "mallard_long_quack_2.mp3": {
        "id": "mallard_long_quack_2", "animalName": "Mallard Duck", "callType": "Lonesome Hen",
        "category": "Waterfowl", "difficulty": "Pro",
        "description": "The tail end of a long calling sequence — soft, pleading quacks that seal the deal.",
        "proTips": "Soft and subtle. This is the 'I'm here, where are you?' part of the sequence.",
        "scientificName": "Anas platyrhynchos",
        "imageUrl": "assets/images/animals/mallard.jpg",
    },
    "mallard_quack_chirp.mp3": {
        "id": "mallard_quack_chirp", "animalName": "Mallard Duck", "callType": "Quack & Chirp",
        "category": "Waterfowl", "difficulty": "Intermediate",
        "description": "A quack punctuated by a high chirp — a contented feeding sound that reassures nearby birds.",
        "proTips": "Mix quack with a quick upward chirp. Mimics a hen feeding confidently.",
        "scientificName": "Anas platyrhynchos",
        "imageUrl": "assets/images/animals/mallard.jpg",
    },

    # ── Green-Winged Teal (NEW species) ──
    "green_winged_teal_alarm.mp3": {
        "id": "green_winged_teal_alarm", "animalName": "Green-Winged Teal", "callType": "Alarm Call",
        "category": "Waterfowl", "difficulty": "Intermediate",
        "description": "A sharp, high-pitched peeping alarm that green-wings give when startled.",
        "proTips": "Quick, nervous bursts. These tiny ducks are skittish — sell the urgency.",
        "scientificName": "Anas crecca",
        "imageUrl": "assets/images/animals/green_winged_teal.png",
    },
    "green_winged_teal_flight.mp3": {
        "id": "green_winged_teal_flight", "animalName": "Green-Winged Teal", "callType": "Flight Call",
        "category": "Waterfowl", "difficulty": "Intermediate",
        "description": "The distinctive high whistle given by drakes during fast, agile flight.",
        "proTips": "Thin, reedy whistle. Green-wings are the fighter jets of ducks — match that speed.",
        "scientificName": "Anas crecca",
        "imageUrl": "assets/images/animals/green_winged_teal.png",
    },
    "green_winged_teal_repeated.mp3": {
        "id": "green_winged_teal_repeated", "animalName": "Green-Winged Teal", "callType": "Repeated Call",
        "category": "Waterfowl", "difficulty": "Easy",
        "description": "A steady, repetitive peeping used for social contact on the water.",
        "proTips": "Even rhythm, consistent pitch. Think 'I'm here, I'm here, I'm here.'",
        "scientificName": "Anas crecca",
        "imageUrl": "assets/images/animals/green_winged_teal.png",
    },
    "green_winged_teal_whistle.mp3": {
        "id": "green_winged_teal_whistle", "animalName": "Green-Winged Teal", "callType": "Drake Whistle",
        "category": "Waterfowl", "difficulty": "Pro",
        "description": "The crisp, ringing whistle of the drake — a signature green-wing sound.",
        "proTips": "Clean, clear whistle with a slight upward inflection at the end.",
        "scientificName": "Anas crecca",
        "imageUrl": "assets/images/animals/green_winged_teal.png",
    },

    # ── American Wigeon (NEW species) ──
    "american_wigeon_female_call.mp3": {
        "id": "american_wigeon_female_call", "animalName": "American Wigeon", "callType": "Female Call",
        "category": "Waterfowl", "difficulty": "Intermediate",
        "description": "A low, rough growl from the hen wigeon — often heard on marshes.",
        "proTips": "Guttural and low. Very different from a mallard quack — more like a short growl.",
        "scientificName": "Mareca americana",
        "imageUrl": "assets/images/animals/american_wigeon.png",
    },
    "american_wigeon_song.mp3": {
        "id": "american_wigeon_song", "animalName": "American Wigeon", "callType": "Drake Whistle",
        "category": "Waterfowl", "difficulty": "Easy",
        "description": "The iconic three-note 'whew-whew-whew' whistle of the drake wigeon.",
        "proTips": "Three breathy whistles, rising slightly. One of the easiest duck calls to learn.",
        "scientificName": "Mareca americana",
        "imageUrl": "assets/images/animals/american_wigeon.png",
    },

    # ── Bufflehead (NEW species) ──
    "bufflehead_flush_out.mp3": {
        "id": "bufflehead_flush_out", "animalName": "Bufflehead", "callType": "Flush Call",
        "category": "Waterfowl", "difficulty": "Pro",
        "description": "The hurried chattering a hen bufflehead makes when flushed from cover.",
        "proTips": "Rapid, nasal chattering. Buffleheads are quiet ducks — this is their loudest moment.",
        "scientificName": "Bucephala albeola",
        "imageUrl": "assets/images/animals/bufflehead.png",
    },
    "bufflehead_long_call.mp3": {
        "id": "bufflehead_long_call", "animalName": "Bufflehead", "callType": "Extended Call",
        "category": "Waterfowl", "difficulty": "Intermediate",
        "description": "A longer social call used between paired birds on calm water.",
        "proTips": "Soft and nasal. Buffleheads are tiny — keep the volume down.",
        "scientificName": "Bucephala albeola",
        "imageUrl": "assets/images/animals/bufflehead.png",
    },
    "bufflehead_alarm.mp3": {
        "id": "bufflehead_alarm", "animalName": "Bufflehead", "callType": "Alarm Call",
        "category": "Waterfowl", "difficulty": "Intermediate",
        "description": "A quick, squeaky alarm given before diving or taking flight.",
        "proTips": "Short squeaky bursts. Buffleheads prefer diving to flying — mirror that nervousness.",
        "scientificName": "Bucephala albeola",
        "imageUrl": "assets/images/animals/bufflehead.png",
    },

    # ── Gadwall (NEW species) ──
    "gadwall_alarm.mp3": {
        "id": "gadwall_alarm", "animalName": "Gadwall", "callType": "Alarm Call",
        "category": "Waterfowl", "difficulty": "Intermediate",
        "description": "A nasal, reedy alarm call — the gadwall's signature nervous quack.",
        "proTips": "Nasally and reedy, not as loud as a mallard. Think 'meh' with attitude.",
        "scientificName": "Mareca strepera",
        "imageUrl": "assets/images/animals/gadwall.png",
    },
    "gadwall_alarm_2.mp3": {
        "id": "gadwall_alarm_2", "animalName": "Gadwall", "callType": "Alarm Series",
        "category": "Waterfowl", "difficulty": "Intermediate",
        "description": "A sustained alarm calling sequence, more urgent than the single alarm.",
        "proTips": "Faster tempo than the single alarm. Escalating urgency.",
        "scientificName": "Mareca strepera",
        "imageUrl": "assets/images/animals/gadwall.png",
    },
    "gadwall_flight.mp3": {
        "id": "gadwall_flight", "animalName": "Gadwall", "callType": "Flight Call",
        "category": "Waterfowl", "difficulty": "Pro",
        "description": "The subtle flight call male gadwalls make — a short, nasal 'nheck.'",
        "proTips": "Very understated. Gadwalls are the 'gray ghost' — their calls match their subtlety.",
        "scientificName": "Mareca strepera",
        "imageUrl": "assets/images/animals/gadwall.png",
    },

    # ── Northern Shoveler (NEW species) ──
    "northern_shoveler_alarm.mp3": {
        "id": "northern_shoveler_alarm", "animalName": "Northern Shoveler", "callType": "Alarm Call",
        "category": "Waterfowl", "difficulty": "Intermediate",
        "description": "A low, nasal 'took-took' alarm call unique to shovelers.",
        "proTips": "Low and hollow-sounding. The oversized bill creates a unique resonance.",
        "scientificName": "Spatula clypeata",
        "imageUrl": "assets/images/animals/northern_shoveler.png",
    },
    "northern_shoveler_chirp.mp3": {
        "id": "northern_shoveler_chirp", "animalName": "Northern Shoveler", "callType": "Chirp",
        "category": "Waterfowl", "difficulty": "Easy",
        "description": "A soft chirping contact sound shovelers make while feeding in groups.",
        "proTips": "Soft, bubbly chirps. Think of it as 'contented background noise.'",
        "scientificName": "Spatula clypeata",
        "imageUrl": "assets/images/animals/northern_shoveler.png",
    },
    "northern_shoveler_quick.mp3": {
        "id": "northern_shoveler_quick", "animalName": "Northern Shoveler", "callType": "Quick Call",
        "category": "Waterfowl", "difficulty": "Intermediate",
        "description": "A rapid call burst used as an attention-getter on the water.",
        "proTips": "Quick and nasally. Shovelers tend to call in short bursts.",
        "scientificName": "Spatula clypeata",
        "imageUrl": "assets/images/animals/northern_shoveler.png",
    },

    # ── Blue-Winged Teal (existing species) ──
    "bw_teal_cluck.mp3": {
        "id": "bw_teal_cluck", "animalName": "Blue-Winged Teal", "callType": "Cluck",
        "category": "Waterfowl", "difficulty": "Easy",
        "description": "A soft clucking sound blue-wings make while loafing on water.",
        "proTips": "Gentle, quiet. Blue-wings are often silent — this is their casual chatter.",
        "scientificName": "Spatula discors",
        "imageUrl": "assets/images/animals/teal.jpg",
    },
    "bw_teal_flying.mp3": {
        "id": "bw_teal_flying", "animalName": "Blue-Winged Teal", "callType": "Flying Call",
        "category": "Waterfowl", "difficulty": "Intermediate",
        "description": "A thin, lisping flight call blue-wings give when moving between feeding areas.",
        "proTips": "Thin and high. Blue-wings are small and their calls reflect that.",
        "scientificName": "Spatula discors",
        "imageUrl": "assets/images/animals/teal.jpg",
    },
    "bw_teal_song.mp3": {
        "id": "bw_teal_song", "animalName": "Blue-Winged Teal", "callType": "Song",
        "category": "Waterfowl", "difficulty": "Pro",
        "description": "A complex vocalization the drake produces during breeding display.",
        "proTips": "Multi-note, musical. This is the showpiece call of the blue-wing drake.",
        "scientificName": "Spatula discors",
        "imageUrl": "assets/images/animals/teal.jpg",
    },

    # ── Wood Duck (existing species) ──
    "wood_duck_flushed.mp3": {
        "id": "wood_duck_flushed", "animalName": "Wood Duck", "callType": "Flush Call",
        "category": "Waterfowl", "difficulty": "Intermediate",
        "description": "The panicked 'oo-eek!' a hen wood duck gives when flushed from cover.",
        "proTips": "Rising, squealing note. Very distinctive — like a surprised squeak.",
        "scientificName": "Aix sponsa",
        "imageUrl": "assets/images/animals/wood_duck.jpg",
    },
    "wood_duck_flying.mp3": {
        "id": "wood_duck_flying", "animalName": "Wood Duck", "callType": "Flying Call",
        "category": "Waterfowl", "difficulty": "Intermediate",
        "description": "The thin whistle wood ducks make during flight through wooded corridors.",
        "proTips": "Thin, wheezy whistle. Wood ducks fly through tight spaces — light, agile sound.",
        "scientificName": "Aix sponsa",
        "imageUrl": "assets/images/animals/wood_duck.jpg",
    },
    "wood_duck_scared.mp3": {
        "id": "wood_duck_scared", "animalName": "Wood Duck", "callType": "Distress Call",
        "category": "Waterfowl", "difficulty": "Pro",
        "description": "A loud, harsh alarm sound given when a wood duck senses danger.",
        "proTips": "Loud and sharp — the woodie is genuinely afraid. Maximum urgency.",
        "scientificName": "Aix sponsa",
        "imageUrl": "assets/images/animals/wood_duck.jpg",
    },
    "wood_duck_squeal.mp3": {
        "id": "wood_duck_squeal", "animalName": "Wood Duck", "callType": "Squeal",
        "category": "Waterfowl", "difficulty": "Intermediate",
        "description": "The classic ascending squeal — the most recognizable wood duck sound.",
        "proTips": "Rising squeal that drops off. This IS the wood duck sound everyone knows.",
        "scientificName": "Aix sponsa",
        "imageUrl": "assets/images/animals/wood_duck.jpg",
    },

    # ── Muscovy Duck (NEW species) ──
    "muscovy_quack.mp3": {
        "id": "muscovy_quack", "animalName": "Muscovy Duck", "callType": "Quack",
        "category": "Waterfowl", "difficulty": "Easy",
        "description": "A low, breathy hissing quack — muscovies are nearly silent compared to other ducks.",
        "proTips": "Very quiet and breathy. Muscovies rarely vocalize loudly — keep it subdued.",
        "scientificName": "Cairina moschata",
        "imageUrl": "assets/images/animals/muscovy_duck.png",
    },

    # ── Fulvous Whistling-Duck (NEW species) ──
    "fulvous_whistling_duck.mp3": {
        "id": "fulvous_whistling_duck_call", "animalName": "Fulvous Whistling-Duck", "callType": "Whistle",
        "category": "Waterfowl", "difficulty": "Intermediate",
        "description": "A clear, high-pitched 'pe-chee' whistle given in flight and on the ground.",
        "proTips": "Clean two-note whistle, rising sharply. Very different from dabbling duck calls.",
        "scientificName": "Dendrocygna bicolor",
        "imageUrl": "assets/images/animals/fulvous_whistling_duck.png",
    },

    # ── American Crow (existing species) ──
    "crow_alarm.mp3": {
        "id": "crow_alarm", "animalName": "American Crow", "callType": "Alarm Call",
        "category": "Land Birds", "difficulty": "Easy",
        "description": "The urgent, rapid cawing crows give when a hawk or owl is spotted.",
        "proTips": "Fast, aggressive caws. This is the 'DANGER!' call — sell the panic.",
        "scientificName": "Corvus brachyrhynchos",
        "imageUrl": "assets/images/animals/crow.jpg",
    },
    "crow_caw_looped.mp3": {
        "id": "crow_caw_looped", "animalName": "American Crow", "callType": "Caw (Looped)",
        "category": "Land Birds", "difficulty": "Easy",
        "description": "A sustained cawing sequence — the standard 'I'm here' territorial call.",
        "proTips": "Steady, rhythmic caws. Each one should be clean and equally spaced.",
        "scientificName": "Corvus brachyrhynchos",
        "imageUrl": "assets/images/animals/crow.jpg",
    },

    # ── Wild Turkey (existing species) ──
    "turkey_roost.mp3": {
        "id": "turkey_roost", "animalName": "Wild Turkey", "callType": "Roost Call",
        "category": "Land Birds", "difficulty": "Pro",
        "description": "The soft tree yelps turkeys make at dusk as they settle onto roost branches.",
        "proTips": "Soft, muffled yelps. Roosting turkeys are calm — match that mood.",
        "scientificName": "Meleagris gallopavo",
        "imageUrl": "assets/images/animals/turkey.jpg",
    },
    "turkey_unique.mp3": {
        "id": "turkey_unique_call", "animalName": "Wild Turkey", "callType": "Unique Call",
        "category": "Land Birds", "difficulty": "Intermediate",
        "description": "A distinctive vocalization not commonly heard — effective for curious toms.",
        "proTips": "Unusual cadence that stands out. Use sparingly for maximum effect.",
        "scientificName": "Meleagris gallopavo",
        "imageUrl": "assets/images/animals/turkey.jpg",
    },

    # ── Lion (NEW species) ──
    "lion_scream.mp3": {
        "id": "lion_scream", "animalName": "Lion", "callType": "Scream",
        "category": "Predators", "difficulty": "Pro",
        "description": "A raw, piercing scream — used for long-distance territorial communication.",
        "proTips": "Deep, powerful sound from the chest. Feel the vibration in your core.",
        "scientificName": "Panthera leo",
        "imageUrl": "assets/images/animals/lion.png",
    },
}


def get_audio_info(filepath):
    """Get duration and sample rate using ffprobe."""
    cmd = [
        "ffprobe", "-v", "quiet", "-print_format", "json",
        "-show_streams", "-show_format", filepath
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        return None, None
    data = json.loads(result.stdout)
    duration = float(data.get("format", {}).get("duration", 0))
    sr = int(data.get("streams", [{}])[0].get("sample_rate", 44100))
    return duration, sr


def get_raw_pcm(filepath, sr=44100):
    """Convert audio to raw PCM float32 using ffmpeg."""
    cmd = [
        "ffmpeg", "-y", "-i", filepath,
        "-ar", str(sr), "-ac", "1",
        "-f", "f32le", "-"
    ]
    result = subprocess.run(cmd, capture_output=True)
    if result.returncode != 0:
        return []
    raw = result.stdout
    n_samples = len(raw) // 4
    samples = list(struct.unpack(f"{n_samples}f", raw))
    return samples


def compute_waveform(samples, n_bins=WAVEFORM_SAMPLES):
    """Compute amplitude envelope (RMS per bin)."""
    if not samples:
        return [0.0] * n_bins
    bin_size = max(1, len(samples) // n_bins)
    waveform = []
    for i in range(n_bins):
        start = i * bin_size
        end = min(start + bin_size, len(samples))
        chunk = samples[start:end]
        if not chunk:
            waveform.append(0.0)
            continue
        rms = math.sqrt(sum(s * s for s in chunk) / len(chunk))
        waveform.append(rms)
    # Normalize to 0-1
    mx = max(waveform) if waveform else 1.0
    if mx > 0:
        waveform = [round(v / mx, 3) for v in waveform]
    return waveform


def compute_spectrogram(samples, sr=44100, n_time=SPECTROGRAM_TIME_BINS, n_freq=SPECTROGRAM_FREQ_BINS):
    """Compute a basic spectrogram using DFT (no numpy required)."""
    if not samples:
        return [[0.0] * n_freq for _ in range(n_time)]
    
    # Window size for each time bin
    hop = max(1, len(samples) // n_time)
    fft_size = 512  # Small FFT for speed
    
    spectrogram = []
    for t in range(n_time):
        start = t * hop
        end = min(start + fft_size, len(samples))
        frame = samples[start:end]
        
        # Zero-pad if needed
        while len(frame) < fft_size:
            frame.append(0.0)
        
        # Apply Hann window
        for i in range(fft_size):
            frame[i] *= 0.5 * (1 - math.cos(2 * math.pi * i / (fft_size - 1)))
        
        # Compute magnitude spectrum via DFT (only first n_freq bins)
        magnitudes = []
        bins_per_band = max(1, (fft_size // 2) // n_freq)
        for band in range(n_freq):
            # Average magnitude in this frequency band
            band_sum = 0.0
            for k in range(band * bins_per_band, min((band + 1) * bins_per_band, fft_size // 2)):
                real = sum(frame[n] * math.cos(2 * math.pi * k * n / fft_size) for n in range(fft_size))
                imag = sum(frame[n] * math.sin(2 * math.pi * k * n / fft_size) for n in range(fft_size))
                band_sum += math.sqrt(real * real + imag * imag)
            magnitudes.append(band_sum / bins_per_band)
        
        spectrogram.append(magnitudes)
    
    # Normalize to 0-1
    flat = [v for row in spectrogram for v in row]
    mx = max(flat) if flat else 1.0
    if mx > 0:
        spectrogram = [[round(v / mx, 3) for v in row] for row in spectrogram]
    
    return spectrogram


def estimate_pitch(samples, sr=44100):
    """Simple autocorrelation pitch detection."""
    if len(samples) < 1024:
        return 440.0
    
    # Use middle portion of audio
    mid = len(samples) // 2
    frame = samples[mid - 512:mid + 512]
    
    # Autocorrelation
    min_lag = sr // 2000  # Max 2000 Hz
    max_lag = sr // 50    # Min 50 Hz
    max_lag = min(max_lag, len(frame) - 1)
    
    best_lag = min_lag
    best_val = -1
    
    for lag in range(min_lag, max_lag):
        correlation = sum(frame[i] * frame[i + lag] for i in range(len(frame) - lag))
        if correlation > best_val:
            best_val = correlation
            best_lag = lag
    
    pitch = sr / best_lag if best_lag > 0 else 440.0
    return round(pitch, 1)


if __name__ == "__main__":
    entries = []
    total = len(CALL_DEFS)
    
    for i, (filename, meta) in enumerate(sorted(CALL_DEFS.items()), 1):
        filepath = os.path.join(AUDIO_DIR, filename)
        if not os.path.exists(filepath):
            print(f"[{i}/{total}] SKIP (missing): {filename}")
            continue
        
        print(f"[{i}/{total}] Analyzing: {filename} ... ", end="", flush=True)
        
        # Get duration
        duration, sr = get_audio_info(filepath)
        if duration is None:
            print("ERROR (ffprobe)")
            continue
        
        # Get raw samples
        samples = get_raw_pcm(filepath, sr=44100)
        if not samples:
            print("ERROR (pcm)")
            continue
        
        # Compute features
        pitch = estimate_pitch(samples, 44100)
        waveform = compute_waveform(samples)
        spectrogram = compute_spectrogram(samples)
        
        entry = {
            "id": meta["id"],
            "animalName": meta["animalName"],
            "callType": meta["callType"],
            "category": meta["category"],
            "difficulty": meta["difficulty"],
            "description": meta["description"],
            "proTips": meta["proTips"],
            "idealPitchHz": pitch,
            "idealDurationSec": round(duration, 1),
            "audioAssetPath": f"assets/audio/{filename}",
            "isLocked": False,
            "scientificName": meta["scientificName"],
            "imageUrl": meta["imageUrl"],
            "waveform": waveform,
            "spectrogram": spectrogram,
        }
        entries.append(entry)
        print(f"OK (pitch={pitch}Hz, dur={duration:.1f}s)")
    
    # Write output
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump({"new_calls": entries}, f, indent=2, ensure_ascii=False)
    
    print(f"\nGenerated {len(entries)} entries -> {OUTPUT_FILE}")
