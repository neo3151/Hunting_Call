# Red Fox Scream

The raspy bark and piercing scream of the red fox is a hallmark of winter predator hunting. It is primarily a territorial warning or mating call.

## Field Application
- **Purpose:** To locate other foxes at night or to challenge a dominant male defending his territory.
- **Tools:** Open-reed predator calls or natural voice (though very difficult).

## Engine Analysis & Scoring
The fox scream is an acoustic anomaly—it is incredibly raspy, extremely chaotic, and lacks a steady fundamental frequency.

### Key Processing Metrics
1. **Broadband Energy Tolerance:** Unlike a clean elk bugle or a duck quack, the OUTCALL engine has to widen its pitch-tracking tolerances significantly. The Fox Scream is expected to be "messy" acoustically.
2. **The 2-Part "Wow-Wow" Bark:** A true fox bark is often a harsh "Wow-WOW," with the second syllable higher and louder. The beat-tracking algorithm specifically looks for this dual-peak envelope.
3. **High-Frequency Harshness:** The Tone Quality score rewards high-frequency harmonic energy. A low, muffled bark will be flagged as a generic domestic dog.

### Scoring Tips
- **Gravel the Throat:** A smooth whistle will fail immediately. The engine expects intense vibrato and throat-rattle (MFCC irregularity).
- **The Sharp Cut-off:** Each bark or scream in the sequence must end abruptly. The volume envelope should look like sharp spikes, not slow swells.
