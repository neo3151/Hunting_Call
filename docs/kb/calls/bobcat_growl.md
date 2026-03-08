# Bobcat Growl & Purr Masterclass

The bobcat vocalizes primarily for territorial defense, mating, and communicating with kittens. Unlike the harsh scream of a cougar, bobcat growls and purrs are low-frequency, guttural, and highly textured. Because bobcats are notoriously stealthy and visual hunters, using audio to manipulate them requires absolute precision and patience.

---

## 1. Deep Biological Context
Bobcats (`Lynx rufus`) are solitary predators that rely on ambush tactics. Their vocal apparatus is designed for close-to-medium-range communication.
- **The Purr:** Similar to a domestic cat but much deeper. Used when content, nursing, or approaching a mate. It vibrates at an extremely low frequency (25-30 Hz) which has been biologically shown to promote bone density and healing in felines.
- **The Growl / Yowl:** A drawn-out, guttural moan often escalating into a raspy yowl. This is strictly territorial or related to estrus (mating season, typically late winter: February-March).
- **Behavioral Triggers:** A bobcat hunting a rabbit distress call will often sit down and watch the source for 20-40 minutes before moving. A bobcat growl can break this stalemate by triggering a territorial defense instinct, forcing the cat to approach and defend its hunting ground.

## 2. Advanced Calling Mechanics
It is exceedingly difficult to reproduce naturally with just the mouth. Most hunters use specialized tools or electronic callers.
- **Tools:** Open-reed voice-manipulable calls (like the Dan Thompson PC2) are preferred over closed reeds because they allow for manipulating the pitch by sliding teeth/lips up and down the mylar reed.
- **Airflow & Diaphragm:** To mimic a growl on a hand call, the hunter must "gargle" or flutter their uvula while exhaling slowly over the reed. 
- **Hand Manipulation:** Cupping the hands tightly over the end of the call and slowly opening them creates the "wah" effect of a cat opening its mouth to yowl, filtering the high frequencies dynamically.

## 3. Hunting Setup & Strategy
Bobcats are not coyotes; they do not come running in recklessly.
- **Pacing:** Call sequences must be long. Play a distress sound for 15 minutes, pause for 5. If a cat is spotted but won't commit, switch immediately to a low bobcat growl to challenge them.
- **Visuals:** Because bobcats are sight-hunters, pairing a growl with a visual decoy (a motorized furry tail) is critical. The growl gets their attention; the visual motion locks them in.
- **Wind & Terrain:** Bobcats prefer thick brush, rocky outcroppings, and creek beds. Set up with a crosswind. They will almost always try to circle downwind to smell the intruder before committing.

## 4. Common Mistakes & Diagnostics
- **Too Loud:** The most common mistake. Bobcats have incredible hearing. Blasting a growl at 100 dB sounds unnatural and will spook them. The sound should carry no more than 100-200 yards.
- **Wrong Pitch (Too High):** Slipping on an open reed will cause the call to squeak. To a mature bobcat, a high-pitch squeak from a "rival" sounds like a kitten and will not trigger a dominant response.

## 5. Engine Analysis & Scoring (OUTCALL Deep Dive)
Bobcat calls present a unique challenge for the OUTCALL scoring engine due to their low fundamental frequency and heavy harmonic distortion (the "gravelly" nature of a growl).

### Key Processing Metrics
1. **Low Frequency Focus:** The fundamental frequency (F0) of a bobcat growl often sits between 150 Hz and 300 Hz. The engine filters out anything above 1200 Hz to isolate the "rumble."
2. **Pitch Detection Algorithm:** The YIN algorithm is prioritized over simple autocorrelation here. YIN is specifically mathematically robust against the heavy harmonic noise and sub-harmonics present in feline growls.
3. **MFCC Weighting:** Because the growl is essentially "textured noise," the MFCC (Mel-frequency cepstral coefficients) score makes up 60% of the Tone Quality grade. The engine analyzes the envelope of the noise floor to ensure it matches the biological acoustic chamber of a 20-30 lb feline.
4. **Duration & Steadiness:** A high score requires maintaining a steady, low rumble without breaking pitch for 3-5 seconds. Shorter bursts are penalized as unnatural.
