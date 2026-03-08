# OUTCALL - THE MASTER KNOWLEDGE BASE\nThis document contains the entire 44-article encyclopedia, wiki, and technical documentation for the OUTCALL application. It is specifically compiled for LLM ingestion. Use this to reference bioacoustics, hunting strategies, app architecture, AI scoring, and premium mechanics.\n\n---\n\n## FILE: `animal_bioacoustics.md` [Category: Technical/Core]\n<document_content>\n# Animal Bioacoustics — Frequency & Spectral Reference

> Compiled from peer-reviewed bioacoustics research for use in OUTCALL's scoring engine calibration and reference call validation.

## Turkey (Meleagris gallopavo)

**Hearing range**: 290 Hz – 5,250 Hz (optimal sensitivity ~2,000 Hz)

| Call Type | Frequency Range | Notes |
|-----------|----------------|-------|
| **Gobble** | 400 – 4,500 Hz | Complex multi-harmonic vocalization |
| **Yelp** | ~1,000 Hz | Hen yelps higher-pitched than tom yelps |
| **Cluck** | ~1,300 Hz | Short, sharp single notes |
| **Purr** | 700 – 1,400 Hz | Soft, rolling contentment call |
| **Cackle** | 1,000 – 4,000 Hz | Excited, rapid series |
| **Cutting** | Up to 12,000–15,000 Hz | Aggressive excited calls; highest energy calls |

### Scoring Implications
- Turkey calls span a wide frequency range; pitch tolerance should be relatively wide (±100-200 Hz for fundamental)
- Harmonic content is critical for realism assessment (especially gobble)
- Rhythm/tempo matters greatly for yelps, clucks, and cutting sequences

---

## Elk (Cervus canadensis)

**Bugle structure**: Three segments — on-glide → whistle → off-glide

| Call Type | Frequency Range | Notes |
|-----------|----------------|-------|
| **Bugle (fundamental)** | ~145 Hz | Low-frequency vocal fold tone |
| **Bugle (whistle)** | 1,000 – 4,000+ Hz | Upper airway whistle, can be 10x higher than fundamental |
| **Cow call / Mew** | 800 – 2,000 Hz | Soft, rising pitch that trails off |
| **Alarm bark** | 1,500 – 3,000 Hz | Sharp, urgent, dog-like bark |
| **Calf mew** | Higher than cow mew | Higher pitch signals youth |

### Scoring Implications
- Elk bugle uses **biphonation** (two independent sound sources) — MFCC comparison must account for this dual-frequency signature
- Aggressive vs non-aggressive bugles differ in formant structure, not just pitch
- Duration is a key differentiator (bull bugles are longer than cow calls)

---

## White-tailed Deer (Odocoileus virginianus)

**Hearing range**: 250 Hz – 30+ kHz (best sensitivity 4–8 kHz)

| Call Type | Frequency Range | Notes |
|-----------|----------------|-------|
| **Grunt** | 100 – 500 Hz | Low, guttural; dominant buck communication |
| **Bleat** | 1,500 – 4,000 Hz | High-pitched doe/fawn call |
| **Fawn distress** | 2,000 – 6,000 Hz | Urgent, high-pitched |
| **Snort-wheeze** | Broadband | Nasal snort + wheeze; aggressive dominance display |
| **General vocalizations** | 1,000 – 8,000 Hz | Strongest energy at 3,000–6,500 Hz |

### Scoring Implications
- Grunt calls are very low frequency — pitch detection algorithms may need larger analysis windows
- Deer call audible range is only 100–200 yards, so volume/projection matters
- Snort-wheeze is broadband noise, difficult to score spectrally

---

## Coyote (Canis latrans)

**Hearing range**: Up to 45,000 Hz (45 kHz)

| Call Type | Frequency Range | Notes |
|-----------|----------------|-------|
| **Howl** | 500 – 3,000 Hz | Long-range territorial/social communication |
| **Yips/Yip-howl** | 1,000 – 5,000 Hz | Social bonding, pack reunion |
| **Bark** | 500 – 2,000 Hz | Low-medium intensity warning |
| **Unstructured shrieks** | 1,000 – 6,000 Hz | Energy concentrated 1–3 kHz |
| **Distress calls (prey mimicry)** | Up to 40,000+ Hz | Coyotes can hear these; humans cannot |

### Scoring Implications
- Coyote calls use extensive tone/pitch/modulation variation via mouth, lips, and tongue
- Howls have complex frequency modulation — DTW-based comparison more appropriate than static pitch matching
- Distress calls lure coyotes from frequencies far above human hearing; app scoring should focus on audible components

---

## Duck (Mallard — Anas platyrhynchos)

**Hearing range**: 66 Hz – 7,600 Hz (best sensitivity ~2,000 Hz)

| Call Type | Frequency Range | Notes |
|-----------|----------------|-------|
| **Hen quack** | 1,000 – 4,000 Hz | The classic "quack" — reed vibration on tone board |
| **Decrescendo / hail call** | 1,500 – 4,000 Hz | 5-6 notes, loud → soft, attracts distant ducks |
| **Feeding chuckle** | 800 – 2,500 Hz | Raspy, low-intensity |
| **Drake quack** | 800 – 2,500 Hz | Lower-pitched, longer than hen quack |
| **Teal whistle** | 2,000 – 5,000 Hz | Short, high-pitched |

### Scoring Implications
- Duck calls rely on reed mechanics; frequency AND intensity are both meaningful
- Single-reed calls offer wider range (high hails → raspy feeds); scoring should account for call type
- Decrescendo call has declining volume curve — duration + volume envelope scoring relevant

---

## Cross-Species Reference Table

| Species | Lowest Call Hz | Highest Call Hz | Primary Energy Band | Pitch Tolerance Recommendation |
|---------|---------------|-----------------|---------------------|---------------------------------|
| Turkey | 400 | 15,000 | 1,000–4,000 | ±150 Hz on fundamental |
| Elk | 145 | 4,000+ | 800–2,000 (cow) | ±80 Hz (cow), ±200 Hz (bugle) |
| Deer | 100 | 8,000 | 3,000–6,500 | ±100 Hz |
| Coyote | 500 | 6,000+ | 1,000–3,000 | ±200 Hz (high variability) |
| Duck | 800 | 5,000 | 1,000–4,000 | ±120 Hz |\n</document_content>\n\n---\n\n## FILE: `audio_normalization.md` [Category: Technical/Core]\n<document_content>\n# Audio Asset Normalization Workflow

New animal calls are added to the reference library frequently. It is highly disruptive to the user if a user swaps from a quiet turkey purr to a blaring elk bugle unexpectedly. 

## The Problem
Raw WAV and MP3 files provided by different hunters or stock libraries possess wildly varying:
- RMS amplitudes
- Peak decibels
- Sample rates (44.1kHz vs 48kHz)
- Bit depths

## The Solution: Workflow Automation
All incoming assets must pass through an automated normalization step before being ingested into the `ReferenceDatabase`.

### 1. Slash Command Workflow
The OUTCALL development environment is configured with a custom workspace workflow: `/update-assets`.

This workflow performs the following:
1. Downloads the target audio assets.
2. Runs batch processing to normalize peak amplitude to a target `-3.0 dBFS`.
3. Standardizes sample rates to `44100 Hz` (optimal for our `AnalyzeAudioUseCase` FFT processing constraint length of 1024).

### 2. Goal
This guarantees that the UI feels premium: switching between reference tracks maintains a consistent volume, and the recording graph does not suffer scale mismatch issues when comparing user attempts.\n</document_content>\n\n---\n\n## FILE: `audio_techniques.md` [Category: Technical/Core]\n<document_content>\n# Advanced Audio Analysis Techniques

> Reference guide for audio comparison, pitch detection, and signal processing relevant to OUTCALL's scoring engine.

## 1. Pitch Detection Algorithms

### Algorithm Comparison

| Algorithm | Accuracy | Noise Robustness | Speed | Best For |
|-----------|----------|-------------------|-------|----------|
| **Autocorrelation** | Basic | Low | ⚡ Fastest | Low frequencies, resource-constrained |
| **YIN** | Good | Medium | ⚡ Fast | Monophonic audio, low latency |
| **pYIN** | Very Good | Good | ⚡ Fast | Varied audio, reduces octave errors |
| **CREPE** | Best | Excellent | 🐢 Slow | Best accuracy, handles noise well |
| **SwiftF0** | Very Good | Good | ⚡ 90x faster than CREPE | Future mobile deployment |

### Current OUTCALL Implementation
OUTCALL uses **autocorrelation-based pitch detection** in `ComprehensiveAudioAnalyzer._analyzePitch()`. This is computationally efficient for isolate-based processing but can suffer from:
- Octave errors (detecting harmonics instead of fundamental)
- Noise sensitivity in real-world recording conditions

### Recommended Upgrade Path
1. **Short term**: Add parabolic interpolation to current autocorrelation (already partially implemented via YIN-style difference function)
2. **Medium term**: Implement pYIN for probabilistic pitch tracking with HMM smoothing
3. **Long term**: Consider CREPE-tiny for maximum accuracy (requires TFLite integration)

---

## 2. Audio Comparison Metrics

### MFCC + Cosine Similarity (Current Approach)

**How it works**: Extract 13 MFCC coefficients per frame, average across frames, compute cosine similarity between user and reference vectors.

**Strengths**:
- Captures spectral envelope (timbre/tone quality)
- Scale-invariant (ignores loudness differences)
- Computationally efficient

**Weaknesses**:
- Sensitive to recording device differences (microphone response curves)
- Degrades with reverberation and background noise
- Requires sequences of equal length (loses temporal info)

### Dynamic Time Warping (DTW) — Recommended Enhancement

**How it works**: Aligns two sequences of feature vectors (e.g., MFCC frames) by non-linearly warping the time axis to minimize total distance.

**Why DTW is better for animal calls**:
- Handles tempo variations (calls at different speeds)
- Compares sequences of different lengths naturally
- Aligns complex patterns with local time shifts
- No ML training required — pure mathematical comparison

**Perfect for**: Turkey yelp sequences, coyote howls, elk bugle segments

### Gammatone Frequency Cepstral Coefficients (GFCCs)
- Alternative to MFCCs with **superior noise robustness**
- Based on gammatone filter model of the peripheral auditory system
- Particularly better at low SNR (signal-to-noise ratio)
- Drop-in replacement for MFCC extraction pipeline

---

## 3. WAV File Format — Robust Parsing

### Current Issue
OUTCALL hardcodes the PCM data offset at byte 44, which assumes:
- Standard RIFF header (12 bytes)
- Standard fmt chunk (24 bytes: 8 header + 16 data)
- Data chunk starts immediately after

### Real-World WAV Files Can Have:
- Extended fmt chunks (18, 40+ bytes) for non-PCM or WAVE_FORMAT_EXTENSIBLE
- JUNK chunks, fact chunks, LIST chunks inserted between fmt and data
- Different bit depths (8, 16, 24, 32-bit)
- Non-standard metadata chunks

### Correct Parsing Algorithm
```
1. Read bytes 0-3: Verify "RIFF"
2. Read bytes 4-7: File size (little-endian)
3. Read bytes 8-11: Verify "WAVE"
4. Loop through chunks:
   a. Read 4-byte chunk ID
   b. Read 4-byte chunk size (little-endian)
   c. If "fmt ": Parse format data (sample rate, bit depth, channels)
   d. If "data": Record offset, this is where PCM data starts
   e. Otherwise: Skip chunkSize bytes and continue
5. Begin reading PCM data at the recorded data offset
```

---

## 4. Flutter Audio Processing Patterns

### Isolate Architecture (Current — Good ✅)
OUTCALL correctly uses `compute()` to run analysis in a separate isolate. This prevents UI jank during FFT and pitch analysis.

### Recommended Libraries
| Library | Purpose | Status in OUTCALL |
|---------|---------|-------------------|
| `fftea` | FFT analysis | ✅ In use |
| `record` | Audio capture | ✅ In use |
| `audio_waveforms` | Waveform visualization | Consider for real-time viz |
| `flutter_soloud` | Low-latency playback + FFT | Consider for real-time analysis |
| `coast_audio` | Real-time DSP pipeline | Consider for future |

### Performance Best Practices
1. **Throttle UI updates** — Don't redraw waveform every frame; 30 FPS is sufficient
2. **Buffer management** — Balance responsiveness vs. smoothness
3. **Dispose resources** — Always clean up recorder/player controllers
4. **Cache analysis results** — Avoid re-analyzing the same file (currently only waveform is cached)

---

## 5. Signal Quality Assessment

### Environmental Factors Affecting Scores
| Factor | Impact on Score | Mitigation |
|--------|----------------|------------|
| Speaker playback → mic chain | MFCC distortion, harmonic loss | Reduced MFCC weight (40%) |
| Background wind/noise | Noise penalty, pitch detection errors | Noise floor calibration |
| Device microphone quality | Frequency response coloring | Channel compensation |
| Room reverb | MFCC smearing, duration extension | Pre-emphasis filtering |
| Distance from mic | Lower SNR, more noise | Volume normalization |

### Adaptive Noise Floor (Current Implementation)
OUTCALL already implements adaptive noise floor calibration in `_calibrateNoiseFloor()`:
- Segments audio into frames
- Calculates RMS energy per frame
- Uses bottom 10% of frames as noise floor reference
- Pitch detection ignores frames below noise floor\n</document_content>\n\n---\n\n## FILE: `build_ops.md` [Category: Technical/Core]\n<document_content>\n# Android Build & Operations Log

## Android Release Troubleshooting
Production builds (APKs/AABs) are generated via `./scripts/build_app.sh`.
- **Firebase Config:** Valid `android/app/google-services.json` required. 
- **Gradle OOMs:** Out of Memory errors during assembly.
  - **Fix:** Update `android/gradle.properties`:
  ```properties
  org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=1G
  org.gradle.workers.max=1
  ```
- **Deadlock Cleanup:** If builds fail with timeouts or hung lock files:
  ```bash
  cd android && ./gradlew --stop
  rm -f .gradle/noVersion/buildLogic.lock
  ```

## Release Workflows
- **Upload scripts:** `upload_play.py` and `upload_apk_gdrive.py` used for Alpha/Drive uploads.
- **Tagging:** Use `vX.Y.Z` tags to trigger automated GitHub Action releases.
- **Analytics:** Post-release track conversion and performance via `AnalyticsService` events.\n</document_content>\n\n---\n\n## FILE: `build_release.md` [Category: Technical/Core]\n<document_content>\n# Build & Release Workflow

This document tracks the workflow for building and releasing the Outcall application to Google Play.

## 1. Automated Release Workflow (Recommended)
The primary release mechanism is the `release.sh` script, which categorizes versions, tags the repository, and triggers the GitHub Actions CI/CD pipeline.

### Step 1: Execute the Release Script
```bash
# Usage: ./scripts/release.sh <version> <build_number> [release_notes]
./scripts/release.sh 1.8.3 37 "Major update with new animal calls and calibration."
```
1. Updates `pubspec.yaml` versions.
2. Updates `distribution/whatsnew/en-US.txt`.
3. Commits and tags the release (e.g., `v1.8.3`).
4. Pushes to `main`, triggering `.github/workflows/deploy_release.yml`.

### Step 2: GitHub Actions Pipeline
The pipeline triggers on any tag starting with `v`.
1. **quality-gate**: Restores `google-services.json`, runs `flutter analyze` and `flutter test`.
2. **deploy**: Restores Keystore, builds the Release AAB (`flutter build appbundle --release --obfuscate --split-debug-info`), uploads to Play Store Alpha Track, and creates a GitHub Release.

## 2. Manual Build & Upload Tools
If automation fails, use these specialized scripts:

