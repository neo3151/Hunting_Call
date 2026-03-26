"""
Analyze 49 new audio files and generate complete reference_calls.json entries.
Computes: duration, pitch (Hz), waveform (80 samples), spectrogram (32x16).
Outputs: new_calls_entries.json ready to merge into reference_calls.json.
"""

import json
import os
import sys
import struct
import numpy as np
from pydub import AudioSegment
from scipy import signal as sig
from scipy.fft import rfft, rfftfreq

AUDIO_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio')
OUTPUT_FILE = os.path.join(os.path.dirname(__file__), 'new_calls_entries.json')

# The 49 truly new calls
NEW_CALLS = [
    'beaver_slap', 'bobcat_growl', 'bobcat_growl_v2',
    'bufflehead_alarm', 'bufflehead_chatter', 'bufflehead_flush',
    'canada_goose_return', 'cinnamon_teal', 'cougar', 'coyote_challenge',
    'crow', 'crow_caw_series', 'crow_caw_series_v2',
    'deer_buck_challenge', 'deer_buck_grunt', 'deer_doe_bleat',
    'deer_fawn_distress_v2', 'deer_tending_grunt_v2',
    'dove', 'duck_mallard_alarm', 'duck_mallard_feeding', 'duck_mallard_hail',
    'egyptian_goose', 'emperor_goose',
    'gadwall_alarm', 'gadwall_alarm_v2', 'gadwall_flight', 'goose_cluck',
    'mallard_hen', 'moose_bellow', 'mule_deer', 'muscovy_duck_hiss',
    'pheasant', 'pintail', 'quail',
    'raccoon_hiss', 'raccoon_snarl', 'raccoon_squall',
    'shoveler_flushed_out', 'snow_goose', 'teal',
    'trumpeter_swan', 'tundra_swan',
    'turkey_gobble', 'turkey_purr',
    'white_fronted_goose', 'wood_duck', 'wood_duck_jeeee', 'wood_duck_sit'
]

