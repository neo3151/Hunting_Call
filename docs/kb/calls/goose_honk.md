# Canada Goose Honk & Cluck

The standard Canada goose honk is an iconic two-syllable sound. The cluck is a shorter, sharper single-note version used for aggressive feeding and finishing.

## Field Application
- **Purpose:** To hail distant flocks and create the illusion of a massive, active feeding group on the ground or water.
- **Tools:** Short-reed or flute-style Canada goose calls. Short reeds offer far more speed and versatility.

## Engine Analysis & Scoring
The Canada goose call is defined by its dramatic "break" or "crack" in pitch.

### Key Processing Metrics
1. **The "Her-Onk" Pitch Break:** A goose call ALWAYS has two parts. The fundamental frequency starts low and guttural ("Her-") and then sharply "cracks" into a high, piercing note ("-Onk"). 
2. **Glissando Rejection:** The engine explicitly looks for a *sharp, instantaneous* jump in pitch between the two syllables. If the pitch slides smoothly from low to high over time, the algorithm flags it as unnatural (a common beginner mistake on a flute call).
3. **The "Cluck" Condensation:** A cluck is simply a compressed honk where the two syllables occur in a fraction of a second. The rhythm analyzer measures the duration of the "break" to differentiate between a hailing honk and an aggressive cluck.

### Scoring Tips
- **The Air Wall:** The high note ("-Onk") is achieved by hitting a wall of back-pressure in the call, causing the reed to snap over. Pushing slowly will result in a flat, monotone drone that the engine will penalize heavily. 
- **Cadence is King:** A flock of geese sounds chaotic, but individual birds maintain steady cadences. The beat tracker will analyze sequences of 5-10 honks for rhythmic consistency.