### Local Production Build
```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

### Manual Play Store Upload
**Service Account Method (Recommended)**: `scripts/upload_to_play_store.py`
- Utilizes `scripts/play-store-key.json`.
- Usage: `python scripts/upload_to_play_store.py --track alpha --name "v1.8.3" --notes "Fixes" --aab <path>`

**OAuth2 Interactive Method**: `scripts/upload_play.py`
- Utilizes user OAuth flow. Best for one-off manual uploads without service accounts.

### Google Drive Upload (For Testers)
Used to upload APKs directly to the "Benchmark Apps" folder.
```bash
flutter build apk --release
python scripts/upload_apk_gdrive.py
```

## 3. Troubleshooting & Common Pitfalls

- **Gradle Daemon Exit / OOM**: Increase memory limit in `android/gradle.properties`:
  ```properties
  org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=1G
  org.gradle.workers.max=1
  ```
- **Missing `google-services.json`**: Ensure the file is present in `android/app/`.
- **Stale Build Locks**:
  ```bash
  cd android && ./gradlew --stop
  rm -f .gradle/noVersion/buildLogic.lock
  ```\n</document_content>\n\n---\n\n## FILE: `bobcat_growl.md` [Category: Calls]\n<document_content>\n# Bobcat Growl & Purr Masterclass

The bobcat vocalizes primarily for territorial defense, mating, and communicating with kittens. Unlike the harsh scream of a cougar, bobcat growls and purrs are low-frequency, guttural, and highly textured. Because bobcats are notoriously stealthy and visual hunters, using audio to manipulate them requires absolute precision and patience.

---

## 1. Deep Biological Context
Bobcats (`Lynx rufus`) are solitary predators that rely on ambush tactics. Their vocal apparatus is designed for close-to-medium-range communication.
- **The Purr:** Similar to a domestic cat but much deeper. Used when content, nursing, or approaching a mate. It vibrates at an extremely low frequency (25-30 Hz) which has been biologically shown to promote bone density and healing in felines.
- **The Growl / Yowl:** A drawn-out, guttural moan often escalating into a raspy yowl. This is strictly territorial or related to estrus (mating season, typically late winter: February-March).
- **Behavioral Triggers:** A bobcat hunting a rabbit distress call will often sit down and watch the source for 20-40 minutes before moving. A bobcat growl can break this stalemate by triggering a territorial defense instinct, forcing the cat to approach and defend its hunting ground.

## 2. Advanced Calling Mechanics
It is exceedingly difficult to reproduce naturally with just the mouth. Most hunters use specialized tools or electronic callers.
- **Tools:** Open-reed voice-manipulable calls (like the Dan Thompson PC2) are preferred over closed reeds because they allow for manipulating the pitch by sliding teeth/lips up and down the mylar reed.
- **Airflow & Diaphragm:** To mimic a growl on a hand call, the hunter must "gargle" or flutter their uvula while exhaling slowly over the reed. 
- **Hand Manipulation:** Cupping the hands tightly over the end of the call and slowly opening them creates the "wah" effect of a cat opening its mouth to yowl, filtering the high frequencies dynamically.

## 3. Hunting Setup & Strategy
Bobcats are not coyotes; they do not come running in recklessly.
- **Pacing:** Call sequences must be long. Play a distress sound for 15 minutes, pause for 5. If a cat is spotted but won't commit, switch immediately to a low bobcat growl to challenge them.
- **Visuals:** Because bobcats are sight-hunters, pairing a growl with a visual decoy (a motorized furry tail) is critical. The growl gets their attention; the visual motion locks them in.
- **Wind & Terrain:** Bobcats prefer thick brush, rocky outcroppings, and creek beds. Set up with a crosswind. They will almost always try to circle downwind to smell the intruder before committing.

## 4. Common Mistakes & Diagnostics
- **Too Loud:** The most common mistake. Bobcats have incredible hearing. Blasting a growl at 100 dB sounds unnatural and will spook them. The sound should carry no more than 100-200 yards.
- **Wrong Pitch (Too High):** Slipping on an open reed will cause the call to squeak. To a mature bobcat, a high-pitch squeak from a "rival" sounds like a kitten and will not trigger a dominant response.

## 5. Engine Analysis & Scoring (OUTCALL Deep Dive)
Bobcat calls present a unique challenge for the OUTCALL scoring engine due to their low fundamental frequency and heavy harmonic distortion (the "gravelly" nature of a growl).

### Key Processing Metrics
1. **Low Frequency Focus:** The fundamental frequency (F0) of a bobcat growl often sits between 150 Hz and 300 Hz. The engine filters out anything above 1200 Hz to isolate the "rumble."
2. **Pitch Detection Algorithm:** The YIN algorithm is prioritized over simple autocorrelation here. YIN is specifically mathematically robust against the heavy harmonic noise and sub-harmonics present in feline growls.
3. **MFCC Weighting:** Because the growl is essentially "textured noise," the MFCC (Mel-frequency cepstral coefficients) score makes up 60% of the Tone Quality grade. The engine analyzes the envelope of the noise floor to ensure it matches the biological acoustic chamber of a 20-30 lb feline.
4. **Duration & Steadiness:** A high score requires maintaining a steady, low rumble without breaking pitch for 3-5 seconds. Shorter bursts are penalized as unnatural.\n</document_content>\n\n---\n\n## FILE: `coyote_howl.md` [Category: Calls]\n<document_content>\n# Coyote Howl & Yaria Masterclass

The coyote (`Canis latrans`) is North America's most talkative predator. Their howling is a complex language of location, territorial claim, and pack bonding. A master predator caller uses this language not just to sound like a coyote, but to trigger specific psychological responses based on the time of year and the biological hierarchy of the local packs.

---

## 1. Deep Biological Context
Coyotes use vocalizations to manage massive territories (often 2 to 10 square miles).
- **The Lone Howl:** A smooth, rising and falling siren. Used at dawn and dusk to locate pack members, or by a transient (non-pack) coyote looking for a mate without provoking a fight.
- **The Challenge Bark-Howl:** Sharp barks followed by a chopped, aggressive howl. Used exclusively by the dominant male (Alpha) to warn intruders out of his territory.
- **The Yip-Howl (Chorus):** A chaotic mix of high-pitched yips and overlapping howls. This is a pack bonding exercise, often done after a successful kill or when reuniting. To a human, 2 coyotes yipping can sound like 10.
- **Seasonal Timing:** 
  - *Late Winter (Jan-Feb):* Mating season. Lone howls and estrus chirps are incredibly effective.
  - *Spring (April-May):* Denning. Challenge barks work well on protective parents.
  - *Fall (Oct-Nov):* Pups dispersing. Pup distress sounds or non-threatening lone howls pull in young, curious transients.

## 2. Advanced Calling Mechanics
- **Tools:** Open-reed bite calls, diaphragm-style predator calls, or closed-reed "howlers" built with cow horns or plastic resonance chambers. 
- **The Glissando (Slide):** The defining characteristic of a coyote howl is the smooth slide between pitches. A hunter must start with light lip pressure (low pitch) and slowly bite down on the reed while increasing air pressure to slide seamlessly to the peak frequency. 
- **The "Bark":** Achieved by placing the tongue sharply against the roof of the mouth and releasing a sudden, violent burst of air ("Thut!") while biting the reed.

## 3. Hunting Setup & Strategy
Coyotes are sight-hunters with a phenomenal sense of smell. They will almost always circle downwind.
- **The Downwind Trap:** Set up with a crosswind, facing the direction you expect them to come from, but with a clear shooting lane downwind of the caller. 
- **Pacing:** When howling, less is more. Send two lone howls. Wait 20 minutes in absolute silence. A committed coyote may cover a mile in that time without making a sound.
- **The "Puppy Decoy":** Mixing a lone howl with a high-pitched pup distress sound can trigger an overwhelming maternal/paternal instinct in adult coyotes, forcing them to run in recklessly.

## 4. Common Mistakes & Diagnostics
- **Over-Howling:** Howling continuously for 5 minutes sounds unnatural. Real coyotes howl for 30 seconds and then listen.
- **The "Voice Crack":** Slipping off the reed at the peak of the howl causes a sudden drop or squeak in pitch. This immediately identifies you as a human to an educated coyote.
- **Immediate Challenge:** Starting a stand with an aggressive Alpha Challenge Bark will terrify young or subordinate coyotes, pushing them out of the area permanently. Always start soft.

## 5. Engine Analysis & Scoring (OUTCALL Deep Dive)
Coyote howls are characterized by extremely clean, sweeping frequency curves. The OUTCALL engine analyzes these using advanced pitch-tracking logic.

### Key Processing Metrics
1. **The Trajectory (Glissando):** The scoring engine heavily relies on Dynamic Time Warping (DTW) to analyze the *shape* of the howl. A true lone howl starts low (~400-500 Hz), rises smoothly over 2-3 seconds to a peak (~1200-1500 Hz), holds, and falls softly. 
2. **Pitch Detection (CREPE):** CREPE (a deep learning pitch tracker) or pYIN is favored here over standard FFT. The engine requires high-resolution pitch tracking to ensure the glissando is perfectly smooth, penalizing the "voice cracks" common in amateur callers.
3. **Harmonic Purity (Tone Clarity):** Coyotes have surprisingly pure "singing" voices compared to wolves. The Tone Clarity metric penalizes excessive rasp, saliva gurgle, or air noise during the main body of the lone howl. (Conversely, rasp is expected and rewarded during a Challenge Bark).
4. **Volume Envelope (The Roll):** The engine tracks the amplitude envelope. A high score requires starting softly, swelling to a loud peak at the highest pitch, and tapering off naturally—not cutting off abruptly due to lack of breath.\n</document_content>\n\n---\n\n## FILE: `crow_call.md` [Category: Calls]\n<document_content>\n# Crow Locator Call Masterclass

The American Crow (`Corvus brachyrhynchos`) is one of the most intelligent and vocal birds in North America. In the context of hunting, the crow call is rarely used to hunt crows themselves; rather, it is a specialized tool used by turkey hunters as a "locator."

---

## 1. Deep Biological Context
Crows are intensely loud and universally prevalent in the turkey woods. They have a complex vocabulary to warn of predators, coordinate foraging, and mob raptors.
- **The Shock Gobble:** Wild turkeys (specifically Toms) have a physiological reflex to loud, sudden, high-frequency noises. A sharp crow call causes a Tom to involuntarily "shock gobble" in response. This reveals his location to the hunter, allowing them to close the distance without the turkey realizing a human is near.
- **Why Crows?** Because crows are everywhere, a turkey hears them constantly. A crow calling does not alarm the turkey or make him cautious, whereas an owl hooting in the middle of the day is unnatural and puts the bird on edge.
- **The Mobbing Call:** The most effective cadence for shock gobbling is the "mobbing" sequence—the rapid, aggressive caws a crow makes when dive-bombing an owl or a hawk. 

## 2. Advanced Calling Mechanics
- **Tools:** Wooden or synthetic reed-based crow calls, or natural voice calling (cupping the hands over the mouth, taking a deep breath, and screaming "Caw" through the vocal cords).
- **Diaphragm Pressure:** A good crow call is not a long exhale. It requires sharp, forceful bursts of air directly from the diaphragm. You must "punch" the air.
- **Voice Inflection:** The best callers actually vocalize a sound (like "Grrrrr" or "Raaaak") *into* the call while blowing. This introduces human vocal cord resonance into the reed, creating the necessary rasp and volume.

## 3. Hunting Setup & Strategy
- **Timing:** Use the crow call during the middle of the day (10:00 AM to 3:00 PM) when turkeys are loafing in the shade and not actively gobbling. 
- **Distance:** A crow call must be blisteringly loud to trigger a shock gobble from a mile away. Do not call softly.
- **The Silent Move:** Once the Tom shock gobbles, DO NOT call again immediately. Memorize the location, move silently to within 100-150 yards, set up against a tree, and switch to soft turkey hen yelps to draw him in.

## 4. Common Mistakes & Diagnostics
- **The "Dying Duck" Sound:** Blowing softly into a crow call results in a flat, nasal "quack." It takes extreme air pressure to force the stiff reed into the correct high-frequency vibration.
- **Machine-Gun Cadence:** While the sequence should be aggressive, there must be distinct micro-pauses between the caws. "CawCawCawCaw" sounds like a mechanical toy. "Caw... Caw... Caw-Caw!" sounds like a real bird.

## 5. Engine Analysis & Scoring (OUTCALL Deep Dive)
The crow call is short, sharp, and highly repetitive, requiring the engine to process staccato bursts rather than sweeping melodies.

### Key Processing Metrics
1. **Rhythm & Cadence Tracking:** The most critical factor. Crows call in distinct cadences (e.g., the 3-note burst: Caw-caw-caw). The Rhythm score accounts for 40% of the total rating, measuring the exact temporal spacing between the attack transients of each note.
2. **The "Rasp" Baseline (MFCC):** A crow call is inherently raspy. The Tone Quality algorithm adjusts its baseline expectations; what would be considered "too much noise" for an elk bugle is required here. The engine looks for heavy spectral scattering in the upper frequencies.
3. **Frequency Peak & Attack:** The dominant frequency is sharp and piercing, usually spiking rapidly around 1000-1500 Hz. The pitch tolerance band is wider, focusing more on the harshness of the note than the musicality.
4. **Transient Analysis:** The engine tracks the attack envelope of each note. A real crow call hits its peak volume almost instantly. Slow, swelling buildups of air are heavily penalized. The algorithm literally scores how "hard" you hit the note.\n</document_content>\n\n---\n\n## FILE: `deer_buck_grunt.md` [Category: Calls]\n<document_content>\n# Whitetail Buck Grunt Masterclass

The buck grunt is the cornerstone of whitetail deer (`Odocoileus virginianus`) communication. It ranges from soft social check-ins to aggressive territorial challenges. Mastering the subtle variations of the grunt is essential for any serious whitetail bowhunter.

---

## 1. Deep Biological Context
A buck's grunt is driven by testosterone, age, and social hierarchy. As a buck matures, his chest cavity deepens, lowering the fundamental frequency of his voice.
- **The Social/Trailing Grunt:** Soft, rhythmic, short grunts. Used essentially to say, "I am here." Often used by bucks while walking or casually trailing a doe.
- **The Tending Grunt:** Faster, more urgent, and slightly varied in pitch. Used when a buck is actively pushing or sequestering a doe that is nearing estrus. It sounds like a rhythmic pig-like series of pops.
- **The Dominant Grunt:** Deep, loud, and drawn-out (1.5 to 2 seconds). Used to challenge another buck. It is an acoustic flexing of muscles.
- **The Buck Roar:** An extreme, guttural scream. Only produced by mature whitetails experiencing absolute peak testosterone during a fight.

## 2. Advanced Calling Mechanics
- **Tools:** Adjustable, corrugated plastic grunt tubes with internal Mylar reeds. The corrugated tube mimics the animal's windpipe, allowing the sound to be muffled and shaped.
- **Vocalization:** Never just blow air. A hunter must forcefully vocalize the word "Urrrrkk" or "Urrrp" from the bottom of their diaphragm into the tube.
- **Inflection (The "Roll"):** A robotic, flat tone is unnatural. By slightly cupping and uncupping the hand over the exhaust end of the tube, the caller can bend the pitch slightly, giving the grunt "life" and realism. 

## 3. Hunting Setup & Strategy
- **Blind Calling (Pre-Rut):** Every 30 minutes, issue 2 or 3 soft social grunts. This mimics a buck casually walking through the timber and can draw curious deer out of their bedding areas.
- **The "Stop" Grunt:** If a buck is walking quickly past your archery stand and won't stop for a shot, a short, sharp "Urrp!" with your mouth will cause him to freeze instantly, locking his legs to locate the sound, offering a perfect stationary target.
- **The Challenge:** During the rut, if a mature buck is visible but walking away, hit him with a loud, aggressive dominant grunt followed immediately by rattling antlers. This simulates an intruder fighting over a doe in his territory.

## 4. Common Mistakes & Diagnostics
- **Too Fast/Too Many:** Grunting 20 times in a row sounds panicked. Real bucks grunt 2 to 4 times and keep walking.
- **DMD (Dead Mylar Disease):** Saliva freezing on the reed during late-season hunts causes the grunt tube to freeze or "click" instead of vibrating. Keep the call tucked inside the jacket against the body heat.
- **Shallow Air:** "Cheek air" produces a hollow, reedy sound that mimics a tiny 6-month-old fawn rather than a mature buck.

## 5. Engine Analysis & Scoring (OUTCALL Deep Dive)
The buck grunt is a low-frequency, pulsed vocalization. It is short but carries significant acoustic weight, requiring specialized sub-bass tracking.

### Key Processing Metrics
1. **Sub-Bass Verification (F0 Tracking):** A mature buck grunt sits very low in the spectrum, often between 80 Hz and 120 Hz. The OUTCALL pitch tracker heavily penalizes calls that spike into the 200+ Hz range, which simulates a young, non-threatening yearling.
2. **Pulse/Beat Rate (Rhythm):** For a tending grunt sequence, the engine uses beat-tracking algorithms to ensure the grunts match the rhythmic tempo of a deer walking (roughly one grunt every 0.8 to 1.2 seconds). Erratic timing drops the rhythm score.
3. **MFCC Depth Evaluation (Resonance):** The "throatiness" of the call is analyzed via Mel-Frequency Cepstral Coefficients. The engine mathematically maps the spectral depth of the user's call and compares it against the acoustic resonance chamber of an actual 200lb deer's chest/neck cavity.
4. **The Inflection Curve:** The best scores require a slight curve in the pitch—starting low, rising slightly, and falling off at the end of the breath. Monotone, straight-line frequencies are flagged as synthetic.\n</document_content>\n\n---\n\n## FILE: `deer_doe_bleat.md` [Category: Calls]\n<document_content>\n# Whitetail Doe Bleat Masterclass

The doe bleat is the primary vocalization used by female whitetails (`Odocoileus virginianus`) to communicate location, establish dominance, or signify readiness to breed. Understanding the subtle nuances of pitch and duration can turn a casual "social" sound into an irresistible rut-phase magnet.

---

## 1. Deep Biological Context
While bucks communicate via low-frequency chest grunts, does communicate primarily through mid-to-high frequency bleats driven directly by their vocal cords.
- **The Social Bleat (Contact):** A long, drawn-out "Maaaa" sound. It is a relaxed, conversational tone used by does to locate their fawns in deep cover or to signal safety to other feeding deer.
- **The Estrus Bleat:** A shorter, more urgent, pleading tone ("Maaah!"). A doe only goes into estrus (ready to breed) for roughly 24-36 hours a year. During this microscopic window, she produces this specific bleat to stop a trailing buck or invite him closer.
- **Fawn Distress:** An intensely high-pitched, screaming "Baaah!" that lasts for several seconds. Used to summon an aggressively protective doe, but often ends up calling in coyotes.

## 2. Advanced Calling Mechanics
- **Tools:** The ubiquitous "Can Call" (like the Primos Original Can) is an acrylic cylinder with an internal weighted reed. Tipping the can over automatically uses gravity to push air through the reed, creating a nearly perfect estrus bleat. Mouth-blown bite reeds are also common but require precise breath control.
- **The Can Technique:** Do not simply flip it upside down and back again. The most realistic bleat requires tipping the can smoothly, placing your thumb over the bottom hole to muffle the end of the note, and then quickly flipping it right-side-up silently.
- **Mouth Reeds (The Wobble):** If using a bite reed, the hunter must pinch the reed lightly to hit the high pitch, then flutter their tongue rapidly against the roof of the mouth to create the vibrating "vibrato" or "wobble" characteristic of an older doe.

## 3. Hunting Setup & Strategy
The doe bleat is most violently effective during the **pre-rut and peak rut** (late October through late November).
- **The "Blind" Setup:** Set up on the downwind edge of a thick bedding thicket. Tipping the can call 2 or 3 times every 45 minutes can convince a cruising buck that a willing doe is hiding in the brush.
- **The Combo:** A single estrus bleat followed immediately by two aggressive buck grunts tells a dominant buck an incredible story: "A willing doe is here, but a rival buck has found her." This routinely draws mature deer out of thick cover at a dead sprint.
- **Wind:** Bucks will almost never approach a bleat directly. They will attempt to swing 50 yards downwind to "smell" the estrus doe before stepping into the open. Position your stand accordingly.

## 4. Common Mistakes & Diagnostics
- **Over-Bleating:** The most common failure. An estrus doe does not bleat continuously for 10 minutes. A burst of 2-3 bleats is enough. Wait 30 minutes before doing it again.
- **The Accidental Fawn Distress:** Pushing too hard on a mouth call, or uncovering the can entirely, raises the pitch into the Fawn Distress range. Instead of a rutting buck, you will call in an angry matriarch doe who will snort and blow at you, ruining the hunt.
- **Spooking Close Deer:** A can call is incredibly loud. Do not tip it when a deer is within 50 yards, or they will pinpoint your exact location in the tree.

## 5. Engine Analysis & Scoring (OUTCALL Deep Dive)
A doe bleat is characterized by a very steady, high-pitch and a noticeable vibrato (wobble) in older does.

### Key Processing Metrics
1. **The Frequency Ceiling:** The peak fundamental pitch of a doe bleat typically sits firmly between 400 Hz and 600 Hz. The OUTCALL pitch tracker continuously monitors this precise window to ensure the caller isn't accidentally mimicking a distressed fawn (which routinely spikes above 900 Hz).
2. **The "Baaa" Envelope (Acoustic Shape):** The sound must start with a sharp attack (the hard "B/M" consonant sound as air hits the reed) and smoothly transition into a hollow, sustained "aaa" vowel. Tone evaluation heavily scrutinizes this specific two-part envelope structure.
3. **Volume Taper (The Bleed-Off):** The engine expects a louder initial projection that smoothly tapers off over 1-2 seconds. An abrupt, violent stop (like removing your finger from a whistle) is mathematically penalized as a mechanical failure.
4. **Tremolo Analysis (Vibrato):** The advanced Tone Quality algorithm rewards rhythmic fluctuations in the sustained pitch. A perfectly flat, straight 500 Hz tone sounds like an electronic synthesizer. A true doe bleat wavers slightly.\n</document_content>\n\n---\n\n## FILE: `deer_snort_wheeze.md` [Category: Calls]\n<document_content>\n# Whitetail Snort Wheeze Masterclass

The snort wheeze is the most aggressive, violent vocalization a whitetail buck can physically make. It is a direct, physical challenge issued by a dominant male to an intruder, signaling an impending, violent physical confrontation over territory or a breeding doe.

---

## 1. Deep Biological Context
While grunts are conversational and challenging, the snort wheeze is the final acoustic warning before a fight begins.
- **Physiology:** Unlike grunts, which use the vocal cords, the snort wheeze is completely non-vocal. The buck seals his mouth shut, pinches his nostrils, and forcefully violently expels air from his lungs through his nasal cavity in short bursts.
- **The Hierarchy:** Only mature, dominant bucks (3.5+ years old) will issue a snort wheeze. Subordinate bucks will rarely use it because issuing a challenge you can't back up results in serious injury or death in the wild.
- **The Response:** When a dominant buck hears a snort wheeze, his hair stands on end (piloerection), his ears lay flat back, and he typically stiff-walks sideways (to appear larger) directly toward the source of the sound.

## 2. Advanced Calling Mechanics
This is an incredibly difficult call to master naturally and usually requires a specialized grunt tube.
- **Tools:** Multi-chambered grunt tubes (like the Extinguisher or Illusion) often have a small, secondary plastic nozzle on the side specifically designed to channel air into a hissing scream.
- **Natural Voice:** If performed without a call, the hunter must press their tongue tightly against the back of their top teeth, pinch their lips, and force short but violent bursts of air out, ending with a long, drawn-out hiss.
- **The Cadence:** The universally recognized structure is: "Phfft... Phfft... Pshhhhhhhh." Two rapid, explosive bursts of air, followed immediately by a long, 3-4 second sustained screech of air.

## 3. Hunting Setup & Strategy
This is the ultimate high-risk, high-reward tactic. It is the "Hail Mary" of whitetail bowhunting.
- **When to Use It:** The snort wheeze should ONLY be used when you can physically see a mature buck, and he is walking away or completely ignoring your standard grunts. If he looks at you, you have his attention—do not wheeze. If he turns to leave, wheeze to enrage him into returning.
- **The Reaction:** If the buck is subordinate, he will sprint away in terror. If he is the dominant buck in the area, he will instantly turn and march directly at the tree stand on a string. You must be ready to shoot within seconds.
- **Blind Calling:** Never use a snort wheeze as a "blind call" (calling to deer you can't see). It will terrify 95% of the deer in the timber and clear the area entirely.

## 4. Common Mistakes & Diagnostics
- **Soft Air:** A weak, sputtering hiss will just confuse a buck. The bursts must sound violently aggressive, like an air compressor hose bursting.
- **Incorrect Timing:** Wheezing too often, or wheezing at a yearling 1.5-year-old buck, is a waste of effort and educates the deer.
- **Missing the Sibilance:** Relying too much on the vocal cords (making a "Ghhhhs" sound) ruins it. It must be pure, unvocalized, high-pressure sibilance (air rushing).

## 5. Engine Analysis & Scoring (OUTCALL Deep Dive)
This is one of the most mechanically unique calls analyzed by the OUTCALL engine because it is almost entirely **broadband noise** rather than a tonal pitch. Conventional pitch trackers (like CREPE) actually struggle here because there is no F0 (fundamental frequency) to lock onto.

### Key Processing Metrics
1. **The Staccato "Phfft-Phfft-Pshhhhh" Rhythm:** The engine explicitly looks for a two- or three-part temporal envelope. It expects two extremely short (sub 0.2 second) bursts of high-pressure amplitude followed by a long, sustained hiss (2+ seconds) that slowly tapers off. 
2. **MFCC (Timbral) Dominance:** Because there is no true pitch, the Pitch Accuracy score is mathematically zero-weighted in the background. Instead, MFCC analysis (measuring the spectral shape of the sibilant "hiss") and Rhythm combined make up 90% of the scoring metric.
3. **High-Frequency Broadening:** The algorithm expects to see massive acoustic energy scattering across the 2000 Hz to 6000 Hz spectrum. If the sound is too narrow (sounding like a child whistling), it is penalized.
4. **Low-Frequency Rejection:** The engine actively filters out low frequencies to mathematically differentiate a true snort wheeze from wind blowing across the smartphone microphone or the user simply breathing heavily into the phone.\n</document_content>\n\n---\n\n## FILE: `duck_feeding_chuckle.md` [Category: Calls]\n<document_content>\n# Mallard Feed Chuckle Masterclass

The feed chuckle (or rolling chuckle) mimics the chaotic, contented sounds of a large flock of mallards actively feeding, splashing, and fighting over food on the water. It is the ultimate confidence call.

---

## 1. Deep Biological Context
While the greeting call commands attention from afar, the feed chuckle serves to reassure ducks that have already made the decision to approach.
- **The Real Sound:** In nature, a single mallard rarely makes a continuous, rolling machine-gun chuckle. That sound is a human invention designed to mimic the overlapping feeding sounds of 20+ ducks at the same time.
- **Contentment:** The sound is made as ducks dabble in the mud, rip up aquatic vegetation, and occasionally quickly snap at each other to defend a food source. 
- **The "Cluck":** The chuckle is built entirely on the foundation of the single mallard "cluck" or "tick"—a very short, sharp, low-end guttural note.

## 2. Advanced Calling Mechanics
This is universally considered one of the hardest waterfowl calls to master, requiring intense tongue and diaphragm coordination.
- **Tools:** Single or double-reed duck calls. Single reeds are generally capable of much faster, crisper, and more aggressive chuckles because the air only has to move one stiff piece of mylar.
- **The Syllables:** To achieve the rapid-fire staccato sound, callers use specific rapid tongue movements. 
  - *The Single Tick:* "Tick... Tick... Tick." Slower, more rhythmic.
  - *The Double Cluck:* "Dug-a... Dug-a... Dug-a."
  - *The Rolling Chuckle (Machine Gun):* "Tik-a-tik-a-tik" or "Tuka-tuka-tuka" vocalized as fast as humanly possible while maintaining heavy back-pressure in the call.
- **Air Pressure:** The call requires almost no volume. The air pressure is high, but the *volume of air* exhaled is very tiny. You are essentially spitting staccato bursts into the call.

## 3. Hunting Setup & Strategy
- **The Finisher:** Used when a flock is circling tightly overhead (inside 40 yards) or on their final locked-wing descent. A greeting call would be too loud; the feed chuckle tells them the food is plentiful and safe right here.
- **The Illusion of Numbers:** A loud, continuous rolling chuckle sounds like 50 ducks aggressively feeding. This is fantastic over massive decoy spreads (100+ blocks). Over a small spread (12 decoys), it sounds unnatural.
- **The "Bouncing" Hen:** A master caller will mix a rolling 3-second chuckle, instantly cut it with a loud single quack, and go right back to the chuckle. This mimics a dominant hen asserting herself over the food pile.

## 4. Common Mistakes & Diagnostics
- **The "Kazoo" Chuckle:** Vocalizing "Tik-tik-tik" *without* grunting or putting voice throat-rasp into the call results in a high-pitched, childish squeak. The chuckle MUST sound like a duck, not a metronome.
- **Out of Breath:** Trying to run a rolling chuckle for 15 seconds will leave the caller gasping. 3 to 5 second bursts are completely sufficient and much more realistic.
- **Slurring (The Mush):** If the tongue gets tired, the sharp "T" or "K" consonants break down into "Shhh-shhh." The crisp separation of notes is lost, and the sound turns to mush.

## 5. Engine Analysis & Scoring (OUTCALL Deep Dive)
This call is entirely about tempo, rhythm, and extreme low-end resonance. The OUTCALL engine has a specific sub-routine purely dedicated to measuring high-speed staccato events.

### Key Processing Metrics
1. **Staccato Burst Analysis (Rhythm Tracking):** The engine's envelope tracker looks for rapid, continuous, isolated spikes (often 4-8 distinct "ticks" per second). The waveform should look like a barcode, not a solid block. The Rhythm score is heavily weighted here, penalizing "mushy" slurred notes.
2. **Frequency Cap (Low End Check):** A feed chuckle is a low-volume, deeply guttural sound. If the dominant frequency continuously exceeds 600-800 Hz, the engine penalizes the score, flagging it as an airy whistle rather than a throaty cluck.
3. **Dynamic Time Warping (DTW):** Because every caller has a slightly different natural top speed (a biological limit of their tongue muscle), DTW is crucial here. DTW aligns the rhythm of the user's chuckle with the reference track without penalizing them strictly for overall tempo differences, provided the internal spacing is uniformly staccato.
4. **Variable Cadence Bonus:** A metronomic machine-gun chuckle is mathematically perfect but biologically impossible. The engine's advanced algorithm assigns "realism points" to slight micro-pauses and speed variations, mimicking multiple ducks stopping to breathe.\n</document_content>\n\n---\n\n## FILE: `duck_mallard_greeting.md` [Category: Calls]\n<document_content>\n# Mallard Greeting Call Masterclass

The greeting call is the foundational communication of the hen mallard (`Anas platyrhynchos`). It is a rhythmic, confident sequence declaring safety, contentment, and a welcoming landing zone to circling flocks. It is the absolute core of any waterfowl hunter's repertoire.

---

## 1. Deep Biological Context
Mallards are highly flock-oriented and constantly communicate while flying, feeding, and loafing.
- **The "Highball" (Hail Call):** A loud, screaming sequence of 10-15 notes used ONLY when ducks are hundreds of yards away or passing high overhead. It is an attention-getter. As soon as the ducks turn toward the sound, the hail call MUST stop.
- **The Greeting Call:** A much softer, rhythmic 5-7 note sequence ("Quack-quack-quack-quack"). Used when ducks are actively looking at the decoy spread from medium range (50-100 yards). It "greets" them and pulls them down into the final approach.
- **The Lonesome Hen:** A dragged-out, slower version with more spacing between notes. It mimics a hen separated from her flock and is devastatingly effective on small groups or single drakes.

## 2. Advanced Calling Mechanics
- **Tools:** Single or double-reed acrylic/polycarbonate duck calls. Double reeds are easier for beginners and naturally have more "rasp" (sounding like an older, raspier hen). Single reeds offer far more volume, speed, and dynamic range but require absolute air control.
- **Air Presentation (The "Vocalization"):** A duck call is not blown like a whistle. Air must be pushed forcefully from the diaphragm using a specific vocalized syllable. The most common syllables used by champions and guides are "Hut," "Wack," or "Kaa."
- **The Anchor:** The tip of the tongue should be anchored behind the bottom teeth. To make the "Hut" sound, the middle of the tongue strikes the roof of the mouth, acting as a valve to abruptly start and stop the pressurized air. 
- **The Rasp:** Humming or grunting *slightly* into a single-reed call while blowing introduces the necessary low-end "duck" sound (the rasp), differentiating a duck from a kazoo.

## 3. Hunting Setup & Strategy
- **Reading the Birds (The "Turn"):** Never call to ducks that are flying directly toward you—they will pinpoint your exact location and flare. Only call at the "tails and wingtips"—when they are crossing your spread or flying away.
- **The Final Decent:** As ducks commit and drop their landing gear (wings cupped, feet down), reduce the calling entirely. Switch to very soft, single clucks or feeding chuckles. A loud greeting call at 20 yards will bounce off the water and terrify them.
- **Wind:** Ducks ALWAYS land directly into the wind to create aerodynamic drag. Set your decoys with a large "U" or "J" hook opening downwind, with the greeting call pulling them straight up the middle of the hook.

## 4. Common Mistakes & Diagnostics
- **Puffy Cheeks:** If your cheeks are inflating, you are blowing mouth air. Mouth air cannot produce the sharp, high-pressure attack needed for a real quack. It sounds flat, "buzzy," and lacks resonance.
- **Machine-Gunning:** Blowing 10 quacks at exactly the same pitch and volume sounds mechanical. Real hens vary their cadence and volume constantly.
- **Over-Blowing:** Pushing too much air, especially into a single-reed call, causes the reed to lock against the tone board, creating a horrible, high-pitched "squeak." 

## 5. Engine Analysis & Scoring (OUTCALL Deep Dive)
A mallard greeting call is a highly rhythmic sequence of 5 to 7 distinct quacks that descend slightly in both volume and pitch as the sequence progresses. The OUTCALL engine analyzes this with forensic precision.

### Key Processing Metrics
1. **The Quack Envelope (The "Ear"):** A proper quack is comprised of a sharp attack (the "Kwa"), a burst of harmonic resonance, and a clean closure (the "ck"). The OUTCALL engine's Tone Quality metric specifically looks for this structured envelope in *every individual note*.
2. **Descending Cadence Tracking (Rhythm):** The engine's Rhythm analyzer mathematically requires the first quack to be the loudest and longest, with each successive quack becoming slightly shorter and softer ("TEN... nine... eight.. seven.. six"). Flat volume across 5 notes loses 30 points instantly.
3. **Pitch Stability (Squeak Rejection):** The pitch tracking algorithm (CREPE) aggressively monitors the F0 (fundamental). If it detects an instantaneous leap in frequency (a single-reed squeak), it flags the note as a mechanical error.
4. **Resonance vs. Tonal (MFCC):** The engine uses Mel-Frequency Cepstral Coefficients to differentiate between the buzzy, vibrating sound of a proper duck call and the smooth, airy whistle of someone blowing a kazoo. The harmonic overtones must be deep and raspy.\n</document_content>\n\n---\n\n## FILE: `elk_bugle.md` [Category: Calls]\n<document_content>\n# Elk Bugle Masterclass

The elk bugle (`Cervus canadensis`) is the loudest, most complex, and arguably most awe-inspiring bioacoustic signal produced by any North American land mammal. It ranges from deeply guttural, roaring growls that rattle the chest, to piercing, multi-octave screams that carry for miles across mountain canyons.

---

## 1. Deep Biological Context
A bull elk bugles for two primary reasons during the September/October rut: to gather and maintain his harem of cows, and to aggressively ward off rival "satellite" bulls.
- **The Location Bugle (The "Searcher"):** A clean, high-pitched two-note bugle without any aggressive, guttural grunts at the beginning or end. It is simply a long whistle saying, "I am a bull, and I am over here." Used by a hunter to locate a herd from afar without picking a fight.
- **The Challenge Bugle (The "Lip Bawl"):** This is a violent, multi-stage scream meant to enrage a herd bull into a physical fight. It starts with a deep, violent, roaring growl, transitions into an ear-splitting high note, and finishes with a series of aggressive, hyperventilating "chuckles" or "grunts."
- **The "Display" Mechanism:** A 700-pound bull elk actually produces two distinct sounds simultaneously—a deep, roaring vocalization from his massive larynx, and a high-pitched whistling overtone by forcing air rapidly through his nasal cavity.

## 2. Advanced Calling Mechanics
This call demands absolute mastery of the diaphragm reed and massive lung capacity.
- **Tools:** A latex diaphragm (mouth) call combined with a large plastic or carbon-fiber resonance "bugle tube." The tube acts as the bull's throat and nasal cavity to amplify and round out the sound.
- **The Tongue Placement:** The latex reed is pinned to the roof of the mouth. The tip of the tongue applies pressure. Light pressure creates the low growl; intense, hard pressure (pushing the tongue tight against the roof) creates the high scream.
- **The Glissando Slide:** The slide from low to high must be smooth. Releasing the tongue pressure suddenly will cause the high note to "crack" or stall, sounding like a teenager's voice breaking.
- **The Chuckles:** At the end of the high scream, drop the jaw open dramatically to release the reed entirely, and forcefully pump the stomach muscles (saying "He! He! He!") to create the deep, trailing grunts.

## 3. Hunting Setup & Strategy
- **The Engagement Protocol:** Never start a morning with an aggressive Lip Bawl. If you challenge a herd bull from 800 yards away, he may simply gather his cows and push them over the next ridge to avoid a fight. Start with a soft Cow Mew to gauge distance. If he answers, cut the distance in half silently.
- **The Breaking Point:** Once you are inside 100 yards (the "red zone"), wait for the bull to bugle. The instant he finishes, hit him immediately with a violently aggressive Challenge Bugle, cutting off his echo. This signifies a rival has breached his comfort zone and often provokes a blind, furious charge.
- **Wind Check:** Mountain thermals are brutal. In the morning, air flows down; in the evening, air flows up. If a bull smells you, no amount of perfect bugling will stop him from running to the next county.

## 4. Common Mistakes & Diagnostics
- **"Cracking" the High Note:** The most universal failure. Over-pressurizing the mouth or slipping the tongue causes the latex reed to stall, instantly killing the majestic scream and replacing it with a flat buzz.
- **Not Enough Tube Coverage:** If the bugle sounds like a referee whistle rather than a majestic animal, the hunter is likely not sealing their lips tightly around the mouthpiece of the bugle tube. The sound must travel *through* the resonance chamber, not escape out the sides.
- **Over-Mewing the Bugle:** Ending a bugle with a high-pitched squeak instead of a deep grunt indicates poor diaphragm release.

## 5. Engine Analysis & Scoring (OUTCALL Deep Dive)
The elk bugle pushes the absolute limits of the OUTCALL audio processing engine. The software must track a wildly sweeping fundamental frequency while simultaneously analyzing complex sub-harmonics and rapid rhythm changes.

### Key Processing Metrics
1. **The Three-Part Envelope (Phase Analysis):** The engine mathematically maps the waveform to expect three distinct acoustic phases:
    - **Phase 1: The Base Growl:** A low, guttural vibration (often dipping below 150 Hz). A pure high whistle from the start loses points.
    - **Phase 2: The Screaming Octave (CREPE Tracking):** A sudden, steep glissando (slide) up to a deafening high pitch, often exceeding 2500 Hz. The neural network pitch tracker (CREPE) must verify the continuous climb. "Steps" or "cracks" in the pitch are penalized.
    - **Phase 3: The Trailing Chuckles:** 3 to 7 rapid, rhythmic grunts simulating the hyperventilating bull. The rhythm analyzer checks for rigid cadence peaks.
2. **Dual-Layer Spectrum (MFCC Formant Analysis):** Because a real bull produces a vocal roar and a nasal whistle simultaneously, the Tone Quality algorithm uses Mel-Frequency Cepstral Coefficients to scan for this dual-layer spectral richness. A simple "plastic whistle" sound is heavily penalized.
3. **Duration Integrity (Sustain Check):** A full challenge bugle lasts 4-6 seconds. Early cutoff due to lack of breath destroys the realism score. The engine models the lung capacity of the animal.\n</document_content>\n\n---\n\n## FILE: `elk_cow_mew.md` [Category: Calls]\n<document_content>\n# Elk Cow Mew & Calf Chirp Masterclass

The cow mew is the universal, daily language of an elk herd. While the majestic bugle gets all the glory in hunting media, the simple cow mew is arguably the deadliest and most effective call for drawing a cagey herd bull the final 40 yards into archery range.

---

## 1. Deep Biological Context
It signifies contentment, location, social cohesion, and in the case of a "lost cow," desperation. A calf chirp is a shorter, higher-pitched, more urgent version of the same sound.
- **The Social Mew:** A soft, rolling sound used by feeding cows to maintain contact with each other in dense timber. It tells a listening bull that "the herd is calm and safe."
- **The Estrus Whine:** A much longer, drawn-out, pleading mew. A cow elk is only receptive to breeding for a 12-24 hour window. During this phase, she will aggressively search for a dominant bull, using this whine to signal her readiness.
- **The Calf Distress:** A frantic, high-pitched, repetitive squeal. While effective, it often draws in cows, coyotes, or bears rather than the intended target bull.

## 2. Advanced Calling Mechanics
The cow mew is relatively simple to make, but incredibly difficult to master emotionally.
- **Tools:** Open-reed "bite" calls (like the Primos Hoochie Mama or standard bite-reeds) or latex diaphragm mouth reeds. Bite calls produce perfect, consistent mews with very little practice but lack dynamic range.
- **The Jaw Drop:** If using a mouth reed, the caller must start with high tongue pressure against the roof of the mouth and slowly "drop the jaw" while exhaling. This slides the pitch from high to low smoothly.
- **The Syllable:** Vocalizing "Eee-Uuuu" forces the mouth into the correct shape to create the signature slide.

## 3. Hunting Setup & Strategy
- **The "Blind Setup" Finisher:** If a bull is hung up at 80 yards in the timber and refuses to approach a bugle, a single, soft cow mew can be the tipping point. It convinces him that a willing cow has splintered off from the herd and is looking for him.
- **The Decoy Play:** Elk are incredibly visually astute. If you mew loudly, the bull will pinpoint your exact location. If he crests a ridge and doesn't see a physical cow standing there, he will instantly spook. Pairing the mew with a lightweight 2D cow decoy is devastating.
- **The "Lost Calf" Trap:** Ripping a frantic series of high-pitched calf chirps can pull the lead cow of a herd straight toward you (maternal instinct). Where the lead cow goes, the herd bull will absolutely follow.

## 4. Common Mistakes & Diagnostics
- **Going Up Instead of Down:** A cow mew MUST slide down in pitch. Starting low and going high sounds like a startled warning bark, which will instantly blow the herd out of the basin.
- **Too Monotone:** Failing to drop the jaw results in a flat, nasal whistling sound. The emotional "pleading" aspect is lost.
- **Over-Calling:** Making 20 cow mews a minute sounds like a circus. Real elk are often silent for hours. One or two mews an hour in a bedding area is often enough to provoke a silent, creeping approach from a curious bull.

## 5. Engine Analysis & Scoring (OUTCALL Deep Dive)
The cow mew is a relatively simple, smooth vocalization, but it requires precise pitch sliding (glissando) and specific nasal overtone modeling to score highly in the app.

### Key Processing Metrics
1. **The Trajectory (Glissando) Check:** A perfect cow mew always slides *down* in pitch. It typically starts around 800-1100 Hz (the "Eee") and smoothly "rolls over" the top, tapering down to 400-600 Hz (the "Uuu"). The CREPE pitch detector actively scores the mathematical smoothness and direction of this downward trajectory.
2. **Nasality Modeling (MFCC Baseline):** Elk have highly nasal voices due to their large sinus cavities. The Tone Quality algorithm (using Mel-Frequency Cepstral Coefficients) is calibrated to expect a specific degree of harmonic "buzz" or nasality. This differentiates a true mew from a human lips-whistle.
3. **Duration Constraints:** A standard social cow mew is short—usually only 0.5 to 1.5 seconds. The engine will dock points for artificially over-elongating the sound, which inadvertently bleeds into the "estrus whine" category (which isn't scored in this specific module).
4. **Volume Roll-Off:** The attack (start) of the note should hit its peak quickly, and the ending should softly trail into silence. An abrupt, chopped ending sounds unnatural and is penalized.\n</document_content>\n\n---\n\n## FILE: `fox_scream.md` [Category: Calls]\n<document_content>\n# Red Fox Scream Masterclass

The raspy bark and piercing scream of the red fox (`Vulpes vulpes`) is a hallmark of winter predator hunting. It is primarily a territorial warning or mating call. To a human, a screaming fox in the dead of night is often mistaken for a screaming woman—an unnervingly loud, chaotic, and terrifying sound.

---

## 1. Deep Biological Context
Foxes use screams and barks to communicate across vast distances, establish territory, and locate mates.
- **The Territory Bark ("Wow-Wow"):** This is a harsh, raspy, two-syllable bark. It is the most common fox vocalization. Foxes use this to warn intruders out of their territory or to locate other family members.
- **The Vixen's Scream:** A terrifying, high-pitched, drawn-out shriek. It is heavily utilized during the peak mating season (January-February) by female foxes (vixens) summoning males from miles away.
- **The "Gekkering" (Fighting/Playing):** A rapid, stuttering, clicking sound made when two foxes are interacting closely—either enthusiastically greeting each other or aggressively fighting over food. It sounds like a mechanical "kak-kak-kak-kak."

## 2. Advanced Calling Mechanics
The fox scream is an acoustic anomaly—it is incredibly raspy, extremely chaotic, and lacks a steady fundamental frequency.
- **Tools:** Open-reed predator calls are the gold standard because they allow infinite pitch manipulation.
- **The "Bite and Gravel" Technique:** To produce the raspy bark, the caller must bite down on the reed to raise the pitch slightly, but immediately force a massive amount of "gravel" or throat-rasp into the call while exhaling. A smooth whistle will blow foxes out of the county.
- **The "Wow-Wow" Syllables:** Vocalize the word "Wow" sharply twice. The first "Wow" should be slightly lower in pitch and volume than the second "Wow!"

## 3. Hunting Setup & Strategy
Foxes are notoriously cautious, often circling downwind just like coyotes, but they are smaller and easier to intimidate.
- **The Challenge:** If you spot a fox that refuses to come into a rabbit distress call, hitting them with an aggressive "Wow-Wow" bark can trigger a territorial response. They will often bark back. If they do, mimic their exact cadence back to them to draw them closer.
- **The Vixen Scream Play:** During late January, ditch the rabbit distress entirely. A single, long Vixen Scream will put every male fox in a three-mile radius on a dead sprint toward your location.
- **Stand Placement:** Foxes prefer field edges, fence lines, and the transition zones between thick timber and open pasture. Set your electronic caller or mouth series pointing toward the thick cover, and watch the downwind edge of the field.

## 4. Common Mistakes & Diagnostics
- **Sounding Clean:** A smooth, musical whistle will fail immediately. The engine expects intense vibrato and throat-rattle (MFCC irregularity). If the call sounds pleasant, it’s wrong.
- **Over-Screaming:** The Vixen Scream is physically exhausting to the caller and the listener. Screaming continuously for 5 minutes is biologically impossible. Hit one scream, then wait 15 minutes.
- **Too Fast on the Bark:** The "Wow-Wow" bark must have a distinct micro-pause between syllables. Mushed together, it sounds like a dog hacking up a hairball.

## 5. Engine Analysis & Scoring (OUTCALL Deep Dive)
The fox bark and scream represent extreme edge cases for the OUTCALL audio processing engine. The acoustic profile is almost entirely noise-based with erratic, instantaneous pitch jumps.

### Key Processing Metrics
1. **Broadband Energy Tolerance (High Thresholds):** Unlike a clean elk bugle or a duck quack, the OUTCALL engine has to widen its pitch-tracking tolerances significantly. The Fox Scream is mathematically expected to be "messy." The engine actually lowers the penalty for frequency instability here.
2. **The 2-Part "Wow-Wow" Temporal Envelope:** The beat-tracking algorithm specifically looks for a dual-peak amplitude envelope. The first spike (Attack 1) must be immediately followed by a slightly louder spike (Attack 2).
3. **High-Frequency Harshness (Spectral Centroid):** The Tone Quality score rewards high-frequency harmonic energy. A low, muffled bark will be flagged as a generic domestic dog. The engine calculates the "spectral centroid" (the center of mass of the sound spectrum) and requires it to sit very high in the frequency range.
4. **The Sharp Cut-off:** Each bark or scream in the sequence must end abruptly. The volume envelope should look like sharp, jagged spikes on a graph, not slow, rolling swells.\n</document_content>\n\n---\n\n## FILE: `goose_honk.md` [Category: Calls]\n<document_content>\n# Canada Goose Honk & Cluck Masterclass

The standard Canada goose honk (`Branta canadensis`) is an iconic two-syllable sound. The rapid-fire cluck is a shorter, sharper single-note version used for aggressive feeding and finishing. Mastering the Canada goose call requires raw physical power and perfect pneumatic air control.

---

## 1. Deep Biological Context
Geese are large, loud, and incredibly social birds that fly in massive V-formations. They use a complex vocabulary of honks, clucks, murmurs, and spit-notes to maintain the flock geometry and coordinate landings.
- **The Honk (The Hail):** A loud, drawn-out "Her-Onk." Used communicating over extreme distances. It tells flying geese that there is a flock safely on the ground or water.
- **The Cluck (The Finisher):** A fast, sharp "Hut!" or "Tick!" sound. When a flock of geese lands, they immediately begin feeding and arguing. The cluck is the sound of an aggressive, hungry, active feeding frenzy.
- **The Murmur (The Lay-Down):** A soft, low-frequency buzzing or rolling sound made by hundreds of geese resting quietly. It is the ultimate confidence sound used when the birds are directly over the decoys.

## 2. Advanced Calling Mechanics
The modern short-reed Canada goose call is a masterpiece of acoustic engineering, but it is notoriously difficult for beginners to operate correctly.
- **Tools:** Short-reed acrylic or Delrin calls are the undisputed kings of the goose blind. They offer incredible speed, volume, and absolute control. Flute calls are obsolete but still used by some older hunters.
- **The "Air Wall" (Back-Pressure):** A goose call works entirely on the principle of breaking. The hunter must blow air forcefully into the call while placing the tongue against the roof of the mouth to create intense internal air pressure. 
- **The Syllable (The "Break"):** The caller vocalizes "Hut-To!" or "Whit-To!" The moment the tongue releases from the roof of the mouth, the massive air pressure blasts over the reed, causing it to violently snap from a low resonant pitch to a high-pitched "crack." This is the "Honk."
- **Hand Manipulation:** Hand positioning is everything. Creating a tight, sealed cup over the end of the call creates the low, guttural notes. Opening the hand suddenly releases the high-pitched "crack."

## 3. Hunting Setup & Strategy
- **The Distant Hail:** When a "V" of geese is spotted a mile away, scream loudly with drawn-out honks to break their flight path and get them to turn their heads. 
- **The Aggressive Approach:** As they turn and head toward your decoy spread (the "X"), switch from slow honks to rapid, aggressive, overlapping clucks. You are trying to sound like a massive flock of birds frantically eating all the food. Geese are greedy; this draws them in fast.
- **The Layout:** Geese land directly into the wind and require a massive runway to slow down their 12-lb bodies. Set the decoys in a "U" or "V" shape with a 40-yard landing zone squarely resting in the middle of the "U," pointing downwind. 

## 4. Common Mistakes & Diagnostics
- **The "Flute" Drone (No Break):** Blowing steadily into a short-reed call without "breaking" the air pressure using the tongue results in a flat, monotone kazoo sound. The call must "snap" or "crack" every single time.
- **Cheek Pumping:** Using the cheeks to blow air instead of the diaphragm will instantly cause the caller to lose all back-pressure. The sound will be weak, flat, and hollow.
- **Calling at their Bellies:** Once the geese have locked their wings and are gliding perfectly into the landing zone, *stop calling loudly*. Soft murmurs are fine. Hitting them with a loud honk at 15 yards will cause them to "flare" (abort the landing and fly straight up).

## 5. Engine Analysis & Scoring (OUTCALL Deep Dive)
The Canada goose call is defined by its dramatic "break" or "crack" in pitch. The OUTCALL engine utilizes a specific algorithm purely designed to detect this instantaneous acoustic snap.

### Key Processing Metrics
1. **The "Her-Onk" Pitch Break Detection:** A goose call ALWAYS has two parts. The fundamental frequency starts low and guttural ("Her-") and then sharply "cracks" into a high, piercing note ("-Onk"). The pitch tracker searches for this massive, sudden vertical jump on the frequency spectrum. 
2. **Glissando Rejection (Anti-Slide):** The engine explicitly penalizes a slow, smooth pitch slide. The jump from low to high must be *instantaneous* (sub-0.1 seconds). If the pitch slides smoothly, the algorithm flags it as an unnatural mistake (the trademark of a badly blown flute call).
3. **The "Cluck" Temporal Condensation:** A cluck is simply a mathematically compressed honk where the sequence occurs in a fraction of a second. The rhythm analyzer measures the overall duration of the note to differentiate between a 1.5-second hailing honk and an aggressive 0.2-second cluck.
4. **Cadence Tracking (The Flock Effect):** A flock of geese sounds chaotic, but individual birds maintain heavily regimented cadences. The beat tracker will analyze sequences of 5-10 honks for rhythmic consistency and biological pacing. Random, erratic honking is scored lower than a defined rhythm.\n</document_content>\n\n---\n\n## FILE: `hog_grunt.md` [Category: Calls]\n<document_content>\n# Feral Hog Grunt & Squeal Masterclass

Feral hogs (`Sus scrofa`) are highly social, aggressively territorial, and incredibly intelligent animals. Their vocalizations range from the soft, rhythmic feeding grunts of a contented sounder (herd) to the violent, earsplitting, multi-tonal squeals of boars fighting for dominance.

---

## 1. Deep Biological Context
A hog sounder communicates constantly, and silence in the woods often indicates danger.
- **The Feeding/Social Grunt:** A deep, continuous, low-frequency rhythmic grunt. Made by sows and piglets actively rooting up soil. It is the ultimate confidence sound, acting as an acoustic camouflage. If a sounder is feeding, they do not care about snapping twigs or rustling leaves, allowing a hunter to stalk closer.
- **The Squeal (Aggression):** A violently chaotic, high-pitched scream. This mimics hogs aggressively fighting over a rich food source or establishing social dominance. The sound of a fight triggers an intense curiosity and dominant response from mature, solitary boars in the area.
- **The Danger Bark:** A short, sharp, violently loud "Woof!" issued by the lead sow when she smells or sees danger. This instantly scatters the entire sounder into heavy cover.

## 2. Advanced Calling Mechanics
- **Tools:** Specialized, ridged plastic/acrylic grunt tubes specifically tuned much larger and lower than whitetail deer calls. Electronic callers playing recorded audio are extremely popular and widely legal in many states specifically for feral hog eradication.
- **The Squeal Tube:** Many hog calls feature an exposed, dual-reed system on the outside of the tube. By biting down violently on the external reed while exhaling forcefully, the hunter can instantly spike the pitch into a deafening squeal.
- **Guttural Resonance:** True hog grunts require forcing air from the absolute bottom of the diaphragm while simultaneously tightening the throat. Mouth grunts sound too hollow and "airy" to trick an educated hog.

## 3. Hunting Setup & Strategy
- **The Stalking Camouflage:** The most effective use of a hog call is as cover noise during a spot-and-stalk hunt in thick brush. If you accidentally snap a loud twig while creeping up on a sounder, immediately hitting a soft feeding grunt can convince them it was just another hog foraging nearby.
- **The Dinner Bell (Squeal Play):** If hunting from a blind over an open field or feeder, playing an aggressive, violent 1-minute fight sequence (squeals mixed with deep grunts) can draw a cautious mature boar out of the thick timber to investigate the commotion and claim the food.
- **Swamp Thermals:** Hogs rely primarily on their phenomenal sense of smell. Set up crosswind in riparian zones, swamps, or creek beds where scent naturally flows parallel to the water source.

## 4. Common Mistakes & Diagnostics
- **Deer Grunting:** Using a standard whitetail deer grunt tube. It is entirely the wrong frequency, lacking the deep sub-bass resonance and rhythmic chaos of a hog.
- **Constant Squealing:** Continuously playing a brutal squeal sequence for 20 minutes is unnatural. Real hog fights last 15-30 seconds, followed by contented grunting as the winner eats.
- **Ignoring the Wind:** A hog can be fooled repeatedly by sound and sight, but they will never second-guess their nose. If they get downwind of you, the hunt is over instantly.

## 5. Engine Analysis & Scoring (OUTCALL Deep Dive)
The OUTCALL engine must handle two extreme ends of the acoustic spectrum simultaneously within this single profile: the sub-bass of the grunt and the piercing high frequencies of the squeal. 

### Key Processing Metrics
1. **The Sub-Bass Floor Validation (F0):** A hog grunt sits incredibly low, vibrating heavily around 60 Hz to 100 Hz. The MFCC spectral array specifically compares this deep resonance against the user's call to ensure the call is originating from a broad resonance chamber (a massive chest cavity) rather than being a "shallow" mouth noise.
2. **The Harmonic Shriek Filter (Squeal):** A true hog squeal is chaotic and multi-tonal. The engine's pitch tracker expects the frequency to spike violently from 500 Hz to over 3000 Hz in a fraction of a second, with intense harmonic distortion. Pure, clean whistles are severely penalized.
3. **Chaotic Cadence Variability (Rhythm):** Unlike the steady, walking, metronomic rhythm of a whitetail buck grunt, a feeding hog sounder's grunts are rapid, uneven, erratic, and sometimes overlapping. The Rhythm scoring algorithm is explicitly inverted here—it rewards erratic, randomized beat patterns (simulating multiple pigs feeding simultaneously) and penalizes perfect, machine-like consistency.\n</document_content>\n\n---\n\n## FILE: `owl_hoot.md` [Category: Calls]\n<document_content>\n# Barred / Great Horned Owl Hoot Masterclass

The hoot of a massive predatory owl is the secondary "shock gobble" trigger in a turkey hunter's arsenal. While the crow call is utilized during the bright midday sun, the Owl Hoot rules the dark, quiet timber at first light before the sun rises, or right at dusk as turkeys fly up to roost.

---

## 1. Deep Biological Context
The Barred Owl (`Strix varia`) and the Great Horned Owl (`Bubo virginianus`) are apex nocturnal predators in the turkey woods, and they frequently pray on roosting turkeys at night.
- **The Shock Reflex:** A loud, booming owl hoot near a roosting turkey before dawn triggers an overpowering, involuntary shock gobble from the Tom. It forces him to reveal the exact tree he is sleeping in while it is still too dark for him to see the approaching hunter.
- **Why Owl?** Turkeys know that an owl hoots at dawn and dusk. A crow calling at 5:00 AM completely alarms a gobbler because crows sleep at night. Matching the specific locator call to the ambient biological clock of the woods is essential.
- **The Cadence:** The Barred Owl's classic sequence is an 8-note or 9-note phrase, universally translated by hunters as: *"Who cooks for you... who cooks for you-allllll."*

## 2. Advanced Calling Mechanics
- **Tools:** Wooden or synthetic resonant chambers that the hunter blows directly into, or natural voice calling (extremely difficult but highly respected in competition calling).
- **The Diaphragm Push:** The deep resonance requires pushing a colossal volume of air from the absolute bottom of the stomach/diaphragm. "Cheeking" the call (using only the air in your mouth) will result in a flat, high-pitched, reedy whistle that lacks any booming echo.
- **The Vocal Box:** Master callers will physically say the words "Who Cooks For You" deep in their throat while pushing air through the wooden call, allowing their own vocal cords to shape the start and stop of the airflow precisely.
- **The Final Slide:** The final note ("allllll") must trail off slowly, sliding smoothly down in pitch and volume until it fades into the natural echo of the woods.

## 3. Hunting Setup & Strategy
- **Roost Pinpointing:** At 4:30 AM, stand on a high ridge and let out one massive sequence. Listen intently. If a Tom gobbles 400 yards away, move silently in the dark to within 100 yards of that specific tree and sit down. Wait for the sun to rise, then switch to soft hen tree-yelps.
- **Distance Control:** Never hoot when you are already within 50 yards of the roost tree. A blaring owl hoot directly beneath a gobbler will terrify him into flying off the roost in the opposite direction.
- **The Evening "Put-to-Bed":** Shortly after sunset, hit a single owl hoot. If a gobbler answers, you now know exactly what tree he is sleeping in tonight, allowing you to set up underneath him silently the following morning.

## 4. Common Mistakes & Diagnostics
- **Wrong Time of Day:** Using an owl hoot at 1:00 PM in the blazing sun is biologically incorrect and immediately signals to the turkey that a human predator is in the woods. Switch to the crow call.
- **Skipping the Pauses:** Missing the rhythmic pauses between the two halves of the *Who-cooks-for-you* phrase sounds unnatural. The Barred Owl always leaves a 1-second gap in the middle.
- **Raspy Overtones:** A true owl hoot has almost no high-frequency "rasp." It is a pure, clean, hollow bass tone. Rasp indicates a badly sealed mouth ring on the call.

## 5. Engine Analysis & Scoring (OUTCALL Deep Dive)
Owl hoots are a rigorous test of the AI engine's ability to measure deep, hollow spectral resonance and strict, classic rhythmic cadences simultaneously.

### Key Processing Metrics
1. **The 8-Note Rhythm Matrix (Syllabus Tracking):** The Rhythm analyzer tracks the exact syllabus structure of the temporal envelope. The engine has pre-loaded templates for the classic 8-note sequence, as well as the aggressive 9-note "laughing" sequence. It ruthlessly penalizes sequences that skip the signature rhythmic gap.
2. **Deep Spectral Formant Analysis:** A proper owl hoot has almost no high-frequency harmonic energy. It is a pure, hollow, bass-heavy tone, typically sitting well below 500 Hz. The Tone Quality algorithm (MFCC) severely penalizes raspy, airy overtones (frequencies >1000 Hz) that result from poor air control or a cracked wooden call.
3. **The Final Glissando ("Allll" Slide):** The cadence must end on a sustained, descending note. The CREPE Pitch Tracker specifically expects the final second of the audio sequence to slide smoothly and cleanly downward to a vibrating stop. Abruptly ending the final note drops the score heavily.\n</document_content>\n\n---\n\n## FILE: `rabbit_distress.md` [Category: Calls]\n<document_content>\n# Rabbit Distress Weeps & Screams Masterclass

The rabbit distress call is the universal "dinner bell" for predators across North America. It perfectly mimics the chaotic, squealing desperation of a cottontail or jackrabbit caught by a hawk, owl, or coyote. This sound triggers a predatory feeding instinct—or an opportunistic scavenging instinct—in coyotes, bobcats, foxes, cougars, and even bears.

---

## 1. Deep Biological Context
Predators live on a razor-thin margin of survival. The sound of a dying rabbit represents a free, low-risk meal.
- **The Instinctual Response:** Coyotes will often abandon a territorial dispute to investigate a dying rabbit. They know that if another predator has made a kill, they might be able to steal it.
- **Cottontail vs. Jackrabbit:** 
  - *Cottontail* (`Sylvilagus`): Higher pitched, shorter bursts of screaming. Better for foxes and bobcats in thick brush or eastern timber.
  - *Jackrabbit* (`Lepus`): Deeper, raspier, and substantially louder. Carries across miles of open prairie. Better for western coyotes.
- **The "Fading" Sequence:** A rabbit does not scream at maximum volume for 20 minutes straight. A realist sequence mimics the animal struggling, getting tired, resting, and struggling again as the predator readjusts its grip.

## 2. Advanced Calling Mechanics
The distress call is chaotic, but it is not entirely random. It has a structure of desperation.
- **Tools:** Synthetic closed-reed calls are easiest to blow but sound identical to every other hunter in the woods. Open-reed bite calls are far more versatile, allowing the caller to introduce intense voice-rasp and pitch changes. Electronic callers are the industry standard for sheer volume and biological realism.
- **The "Waaa-Waaa" Syllables:** Vocalizing the syllables "Waaaa-Waaaa" or "Wah-Wah" into the call creates the necessary vibrato and jaw movement to mimic the rabbit opening and closing its mouth while screaming.
- **Hand Muffling:** To mimic a struggling rabbit fading out, the hunter must cup their hand tightly over the exhaust of the call, slowly opening and closing their fingers to warp the sound, eventually choking it off completely as the rabbit "dies."

## 3. Hunting Setup & Strategy
- **Volume Control:** Start soft. Often, a coyote is already sleeping within 200 yards. If you blast a 120-decibel jackrabbit scream into their ears, they will run the other way. Call softly for 2 minutes (the "coaxer"). If nothing shows, gradually increase the volume over the next 10 minutes to reach out miles.
- **Stand Duration:** 
  - *Coyotes:* 15-20 minutes. If they are coming, they will usually come fast and hard.
  - *Bobcats/Cougars:* 45-60 minutes. Felines will often stalk the sound for half an hour, sit on a ridge to watch the scene for 20 minutes, and then creep in silently. Patience is everything.
- **The Visual Decoy:** Pairing the continuous screaming with a motorized "wiggler" or "flicker" decoy (a piece of fur spinning on a stick) gives the predator a visual target to lock onto, pulling their eyes away from the hunter.

## 4. Common Mistakes & Diagnostics
- **The Metronome Scream:** A perfectly steady "waa... waa... waa..." rhythm is heavily penalized in the field. It sounds like a car alarm, not a dying animal. It MUST be irregular, desperate, and erratic.
- **Blowing Without Biting:** Failing to bite down on an open-reed call results in a flat, nasal beep rather than a blood-curdling shriek. The teeth provide the necessary tension on the mylar.
- **Giving Up Too Early:** Leaving the stand after 10 minutes guarantees you will spook a bobcat that was slowly creeping in just out of sight.

## 5. Engine Analysis & Scoring (OUTCALL Deep Dive)
The Rabbit Distress call is arguably the most chaotic spectral anomaly analyzed by the OUTCALL engine. It explicitly lacks a steady pitch, a clean envelope, and a predictable cadence.

### Key Processing Metrics
1. **The Panic Envelope (Erratic Rhythm):** The engine's rhythm analyzer explicitly looks for *irregular* bursts of sound and non-uniform spacing between acoustic transients. The algorithm is inverted: rhythmic perfection loses points, while chaotic staccato grouping is rewarded as "desperation."
2. **High-Frequency Distress Tolerance (CREPE Unlocking):** The pitch of a rabbit scream often spikes from 800 Hz to over 3000 Hz almost instantaneously. The CREPE pitch detector is set to its highest tolerance and broadest glissando-tracking band here, tracking rapid, shrieking slides without flagging them as mechanical errors.
3. **MFCC Chaos (The Rasp Factor):** The tone of this call is pure biological rasp and vibration. A pure, clean sine-wave whistle will score a zero on Tone Quality. The MFCC algorithm looks for heavy harmonic distortion, multi-layered overtones, and "throatiness" specifically in the upper-mid frequencies (1500-2500 Hz). In short, the "uglier" and harsher it sounds, the higher it scores.\n</document_content>\n\n---\n\n## FILE: `turkey_gobble.md` [Category: Calls]\n<document_content>\n# The Turkey Gobble Masterclass

The gobble is the signature acoustic trademark of the male wild turkey (`Meleagris gallopavo`). It is a booming, rattling, multi-noted explosion of sound used exclusively by males to establish physical dominance over subordinate birds, warn rivals, and attract willing hens from across an entire valley.

---

## 1. Deep Biological Context
The gobble is testosterone translated into sound. 
- **The Spring Hierarchy:** Leading up to the spring mating season, "boss" toms will fight violently for breeding rights. The gobble is the auditory announcement of who won the fight. 
- **The "Shock" Reflex:** A tom's gobble reflex is deeply tied to sudden high-pressure acoustic waves (which is why thunder, crow calls, and owl hoots cause them to "shock gobble" involuntarily). 
- **The Jake vs. The Tom:** A 1-year-old "Jake" (juvenile male) has a short, high-pitched, awkward gobble that often cuts off early. A mature 3+ year old "Boss Tom" has a deep, chest-rattling boom that echoes significantly longer.
- **Why Hunters Gobble:** Counter-intuitively, hunters rarely use a gobble to physically draw a bird into shooting range. Gobbling usually attracts subordinate jakes (who think a new, beatable turkey has arrived) or other hunters (which is incredibly dangerous). It is primarily used when a stubborn, mature tom absolutely refuses to approach a hen yelp. A sudden "challenge gobble" can infuriate him into coming over to fight the intruder.

## 2. Advanced Calling Mechanics
The turkey gobble is incredibly difficult to mimic perfectly with the human mouth, requiring years of practice.
- **Tools:** Specialized shaker boxes (shaking a wooden box to rattle an internal heavy reed rapidly) or mouth-blown "gobble tubes" (a rubber diaphragm stretched over an open cylinder). 
- **The Diaphragm Method:** The absolute hardest calling technique in the woods. The caller pins standard latex mouth reed to the roof of their mouth and forcefully rapidly flutters their tongue ("Tuka-Tuka-Tuka") or violently shakes their head while screaming air from the diaphragm.
- **The Shaker Box:** Requires a hard, violent "snap" of the wrist back and forth to force the heavy internal block to scrape perfectly across the internal soundboards. A slow shake sounds like a wooden toy.

## 3. Hunting Setup & Strategy
- **The Ultimate Challenge (The Hang-up):** The tom is 70 yards away, entirely visible, strutting in a field, but he will not take another step toward your hen decoys. You have called to him for two hours. He expects the hen to come to him. If you hit him with a massive, aggressive challenge gobble, his dominance is threatened. He will often break strut, stand tall, and march straight at you to kill the rival.
- **The Safety Warning:** **NEVER USE A GOBBLE CALL ON PUBLIC LAND.** Because it is so effective at locating male turkeys, a hunter using a gobble call runs an exceptionally high risk of another hunter stalking them and potentially mistaking them for a live bird. It is a private-land tactic only.

## 4. Common Mistakes & Diagnostics
- **The Clunky Rattle:** Using a shaker box slowly results in a staggered "Clack... Clack... Clack." A real gobble is a liquid explosion of 20 notes in 1.5 seconds. It must be a blur of sound.
- **No Chest Resonance:** Many mouth-callers hit the high-pitched rattling notes but forget to push air from deep in the stomach. The engine (and the real turkey) identifies this lack of low-end resonance as a juvenile Jake, not a threat.
- **The Abrupt Cutoff:** Stopping the shake instantly. A real gobble trails off softly for the last half-second.

## 5. Engine Analysis & Scoring (OUTCALL Deep Dive)
The turkey gobble presents arguably the hardest computational processing challenge for the entire OUTCALL engine architecture due to its violently rapid, rattling staccato rhythm overlapping with massive dual-tone frequencies.

### Key Processing Metrics
1. **The Machine-Gun Rattle (High-Speed Envelope Tracking):** A gobble is not one sound; it is a rapid explosion of 15 to 25 distinct, microscopic notes delivered in under two seconds. The rhythm analyzer relies on high-speed transient envelope tracking to literally count and measure the fractional spacing of these staccato bursts. If the bursts are too slow or too far apart, the score plummets.
2. **Dual-Tone Harmonic Structure (MFCC Overlap):** A mature boss-tom gobbles with two distinct voices simultaneously: a high-pitched, chattering "rattle" (from the upper throat) and a deep, sub-bass "boom" resonating from the massive chest cavity. The MFCC Tone Quality algorithm algorithm actively scans for this dual-layer spectral richness (mathematically representing the "roundness" of the gobble).
3. **The Roll-Off Phase:** A gobble explodes violently at the front end (the attack) but trails off into a sputtering, significantly slower rattle at the absolute end. The engine penalizes an abrupt, sharp silence.
4. **Low-Frequency Dominance:** The F0 base of the "boom" must dive below 200 Hz to score as a mature tom. If the lowest frequency generated is 400 Hz, the app explicitly grades it as a "Jake Gobble."\n</document_content>\n\n---\n\n## FILE: `turkey_yelp.md` [Category: Calls]\n<document_content>\n# Wild Turkey Yelp & Cluck Masterclass

The standard yelp is the absolute foundation of communication among wild turkeys (`Meleagris gallopavo`). A hen yelps to gather a flock scattered by danger, to locate her poults, or, most critically for the hunter, to indicate her location and readiness to mate to a listening gobbler.

---

## 1. Deep Biological Context
While the gobble is the sound of the tom, the yelp is the pulse of the turkey woods. Mastering the subtle emotional inflections of the yelp is the difference between a master caller and a novice.
- **The Plain Yelp:** A 3-to-7 note rhythmic sequence ("Yauk... Yauk... Yauk"). It is a basic "Here I am" or "Where are you?" call.
- **The Tree Yelp:** A very soft, muffled, slow 3-note yelp used while the turkeys are still sitting on branches in the dark before dawn. It simply acknowledges the flock is waking up.
- **The Assembly Yelp:** A loud, long, aggressive sequence of 15-20 yelps used by a mature "boss hen" demanding her flock regroup immediately after being scattered.
- **The Cluck:** A single, sharp, short "Pop" or "Put." It is a reassurance call. It means "I am here, and everything is safe." (Conversely, a loud, sharp, repeated "Putt-Putt-Putt!" is the universal alarm call, signaling mortal danger to every bird in the area).

## 2. Advanced Calling Mechanics
- **Tools:** The friction call (slate, glass, or crystal pot paired with a wooden striker), the rubber-and-latex diaphragm mouth call, or the air-operated wooden box call. 
- **The Friction Pot:** The striker must be held like a pencil, tilted at a 45-degree angle away from the body. The caller draws tiny, tight ovals without ever lifting the striker off the slate. The friction creates the high-to-low snap.
- **The Diaphragm "Roll-Over":** The mouth caller pins the latex reed to the roof of their mouth, pushes air, and dramatically drops their bottom jaw mid-breath. This drops the tongue pressure off the reed in a fraction of a second, causing the pitch to "break" or snap drastically from a high whistle to a raspy cluck.

## 3. Hunting Setup & Strategy
- **The Morning Fly-Down:** Before sunrise, hit a single, soft Tree Yelp. If the tom gobbles above you, DO NOTHING else. Wait until you hear the heavy wings of the turkey flying down to the ground. Then, hit him with a confident 5-note plain yelp.
- **The Phantom Hen:** If a tom is answering every yelp you make but refuses to walk closer than 80 yards, he is "hung up" waiting for the hen. Stop calling entirely. The silence will confuse him, simulating a hen that lost interest and walked away, often forcing him to run toward you to find her.
- **Cluck and Purr:** As the tom enters the "red zone" (inside 40 yards), switch from loud yelps to entirely soft, single clucks mixed with purring. This paints a picture of a calm hen feeding happily, lowering his guard completely.

## 4. Common Mistakes & Diagnostics
- **Machine-Gun Cadence:** A yelp is not a metronome. It has a specific biological pacing. "Yauk-Yauk-Yauk" with zero spacing sounds frantic and unnatural. The classic cadence is: "Yee-auk... Yee-auk... Yee-auk."
- **Missing the "Front End":** A yelp is actually a two-syllable word. Just making a low, raspy "auk" sound skips the high-pitched clear whistle ("Yee") at the beginning. It sounds like a dying frog.
- **Over-Calling:** A gobbler that has heard 200 yelps in 10 minutes knows exactly where you are, and knows a real hen would have walked over to him by now. Silence is a weapon.

## 5. Engine Analysis & Scoring (OUTCALL Deep Dive)
The turkey yelp is defined by its signature two-note "roll-over." The OUTCALL algorithms mathematically dissect this specific structural transition within every single note.

### Key Processing Metrics
1. **The "Kee-Yauk" Pitch Break (Glissando Vector):** A perfect yelp is actually two distinct notes slammed together. It starts with a high, clear "Kee" (the front-end whistle, often around 1200-1500 Hz) and immediately, violently snaps downward into a raspy, lower "Yauk" (around 400-600 Hz). The OUTCALL CREPE engine meticulously tracks this high-to-low *instantaneous* pitch break. If the pitch slides slowly downward, it is heavily penalized.
2. **The Front-to-Back Ratio (MFCC Check):** A high-scoring Tone Quality relies on the ratio of the clear front-end (the "Kee") to the raspy back-end (the "Yauk"). Too much clear whistle sounds like a domestic farm bird; too much heavy rasp sounds like a dying coyote. The MFCC algorithm perfectly balances this 40/60 "whistle-to-rasp" expectation.
3. **The Rhythm Benchmark:** A standard hen yelp sequence is a beautiful, rhythmic spacing. The beat-tracking algorithm expects near-perfect biological spacing between the notes, but it importantly requires the actual notes themselves to get slightly shorter in duration and softer in volume toward the absolute end of the 5-note sequence.
4. **The Reassurance Cluck Isolate:** The app can score a cluck independently. The algorithm identifies a cluck as exactly the "Yauk" half of the yelp, delivered perfectly isolated as a single, incredibly sharp, sub-0.3-second acoustic pop.\n</document_content>\n\n---\n\n## FILE: `competitive_landscape.md` [Category: Technical/Core]\n<document_content>\n# Competitive Landscape — Hunting Call Apps (2024–2025)

## Market Position

OUTCALL occupies a **unique niche** — it's the only hunting call app that provides **real-time audio analysis and scoring** of the user's own calling technique. No competing app offers this.

## Key Competitors

### iHunt
- **Category**: Call library & playback
- **750+ calls** from 59+ species, with new calls added yearly
- Custom playlists with adjustable sequences, delays, repeats, volume
- Solunar tables, weather forecasts, GPS tracking
- Bluetooth speaker integration (100+ yard range)
- **Pricing**: Free (75 calls) + one-time IAP for full unlock
- **No training/scoring features**

### HuntWise  
- **Category**: Data-driven hunting intelligence
- HuntCast™ predictive algorithm (weather + lunar = movement prediction)
- RutCast (whitetail rut phase tracking)
- WindCast (real-time wind direction for scent control)
- 450+ mapping layers, property lines, landowner info, 3D/LiDAR
- **Pricing**: Free tier + paid subscription (monthly/annual)
- **No call training features whatsoever**

### Trophy Scan (Launched Feb 2025)
- **Category**: Antler scoring
- LiDAR/photogrammetry-based antler measurement
- Score generation in seconds via smartphone
- **Pricing**: Subscription-based
- **Completely different product category**

## Feature Gap Analysis

| Feature | OUTCALL | iHunt | HuntWise |
|---------|---------|-------|----------|
| Call playback library | ✅ | ✅ (750+) | ❌ |
| **Audio scoring/analysis** | ✅ | ❌ | ❌ |
| **AI coaching feedback** | ✅ | ❌ | ❌ |
| **Real-time waveform visualization** | ✅ | ❌ | ❌ |
| Leaderboards | ✅ | ❌ | ❌ |
| Mapping/GPS | ❌ | ✅ | ✅ (best) |
| Weather/solunar | ❌ | ✅ | ✅ |
| Property lines | ❌ | ❌ | ✅ |
| Movement prediction | ❌ | ❌ | ✅ |
| Bluetooth speaker | ❌ | ✅ | ❌ |

## Monetization Models in Hunting Apps

| Model | Effectiveness | Examples |
|-------|--------------|----------|
| **Freemium + IAP** | Highest reach, 48.2% of all mobile earnings | iHunt (one-time unlock) |
| **Subscription** | Best for recurring revenue, 40%+ of App Store revenue | HuntWise (monthly/annual) |
| **Hybrid (freemium + subscription)** | Best of both worlds | OUTCALL's current model |
| **Paid upfront** | Limits reach; 90% of revenue comes from free apps | Declining trend |
| **Ad-supported** | Risky in focus-driven hunting context | Not recommended as primary |

### OUTCALL's Current Strategy
OUTCALL uses a **hybrid freemium model**:
- Free tier with limited animals/features
- Premium tier unlocks full library, leaderboards, social features
- In-app purchase system via native IAP (Google Play Billing)

### Opportunity Areas
1. **Brand partnerships** — hunting gear manufacturers, call makers
2. **Seasonal content packs** — spring turkey, fall elk, etc.
3. **Competition mode** — paid entry tournaments with prizes
4. **Community feed** — similar to HuntWise's social features\n</document_content>\n\n---\n\n## FILE: `conservation_ethics.md` [Category: Technical/Core]\n<document_content>\n# Conservation, Ethics, and the Calling Community: A Masterclass

Hunting with a call is a direct, artificial insertion of a human into the bioacoustic fabric of nature. It carries immense responsibility. Calling manipulates animals out of their natural survival patterns, inducing extreme stress, territorial anxiety, or mating instincts. Doing so unethically, or simply poorly, actively damages the resource, educates the wildlife, and ruins the experience for fellow hunters on public land.

---

## 1. The Acoustic Footprint: The Problem of Over-Calling

### The "Pressured" Gobbler
On heavily hunted public lands, wild turkeys hear box calls and slate calls every single morning from amateur hunters. When a hunter calls incessantly—yelping every two minutes without pause at maximum volume—the gobbler quickly realizes the sound is unnatural. 
- **The Result:** The bird "hangs up" 100 yards out, refuses to strut, and slinks away silently. Worse, he forever associates those specific raspy yelps with extreme danger, becoming what the community calls "call-shy." This makes him nearly impossible for the next ethical hunter to harvest.
- **The Solution:** Silence is a weapon. A master caller uses the "Phantom Hen" technique. Call once to get his attention, and then go completely silent for an hour to force the bird to come looking for the sound.

### The Spooked Elk Herd
Likewise, poor bugling technique or ripping off challenge bugles without the proper wind/thermal setup educates elk herds to human presence. An elk herd relies on the lead cow for safety. If she hears a bugle that sounds slightly wrong, or smells human scent associated with a bugle, the entire herd will vacate a watershed entirely, seeking deeper, thicker sanctuaries miles away.
- **The Solution:** Never bugle aggressively if the wind is swirling. Use soft cow mews to navigate timber, reserving the bugle strictly for the final 60-yard challenge.

## 2. Ethical Standards for Acoustic Manipulation

1. **Less is More:** Always start soft and infrequent. Let the animal dictate the pace of the conversation. If a bird cuts you off aggressively, talk back aggressively. If he goes silent, give him an hour of silence. Patience kills exponentially more animals than perfect calling technique.
2. **Never Call "Just to Hear Them" (The Drive-By):** Do not drive rural dirt roads in the spring and blow a locator crow call or bugle out the window just to hear a response "for fun," unless you actively intend to get out, set up, and hunt that specific animal. Every artificial interaction educates them, making them harder to hunt for the people actually putting in the physical effort.
3. **Proper Identification (The Safety Factor):** A perfect elk bugle successfully draws in another bull, but it also invariably draws in other hunters who are stalking the sound. Never shoot at movement. Always maintain 100% positive visual identification of the target animal and the background behind it.

## 3. Community Etiquette on Public Land
Public land is the lifeblood of the North American hunting model. Navigating it requires strict adherence to unwritten, but critical, social rules.

- **First Come, First Serve:** If you hike 3 miles in the dark and hear someone calling a turkey on the ridge ahead of you, back out quietly and immediately. Do not attempt to "horn in," circle them, or call the bird away from them. It is highly unethical, ruins their hunt, and is extremely dangerous.
- **Respect Boundaries:** Use digital mapping apps (like OnX or HuntStand) to ensure the animal you are calling is on public land. Standing on public land and actively calling a deer across a fence-line off of private property is illegal in many jurisdictions and highly unethical.
- **Support the Resource:** The calling community is deeply tied to massive conservation organizations like the NWTF (National Wild Turkey Federation), RMEF (Rocky Mountain Elk Foundation), and DU (Ducks Unlimited). Mastering the physics of the call is only half the battle; ensuring the habitats, swamps, and timber remain intact for these vocals to echo through is the real objective of the modern hunter.\n</document_content>\n\n---\n\n## FILE: `data_fetching.md` [Category: Technical/Core]\n<document_content>\n# Data Fetching Strategy: Cache-First Firestore

To ensure a "snappy" luxury experience, a cache-first strategy is implemented for all high-traffic read operations in the `FirebaseApiGateway`.

## 1. Overview
By default, Firestore queries attempt to reach the server to ensure the freshest data. On mobile networks, this can introduce noticeable latency, breaking the premium feel. The **Cache-First** strategy attempts to read from the local persistent cache first, instantly returning results while Firestore background-syncs with the server.

## 2. Implementation (`FirebaseApiGateway`)
The following methods use `Source.cache` in their `get()` calls:
- `getDocument(String path)`
- `getCollection(String path)`
- `queryCollection(Query query)`
- `getTopDocuments(String path, String orderBy, int limit)`

### Example Logic
```dart
Future<Map<String, dynamic>> getDocument(String path) async {
  try {
    // Attempt cache first for instant UI response
    final snapshot = await _firestore.doc(path).get(const GetOptions(source: Source.cache));
    return snapshot.data() ?? {};
  } catch (e) {
    // Fallback to server if cache is empty or fails
    final snapshot = await _firestore.doc(path).get(const GetOptions(source: Source.server));
    return snapshot.data() ?? {};
  }
}
```

## 3. Benefits
1.  **Near-Instant Loading**: Screens like Global Rankings and Animal Libraries load in <100ms when data is already cached.
2.  **Offline Support**: Users can browse the library and review their offline practice attempts without an active connection.
3.  **Reduced Data Usage**: Fewer server read operations occur during frequent navigation between tabs.

## 4. Risks & Considerations
- **Stale Data**: Users might see slightly outdated leaderboards if they haven't synced recently. This is an acceptable trade-off for the performance gain.
- **Cache Size**: Firestore manages cache eviction automatically, but testing should verify that large amounts of audio/profile data do not bloat the local storage excessively.\n</document_content>\n\n---\n\n## FILE: `dev_major_implementations.md` [Category: Technical/Core]\n<document_content>\n# Major App Implementations & Dev History

OUTCALL's development path is marked by conquering difficult, hardware-level audio processing challenges within the constraints of a cross-platform mobile framework (Flutter). This document serves as a high-level summary of the major technical pillars erected during development.

---

## 1. The Real-Time Scoring Pipeline (Isolate Architecture)
**The Challenge:** Processing Fast Fourier Transforms (FFTs) and Mel-Frequency Cepstral Coefficients (MFCCs) on a 44.1kHz audio stream instantly causes the main Dart UI thread to drop frames, resulting in extreme visual jank.
**The Implementation:** 
- Converted all heavy DSP math into a standalone Dart Isolate via `compute()`.
- The audio buffer fills continuously, and every 500ms, a chunk of byte-data is serialized and passed across the Isolate boundary.
- The secondary thread calculates pitch, rhythm, and timbre, returning a lightweight JSON payload of scores back to the main thread for 60FPS UI rendering.

## 2. In-App Purchase & Hybrid Entitlements
**The Challenge:** Relying solely on a cloud database to check if a user is "Premium" fails when the hunter is out of cell service.
**The Implementation:**
- Integrated `in_app_purchase` for the native native Android/iOS transaction handling.
- Built a dual-layer persistence model. The `EntitlementsRepository` first attempts a network check with RevenueCat/Firebase. If that fails, it reads a securely encrypted local cache (`shared_preferences` with AES encryption) to verify the premium token.
- Designed a "Luxury" Paywall UI using the brand's Gold/Charcoal aesthetic to convert free users to the AI Coach tier.

## 3. The "AI Coach" Integration
**The Challenge:** Providing users with more than just a number. If they score a 45/100, they need to know *why* and *how* to fix it.
**The Implementation:**
- Integrated the local Gemma 3 (4B) LLM model.
- The `RealRatingService` feeds the raw, sub-component scores (e.g., Pitch: 90, Rhythm: 20, Timbre: 45) into a strict system prompt.
- The LLM acts as the "Coach," generating 2-sentence actionable feedback ("Your tone was great, but you rushed the sequence. Put more space between your clucks.").
- *Note:* Also implemented a web-based FAQ chatbot for the landing page using Ollama via Cloudflare Tunnels to drive early-access signups.

## 4. Riverpod State Management & Navigation
**The Challenge:** Managing deeply nested state across recording active states, audio playback, scoring history, and premium paywall lockouts without creating a spaghetti architecture.
**The Implementation:**
- Adopted strict **MVVM (Model-View-ViewModel)** using `flutter_riverpod`.
- Implemented `AutoDispose` providers heavily to ensure the heavy RAM footprint of the AudioCache is flushed immediately when the user leaves the recording screen.
- Centralized dependency injection in `di_providers.dart` to allow effortless mocking of the audio engine and Firebase during unit testing (achieving 90%+ test coverage on core services).

## 5. The OUTCALL Brand Transformation
**The Challenge:** The app started as a generic "Gobble Guru" turkey-only application with standard Material Design colors.
**The Implementation:**
- Executed a major repository-wide rename and continuous integration restructuring to "OUTCALL".
- Standardized the visual design system across all screens, docs, and the wiki using Charcoal (`#0C0E12`) and Gold (`#E8922D`).
- Consolidated 135+ reference animal sounds into a heavily compressed, high-fidelity asset pack.\n</document_content>\n\n---\n\n## FILE: `dev_roadmap.md` [Category: Technical/Core]\n<document_content>\n# App Development Roadmap (2026-2027)

