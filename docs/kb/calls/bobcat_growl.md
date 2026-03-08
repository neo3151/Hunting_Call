# Bobcat Growl & Purr Analysis

The bobcat vocalizes primarily for territorial defense and mating. Unlike the harsh scream of a cougar, bobcat growls and purrs are low-frequency, guttural, and highly textured.

## Field Application
- **Purpose:** Used primarily by hunters to challenge an incoming bobcat or to stop one that is trotting away. It triggers a territorial response.
- **Tools:** Most effectively produced using open-reed voice-manipulable calls, or specialized electronic callers. It is exceedingly difficult to reproduce naturally with just the mouth.

## Engine Analysis & Scoring
Bobcat calls present a unique challenge for the OUTCALL scoring engine due to their low fundamental frequency and heavy harmonic distortion (the "gravelly" nature of a growl).

### Key Processing Metrics
1. **Low Frequency Focus:** The fundamental frequency (F0) of a bobcat growl often sits between 150 Hz and 300 Hz.
2. **Pitch Detection Algorithm:** The YIN algorithm is prioritized over simple autocorrelation here to accurately track the low, sustained pitch amidst the heavy harmonic noise.
3. **MFCC Weighting:** Because the growl is essentially "textured noise," the MFCC (Mel-frequency cepstral coefficients) score makes up 60% of the Tone Quality grade, prioritizing the spectral shape of the growl over the pure pitch itself.

### Scoring Tips
- **Consistency is Key:** A high score requires maintaining a steady, low rumble without breaking pitch into a higher-octave squeak. 
- **Duration:** Sustaining the growl for 3-5 seconds mimics a mature, confident cat. Shorter bursts are penalized as unnatural.
