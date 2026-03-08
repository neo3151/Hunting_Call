# Feral Hog Grunt & Squeal

Feral hogs are highly social but incredibly aggressive animals. Their vocalizations range from soft, rhythmic feeding grunts to violent, earsplitting territorial squeals.

## Field Application
- **Feeding/Social Grunt:** Used to mimic a contented sounder (herd) actively rooting for food. This calms approaching hogs and draws them out of heavy cover.
- **The Squeal:** Used to mimic hogs fighting over food or establishing dominance. It triggers an aggressive response from mature or dominant boars.
- **Tools:** Ridged plastic/acrylic grunt tubes specifically tuned lower than deer calls, or electronic callers (widely legal in many states for hogs).

## Engine Analysis & Scoring
The engine must handle two extreme ends of the acoustic spectrum within the same profile: the sub-bass of the grunt and the piercing high-frequency of the squeal.

### Key Processing Metrics
1. **The Sub-Bass Floor (Grunt):** A hog grunt is incredibly low, often vibrating around 60 Hz to 100 Hz. The MFCC algorithms compare this deep resonance against the user's call to ensure it isn't "shallow." 
2. **The Harmonic Shriek (Squeal):** A true hog squeal is chaotic and multi-tonal. The engine expects the pitch to spike violently from 500 Hz to over 3000 Hz in a fraction of a second, with intense harmonic distortion.
3. **Cadence Variability:** Unlike the steady, walking rhythm of a whitetail buck grunt, a hog sounder's grunts are rapid, uneven, and chaotic. The Rhythm score is adjusted to reward this erratic beat pattern (simulating multiple pigs feeding simultaneously).

### Scoring Tips
- **Guttural Origin (Grunts):** True hog grunts require forcing air from the absolute bottom of the diaphragm while tightening the throat. Mouth grunts will be flagged as "airy."
- **Nasal Violence (Squeals):** If mimicking a squeal manually (very difficult), the sound must be intensely nasal and high-pitched. Inconsistent volume or smooth, musical whistling will score a zero in Tone Quality.
