# The Scoring Pipeline: How OUTCALL Analyzes Sound

The OUTCALL scoring engine is a sophisticated real-time analysis pipeline utilizing machine learning and advanced digital signal processing (DSP) to translate raw acoustic signals into an actionable 100-point performance metric.

## 1. High-Level Pipeline Architecture
The scoring process rigorously separates raw feature extraction (the "Ear") from mathematical evaluation (the "Brain") into an isolated thread execution.

1.  **Audio Capture**: Standardized 44.1kHz / 16-bit PCM recording via the microphone.
2.  **Isolate Feature Extraction**: `AnalyzeAudioUseCase` offloads processing to a `compute()` thread to prevent UI jank while calculating heavy Fast Fourier Transforms (FFT).
3.  **Reference Retrieval**: The target `ReferenceCall` is pulled from the local library cache.
4.  **Biological Comparison**: `CalculateScoreUseCase` processes the deviation thresholds against expected biological parameters.
5.  **Smoothing**: The `RealRatingService` averages the final output.

## 2. Advanced Feature Extraction

### Mel-Frequency Cepstral Coefficients (MFCC)
A spectral fingerprinting technique originally developed for human speech recognition, now adapted for bioacoustics. MFCC captures the **timbre** (tone quality) of the call—allowing OUTCALL to differentiate a turkey yelp made poorly with the mouth versus an authentic wooden box call, even if the pitch is identical.

### Dynamic Time Warping (DTW)
Standard cosine similarity fails when a user makes a call slightly faster or slower than the reference. DTW algorithmically "stretches" or "squashes" the time axis of the user's attempt to align the spectral peaks with the reference track, providing a fair tone score regardless of tempo variations.

### Pitch & Harmonic Extraction (YIN / CREPE)
The engine extracts the dominant frequency (Hz) array over time to evaluate the "break" (turkey yelp) or the "slide" (cow elk mew). It also measures **Harmonic Richness** to differentiate true vocal fold resonance from simple white-noise rushing air.

## 3. The Weighted Scoring Matrix

The final `overallScore` is dynamically weighted depending on the call type (pulsed vs. non-pulsed):

| Metric | Weight | Biological Context |
| :--- | :--- | :--- |
| **Pitch Accuracy** | **40%** | Is the dominant frequency matching the expected animal vocal range? Evaluated on a curved falloff to prevent harsh "cliffs". |
| **Tone Quality** | **30%** | A blend of MFCC spectral matching (40%) and raw tonal clarity (60%). Does it sound like a turkey, or does it sound like a human whistling? |
| **Rhythmic Cadence** | **20%** | Crucial for pulsed calls (clucks, feed chuckles). Measures tempo stability and precise pauses between notes. |
| **Duration & Envelope** | **10%** | Does the call start, peak, and finish with the right volume envelope within the correct total seconds? |

## 4. Addressing Environmental Noise (March 2026 Audit Update)
Following extensive field testing in windy environments and through cheap tablet speakers, the OUTCALL logic was retuned:
- **Adaptive Noise Floor:** The bottom 10% of frequency frames are dynamically treated as the background noise floor and excluded from MFCC calculations.
- **Lower Tone Penalties:** The strict 50-point drop for dropping below 25% tone clarity was softened to a gradual 15% threshold multiplier, ensuring accurate tracking even in the windy hunting woods.