OUTCALL is currently in active beta on Android, with a massive set of core features already completed. The roadmap below outlines the immediate short-term goals for commercial release and long-term expansion plans into new tech and platforms.

## Q2 2026: Commercial Launch & Hardening
The immediate priority is transitioning from a functional beta into a resilient, monetized consumer product.
- **Scoring Engine V2:** Completing the transition from YIN pitch detection to the deep-learning pYIN/CREPE models for high-noise environments (especially for windy waterfowl hunting).
- **iOS Port Validation:** The Flutter codebase is theoretically cross-platform, but CoreAudio integration and permission handling for the iOS microphone require extensive physical device testing.
- **Paywall Refinement:** Launching the "OUTCALL Elite" tier ($4.99/mo or $29.99/yr) powered by RevenueCat.
- **Offline Mode Validation:** Ensuring Firebase Analytics and the local Core Data caching system gracefully handle users tracking calls entirely deep in the backcountry without cell service.

## Q3 2026: Social & Competitive Features
Hunting is inherently social and competitive. OUTCALL will expand beyond solo coaching.
- **Global Leaderboards & Seasons:** Implementing a ranked Elo system where users compete globally on specific species calls (e.g., "September Elk Bugle Challenge").
- **Shareable Brag-Cards:** Generative images displaying the user's score waveform against the golden reference, formatted for easy sharing on Instagram/X.
- **Live Head-to-Head:** WebRTC audio streaming to allow two hunters to "call-off" against each other, with the AI engine acting as the live judge.

