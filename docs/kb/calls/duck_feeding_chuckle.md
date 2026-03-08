# Mallard Feed Chuckle

The feed chuckle (or rolling chuckle) mimics the chaotic, contented sounds of a large flock of mallards actively feeding and fighting over food on the water.

## Field Application
- **Purpose:** Used as a close-in finishing call. When a flock is circling tightly overhead, the feed chuckle provides the final "confidence" sound needed to convince them to drop their landing gear.
- **Tools:** Single or double-reed duck calls. Single reeds are generally capable of much faster, crisper chuckles.

## Engine Analysis & Scoring
This call is entirely about tempo, rhythm, and low-end resonance.

### Key Processing Metrics
1. **Staccato Burst Analysis:** The OUTCALL engine expects to see rapid, continuous bursts of sound (often 3-5 distinct "ticks" per second). The Rhythm score is heavily weighted here.
2. **Frequency Cap:** A feed chuckle is a low-volume, guttural sound. If the dominant frequency exceeds 600 Hz, the engine penalizes the score, assuming the hunter is blowing "kazoos" rather than producing the low vibrating "cluck".
3. **Dynamic Time Warping (DTW):** Because every caller has a slightly different natural speed (some use a "tik-a-tik-a-tik" vocalization, others use "dug-a-dug-a-dug"), DTW is crucial here. It aligns the rhythm of the user's chuckle with the reference track without penalizing them strictly for tempo differences as long as the spacing is uniform.

### Scoring Tips
- **Guttural Air:** The sound should originate deep in the throat. High-pitched, squeaky chuckles will score poorly on Tone Quality.
- **Variability:** A truly realistic feed chuckle is not a metronome. It should have slight bursts of speed mixed with short pauses, mimicking multiple ducks simultaneously. OUTCALL analyzes the rhythmic variance specifically.
