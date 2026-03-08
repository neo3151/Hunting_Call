# Elk Cow Mew & Calf Chirp

The cow mew is the universal language of an elk herd. It signifies contentment, location, and social cohesion. A calf chirp is a shorter, higher-pitched version of the same sound.

## Field Application
- **Purpose:** Used to calm a nervous herd, locate other cows, or coax a hesitant bull the final few yards into bow range.
- **Tools:** Open-reed "bite" calls (which produce perfect mews with little practice) or diaphragm mouth reeds.

## Engine Analysis & Scoring
The cow mew is a relatively simple, smooth vocalization, but it requires precise pitch sliding to score highly.

### Key Processing Metrics
1. **The Downward Slide:** A perfect cow mew always slides *down* in pitch. It typically starts around 800-1000 Hz and smoothly "rolls over" the top, tapering down to 400-600 Hz. The CREPE pitch detector actively scores the smoothness of this downward trajectory.
2. **Nasality (MFCC Baseline):** Elk have highly nasal voices. The Tone Quality algorithm is calibrated to expect a specific degree of harmonic "buzz" or nasality, differentiating a true mew from a simple human whistle.
3. **Duration Constraints:** A cow mew is short—usually only 0.5 to 1.5 seconds. The engine will dock points for over-elongating the sound, which can inadvertently sound like a distressed calf and spook the herd.

### Scoring Tips
- **The "Eee-uuu" Articulation:** The sound is created by dropping the jaw or releasing pressure on the reed to create a distinct high-to-low transition. Flat, monotone squeaks will score a zero in Rhythm/Trajectory.
- **Soft Touch:** These are social, conversational calls. Over-blowing the reed to achieve volume will distort the Tone Quality score.