## Q4 2026: The "Live Woods" Wearable Integration
Moving the app from a pre-hunt training tool into an active, in-the-field companion.
- **Smartwatch Haptics (Apple Watch / WearOS):** While hunting, taking out a bright phone screen is unviable. The user will be able to start an active listening session via their watch. The watch will use haptic feedback (buzzing) to tell the hunter if the turkey they just heard in the distance was a 1-year-old Jake, or a mature 3-year-old Boss Tom based on the engine's sub-bass resonance analysis.
- **Bluetooth Decoy Integration:** Syncing the OUTCALL engine with motorized decoys to automatically trigger motion only when the user executes a perfectly timed "Feed Chuckle" sequence.

## 2027 & Beyond: Synthetic Wildlife Generation
- **Dynamic AI Opponents:** Generating completely synthetic, reactive animal audio using advanced TTS and sound-synthesis models. The user will engage in a "mock hunt" where an AI-generated elk bugles back at them, dynamically changing its aggression, volume, and simulated distance based exactly on how the user responds.\n</document_content>\n\n---\n\n## FILE: `elk_calling.md` [Category: Technical/Core]\n<document_content>\n# Elk Calling: The Encyclopedia of the Mountain Rut

The North American Elk (`Cervus canadensis`) is one of the continent's most majestic and vocal big-game animals. Hunting them during the September rut is a phenomenal, chaotic display of acoustic dominance and extreme physical endurance at high altitudes.

