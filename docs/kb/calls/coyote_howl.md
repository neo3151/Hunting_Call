# Coyote Howl & Yip Analysis

The coyote is North America's most talkative predator. Their howling is a complex language of location, territorial claim, and pack bonding.

## Field Application
- **The Lone Howl:** A smooth, rising and falling siren. Used at dawn and dusk to locate packs.
- **The Challenge Bark-Howl:** Sharp barks followed by a chopped howl, aggressively territorial.
- **Tools:** Open-reed bite calls or diaphragm-style predator calls. 

## Engine Analysis & Scoring
Coyote howls are characterized by extremely clean, sweeping frequency curves. 

### Key Processing Metrics
1. **The Trajectory (Glissando):** The scoring engine heavily relies on Dynamic Time Warping (DTW) to analyze the *shape* of the howl. A true lone howl starts low (~500 Hz), rises smoothly over 3 seconds to a peak (~1200 Hz), and falls softly. 
2. **Pitch Detection:** CREPE or pYIN is favored here. The engine requires high-resolution pitch tracking to ensure the glissando is smooth and lacks the sudden "voice cracks" common in amateur callers.
3. **Harmonic Clarity:** Coyotes have surprisingly pure "singing" voices. The Tone Clarity metric penalizes excessive rasp or air noise during the main body of the howl.

### Scoring Tips
- **The Roll:** The OUTCALL engine tracks the volume envelope. A high score requires starting softly, swelling to a loud peak, and tapering off naturally—not cutting off abruptly.
- **Avoid Flutter:** Tremolo (shaking the pitch) is a common mistake that drastically reduces the Rhythm and Tone scores.
