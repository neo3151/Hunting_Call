# Feral Hog Grunt & Squeal Masterclass

Feral hogs (`Sus scrofa`) are highly social, aggressively territorial, and incredibly intelligent animals. Their vocalizations range from the soft, rhythmic feeding grunts of a contented sounder (herd) to the violent, earsplitting, multi-tonal squeals of boars fighting for dominance.

---

## 1. Deep Biological Context
A hog sounder communicates constantly, and silence in the woods often indicates danger.
- **The Feeding/Social Grunt:** A deep, continuous, low-frequency rhythmic grunt. Made by sows and piglets actively rooting up soil. It is the ultimate confidence sound, acting as an acoustic camouflage. If a sounder is feeding, they do not care about snapping twigs or rustling leaves, allowing a hunter to stalk closer.
- **The Squeal (Aggression):** A violently chaotic, high-pitched scream. This mimics hogs aggressively fighting over a rich food source or establishing social dominance. The sound of a fight triggers an intense curiosity and dominant response from mature, solitary boars in the area.
- **The Danger Bark:** A short, sharp, violently loud "Woof!" issued by the lead sow when she smells or sees danger. This instantly scatters the entire sounder into heavy cover.

## 2. Advanced Calling Mechanics
- **Tools:** Specialized, ridged plastic/acrylic grunt tubes specifically tuned much larger and lower than whitetail deer calls. Electronic callers playing recorded audio are extremely popular and widely legal in many states specifically for feral hog eradication.
- **The Squeal Tube:** Many hog calls feature an exposed, dual-reed system on the outside of the tube. By biting down violently on the external reed while exhaling forcefully, the hunter can instantly spike the pitch into a deafening squeal.
- **Guttural Resonance:** True hog grunts require forcing air from the absolute bottom of the diaphragm while simultaneously tightening the throat. Mouth grunts sound too hollow and "airy" to trick an educated hog.

## 3. Hunting Setup & Strategy
- **The Stalking Camouflage:** The most effective use of a hog call is as cover noise during a spot-and-stalk hunt in thick brush. If you accidentally snap a loud twig while creeping up on a sounder, immediately hitting a soft feeding grunt can convince them it was just another hog foraging nearby.
- **The Dinner Bell (Squeal Play):** If hunting from a blind over an open field or feeder, playing an aggressive, violent 1-minute fight sequence (squeals mixed with deep grunts) can draw a cautious mature boar out of the thick timber to investigate the commotion and claim the food.
- **Swamp Thermals:** Hogs rely primarily on their phenomenal sense of smell. Set up crosswind in riparian zones, swamps, or creek beds where scent naturally flows parallel to the water source.

## 4. Common Mistakes & Diagnostics
- **Deer Grunting:** Using a standard whitetail deer grunt tube. It is entirely the wrong frequency, lacking the deep sub-bass resonance and rhythmic chaos of a hog.
- **Constant Squealing:** Continuously playing a brutal squeal sequence for 20 minutes is unnatural. Real hog fights last 15-30 seconds, followed by contented grunting as the winner eats.
- **Ignoring the Wind:** A hog can be fooled repeatedly by sound and sight, but they will never second-guess their nose. If they get downwind of you, the hunt is over instantly.

## 5. Engine Analysis & Scoring (OUTCALL Deep Dive)
The OUTCALL engine must handle two extreme ends of the acoustic spectrum simultaneously within this single profile: the sub-bass of the grunt and the piercing high frequencies of the squeal. 

### Key Processing Metrics
1. **The Sub-Bass Floor Validation (F0):** A hog grunt sits incredibly low, vibrating heavily around 60 Hz to 100 Hz. The MFCC spectral array specifically compares this deep resonance against the user's call to ensure the call is originating from a broad resonance chamber (a massive chest cavity) rather than being a "shallow" mouth noise.
2. **The Harmonic Shriek Filter (Squeal):** A true hog squeal is chaotic and multi-tonal. The engine's pitch tracker expects the frequency to spike violently from 500 Hz to over 3000 Hz in a fraction of a second, with intense harmonic distortion. Pure, clean whistles are severely penalized.
3. **Chaotic Cadence Variability (Rhythm):** Unlike the steady, walking, metronomic rhythm of a whitetail buck grunt, a feeding hog sounder's grunts are rapid, uneven, erratic, and sometimes overlapping. The Rhythm scoring algorithm is explicitly inverted here—it rewards erratic, randomized beat patterns (simulating multiple pigs feeding simultaneously) and penalizes perfect, machine-like consistency.
