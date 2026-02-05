# 🦆 Hunting Call Audio Sourcing Guide

To reach the goal of 50 high-fidelity animal calls, you can replace the current synthetic reference tones with real-world recordings. This guide provides sources and instructions for normalization.

## 📥 Recommended Real-Audio Sources

### 🦊 Predators (Coyote, Wolf, Bobcat, Fox)
- **Coyote (Howl/Pup Distress)**: [Varmint Al's Archive](https://www.varmintal.net/ahunt.htm#Sound) - *Legendary high-quality WAVs.*
- **Gray Wolf (Howl/Bark)**: [NPS Denali Sound Gallery](https://www.nps.gov/dena/learn/nature/soundgallery-mammals.htm)
- **Bobcat/Fox**: [Predator Masters Forum Downloads](https://www.predatormasters.com/downloads/)

### 🦌 Big Game (Elk, Deer, Moose, Bear)
- **Bull Elk Bugle**: [Yellowstone NPS Library](https://www.nps.gov/yell/learn/photosmultimedia/soundlibrary.htm)
- **Moose Cow Call**: [NPS Denali Sound Gallery](https://www.nps.gov/dena/learn/nature/soundgallery-mammals.htm)
- **Whitetail Deer**: [HME Products Audio](https://www.hmeproducts.com/audio-downloads/) - *Look for Buck Grunt and Doe Bleat.*

### 🦆 Waterfowl & 🦃 Land Birds
- **Mallard/Goose**: [ElevenLabs Field Effects](https://elevenlabs.io/sound-effects/duck)
- **Wild Turkey**: [National Wild Turkey Federation (NWTF)](https://www.nwtf.org/hunt/article/turkey-sounds) - *Excellent for Yelps, Clucks, and Gobbles.*
- **Quail/Pheasant**: [Xeno-canto.org](https://xeno-canto.org/) - *Search species name; download as MP3/Ogg and convert to WAV.*

### 🐗 Exotic & Specialty Game
- **Wild Hog Grunt**: [Mixkit Free Animal Sounds](https://mixkit.co/free-sound-effects/boar/) or [Audio.com](https://audio.com/search?q=boar+grunt)
- **Red Stag Roar**: [SoundBible](https://soundbible.com/tags-stag.html) or [Freesound.org](https://freesound.org/search/?q=red+stag+roar)

## 🛠️ Calibration & Normalization (The "Treatment")

For the scoring engine to work accurately, every new file added to `assets/audio/` should follow these standards:

1.  **Format**: Mono WAV
2.  **Sample Rate**: 44,100 Hz
3.  **Intensity**: Normalize to **-3dB** peak
4.  **Duration**: 3 - 10 seconds (trimmed to the core call)

### 🚀 Automation: The Reference Processor
I have prepared a script at `scripts/generate_refs.dart`. You can run this whenever you add new files:
```bash
dart scripts/generate_refs.dart
```

## 📋 Expansion Progress (50 Animals)

*   [x] **Metadata Structure**: All 50 species defined with descriptions/tips.
*   [x] **Baseline Audio**: 50 reference tones generated and mapped.
*   [ ] **Field Upgrades**: Replace `.wav` files in `assets/audio/` as recordings are collected.

### 📍 Current Mapping Checklist:
- `duck_mallard_greeting.wav` (Verified)
- `coyote_howl.wav` (Verified)
- `elk_bull_bugle.wav` (Verified)
- `turkey_gobble.wav` (Verified)
- *... + 46 more placeholders generated.*

---
> [!TIP]
> If you have a folder of recordings on your machine, you can simply drag them into `assets/audio/` and rename them to match the IDs in `reference_calls.json`. The app will handle the rest!