---

## 1. Deep Biological Context: The Rut Hierarchy
The entire dynamic of elk calling is based on the breeding structure of the herd. Elk are polygynous—one dominant male attempts to breed with a large group of females (a harem).
- **The Herd Bull:** The dominant, mature male (usually 5+ years old). His singular goal is to keep his cows together and ward off any rival males. He does not want to fight if he doesn't have to; fighting risks injury and leaves his cows unprotected.
- **The Satellite Bulls:** Subordinate, often younger males that constantly shadow the herd, attempting to steal a cow while the herd bull is distracted. They are the primary targets of aggressive bugling tactics.
- **The Cows:** The decision-makers. The herd goes where the lead cow goes. If the lead cow feels threatened by a hunter, she will take the entire herd into the next drainage, regardless of what the herd bull wants.

## 2. Advanced Calling Tools & Mechanics

### The Diaphragm Call (Mouth Reed)
A U-shaped frame with latex stretched across it, placed on the roof of the mouth.
- *Pros:* Hands-free, capable of making every sound in the elk vocabulary (from soft calf mews to screaming Lip Bawl bugles).
- *Mechanics:* Light tongue pressure and slow air creates low mews. High tongue pressure, stretched latex, and massive air pressure creates the high "screaming" octave of the bugle.

### The Bugle Tube (Resonance Chamber)
A hollow plastic or carbon-fiber tube measuring 18-30 inches long.
- *Pros:* Amplifies the sound produced by the diaphragm call. Crucial for imitating the anatomical reality of a 700lb bull's massive chest cavity and windpipe.
- *Mechanics:* A diaphragm alone sounds like a kazoo. Blowing the diaphragm *through* the tube provides the deep, guttural "growl" at the bottom of the bugle and the nasal resonance at the top.

