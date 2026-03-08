# The Turkey Gobble

The gobble is the signature acoustic trademark of the male wild turkey. It is a booming, rattling, multi-noted challenge used to establish dominance over subordinate males and attract willing hens.

## Field Application
- **Purpose:** Rarely used by hunters to actually draw in a bird (as it often attracts predators or other hunters). Primarily used as a "shock" or "challenge" call to force a silent, stubborn tom to reveal his exact location or engage in a dominance fight.
- **Tools:** Specialized shaker boxes (shaking a wooden box to rattle an internal reed) or specialized mouth-blown gobble tubes. Very few hunters can produce a realistic gobble with a standard diaphragm.

## Engine Analysis & Scoring
The turkey gobble is incredibly difficult to mimic perfectly and presents a significant processing challenge for the OUTCALL engine due to its rapid, rattling staccato rhythm.

### Key Processing Metrics
1. **The Machine-Gun Rattle (Rhythm):** A gobble is not one sound; it is an explosion of 10 to 25 distinct, rapid-fire notes delivered in about one to two seconds. The rhythm analyzer relies heavily on high-speed envelope tracking to count and measure the spacing of these microscopic staccato bursts.
2. **Dual-Tone Harmonic Structure:** A mature longbeard (three years or older) gobbles with two voices: a high-pitched, rattling "chatter" and a deep, sub-bass "boom" resonating from his chest cavity. The MFCC Tone Quality algorithm actively searches for this dual-layer spectral richness (the "roundness" of the gobble).
3. **The Roll-Off Envelope:** A gobble explodes violently at the start but trails off into a sputtering, slower rattle at the exact end. The engine penalizes an abrupt, sharp cutoff.

### Scoring Tips
- **Chest Resonance:** When using a gobble tube or shaker, the key is the deep, hollow resonance. High-pitched, clacking, or squeaky gobbles are flagged by the engine as "jakes" (juvenile males) and score lower than a mature boss-tom simulation.
- **The Explosive Start:** Do not ease into a gobble. It must violently "snap" onto the frequency spectrum instantly.
