# Advanced Audio Analysis Techniques

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
- Pitch detection ignores frames below noise floor