# Metadata mapping: id -> (animalName, callType, category, difficulty, scientificName, description, proTips, imageUrl)
METADATA = {
    'beaver_slap': ('Beaver', 'Tail Slap', 'Predators', 'Easy', 'Castor canadensis',
        'The distinctive warning slap of a beaver tail on water.',
        'Use near water sources at dawn and dusk for best results.',
        'assets/images/animals/beaver.webp'),
    'bobcat_growl': ('Bobcat', 'Growl', 'Big Cats', 'Intermediate', 'Lynx rufus',
        'A deep, guttural growl used in territorial disputes.',
        'Play at low volume to avoid spooking. Works best during mating season.',
        'assets/images/animals/bobcat.webp'),
    'bobcat_growl_v2': ('Bobcat', 'Aggressive Growl', 'Big Cats', 'Pro', 'Lynx rufus',
        'An intense, aggressive growl variant with more urgency.',
        'Use sparingly. Best combined with prey distress calls.',
        'assets/images/animals/bobcat.webp'),
    'bufflehead_alarm': ('Bufflehead', 'Alarm Call', 'Waterfowl', 'Intermediate', 'Bucephala albeola',
        'A sharp alarm call that signals danger to the flock.',
        'Use to get nearby buffleheads moving and in range.',
        'assets/images/animals/bufflehead.png'),
    'bufflehead_chatter': ('Bufflehead', 'Chatter', 'Waterfowl', 'Intermediate', 'Bucephala albeola',
        'A rapid chattering vocalization used in social contexts.',
        'Effective when birds are settled and need coaxing into range.',
        'assets/images/animals/bufflehead.png'),
    'bufflehead_flush': ('Bufflehead', 'Flush Call', 'Waterfowl', 'Easy', 'Bucephala albeola',
        'The sound made when buffleheads flush from the water.',
        'Use to create urgency and draw decoying birds.',
        'assets/images/animals/bufflehead.png'),
    'canada_goose_return': ('Canada Goose', 'Return Call', 'Geese', 'Intermediate', 'Branta canadensis',
        'A welcoming call used to bring circling geese back to the flock.',
        'Timing is key — use when birds are turning back on approach.',
        'assets/images/animals/canada_goose.webp'),
    'cinnamon_teal': ('Cinnamon Teal', 'Call', 'Waterfowl', 'Intermediate', 'Spatula cyanoptera',
        'The soft, rattling call of the cinnamon teal drake.',
        'Keep it subtle. These are shy ducks that spook easily.',
        'assets/images/animals/cinnamon_teal.webp'),
    'cougar': ('Cougar', 'Call', 'Big Cats', 'Pro', 'Puma concolor',
        'A general cougar vocalization used for communication.',
        'Use extreme caution. Best from an elevated position.',
        'assets/images/animals/puma.webp'),
    'coyote_challenge': ('Coyote', 'Challenge Howl', 'Predators', 'Pro', 'Canis latrans',
        'An aggressive territorial challenge howl.',
        'Use during breeding season to provoke territorial males.',
        'assets/images/animals/coyote.webp'),
    'crow': ('Crow', 'Call', 'Land Birds', 'Easy', 'Corvus brachyrhynchos',
        'The standard crow caw used for general communication.',
        'Great as an attractor. Crows are curious and respond well.',
        'assets/images/animals/crow.webp'),
    'crow_caw_series': ('Crow', 'Caw Series', 'Land Birds', 'Intermediate', 'Corvus brachyrhynchos',
        'A rhythmic series of caws mimicking crow conversation.',
        'Play intermittently with pauses to sound natural.',
        'assets/images/animals/crow.webp'),
    'crow_caw_series_v2': ('Crow', 'Rapid Caw Series', 'Land Birds', 'Intermediate', 'Corvus brachyrhynchos',
        'A faster, more urgent caw series variant.',
        'Use to simulate excitement and draw crows in from farther away.',
        'assets/images/animals/crow.webp'),
    'deer_buck_challenge': ('Whitetail Deer', 'Buck Challenge', 'Big Game', 'Pro', 'Odocoileus virginianus',
        'An aggressive challenge grunt from a dominant buck.',
        'Only use during peak rut. Will attract or provoke mature bucks.',
        'assets/images/animals/whitetail_buck.webp'),
    'deer_buck_grunt': ('Whitetail Deer', 'Buck Grunt', 'Big Game', 'Intermediate', 'Odocoileus virginianus',
        'A short, deep grunt used by bucks to assert presence.',
        'Use every 15-20 minutes during the rut. Keep volume moderate.',
        'assets/images/animals/whitetail_buck.webp'),
    'deer_doe_bleat': ('Whitetail Deer', 'Doe Bleat', 'Big Game', 'Easy', 'Odocoileus virginianus',
        'The social bleat of a doe communicating with other deer.',
        'Great year-round call. Non-threatening and draws both sexes.',
        'assets/images/animals/whitetail_doe.webp'),
    'deer_fawn_distress_v2': ('Whitetail Deer', 'Fawn Distress V2', 'Big Game', 'Easy', 'Odocoileus virginianus',
        'An alternate fawn distress cry with varied pitch.',
        'Effective for attracting does and predators alike.',
        'assets/images/animals/whitetail_doe.webp'),
    'deer_tending_grunt_v2': ('Whitetail Deer', 'Tending Grunt V2', 'Big Game', 'Pro', 'Odocoileus virginianus',
        'A persistent tending grunt variant from a buck following a doe.',
        'Use during peak rut when bucks are actively chasing does.',
        'assets/images/animals/whitetail_buck.webp'),
    'dove': ('Mourning Dove', 'Coo', 'Land Birds', 'Easy', 'Zenaida macroura',
        'The soft, mournful cooing call iconic to mourning doves.',
        'Play softly and let the natural rhythm attract birds.',
        'assets/images/animals/mourning_dove.webp'),
    'duck_mallard_alarm': ('Mallard Duck', 'Alarm Call', 'Waterfowl', 'Intermediate', 'Anas platyrhynchos',
        'A sharp, urgent quack used to alert the flock to danger.',
        'Use to create urgency and get circling ducks to commit.',
        'assets/images/animals/mallard.webp'),
    'duck_mallard_feeding': ('Mallard Duck', 'Feeding Chuckle', 'Waterfowl', 'Easy', 'Anas platyrhynchos',
        'The soft chuckling sound mallards make while feeding.',
        'Essential finishing call. Use when birds are close to decoys.',
        'assets/images/animals/mallard.webp'),
    'duck_mallard_hail': ('Mallard Duck', 'Hail Call', 'Waterfowl', 'Intermediate', 'Anas platyrhynchos',
        'A loud, high-volume call to attract distant mallards.',
        'Maximum volume for distant birds. Reduce as they approach.',
        'assets/images/animals/mallard.webp'),
    'egyptian_goose': ('Egyptian Goose', 'Call', 'Geese', 'Intermediate', 'Alopochen aegyptiaca',
        'The harsh, hissing honk of the Egyptian goose.',
        'Most effective near water with visible decoys.',
        'assets/images/animals/egyptian_goose.webp'),
    'emperor_goose': ('Emperor Goose', 'Call', 'Geese', 'Intermediate', 'Anser canagicus',
        'The deep, rhythmic call of the emperor goose.',
        'These are wary birds. Pair with adequate decoy spreads.',
        'assets/images/animals/emperor_goose.webp'),
    'gadwall_alarm': ('Gadwall', 'Alarm Call', 'Waterfowl', 'Intermediate', 'Mareca strepera',
        'A sharp, nasal alarm quack from the gadwall hen.',
        'Use to add realism to multi-species decoy spreads.',
        'assets/images/animals/gadwall.png'),
    'gadwall_alarm_v2': ('Gadwall', 'Alarm Call V2', 'Waterfowl', 'Intermediate', 'Mareca strepera',
        'An alternate gadwall alarm with slightly different cadence.',
        'Alternate with v1 to avoid sounding repetitive.',
        'assets/images/animals/gadwall.png'),
    'gadwall_flight': ('Gadwall', 'Flight Call', 'Waterfowl', 'Easy', 'Mareca strepera',
        'The whistling call gadwalls make in flight.',
        'Best used when birds are first spotted at a distance.',
        'assets/images/animals/gadwall.png'),
    'goose_cluck': ('Canada Goose', 'Cluck', 'Geese', 'Easy', 'Branta canadensis',
        'A soft clucking sound made by content, feeding geese.',
        'Use as a confidence call when geese are working the decoys.',
        'assets/images/animals/canada_goose.webp'),
    'mallard_hen': ('Mallard Duck', 'Hen Quack', 'Waterfowl', 'Easy', 'Anas platyrhynchos',
        'The classic hen mallard quack — the foundation of duck calling.',
        'Master this first. It is the bread and butter of waterfowl hunting.',
        'assets/images/animals/mallard.webp'),
    'moose_bellow': ('Moose', 'Bull Bellow', 'Big Game', 'Pro', 'Alces alces',
        'The deep, resonant bellow of a bull moose during rut.',
        'Use near water in early morning. Let it echo naturally.',
        'assets/images/animals/moose.webp'),
    'mule_deer': ('Mule Deer', 'Call', 'Big Game', 'Intermediate', 'Odocoileus hemionus',
        'A general mule deer vocalization for attracting deer.',
        'Effective in open terrain where sound carries well.',
        'assets/images/animals/mule_deer.webp'),
    'muscovy_duck_hiss': ('Muscovy Duck', 'Hiss', 'Waterfowl', 'Easy', 'Cairina moschata',
        'The characteristic hissing vocalization of the muscovy duck.',
        'Muscovy ducks are quiet — keep volume very low.',
        'assets/images/animals/muscovy_duck.png'),
    'pheasant': ('Ring-necked Pheasant', 'Cackle', 'Land Birds', 'Easy', 'Phasianus colchicus',
        'The loud, distinctive cackle of a rooster pheasant.',
        'Best in morning and evening. Use during flush-and-walk hunts.',
        'assets/images/animals/pheasant.webp'),
    'pintail': ('Northern Pintail', 'Whistle', 'Waterfowl', 'Intermediate', 'Anas acuta',
        'The soft, rolling whistle of the pintail drake.',
        'Subtle call. Use in mixed decoy spreads to add variety.',
        'assets/images/animals/pintail.webp'),
    'quail': ('Bobwhite Quail', 'Bob-White Call', 'Land Birds', 'Easy', 'Colinus virginianus',
        'The iconic "bob-WHITE" whistle of the bobwhite quail.',
        'Use as a locator call. Wait for response before moving.',
        'assets/images/animals/quail.webp'),
    'raccoon_hiss': ('Raccoon', 'Hiss', 'Predators', 'Easy', 'Procyon lotor',
        'A defensive hissing sound raccoons make when threatened.',
        'Effective as a predator call for coyotes and foxes.',
        'assets/images/animals/raccoon.webp'),
    'raccoon_snarl': ('Raccoon', 'Snarl', 'Predators', 'Intermediate', 'Procyon lotor',
        'An aggressive snarling vocalization during confrontation.',
        'Good secondary predator call. Rotate with distress calls.',
        'assets/images/animals/raccoon.webp'),
    'raccoon_squall': ('Raccoon', 'Squall', 'Predators', 'Intermediate', 'Procyon lotor',
        'A loud squalling cry of a raccoon in distress.',
        'Very effective predator attractor. Use from concealment.',
        'assets/images/animals/raccoon.webp'),
    'shoveler_flushed_out': ('Northern Shoveler', 'Flushed Call', 'Waterfowl', 'Easy', 'Spatula clypeata',
        'The alarm vocalization of a flushed northern shoveler.',
        'Use to simulate activity and attract passing ducks.',
        'assets/images/animals/northern_shoveler.png'),
    'snow_goose': ('Snow Goose', 'Call', 'Geese', 'Intermediate', 'Anser caerulescens',
        'The high-pitched, barking call of the snow goose.',
        'Volume is key. Snow geese are noisy — match their energy.',
        'assets/images/animals/snow_goose.webp'),
    'teal': ('Green-winged Teal', 'Call', 'Waterfowl', 'Easy', 'Anas crecca',
        'A general teal whistle and peep vocalization.',
        'Keep it soft and short. Teal respond to subtle calls.',
        'assets/images/animals/teal.webp'),
    'trumpeter_swan': ('Trumpeter Swan', 'Call', 'Waterfowl', 'Intermediate', 'Cygnus buccinator',
        'The loud, resonant honking of the trumpeter swan.',
        'Use near large water bodies where swans typically feed.',
        'assets/images/animals/trumpeter_swan.webp'),
    'tundra_swan': ('Tundra Swan', 'Call', 'Waterfowl', 'Intermediate', 'Cygnus columbianus',
        'The high-pitched, musical call of the tundra swan.',
        'Effective during migration season near staging areas.',
        'assets/images/animals/tundra_swan.webp'),
    'turkey_gobble': ('Wild Turkey', 'Gobble', 'Land Birds', 'Intermediate', 'Meleagris gallopavo',
        'The iconic gobble of a male wild turkey.',
        'Best in spring. Use to locate and challenge toms.',
        'assets/images/animals/turkey.webp'),
    'turkey_purr': ('Wild Turkey', 'Purr', 'Land Birds', 'Easy', 'Meleagris gallopavo',
        'A soft, contented purring sound turkeys make while feeding.',
        'Great confidence call. Use when birds are close.',
        'assets/images/animals/turkey.webp'),
    'white_fronted_goose': ('White-fronted Goose', 'Call', 'Geese', 'Intermediate', 'Anser albifrons',
        'The distinctive high-pitched laughing call of the specklebelly.',
        'Use two-note calls. Sounds like a "yodel" that carries far.',
        'assets/images/animals/white_fronted_goose.webp'),
    'wood_duck': ('Wood Duck', 'Call', 'Waterfowl', 'Easy', 'Aix sponsa',
        'The squealing whistle of the wood duck drake.',
        'Use near wooded waterways and beaver ponds.',
        'assets/images/animals/wood_duck.webp'),
    'wood_duck_jeeee': ('Wood Duck', 'Jeeee Call', 'Waterfowl', 'Intermediate', 'Aix sponsa',
        'The drawn-out "jeeee" rising whistle of a wood duck in flight.',
        'Most effective when birds are overhead. Timing matters.',
        'assets/images/animals/wood_duck.webp'),
    'wood_duck_sit': ('Wood Duck', 'Sit-down Call', 'Waterfowl', 'Easy', 'Aix sponsa',
        'The soft landing call wood ducks make when setting down.',
        'Use as a finishing call when birds are circling to land.',
        'assets/images/animals/wood_duck.webp'),
}