### Open-Reed Bite Calls (Cow Calls)
External handheld calls where the hunter's teeth apply pressure to a mylar reed.
- *Pros:* Incredibly consistent, easy to use, and requires no diaphragm mastery. Perfect for soft, emotional Cow Mews.

## 3. The Core Vocabulary for OUTCALL Analytics
OUTCALL analyzes these specific acoustic envelopes.

1. **The Location Bugle:** A two-note, clean whistle (Low -> High -> Fade). Used by satellite bulls to locate the herd, or by the herd bull to keep auditory contact with his cows in thick timber.
2. **The Challenge Bugle (Lip Bawl):** The ultimate display of dominance. A chaotic, three-part scream (Growl -> High Scream -> Hyperventilating Chuckles). It is a direct threat to fight.
3. **The Social Cow Mew:** A soft, downward-sliding whistle. "Eeee-uuu." It signifies contentment and safety.
4. **The Estrus Whine:** A drawn-out, nasal, pleading variation of the cow mew. Used by cows actively seeking a bull to breed.
5. **The Glunk:** A bizarre, hollow, thumping sound made by a bull. It sounds like a rock being dropped into a deep well, created by compressing air in the chest cavity. Used when a bull is actively tending to a cow in his physical presence. (Rarely mimicked by hunters, but deeply respected by guides).

