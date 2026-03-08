# App Development Roadmap (2026-2027)

OUTCALL is currently in active beta on Android, with a massive set of core features already completed. The roadmap below outlines the immediate short-term goals for commercial release and long-term expansion plans into new tech and platforms.

## Q2 2026: Commercial Launch & Hardening
The immediate priority is transitioning from a functional beta into a resilient, monetized consumer product.
- **Scoring Engine V2:** Completing the transition from YIN pitch detection to the deep-learning pYIN/CREPE models for high-noise environments (especially for windy waterfowl hunting).
- **iOS Port Validation:** The Flutter codebase is theoretically cross-platform, but CoreAudio integration and permission handling for the iOS microphone require extensive physical device testing.
- **Paywall Refinement:** Launching the "OUTCALL Elite" tier ($4.99/mo or $29.99/yr) powered by RevenueCat.
- **Offline Mode Validation:** Ensuring Firebase Analytics and the local Core Data caching system gracefully handle users tracking calls entirely deep in the backcountry without cell service.

## Q3 2026: Social & Competitive Features
Hunting is inherently social and competitive. OUTCALL will expand beyond solo coaching.
- **Global Leaderboards & Seasons:** Implementing a ranked Elo system where users compete globally on specific species calls (e.g., "September Elk Bugle Challenge").
- **Shareable Brag-Cards:** Generative images displaying the user's score waveform against the golden reference, formatted for easy sharing on Instagram/X.
- **Live Head-to-Head:** WebRTC audio streaming to allow two hunters to "call-off" against each other, with the AI engine acting as the live judge.

## Q4 2026: The "Live Woods" Wearable Integration
Moving the app from a pre-hunt training tool into an active, in-the-field companion.
- **Smartwatch Haptics (Apple Watch / WearOS):** While hunting, taking out a bright phone screen is unviable. The user will be able to start an active listening session via their watch. The watch will use haptic feedback (buzzing) to tell the hunter if the turkey they just heard in the distance was a 1-year-old Jake, or a mature 3-year-old Boss Tom based on the engine's sub-bass resonance analysis.
- **Bluetooth Decoy Integration:** Syncing the OUTCALL engine with motorized decoys to automatically trigger motion only when the user executes a perfectly timed "Feed Chuckle" sequence.

## 2027 & Beyond: Synthetic Wildlife Generation
- **Dynamic AI Opponents:** Generating completely synthetic, reactive animal audio using advanced TTS and sound-synthesis models. The user will engage in a "mock hunt" where an AI-generated elk bugles back at them, dynamically changing its aggression, volume, and simulated distance based exactly on how the user responds.
