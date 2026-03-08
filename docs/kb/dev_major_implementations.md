# Major App Implementations & Dev History

OUTCALL's development path is marked by conquering difficult, hardware-level audio processing challenges within the constraints of a cross-platform mobile framework (Flutter). This document serves as a high-level summary of the major technical pillars erected during development.

---

## 1. The Real-Time Scoring Pipeline (Isolate Architecture)
**The Challenge:** Processing Fast Fourier Transforms (FFTs) and Mel-Frequency Cepstral Coefficients (MFCCs) on a 44.1kHz audio stream instantly causes the main Dart UI thread to drop frames, resulting in extreme visual jank.
**The Implementation:** 
- Converted all heavy DSP math into a standalone Dart Isolate via `compute()`.
- The audio buffer fills continuously, and every 500ms, a chunk of byte-data is serialized and passed across the Isolate boundary.
- The secondary thread calculates pitch, rhythm, and timbre, returning a lightweight JSON payload of scores back to the main thread for 60FPS UI rendering.

## 2. In-App Purchase & Hybrid Entitlements
**The Challenge:** Relying solely on a cloud database to check if a user is "Premium" fails when the hunter is out of cell service.
**The Implementation:**
- Integrated `in_app_purchase` for the native native Android/iOS transaction handling.
- Built a dual-layer persistence model. The `EntitlementsRepository` first attempts a network check with RevenueCat/Firebase. If that fails, it reads a securely encrypted local cache (`shared_preferences` with AES encryption) to verify the premium token.
- Designed a "Luxury" Paywall UI using the brand's Gold/Charcoal aesthetic to convert free users to the AI Coach tier.

## 3. The "AI Coach" Integration
**The Challenge:** Providing users with more than just a number. If they score a 45/100, they need to know *why* and *how* to fix it.
**The Implementation:**
- Integrated the local Gemma 3 (4B) LLM model.
- The `RealRatingService` feeds the raw, sub-component scores (e.g., Pitch: 90, Rhythm: 20, Timbre: 45) into a strict system prompt.
- The LLM acts as the "Coach," generating 2-sentence actionable feedback ("Your tone was great, but you rushed the sequence. Put more space between your clucks.").
- *Note:* Also implemented a web-based FAQ chatbot for the landing page using Ollama via Cloudflare Tunnels to drive early-access signups.

## 4. Riverpod State Management & Navigation
**The Challenge:** Managing deeply nested state across recording active states, audio playback, scoring history, and premium paywall lockouts without creating a spaghetti architecture.
**The Implementation:**
- Adopted strict **MVVM (Model-View-ViewModel)** using `flutter_riverpod`.
- Implemented `AutoDispose` providers heavily to ensure the heavy RAM footprint of the AudioCache is flushed immediately when the user leaves the recording screen.
- Centralized dependency injection in `di_providers.dart` to allow effortless mocking of the audio engine and Firebase during unit testing (achieving 90%+ test coverage on core services).

## 5. The OUTCALL Brand Transformation
**The Challenge:** The app started as a generic "Gobble Guru" turkey-only application with standard Material Design colors.
**The Implementation:**
- Executed a major repository-wide rename and continuous integration restructuring to "OUTCALL".
- Standardized the visual design system across all screens, docs, and the wiki using Charcoal (`#0C0E12`) and Gold (`#E8922D`).
- Consolidated 135+ reference animal sounds into a heavily compressed, high-fidelity asset pack.