## 4. Masterclass Strategy: Wind, Terrain, and Pacing
Elk hunting is chess played on the side of a mountain.

- **The Morning Thermal Rule:** As the sun rises and warms the mountain, air currents flow *up* the mountain. If a bull is above you in the morning, your scent is blowing directly into his nose. Attempting to call him down the mountain to you will fail 99% of the time. You must climb *above* the herd and call *down* to them, using the rising thermals to mask your scent.
- **The Distance Trap:** A herd bull will often answer a hunter's bugle aggressively but refuse to move an inch. He is saying, "I have the cows, if you want to fight, come to me." The hunter must silently close the distance to within 80-100 yards (invading his personal bubble) and *then* issue a challenge bugle. At that distance, the bull's instinct to defend his harem overrides his caution, and he will often charge blindly toward the sound.
- **The Decoy Play:** Elk memory is highly visual. If a bull bugles, runs over a ridge expecting to see an elk, and only sees an empty meadow, he will instantly spook. Placing a lightweight 2D cow elk decoy 30 yards directly behind the caller provides the necessary visual validation to seal the deal.\n</document_content>\n\n---\n\n## FILE: `entitlement_logic.md` [Category: Technical/Core]\n<document_content>\n# Premium Entitlement & Hybrid Persistence

Premium status is not just a boolean in memory; it is a persistently verified state managed by the `UnifiedProfileRepository`.

## Hybrid Verification Logic
To ensure robustness against network issues or Cloud latency, the repository implements a hybrid check in `getProfile()`:
1. **Cloud Source**: Fetch the user document from the `profiles` Firestore collection.
2. **Local Backup**: If `isPremium` is `false` (or the fetch fails partially), the repository checks the `LocalProfileDataSource` (Secure Storage).
3. **Override**: If the local cache says the user is premium, the returned `UserProfile` entity has `isPremium: true` even if the Cloud document isn't updated yet.

## Reliability of `setPremiumStatus`
When a purchase is verified:
- **Local Write**: The status is immediately saved to local secure storage.
- **Cloud Write**: An update is sent to Firestore.
- This ensures that if the user loses internet immediately after a successful purchase, their "Pro" features remain unlocked on the next app restart.

## Guest Users
Users operating as "guest" cannot have their premium status synced to the Cloud, but the repository still attempts to handle their state via the local data source if possible.\n</document_content>\n\n---\n\n## FILE: `lifecycle_management.md` [Category: Technical/Core]\n<document_content>\n# App Shell Lifecycle Management

In Outcall, the `MainShell` uses a `PageView` to host the primary features (Home, Library, Practice, etc.). Because `PageView` keeps inactive routes alive in the widget tree, standard screen-level `dispose()` methods do not fire when the user switches tabs. This creates "resource leaks" where audio or recordings continue playing/running in the background.

## 1. The Centralized Stop Pattern

To prevent leaks, all global services (Audio, Recording) must be hooked into the `MainShell` tab-switching logic.

### Implementation in `MainShell`:
- **MainShell as ConsumerStatefulWidget**: Converted to access Riverpod providers globally.
- **`_onPageChanged(int index)` Hook**: This is the single source of truth for tab transitions.

```dart
void _onPageChanged(int index) {
  // 1. Stop any playing reference audio
  ref.read(audioServiceProvider).stop();
  
  // 2. Kill any active recording or countdown sessions
  final recState = ref.read(recordingNotifierProvider);
  if (recState.isRecording || recState.isCountingDown) {
    ref.read(recordingNotifierProvider.notifier).reset();
  }
  
  setState(() {
    _currentIndex = index;
  });
}
```

## 2. Audio Playback Lifecycle
While the shell handles tab-switching, individual screens should still clean up if they are popped or replaced:
- `AnimalCallsScreen` and `CallDetailScreen` call `_audioService?.stop()` in their `dispose()` methods.
- They also use `RouteAware` (`didPushNext`) to stop audio when the user navigates deeper (e.g., from List to Detail).

## 3. Recording Session Lifecycle
Recording sessions are particularly "risky" because they can consume significant storage if left running.
- **Tab Switch Reset**: Always call `recordingNotifier.reset()` on tab switch.
- **Hard Failsafe**: In addition to the UI-level auto-stop timer, the `RecordingNotifier` implements a controller-level hard max duration (see `recording_logic.md`).

## 4. Best Practices for Navigation Hooks
- **Never rely solely on `dispose()`** for global cleanup if using `PageView` or cached `TabController` views.
- **Centralize Service Ownership**: Use Riverpod to ensure the shell can reach the same service instance that the screens are using.
- **Use Haptics on Switch**: The `MainShell` trigger (`_onBottomNavTapped`) should provide light haptic feedback to confirm the user's tab choice.\n</document_content>\n\n---\n\n## FILE: `paywall_ui.md` [Category: Technical/Core]\n<document_content>\n# Paywall UI & UX Design

The `PaywallScreen` is the primary monetization touchpoint, designed to match the app's charcoal and gold luxury aesthetic.

## Visual Design
- **Gradient Buttons**: Uses a transitioning gold gradient (`accentGoldDark` to `accentGoldLight`) with a shimmer animation controller.
- **Glassmorphism**: The screen is often shown as a modal bottom sheet with a deep charcoal surface and subtle borders.
- **Icons**: Prominent gold "workspace_premium" crown icon.

## Subscription Tiers
The screen currently promotes two tiers:
1. **Monthly**: $4.99/mo
2. **Yearly**: $29.99/yr (labeled with a "Save 50%" badge to encourage conversion).

## Interactive Logic
- **Comparison Matrix**: A clean list showing the difference between Free (e.g., "Limited Call Library", "Basic Info") and Pro (e.g., "All 135+ Calls", "Detailed Scoring", "Offline Mode").
- **State Handling**: The "Upgrade" button transforms into a `CircularProgressIndicator` while the purchase is processing to prevent double-billing.
- **Auto-Dismiss**: If a purchase or restore succeeds, the screen automatically pops itself.

## Price Parsing & Sandbox Handling
Store price strings (from Google Play/Apple Store) vary by locale and environment. In sandbox testing, periods like `/30 min` or `/5 minutes` frequently leak into price strings.

The `PaywallScreen` uses a robust `_stripBillingPeriod` method to clean these strings:
- Uses regex to isolate the currency and numeric amount (e.g., `$24.99`).
- Handles both `/` and ` per ` separators.
- Ensures the UI consistently appends the intended period (e.g., `/yr`) regardless of how the store formatted the original string.

This prevents the confusing "/30mins" or "/5mins" labels from appearing to users in test tracks.\n</document_content>\n\n---\n\n## FILE: `predator_deer.md` [Category: Technical/Core]\n<document_content>\n# Predators & Deer: The Encyclopedia of the Whitetail Woods

Hunting whitetail deer (`Odocoileus virginianus`) and the predators that share their environment (coyotes, bobcats, foxes) requires entirely different biological approaches, yet they occupy the exact same acoustic space in the woods.

---

## 1. Deep Biological Context: The Apex Dynamics

### Whitetail Deer (The Prey)
Whitetail communication is deeply rooted in social hierarchy, the breeding season (the rut), and fear. Because they are a prey species, they are naturally paranoid.
- **The Vocal Range:** Deer are capable of incredibly loud noises (the snort wheeze, the alarm blow) but primarily communicate in soft, low-volume grunts and bleats that carry barely 60 yards. This is an evolutionary adaptation to prevent predators from pinpointing their location.
- **The October Lull vs. The November Rut:** Calling to a deer in early October with loud, aggressive territorial grunts is generally a mistake—bucks haven't established dominance yet and will flee from a perceived super-buck. However, that exact same loud grunt in mid-November (peak rut) will enrage a dominant buck into charging your tree stand to defend his breeding territory.

### The Predators
Coyotes (`Canis latrans`) and Bobcats (`Lynx rufus`) hunt via different senses but respond to the same acoustic triggers.
- **The Coyote (The Olfactory Pack Hunter):** Coyotes rely on smell and pack coordination. They use complex howling sequences to organize attacks or claim territory.
- **The Bobcat (The Visual Ambush Predator):** Bobcats are solitary, silent, and rely heavily on their phenomenal eyesight and stealth. They almost never howl, utilizing low purrs and growls only when physically close to a rival or a mate.

## 2. Advanced Calling Tools & Mechanics

### Corrugated Grunt Tubes (Deer)
A plastic tube with a mylar reed, attached to an expanding, accordion-style corrugated hose.
- *Pros:* The corrugated hose mimics the deer's windpipe. By expanding the hose, the hunter deepens the resonance chamber, lowering the pitch to mimic an older, heavier buck.
- *The "Click" Factor:* The primary failure point of a grunt tube is saliva freezing on the reed during cold November mornings. The caller must keep the tube tucked inside their jacket to maintain body heat, or the call will produce a mechanical "click" instead of a deep grunt, instantly spooking nearby deer.

### The "Can" Call (Deer)
A small, weighted cylinder that produces a perfect "doe bleat" when tipped upside down.
- *Master Technique:* Do not leave the bottom hole open perfectly. By covering the bottom hole with a thumb halfway through the bleat, the hunter dynamically alters the frequency, mimicking the natural "wobble" of a mature doe's voice box.

### Open-Reed Predator Calls
A hard plastic tone board with a single, exposed mylar reed.
- *Versatility:* The most powerful tool in the woods. By sliding their teeth up and down the reed, a hunter can mimic the deep, guttural howl of a coyote, the chaotic, high-pitched scream of a dying rabbit, or the aggressive bark of a red fox—all on the identical instrument.

## 3. The Core Vocabulary for OUTCALL Analytics

1. **The Buck Grunt (Social vs. Dominant):** Analyzed by OUTCALL primarily for its sub-bass F0 frequency and rhythmic tempo. OUTCALL heavily penalizes high-pitched grunts that fail to achieve the required 80-120 Hz chest resonance of a mature buck.
2. **The Snort Wheeze:** A violent, broadband hiss used by a buck to signal an impending physical attack. The engine analyzes this via MFCC algorithms, specifically looking for heavy acoustic scattering in the high frequencies without any defined tonal pitch.
3. **The Rabbit Distress:** The ultimate predator lure. Erratically rhythmic, chaotic, and desperately high-pitched. The OUTCALL engine runs its CREPE pitch-tracker at maximum sensitivity to capture the violent glissando spikes (800 Hz to 3000 Hz) that define a realistic dying animal scream.

## 4. Masterclass Strategy: Blind Calling vs. Reactionary Calling
- **Blind Calling (Deer):** Sitting in a tree stand and calling without seeing an animal. This should be minimal. 2 soft grunts every 45 minutes mimics a buck casually walking through the timber. Calling constantly sounds like an animal stuck in a trap.
- **Reactionary Calling (Deer):** You see a target buck walking out of range. If he is walking casually, hit him with a single grunt and wait. If he ignores it and keeps walking, immediately hit him with a Snort Wheeze. The sudden escalation from "casual greeting" to "violent threat" will often break his concentration and force him to investigate.
- **The Shotgun Predator Stand:** When calling coyotes in thick cover, the distress scream is going to bring them in at a full sprint. You will likely have less than 3 seconds to identify the target, aim, and shoot before they smell you and vanish. A fast-swinging shotgun loaded with heavy tungsten buckshot is far superior to a scoped rifle in these scenarios.\n</document_content>\n\n---\n\n## FILE: `profile_data_management.md` [Category: Technical/Core]\n<document_content>\n# Profile Data Management & History Ordering

Ensuring consistent data ordering across multiple platforms and storage backends (Firebase, Firedart, SQLite) is a core requirement for OUTCALL.

## 1. History Item Ordering Discrepancy
A critical discrepancy was discovered between the local and cloud history storage implementations:
- **Local / Secure Data Sources:** Used `insert(0, item)` to prepend new entries (newest-first).
- **Cloud (Unified Profile Repository):** Used `.add(data)`, which appended entries to the end (newest-last).

Since the UI (e.g., `HistoryDashboardScreen`) and logic consistently expect the history to be in newest-first order, this resulted in an "upside-down" list for cloud-synced profiles.

## 2. Resolving the Mismatch
The `UnifiedProfileRepository.saveResultForUser` method was updated to match the local sources by using `history.insert(0, data)`. All new recordings saved to Firestore will now be correctly ordered.

## 3. Read-time Migration (Sort-on-Read)
To avoid a complex one-time conversion script or an offline migration, a **sort-on-read** strategy was implemented in the `_sanitizeProfileData` method in `UnifiedProfileRepository`.

### Implementation:
- Every time a profile is loaded from any cloud source, the `history` list is explicitly sorted by its `timestamp` field in **descending order** (newest first).
- This ensures that existing users with reversed history data see their records fixed immediately upon loading, without requiring any write-back to the database.

## 4. Best Practices
- **Data sources should be consistent** in their entry-point logic (always prepend for chronological lists).
- **Sanitize on Load:** When data structure or ordering might be unreliable (e.g. from foreign backends), use a sanitization method to enforce the expected format before the data reaches the entities/UI.
- **Unified Achievement Persistence:** Use `profileNotifier.saveAchievementsForUser` when triggering achievement saves from outside the profile feature (e.g., from `RatingScreen`) to ensure consistent persistence.\n</document_content>\n\n---\n\n## FILE: `recording_logic.md` [Category: Technical/Core]\n<document_content>\n# Recording Session Logic & Duration Hardening

The practice and recording session in Outcall requires strict lifecycle management to prevent "runaway" recordings that can occur if the user switches tabs or if the UI-level auto-stop timer fails.

## 1. Practice Mode Selection
To maintain a unified "luxury" feel, the **Practice tab** uses the same 3-tier grid navigation as the Library screen.
- **Selection Mode:** Triggered via `selectionMode: true` on `CategoryGridScreen`.
- In this mode, tapping a call in `AnimalCallsScreen` returns the `call.id` to the `RecorderPage` via `Navigator.pop(result)`.

## 2. Hardening Recording Duration Limits
A critical requirement is that all practice recordings must auto-stop within a few seconds of the reference call's ideal completion time. This prevents recordings from continuing indefinitely (e.g. 5 minutes for an 8-second call).

### 2.1 UI-level Auto-Stop Timer
The `RecorderPage` maintains a `_autoStopTimer` which is calculated as `(call.idealDurationSec + 2).clamp(3, 60)`. 
- **The Problem:** UI timers can be unreliable if the widget enters a background state (e.g. when hosted in a `PageView` and the user switches tabs). In some versions, the `MainShell` was found to keep the practice tab's state alive while it was recording, but UI timers might not fire as expected if the app's focus changes.

### 2.2 Controller-level Hard Max Duration (Nuclear Failsafe)
To ensure recordings always stop, a hard duration limit should be implemented at the `RecordingNotifier` (controller) level.
- **Mechanism:** `RecordingNotifier` calculates a `maxDurationSec` (e.g. `idealDurationSec + 3`, with a hard ceiling of 65s) upon starting a recording.
- **Enforcement:** In the `_startTimer` periodic tick, the controller checks `state.recordDuration >= _maxDuration`. If exceeded, it immediately calls `stopRecording()`.
- This ensures that even if the UI timer fails, the recording will never exceed a reasonable duration.

## 3. Tab Switching Cleanup
In the `MainShell._onPageChanged` hook, the `RecordingNotifier.reset()` method must be called to immediately stop any active recordings or countdowns when the user navigates away from the Practice tab. This mirrors the `AudioService.stop()` implementation for playback.

## Summary of Duration Rules
| Scenario | Behavior |
| :--- | :--- |
| **Normal Practice** | Auto-stop at `idealDurationSec + 2s`. |
| **UI Timer Failure** | Controller-level hard limit stops at `idealDurationSec + 3s`. |
| **Absolute Maximum** | Hard ceiling of 65 seconds for any recording. |
| **Switching Tabs** | Stop recording immediately. |\n</document_content>\n\n---\n\n## FILE: `scoring_pipeline.md` [Category: Technical/Core]\n<document_content>\n# The Scoring Pipeline: Masterclass Deep Dive

The OUTCALL scoring engine is a sophisticated real-time analysis pipeline utilizing machine learning and advanced digital signal processing (DSP) to translate raw acoustic signals into an actionable 100-point performance metric. It acts as an objective, mathematical judge of hunting calls.

---

## 1. High-Level Pipeline Architecture
The scoring process rigorously separates raw feature extraction (the "Ear") from mathematical evaluation (the "Brain") into an isolated thread execution to maintain 60 FPS UI performance.

1.  **Audio Capture**: Standardized 44.1kHz / 16-bit PCM recording via the microphone.
2.  **Isolate Feature Extraction**: `AnalyzeAudioUseCase` offloads processing to a `compute()` thread to prevent UI jank while calculating heavy Fast Fourier Transforms (FFT).
3.  **Reference Retrieval**: The target `ReferenceCall` (e.g., standard mallard greeting) is pulled from the local library cache.
4.  **Biological Comparison**: `CalculateScoreUseCase` processes the deviation thresholds against expected biological parameters.
5.  **Smoothing**: The `RealRatingService` averages the final output.

## 2. Advanced Feature Extraction Sub-Routines

### Mel-Frequency Cepstral Coefficients (MFCC)
A spectral fingerprinting technique originally developed for human speech recognition, now adapted for bioacoustics. MFCC captures the **timbre** (tone quality) of the call—allowing OUTCALL to differentiate a turkey yelp made poorly with the mouth versus an authentic wooden box call, even if the pitch is mathematically identical. It compares the harmonic richness of the user's call against the biological resonance chamber (the chest/beak cavity) of the real animal.

### Dynamic Time Warping (DTW)
Standard cosine similarity fails when a user makes a call slightly faster or slower than the reference. DTW algorithmically "stretches" or "squashes" the time axis of the user's attempt to align the spectral peaks with the reference track, providing a fair rhythm and tone score regardless of overall tempo variations (crucial for feed chuckles and gobbles).

