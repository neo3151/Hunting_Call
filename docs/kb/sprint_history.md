# Development & Sprint History

> Tracks the major epics and feature additions for the OUTCALL application.

## 1. Deep Audit & Knowledge Base (March 7-8, 2026)
- **Objective**: Ground-truth audit of the codebase and creation of this searchable internal wiki.
- **Scoring Engine Retuning**: Solved the "24% score" bug for real-world recordings. Optimized noise penalties (Threshold 15, 0.8x multiplier) and MFCC weights (40%).
- **WAV Parser Roadmap**: Identified risk in hardcoded WAV offsets; established chunk-based parsing strategy.
- **Wiki Implementation**: Developed `docs/wiki.html` as the premium-branded internal documentation hub.
- **Bioacoustics Reference**: Integrated peer-reviewed frequency data for 5+ species directly into the scoring thresholds.
- **Market Analysis**: Conducted competitive research identifying OUTCALL's unique training niche vs. iHunt/HuntWise.

## 2. Rebranding & Performance Optimization (Early March 2026)
- **Complete Rebranding (OUTCALL)**: Removed the green turkey "Gobble Guru" logo. Replaced with gold-on-charcoal OUTCALL branding across the app, splash screen, and Play Store assets.
- **AI Chatbot Integration**: Developed a pure JavaScript chatbot (`chatbot.js`) using a FAQ-First strategy with an Ollama fallback (Gemma 3 4B) to `outcall-coach`.
- **Performance Optimization**: Implemented `Source.cache` first strategy across `FirebaseApiGateway`, resulting in near-instant loading for Global Rankings and Libraries.
- **2x2 Metrics Grid**: Overhauled the `AttemptDetailSheet` UI. Transitioned from a cramped horizontal row to a clean 2x2 grid.
- **Metric Labeling**: Translated raw keys (e.g. `timbre`, `air`) into human-readable tabs: Tone Quality, Breath Control, Pitch, and Rhythm.
- **AI Coach Refinement**: Locked the AI Coach to focus only on the four 0-100 score metrics, preventing hallucinated critiques of raw Hz values.

## 3. The Path to v1.8.3 (February - March 2026)
- **Migration to Native IAP:** Replaced RevenueCat with `in_app_purchase`. Developed a custom `NativePaymentRepository`.
- **Paywall UX Re-Alignment:** Finalized the Monthly ($4.99) and Yearly ($29.99) subscription models in a luxury UI.
- **Universal UX & iOS Accessibility:** Swept the UI ensuring all buttons hit a 14pt minimum size. Added semantic labels and verified WCAG AA high contrast for iOS App Store compliance. Added Apple Sign-In.
- **App Launch Optimization:** Rebuilt the boot sequence. Added a custom native splash screen that precaches assets and defers heavy initializations (cloud audio, remote config) to background isolates.
- **Fixed Practice Recording Times:** Simplified the recording UX by moving to a strict 15-second fixed window rather than matching reference lengths dynamically.
- **Linux Environment Fixes:** Resolved Fingerprint Sensor issues using `fprintd` for the desktop development environment.
