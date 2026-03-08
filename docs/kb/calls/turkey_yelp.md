# Wild Turkey Yelp & Cluck Masterclass

The standard yelp is the absolute foundation of communication among wild turkeys (`Meleagris gallopavo`). A hen yelps to gather a flock scattered by danger, to locate her poults, or, most critically for the hunter, to indicate her location and readiness to mate to a listening gobbler.

---

## 1. Deep Biological Context
While the gobble is the sound of the tom, the yelp is the pulse of the turkey woods. Mastering the subtle emotional inflections of the yelp is the difference between a master caller and a novice.
- **The Plain Yelp:** A 3-to-7 note rhythmic sequence ("Yauk... Yauk... Yauk"). It is a basic "Here I am" or "Where are you?" call.
- **The Tree Yelp:** A very soft, muffled, slow 3-note yelp used while the turkeys are still sitting on branches in the dark before dawn. It simply acknowledges the flock is waking up.
- **The Assembly Yelp:** A loud, long, aggressive sequence of 15-20 yelps used by a mature "boss hen" demanding her flock regroup immediately after being scattered.
- **The Cluck:** A single, sharp, short "Pop" or "Put." It is a reassurance call. It means "I am here, and everything is safe." (Conversely, a loud, sharp, repeated "Putt-Putt-Putt!" is the universal alarm call, signaling mortal danger to every bird in the area).

## 2. Advanced Calling Mechanics
- **Tools:** The friction call (slate, glass, or crystal pot paired with a wooden striker), the rubber-and-latex diaphragm mouth call, or the air-operated wooden box call. 
- **The Friction Pot:** The striker must be held like a pencil, tilted at a 45-degree angle away from the body. The caller draws tiny, tight ovals without ever lifting the striker off the slate. The friction creates the high-to-low snap.
- **The Diaphragm "Roll-Over":** The mouth caller pins the latex reed to the roof of their mouth, pushes air, and dramatically drops their bottom jaw mid-breath. This drops the tongue pressure off the reed in a fraction of a second, causing the pitch to "break" or snap drastically from a high whistle to a raspy cluck.

## 3. Hunting Setup & Strategy
- **The Morning Fly-Down:** Before sunrise, hit a single, soft Tree Yelp. If the tom gobbles above you, DO NOTHING else. Wait until you hear the heavy wings of the turkey flying down to the ground. Then, hit him with a confident 5-note plain yelp.
- **The Phantom Hen:** If a tom is answering every yelp you make but refuses to walk closer than 80 yards, he is "hung up" waiting for the hen. Stop calling entirely. The silence will confuse him, simulating a hen that lost interest and walked away, often forcing him to run toward you to find her.
- **Cluck and Purr:** As the tom enters the "red zone" (inside 40 yards), switch from loud yelps to entirely soft, single clucks mixed with purring. This paints a picture of a calm hen feeding happily, lowering his guard completely.

## 4. Common Mistakes & Diagnostics
- **Machine-Gun Cadence:** A yelp is not a metronome. It has a specific biological pacing. "Yauk-Yauk-Yauk" with zero spacing sounds frantic and unnatural. The classic cadence is: "Yee-auk... Yee-auk... Yee-auk."
- **Missing the "Front End":** A yelp is actually a two-syllable word. Just making a low, raspy "auk" sound skips the high-pitched clear whistle ("Yee") at the beginning. It sounds like a dying frog.
- **Over-Calling:** A gobbler that has heard 200 yelps in 10 minutes knows exactly where you are, and knows a real hen would have walked over to him by now. Silence is a weapon.

## 5. Engine Analysis & Scoring (OUTCALL Deep Dive)
The turkey yelp is defined by its signature two-note "roll-over." The OUTCALL algorithms mathematically dissect this specific structural transition within every single note.

### Key Processing Metrics
1. **The "Kee-Yauk" Pitch Break (Glissando Vector):** A perfect yelp is actually two distinct notes slammed together. It starts with a high, clear "Kee" (the front-end whistle, often around 1200-1500 Hz) and immediately, violently snaps downward into a raspy, lower "Yauk" (around 400-600 Hz). The OUTCALL CREPE engine meticulously tracks this high-to-low *instantaneous* pitch break. If the pitch slides slowly downward, it is heavily penalized.
2. **The Front-to-Back Ratio (MFCC Check):** A high-scoring Tone Quality relies on the ratio of the clear front-end (the "Kee") to the raspy back-end (the "Yauk"). Too much clear whistle sounds like a domestic farm bird; too much heavy rasp sounds like a dying coyote. The MFCC algorithm perfectly balances this 40/60 "whistle-to-rasp" expectation.
3. **The Rhythm Benchmark:** A standard hen yelp sequence is a beautiful, rhythmic spacing. The beat-tracking algorithm expects near-perfect biological spacing between the notes, but it importantly requires the actual notes themselves to get slightly shorter in duration and softer in volume toward the absolute end of the 5-note sequence.
4. **The Reassurance Cluck Isolate:** The app can score a cluck independently. The algorithm identifies a cluck as exactly the "Yauk" half of the yelp, delivered perfectly isolated as a single, incredibly sharp, sub-0.3-second acoustic pop.
