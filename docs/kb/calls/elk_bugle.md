# Elk Bugle (Location / Challenge)

The elk bugle is the loudest and most complex bioacoustic signal produced by any North American land mammal. It ranges from deeply guttural, roaring growls to piercing, multi-octave screams.

## Field Application
- **Location Bugle:** A clear, high-pitched two-note bugle without aggressive grunts at the end. Used to locate bulls from afar.
- **Challenge Bugle (Lip Bawl):** A violent, multi-stage scream meant to enrage a herd bull into a fight. 
- **Tools:** Diaphragm (mouth) calls combined with a large plastic or carbon-fiber resonance tube.

## Engine Analysis & Scoring
The elk bugle pushes the absolute limits of the OUTCALL analysis engine, requiring it to track an incredibly wide frequency sweep while simultaneously analyzing rapid cadence changes.

### Key Processing Metrics
1. **The Three-Part Structure:** The engine expects distinct phases:
    - **Phase 1: The Growl:** A low, guttural vibration (often dipping below 150 Hz).
    - **Phase 2: The Scream:** A sudden, steep glissando (slide) up to a deafening high pitch, often exceeding 2500 Hz. The engine relies on CREPE to accurately track this extreme jump.
    - **Phase 3: The Chuckles:** 3 to 7 rapid, rhythmic grunts simulating the bull hyperventilating. 
2. **Harmonic Overtone Analysis:** A real bull elk produces two distinct sounds simultaneously—a roar from the vocal cords and a whistle from the nasal cavity. The MFCC Tone Quality algorithm actively searches for this dual-layer spectral richness.
3. **Duration Integrity:** A full challenge bugle lasts 4-6 seconds. Early cutoff is heavily penalized.

### Scoring Tips
- **Hit the High Note Cleanly:** The most common mistake is applying too much tongue pressure on the diaphragm reed, causing the high note to "crack" or stall. The pitch tracking algorithm will instantly register a drop in frequency stability.
- **Rhythmic Chuckles:** The trailing chuckles MUST be distinct notes, not just a sputtering breath. The engine expects hard rhythm peaks at the end of the waveform envelope.
