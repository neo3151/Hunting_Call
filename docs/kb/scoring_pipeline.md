# The Scoring Pipeline: Masterclass Deep Dive

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
- **Sibilance Rejection Algorithm:** High-frequency hiss (wind blowing directly across the mobile device mic port) is mathematically filtered out before it corrupts the Pitch Accuracy metrics of high-frequency calls (like the Elk Bugle or Snort Wheeze).
