# Whitetail Buck Grunt

The buck grunt is the cornerstone of whitetail deer communication, ranging from soft social check-ins to aggressive territorial challenges.

## Field Application
- **Tending Grunt:** Rhythmic, walking-cadence grunts simulating a buck trailing a doe.
- **Dominant Grunt:** Deeper, louder, and longer, challenging nearby males.
- **Tools:** Adjustable, corrugated plastic grunt tubes with internal Mylar reeds.

## Engine Analysis & Scoring
The buck grunt is a low-frequency, pulsed vocalization. It is short but carries significant acoustic weight.

### Key Processing Metrics
1. **Frequency Floor Verification:** A mature buck grunt sits very low in the spectrum, often between 80 Hz and 120 Hz. The OUTCALL engine heavily penalizes calls that spike into the 200+ Hz range, simulating a young, non-threatening yearling buck.
2. **Pulse Rate (Rhythm):** For a tending grunt, the engine uses beat-tracking algorithms to ensure the grunts match the rhythmic tempo of a deer walking (roughly one grunt per second).
3. **MFCC Depth Evaluation:** The "throatiness" of the call is analyzed via MFCCs. The engine compares the spectral depth of the user's call against the resonance chamber of an actual deer's chest/neck cavity.

### Scoring Tips
- **Guttural Origin:** Force air from deep in the chest, not the cheeks. The engine will detect the lack of resonance in a shallow "mouth grunt."
- **Inflection:** Adding subtle pitch variations (starting low and ending slightly higher, or vice versa) increases the realism and boosts the Tone score.