WAVEFORM_SAMPLES = 80
SPECTRO_TIME_BINS = 32
SPECTRO_FREQ_BANDS = 16


def analyze_audio(filepath):
    """Analyze an MP3 file and return audio stats."""
    audio = AudioSegment.from_mp3(filepath)
    duration_sec = len(audio) / 1000.0

    # Convert to mono numpy array
    samples = np.array(audio.set_channels(1).get_array_of_samples(), dtype=np.float64)
    sample_rate = audio.frame_rate

    # Normalize
    max_val = np.max(np.abs(samples))
    if max_val > 0:
        samples = samples / max_val

    # == Pitch detection via FFT on loudest 0.5s segment ==
    window_size = min(int(0.5 * sample_rate), len(samples))
    # Find loudest window
    rms_vals = []
    step = max(window_size // 4, 1)
    for i in range(0, len(samples) - window_size, step):
        rms_vals.append((i, np.sqrt(np.mean(samples[i:i+window_size]**2))))
    if rms_vals:
        best_start = max(rms_vals, key=lambda x: x[1])[0]
    else:
        best_start = 0

    segment = samples[best_start:best_start+window_size]
    windowed = segment * np.hanning(len(segment))
    fft_vals = np.abs(rfft(windowed))
    freqs = rfftfreq(len(windowed), 1.0/sample_rate)

    # Focus on animal-relevant range (50 Hz - 8000 Hz)
    mask = (freqs >= 50) & (freqs <= 8000)
    if np.any(mask):
        fft_masked = fft_vals[mask]
        freqs_masked = freqs[mask]
        ideal_pitch = float(freqs_masked[np.argmax(fft_masked)])
    else:
        ideal_pitch = 440.0

    # == Waveform (80 samples, envelope) ==
    abs_samples = np.abs(samples)
    chunk_size = max(len(abs_samples) // WAVEFORM_SAMPLES, 1)
    waveform = []
    for i in range(WAVEFORM_SAMPLES):
        start = i * chunk_size
        end = min(start + chunk_size, len(abs_samples))
        if start < len(abs_samples):
            waveform.append(float(np.max(abs_samples[start:end])))
        else:
            waveform.append(0.0)

    # Normalize waveform to 0-1
    wf_max = max(waveform) if waveform else 1.0
    if wf_max > 0:
        waveform = [round(v / wf_max, 3) for v in waveform]

    # == Spectrogram (32 time bins x 16 freq bands) ==
    nperseg = min(1024, len(samples) // 4) if len(samples) > 256 else len(samples)
    if nperseg < 16:
        nperseg = 16
    noverlap = nperseg // 2

    f, t, Sxx = sig.spectrogram(samples, fs=sample_rate, nperseg=nperseg, noverlap=noverlap)

    # Limit to 0-4000 Hz range
    freq_mask = f <= 4000
    Sxx_limited = Sxx[freq_mask, :]

    # Resample to 16 freq bands x 32 time bins
    from scipy.ndimage import zoom
    if Sxx_limited.shape[0] > 0 and Sxx_limited.shape[1] > 0:
        zoom_factors = (SPECTRO_FREQ_BANDS / Sxx_limited.shape[0],
                       SPECTRO_TIME_BINS / Sxx_limited.shape[1])
        spectro_resampled = zoom(Sxx_limited, zoom_factors, order=1)
    else:
        spectro_resampled = np.zeros((SPECTRO_FREQ_BANDS, SPECTRO_TIME_BINS))

    # Normalize, convert to dB-like scale, then 0-1
    spectro_db = 10 * np.log10(spectro_resampled + 1e-10)
    s_min, s_max = spectro_db.min(), spectro_db.max()
    if s_max > s_min:
        spectro_norm = (spectro_db - s_min) / (s_max - s_min)
    else:
        spectro_norm = np.zeros_like(spectro_db)

    # Transpose to [time][freq] and round
    spectrogram = []
    for t_idx in range(SPECTRO_TIME_BINS):
        freq_row = []
        for f_idx in range(SPECTRO_FREQ_BANDS):
            if t_idx < spectro_norm.shape[1] and f_idx < spectro_norm.shape[0]:
                freq_row.append(round(float(spectro_norm[f_idx, t_idx]), 3))
            else:
                freq_row.append(0.0)
        spectrogram.append(freq_row)

    return {
        'duration': round(duration_sec, 1),
        'pitch': round(ideal_pitch, 1),
        'waveform': waveform,
        'spectrogram': spectrogram,
    }


def build_entry(call_id, audio_stats):
    """Build a complete reference_calls.json entry."""
    meta = METADATA.get(call_id)
    if not meta:
        print(f"WARNING: No metadata for {call_id}, using defaults")
        meta = (call_id.replace('_', ' ').title(), 'Call', 'General', 'Intermediate',
                '', 'Animal call.', 'Listen and practice.', '')

    animal_name, call_type, category, difficulty, sci_name, desc, tips, image_url = meta

    # Determine isPulsedCall based on call type
    pulsed_types = ['Caw Series', 'Rapid Caw Series', 'Chatter', 'Feeding Chuckle', 'Purr', 'Cackle']
    is_pulsed = call_type in pulsed_types

    entry = {
        'id': call_id,
        'animalName': animal_name,
        'callType': call_type,
        'category': category,
        'difficulty': difficulty,
        'description': desc,
        'proTips': tips,
        'idealPitchHz': audio_stats['pitch'],
        'idealDurationSec': audio_stats['duration'],
        'audioAssetPath': f'assets/audio/{call_id}.mp3',
        'isLocked': False,
        'scientificName': sci_name,
        'imageUrl': image_url,
        'waveform': audio_stats['waveform'],
        'spectrogram': audio_stats['spectrogram'],
    }

    if is_pulsed:
        entry['isPulsedCall'] = True
        entry['idealTempo'] = 60.0  # default

    return entry


def main():
    entries = []
    total = len(NEW_CALLS)

    for i, call_id in enumerate(NEW_CALLS, 1):
        filepath = os.path.join(AUDIO_DIR, f'{call_id}.mp3')
        if not os.path.exists(filepath):
            print(f"[ERROR] File not found: {filepath}")
            continue

        pct = round(i / total * 100)
        filled = pct // 5
        empty = 20 - filled
        bar = '\u2588' * filled + '\u2591' * empty
        print(f"[{bar}] {pct}% | {i}/{total} | Analyzing {call_id}", flush=True)

        try:
            stats = analyze_audio(filepath)
            entry = build_entry(call_id, stats)
            entries.append(entry)
        except Exception as e:
            print(f"  [ERROR] Failed to analyze {call_id}: {e}")

    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(entries, f, indent=2, ensure_ascii=False)

    print(f"\nDone! Generated {len(entries)} entries -> {OUTPUT_FILE}")


if __name__ == '__main__':
    main()
