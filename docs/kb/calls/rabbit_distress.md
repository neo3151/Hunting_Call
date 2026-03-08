# Rabbit Distress Weeps & Screams

The rabbit distress call is the universal "dinner bell" for predators across North America. It mimics the chaotic, squealing desperation of a rabbit caught by a hawk or owl, triggering a predatory feeding instinct in coyotes, bobcats, foxes, and even bears.

## Field Application
- **Purpose:** Used to draw predators into bow or rifle range. It is the most universally successfully predator call available.
- **The Rhythm:** Fast, frantic, and desperate. Weeps, screams, and chaotic high-pitched squeals.
- **Tools:** Synthetic closed-reed calls (easiest to use), open-reed bite calls (most versatile), or electronic callers.

## Engine Analysis & Scoring
The Rabbit Distress call is arguably the most chaotic sound analyzed by the OUTCALL engine. It lacks a steady pitch, a clean envelope, and a predictable cadence.

### Key Processing Metrics
1. **The Panic Envelope (Rhythm):** A distressed rabbit does not scream in a metronomic beat. The engine's rhythm analyzer explicitly looks for *irregular* bursts of sound. A perfectly steady "waa... waa... waa..." rhythm is heavily penalized as unnatural and robotic.
2. **High-Frequency Distress Tolerance:** The pitch of a rabbit scream often spikes from 800 Hz to over 3000 Hz instantaneously. The CREPE pitch detector is set to its highest tolerance band here, tracking rapid, shrieking glissandos without flagging them as errors.
3. **MFCC Chaos (Tone Quality):** The tone of this call is pure rasp and vibration. A pure, clean whistle will score a zero. The Tone Quality algorithm looks for heavy harmonic distortion and "throatiness" in the upper frequencies.

### Scoring Tips
- **Bite and Overblow:** The key to this call is intensity. Bite down hard on the reed (if using an open-reed call) and push air aggressively from the diaphragm. Soft, timid air will sound like a sick bird, not a dying rabbit.
- **The "Waaa-Waaa" Syllables:** Vocalizing the syllables "Waaaa-Waaaa" or "Wah-Wah" into the call creates the necessary vibrato and jaw movement to mimic the rabbit opening and closing its mouth while screaming.