### Pitch & Harmonic Extraction (YIN / CREPE)
The engine extracts the dominant frequency (Hz) array over time to evaluate the vertical "break" (turkey yelp) or the horizontal "slide" (cow elk mew glissando). 
- **YIN/pYIN:** Used for clean, tonal calls (elk mews, single-reed ducks).
- **CREPE:** A deep-learning pitch tracker used for chaotic, messy, sliding calls with heavy distortion (fox screams, rabbit distress).

## 3. The Weighted Scoring Matrix

The final `overallScore` is dynamically weighted depending on the call type (pulsed vs. non-pulsed):

| Metric | Weight | Biological Context & Tolerance |
| :--- | :--- | :--- |
| **Pitch Accuracy** | **40%** | Is the dominant frequency hitting the expected animal vocal range? Evaluated on a curved falloff to prevent harsh "cliffs" if the hunter is slightly sharp or flat. |
| **Tone Quality** | **30%** | A blend of MFCC spectral matching (40%) and raw tonal clarity (60%). Evaluates nasality, buzz, throat-rasp, and harmonic sub-layers. |
| **Rhythmic Cadence** | **20%** | Crucial for pulsed calls (clucks, feed chuckles, gobbles). Measures tempo stability, precise micro-pauses between notes, and specifically penalizes metronomic (robotic) perfection in favor of biological variation. |
| **Duration & Envelope** | **10%** | Does the call attack quickly? Does it hold sustain? Does the volume taper off smoothly or crash abruptly like a human running out of air? |

## 4. Addressing Environmental Noise (March 2026 Engine Audit)
Following extensive field testing in windy environments and acoustic analysis through cheap tablet speakers, the OUTCALL logic was aggressively retuned to handle real-world hunting conditions:
- **Adaptive Noise Floor Filtering:** The bottom 10% of frequency amplitude frames are dynamically treated as the background noise floor (wind, leaves rustling) and automatically excluded from MFCC calculations.
- **Lower Tone Penalties:** The strict 50-point drop for dipping below 25% tone clarity was softened to a gradual 15% threshold multiplier, ensuring accurate tracking even when the mic is slightly muffled by gloves or a facemask.
- **Sibilance Rejection Algorithm:** High-frequency hiss (wind blowing directly across the mobile device mic port) is mathematically filtered out before it corrupts the Pitch Accuracy metrics of high-frequency calls (like the Elk Bugle or Snort Wheeze).\n</document_content>\n\n---\n\n## FILE: `sprint_history.md` [Category: Technical/Core]\n<document_content>\n# Development & Sprint History

> Tracks the major epics and feature additions for the OUTCALL application.

## 1. Deep Audit & Knowledge Base (March 7-8, 2026)
- **Objective**: Ground-truth audit of the codebase and creation of this searchable internal wiki.
- **Scoring Engine Retuning**: Solved the "24% score" bug for real-world recordings. Optimized noise penalties (Threshold 15, 0.8x multiplier) and MFCC weights (40%).
- **WAV Parser Roadmap**: Identified risk in hardcoded WAV offsets; established chunk-based parsing strategy.
- **Wiki Implementation**: Developed `docs/wiki.html` as the premium-branded internal documentation hub.
- **Bioacoustics Reference**: Integrated peer-reviewed frequency data for 5+ species directly into the scoring thresholds.
- **Market Analysis**: Conducted competitive research identifying OUTCALL's unique training niche vs. iHunt/HuntWise.

## 2. Rebranding & Performance Optimization (Early March 2026)
- **Complete Rebranding (OUTCALL)**: Removed the green turkey "Gobble Guru" logo. Replaced with gold-on-charcoal OUTCALL branding across the app, splash screen, and Play Store assets.
- **AI Chatbot Integration**: Developed a pure JavaScript chatbot (`chatbot.js`) using a FAQ-First strategy with an Ollama fallback (Gemma 3 4B) to `outcall-coach`.
- **Performance Optimization**: Implemented `Source.cache` first strategy across `FirebaseApiGateway`, resulting in near-instant loading for Global Rankings and Libraries.
- **2x2 Metrics Grid**: Overhauled the `AttemptDetailSheet` UI. Transitioned from a cramped horizontal row to a clean 2x2 grid.
- **Metric Labeling**: Translated raw keys (e.g. `timbre`, `air`) into human-readable tabs: Tone Quality, Breath Control, Pitch, and Rhythm.
- **AI Coach Refinement**: Locked the AI Coach to focus only on the four 0-100 score metrics, preventing hallucinated critiques of raw Hz values.

## 3. The Path to v1.8.3 (February - March 2026)
- **Migration to Native IAP:** Replaced RevenueCat with `in_app_purchase`. Developed a custom `NativePaymentRepository`.
- **Paywall UX Re-Alignment:** Finalized the Monthly ($4.99) and Yearly ($29.99) subscription models in a luxury UI.
- **Universal UX & iOS Accessibility:** Swept the UI ensuring all buttons hit a 14pt minimum size. Added semantic labels and verified WCAG AA high contrast for iOS App Store compliance. Added Apple Sign-In.
- **App Launch Optimization:** Rebuilt the boot sequence. Added a custom native splash screen that precaches assets and defers heavy initializations (cloud audio, remote config) to background isolates.
- **Fixed Practice Recording Times:** Simplified the recording UX by moving to a strict 15-second fixed window rather than matching reference lengths dynamically.
- **Linux Environment Fixes:** Resolved Fingerprint Sensor issues using `fprintd` for the desktop development environment.\n</document_content>\n\n---\n\n## FILE: `technical_quirks.md` [Category: Technical/Core]\n<document_content>\n# Detailed Implementation Quirks

## 1. The DI Matrix & Mocking Strategy
The repository relies on `di_providers.dart` to determine what services are injected.
- The `isMock` boolean controls whether we use `mock_auth_repository` or actual cloud services.
- This **MUST NOT** be set to true in production releases.
- The `PlatformEnvironment` is critical for Riverpod. When `Platform.isLinux` is true, we CANNOT use `Firebase.initializeApp()` normally for Auth. We rely entirely on the `FiredartAuthRepository` and `sqflite_common_ffi` implementations instead.

## 2. The Rating Algorithm Cleanup
The application evaluates user calls against reference audio (`RatingResult`). 
- **FFT Extraction:** Spectrogram comparison logic requires careful memory management.
- **Cleanup:** We must specifically destroy `cloud_audio_service` instances on route pops to prevent memory leaks during spectrogram generation.

## 3. Universal UX & Accessibility
- **Targeting iOS App Store Compliance.**
- **Rules:**
  - Minimum 14pt (16pt+ preferred) font size.
  - 48x48 minimum touch target size.
  - No default Material alert dialogs; always use consistent `showModalBottomSheet` with custom theme and glassmorphism.
  - Semantic labels for all image assets to improve field readability and ScreenReader support.

## 4. Achievement Calculation Race Condition
- **Issue:** Previously earned achievements were being displayed as "newly earned" after an analysis.
- **Cause:** `RatingScreen` was checking for achievements using a stale profile state before the `saveResult` process (which is async and involves multiple Firestore writes/reloads) had fully completed.
- **Resolution:** Modified `_checkForAchievements` to be `async` and enforced a strict sequence: `loadProfile()` → calculate achievements → `saveAchievements()` → final `loadProfile()`. This ensures the UI only celebrates genuinely new unlocks against the most up-to-date data.\n</document_content>\n\n---\n\n## FILE: `testing_methods.md` [Category: Technical/Core]\n<document_content>\n# Testing & Quality Assurance Methodology

Maintaining the "luxury" and "premium" feel of OUTCALL requires rigorous testing, specifically targeting the complexities of cross-platform audio processing and high-concurrency Firestore interactions.

## 1. Automated Testing Stack
- **Domain Logic**: Unit tests cover core logic (`ProfanityFilter`, `SpamFilter`, `CalibrationProfile`).
- **CI Enforcement**: All tests must pass in the `quality-gate` job of the GitHub Actions pipeline before a deployment is allowed.

## 2. Manual "Stress Test" Checklist
Before major releases, a manual check is performed on real hardware.

### Recording Edge Cases
- Home/Back button behavior during active recording.
- Rapid start/stop stress (hammering the record button).
- System interruptions (phone calls, alarms) during recording.
- Storage capacity limits (graceful failure when device is full).

### Audio Playback
- Rapid play/stop toggling (10× quickly on the same track).
- Cloud audio behavior under "Airplane Mode" constraints.
- Audio lifecycle logic (ensuring background audio stops when navigating to "Home").

### Navigation & UX
- Split-screen mode and orientation rotation during analysis processing.
- "Tab hammering": Rapidly switching between Home, Library, and Record.
- Long session stability (30+ minutes of continuous UI interaction).

## 3. Firestore Backend Stress Testing
OUTCALL utilizes a custom Python stress tester (`scripts/stress_test_firestore.py`) to find backend breaking points.

### Key Metrics Tracked
- **Profile Write Latency**: Simulates concurrent users creating/updating profiles. Target P95 latency is <800ms.
- **Leaderboard Contention**: Simulates multiple users submitting scores to the same leaderboard document simultaneously to test transactional isolation.
- **Burst Reads**: Measures duration to fetch 50+ documents across multiple collections.

## 4. Release Protocol
- Any **❌ Fail** in the manual checklist is a hard blocker for production.
- Any **⚠️ Warning** requires a flagged issue and developer sign-off.
- Target is a **100% pass rate** before promoting a build from Alpha to Production.\n</document_content>\n\n---\n\n## FILE: `turkey_calling.md` [Category: Technical/Core]\n<document_content>\n# Turkey Calling: The Encyclopedia of the Spring Woods

The wild turkey (`Meleagris gallopavo`) is North America's premier spring game bird. Hunting them requires an intimate understanding of their complex vocabulary, biological mating rituals, and an absolute mastery of acoustic illusion.

---

## 1. Deep Biological Context
Turkey hunting is fundamentally an exercise in reversing the natural order. In the wild, the male (Tom/Gobbler) goes to a high ridge, gobbles loudly to announce his presence, and the females (Hens) walk to him. The hunter must convince the Tom to break this biological code and walk to the Hen.
- **The Roost Schedule:** Turkeys sleep ("roost") in tall trees to avoid predators. At first light, they gobble on the roost. Around dawn (fly-down), they glide to the ground and begin their daily circuit of feeding, strutting, and loafing.
- **The Estrus Cycle:** A hen is only receptive for a few days. The entire spring hunting season is timed to coincide with the period when hens have been bred and are sitting on nests (incubating eggs). This leaves the Toms desperate, lonely, and much more likely to answer a hunter's call.
- **The Vision:** Turkeys have monocular, periscopic vision, seeing in full color with a 270-degree field of view. They can spot a hunter blinking at 50 yards. Calling them is only 50% of the hunt; sitting perfectly still is the other 50%.

## 2. Advanced Calling Tools & Mechanics
Turkey hunters carry a wider variety of specialized acoustic instruments than any other demographic.

### The Diaphragm (Mouth Call)
A plastic frame holding 1 to 4 stretched latex reeds, placed against the roof of the mouth.
- *Pros:* Completely hands-free (crucial when holding a shotgun). Offers the widest range of volumes and sounds (from soft clucks to screaming cuts).
- *Cons:* Extremely steep learning curve. Requires precise tongue pressure and air control.
- *Cuts:* The arrangement of slits cut into the top reed (V-cut, Batwing, Ghost, Cutter) dictates the amount of "rasp" (harmonic distortion) the call naturally produces.

### The Friction Call (Pot & Peg)
A round dish (the pot) made of plastic or wood, topped in a playing surface of Slate, Glass, Crystal, or Aluminum. Played with a wooden/carbon striker.
- *Pros:* Incredibly realistic, pure tones. Slate produces soft, close-range clucks and purrs. Glass/Crystal produces piercing, high-frequency yelps that carry across ridges.
- *Cons:* Requires two hands. Movement will get the hunter busted. Useless in the rain (unless using specialized waterproof chalk).

### The Box Call
A rectangular wooden trough with a moving lid (the paddle) attached by a single screw.
- *Pros:* The loudest call available. Phenomenal for locating turkeys on windy days. Extremely easy to use.
- *Cons:* Bulky, requires two hands, and the sound cannot be modulated as finely as a friction or mouth call.

## 3. The Core Vocabulary
Mastering these exact cadences is the key to OUTCALL's rhythm and tone scoring algorithms.

1. **The Plain Yelp:** A rhythmic 3-7 note sequence ("Yauk.. yauk.. yauk"). The bread and butter. Used by a hen to say "I am here."
2. **The Cluck & Purr:** A soft, rolling trill mixed with single sharp pops. It is the sound of absolute safety and contentment. Used to coax a gobbler the final 30 yards.
3. **The Cut (Excited Yelp):** Loud, fast, sharp, machine-gun clucks without any rolling "yelp." Used by an aggressive, aggravated, or exceptionally lonely boss hen. It forces a dominant Tom to gobble back in sheer excitement.
4. **The Tree Yelp:** Very soft, muffled yelps used just before dawn while still on the roost branch.
5. **The Kee-Kee Run:** The lost call of a young turkey. A high-pitched, clear whistle ("Kee.. kee.. kee..") often followed by a yelp. Primarily used in the fall hunting season.

## 4. Masterclass Strategy: "Taking His Temperature"
The biggest mistake beginners make is over-calling. A master hunter adjusts their calling volume, cadence, and frequency based strictly on the psychological state (the "temperature") of the bird.
- **The Hot Bird:** He gobbles at every yelp, immediately. He is desperate. *Strategy:* Hit him with loud, aggressive cuts. When he gobbles back, cut him off mid-gobble with more cuts. Enrage him.
- **The Hung-Up Bird:** He gobbles enthusiastically but paces back and forth at 80 yards, refusing to cross a fence or a creek. *Strategy:* Go completely silent (The Phantom Hen). If that fails, drag a leafy branch in the leaves to simulate walking away, or literally crawl backward 30 yards and call softly. Make him think you are leaving.
- **The Henned-Up Bird:** He has live hens with him. He will not leave them. *Strategy:* Ignore the Tom entirely. Focus exclusively on the "boss hen." Every time she yelps, cut her off aggressively with louder, sharper yelps. Insult her. She will eventually march over to fight the intruder, dragging the Tom along behind her.\n</document_content>\n\n---\n\n## FILE: `waterfowl_calling.md` [Category: Technical/Core]\n<document_content>\n# Waterfowl Calling: The Encyclopedia of the Marsh

Hunting ducks and geese is a dynamic, fast-paced acoustic discipline. While big-game hunters use calls to locate or challenge a single animal hidden in thick timber, waterfowl hunters use calls to manipulate massive flocks of flying birds, constantly adjusting their sound in real-time based on the flock's aerodynamic behavior.

---

## 1. Deep Biological Context: The Psychology of the Flock
Waterfowl (`Anatidae`) are highly gregarious species that rely on the safety of massive numbers to survive migration and winter foraging. 
- **The Illusion of Safety:** When a flock of mallards or Canada geese is flying at 200 feet, they are scanning the ground for two things: food and other birds. The goal of the caller is to create the complete auditory illusion of a massive, safe, actively feeding flock already on the ground (to match the visual illusion of the plastic decoys).
- **The Dominant Hen:** In mallard society, the older females (susie hens) are incredibly vocal and bossy. They dictate where the flock lands. A duck caller is almost exclusively mimicking this loud, dominant hen.
- **The Aerodynamics of Calling:** You cannot call ducks when they are flying directly at you—they will instantly pinpoint the source of the sound and realize you are not a duck. Master callers only blow their calls at the "wingtips and tailfeathers" (when the ducks are banking away or flying parallel), pulling them back toward the landing zone.

## 2. Advanced Calling Tools & Mechanics

### Single-Reed Duck Calls
An acrylic or wooden barrel containing a single, stiff mylar reed placed over a curved tone board.
- *Pros:* Ultimate volume and dynamic range. A single reed can scream loud enough to break wind over a mile away, and yet be throttled down to a soft, raspy whisper. It is the tool of champion callers.
- *Cons:* Unforgiving. Requires perfect back-pressure and diaphragm control. Over-blowing causes a catastrophic "squeak," instantly ruining the illusion.

### Double-Reed Duck Calls
Features two stacked mylar reeds (one slightly shorter than the other).
- *Pros:* "Built-in duck." The interaction of the two reeds naturally produces the raspy, vibrating sound of a mature hen mallard. Very difficult to overblow or squeak. The best choice for 90% of hunters.
- *Cons:* Lacks the blistering top-end volume of a single reed, and requires more air pressure to operate.

### Short-Reed Goose Calls
A specialized call utilizing a radically different acoustic principle: the "break."
- *Mechanics:* Unlike a duck call (where air flows smoothly over the reed), a goose call requires the caller to build massive air pressure against their tongue, and then suddenly release it, causing the reed to violently snap from a low pitch to a high pitch (the iconic "Honk").

## 3. The Core Vocabulary for OUTCALL Analytics
OUTCALL analyzes the rhythmic and tonal spacing of these specific sequences.

1. **The Hail Call (Highball):** A blistering, high-volume sequence of 10-20 notes. Used only to grab the attention of ducks flying in the stratosphere. Once they turn, the hail call stops immediately.
2. **The Greeting Call:** A rhythmic 5-7 note sequence ("Quack... quack.. quack. quack"). Declares safety and welcomes circling ducks down to the water. The volume and duration of each note *must* mathematically decrease as the sequence progresses.
3. **The Feed Chuckle:** A rapid, staccato, rolling burst of low-end clucks ("Tuka-tuka-tuka"). Mimics the chaotic sound of 50 ducks aggressively feeding and fighting over grain. It is the ultimate close-range confidence call.
4. **The Lonesome Hen:** A drawn-out, raspy, widely spaced sequence of quacks. Devastatingly effective on single, late-season drakes looking for a mate.

## 4. Masterclass Strategy: The "J" Hook and the Finisher
- **The "J" Hook Spread:** Ducks land directly into the wind like an airplane. A master hunter sets their decoys in the shape of a "J" or a "U", leaving a massive empty hole of water in the middle (the landing zone), facing downwind. The hunters hide at the top of the "J", calling the ducks directly up the runway into their faces.
- **The Finisher (Silence):** The most common mistake in waterfowl hunting is calling too much when the birds have already committed. When a flock of mallards has "locked up" (cupped their wings, extending their feet, dropping altitude rapidly), a loud greeting call will bounce off the water and terrify them. The master caller drops the call entirely and lets the decoys do the rest of the work. If they must call, it is only microscopic, soft feed chuckles.\n</document_content>\n\n---\n