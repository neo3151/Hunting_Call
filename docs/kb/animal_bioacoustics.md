# Animal Bioacoustics — Frequency & Spectral Reference

> Compiled from peer-reviewed bioacoustics research for use in OUTCALL's scoring engine calibration and reference call validation.

## Turkey (Meleagris gallopavo)

**Hearing range**: 290 Hz – 5,250 Hz (optimal sensitivity ~2,000 Hz)

| Call Type | Frequency Range | Notes |
|-----------|----------------|-------|
| **Gobble** | 400 – 4,500 Hz | Complex multi-harmonic vocalization |
| **Yelp** | ~1,000 Hz | Hen yelps higher-pitched than tom yelps |
| **Cluck** | ~1,300 Hz | Short, sharp single notes |
| **Purr** | 700 – 1,400 Hz | Soft, rolling contentment call |
| **Cackle** | 1,000 – 4,000 Hz | Excited, rapid series |
| **Cutting** | Up to 12,000–15,000 Hz | Aggressive excited calls; highest energy calls |

### Scoring Implications
- Turkey calls span a wide frequency range; pitch tolerance should be relatively wide (±100-200 Hz for fundamental)
- Harmonic content is critical for realism assessment (especially gobble)
- Rhythm/tempo matters greatly for yelps, clucks, and cutting sequences

---

## Elk (Cervus canadensis)

**Bugle structure**: Three segments — on-glide → whistle → off-glide

| Call Type | Frequency Range | Notes |
|-----------|----------------|-------|
| **Bugle (fundamental)** | ~145 Hz | Low-frequency vocal fold tone |
| **Bugle (whistle)** | 1,000 – 4,000+ Hz | Upper airway whistle, can be 10x higher than fundamental |
| **Cow call / Mew** | 800 – 2,000 Hz | Soft, rising pitch that trails off |
| **Alarm bark** | 1,500 – 3,000 Hz | Sharp, urgent, dog-like bark |
| **Calf mew** | Higher than cow mew | Higher pitch signals youth |

### Scoring Implications
- Elk bugle uses **biphonation** (two independent sound sources) — MFCC comparison must account for this dual-frequency signature
- Aggressive vs non-aggressive bugles differ in formant structure, not just pitch
- Duration is a key differentiator (bull bugles are longer than cow calls)

---

## White-tailed Deer (Odocoileus virginianus)

**Hearing range**: 250 Hz – 30+ kHz (best sensitivity 4–8 kHz)

| Call Type | Frequency Range | Notes |
|-----------|----------------|-------|
| **Grunt** | 100 – 500 Hz | Low, guttural; dominant buck communication |
| **Bleat** | 1,500 – 4,000 Hz | High-pitched doe/fawn call |
| **Fawn distress** | 2,000 – 6,000 Hz | Urgent, high-pitched |
| **Snort-wheeze** | Broadband | Nasal snort + wheeze; aggressive dominance display |
| **General vocalizations** | 1,000 – 8,000 Hz | Strongest energy at 3,000–6,500 Hz |

### Scoring Implications
- Grunt calls are very low frequency — pitch detection algorithms may need larger analysis windows
- Deer call audible range is only 100–200 yards, so volume/projection matters
- Snort-wheeze is broadband noise, difficult to score spectrally

---

## Coyote (Canis latrans)

**Hearing range**: Up to 45,000 Hz (45 kHz)

| Call Type | Frequency Range | Notes |
|-----------|----------------|-------|
| **Howl** | 500 – 3,000 Hz | Long-range territorial/social communication |
| **Yips/Yip-howl** | 1,000 – 5,000 Hz | Social bonding, pack reunion |
| **Bark** | 500 – 2,000 Hz | Low-medium intensity warning |
| **Unstructured shrieks** | 1,000 – 6,000 Hz | Energy concentrated 1–3 kHz |
| **Distress calls (prey mimicry)** | Up to 40,000+ Hz | Coyotes can hear these; humans cannot |

### Scoring Implications
- Coyote calls use extensive tone/pitch/modulation variation via mouth, lips, and tongue
- Howls have complex frequency modulation — DTW-based comparison more appropriate than static pitch matching
- Distress calls lure coyotes from frequencies far above human hearing; app scoring should focus on audible components

---

## Duck (Mallard — Anas platyrhynchos)

**Hearing range**: 66 Hz – 7,600 Hz (best sensitivity ~2,000 Hz)

| Call Type | Frequency Range | Notes |
|-----------|----------------|-------|
| **Hen quack** | 1,000 – 4,000 Hz | The classic "quack" — reed vibration on tone board |
| **Decrescendo / hail call** | 1,500 – 4,000 Hz | 5-6 notes, loud → soft, attracts distant ducks |
| **Feeding chuckle** | 800 – 2,500 Hz | Raspy, low-intensity |
| **Drake quack** | 800 – 2,500 Hz | Lower-pitched, longer than hen quack |
| **Teal whistle** | 2,000 – 5,000 Hz | Short, high-pitched |

### Scoring Implications
- Duck calls rely on reed mechanics; frequency AND intensity are both meaningful
- Single-reed calls offer wider range (high hails → raspy feeds); scoring should account for call type
- Decrescendo call has declining volume curve — duration + volume envelope scoring relevant

---

## Cross-Species Reference Table

| Species | Lowest Call Hz | Highest Call Hz | Primary Energy Band | Pitch Tolerance Recommendation |
|---------|---------------|-----------------|---------------------|---------------------------------|
| Turkey | 400 | 15,000 | 1,000–4,000 | ±150 Hz on fundamental |
| Elk | 145 | 4,000+ | 800–2,000 (cow) | ±80 Hz (cow), ±200 Hz (bugle) |
| Deer | 100 | 8,000 | 3,000–6,500 | ±100 Hz |
| Coyote | 500 | 6,000+ | 1,000–3,000 | ±200 Hz (high variability) |
| Duck | 800 | 5,000 | 1,000–4,000 | ±120 Hz |
