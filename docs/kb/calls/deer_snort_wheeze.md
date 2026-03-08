# Whitetail Snort Wheeze

The snort wheeze is the most aggressive vocalization a whitetail buck can make. It is a direct, physical challenge issued by a dominant male to an intruder.

## Field Application
- **Purpose:** Used only when a mature buck is visible but ignoring grunts or rattling. It is a high-risk, high-reward call that will either enrage a mature buck into a dead sprint toward the caller or terrify him into running away.
- **Tools:** A multi-chambered grunt tube, or simply natural voice (pushing air hard through pinched lips).

## Engine Analysis & Scoring
This is one of the most mechanically unique calls analyzed by the OUTCALL engine because it is almost entirely **broadband noise** rather than a tonal pitch.

### Key Processing Metrics
1. **The "Phfft-Phfft-Pshhhhh" Structure:** The engine explicitly looks for a two- or three-part rhythm. It expects two short bursts of high-pressure air followed by a long, sustained hiss that tapers off. 
2. **MFCC (Timbral) Dominance:** Because there is no true fundamental frequency (pitch) to track, the Pitch Accuracy score is nearly zero-weighted. Instead, MFCC analysis (measuring the spectral "hiss") and Rhythm combined make up 90% of the scoring metric.
3. **Low-Frequency Rejection:** The engine actively filters out low frequencies to differentiate a snort wheeze from wind blowing across the microphone or heavy breathing.

### Scoring Tips
- **The Staccato Start:** The initial "Phfft" must be sharp and violently short. Soft, airy begins will fail the rhythm check.
- **Intensity:** The final "Wheeze" needs to be sustained with gradually decreasing pressure, like air leaking forcefully from a tire. Start loud and taper off.
