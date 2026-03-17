# OUTCALL Project Knowledge Base
> Comprehensive snapshot of all accumulated project knowledge, architecture, and patterns.
> Generated: March 11, 2026 — saved before `.gemini` cleanup.

---

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Infrastructure & Hosting](#infrastructure--hosting)
3. [Developer Environment](#developer-environment)
4. [Build & Release Automation](#build--release-automation)
5. [Audio Analysis Pipeline](#audio-analysis-pipeline)
6. [AI Coaching System](#ai-coaching-system)
7. [Quality & Security](#quality--security)
8. [Localization](#localization)
9. [Web Assets & Wiki](#web-assets--wiki)
10. [Known Patterns & Gotchas](#known-patterns--gotchas)

---

## Architecture Overview

**OUTCALL** is a Flutter hunting call training app with a clean domain-centric architecture. Sprint 4-7 quality: **A+ (98%)**.

### Tech Stack
| Component | Technology |
|---|---|
| Frontend | Flutter (Dart) — Android + Windows |
| Backend | FastAPI (Python) via Docker |
| Database | Firestore (with offline persistence) |
| Auth | Firebase Auth (Google + Anonymous) |
| Remote Config | Firebase Remote Config |
| AI Coaching | Google Gemini API (`gemini-2.0-flash`) via Cloud Backend |
| Fingerprint DB | GCS (public bucket, downloaded at server startup) |
| Audio Storage | Firebase Storage (paid calls), bundled assets (free calls) |
| CI/CD | GitHub Actions (APK builds, model training pipeline) |
| Distribution | Google Play (CLI upload), Google Drive (debug APKs via rclone) |

### App Score (Sprint 7)
| Category | Grade | Score |
|---|:---:|:---:|
| Architecture | A | 9/10 |
| Feature Depth | A | 9/10 |
| UX Polish | A | 9/10 |
| Security | B+ | 8/10 |
| Test Coverage | B+ | 8/10 |
| Accessibility | B+ | 8/10 |
| Localization | A+ | 10/10 |
| **Overall** | **A+** | **98%** |

### Key Feature Modules
- 16+ feature modules: recording → analysis → leaderboard pipeline
- 30 achievements with celebratory overlay + confetti
- Seasonal themes, history dashboard
- Daily challenge system
- Global leaderboard (Firestore)
- Premium/freemium gating via `FreemiumConfig`

---

## Infrastructure & Hosting

### Cloud Backend (AI Backend)
- **URL**: `api.huntingcalls.app`
- **Env vars**: `GEMINI_API_KEY`, `PORT`, `APP_ENVIRONMENT`
- **Startup**: `_ensure_models()` downloads fingerprint_db.json, coach_classifier.pkl, label_encoder.pkl from GCS if missing or detected as LFS pointer files
- **Dockerfile**: Python 3.11 + FastAPI + Uvicorn
- Response times: AI coaching ~1.2s, fingerprint ~200-500ms

### Google Cloud Storage (Models)
- Public bucket with model files
- Downloaded at startup via `urllib.request.urlretrieve`
- Files: `fingerprint_db.json` (~161MB), `coach_classifier.pkl`, `label_encoder.pkl`

### Firebase Services
- **Firestore**: User profiles, leaderboard, history — offline persistence enabled
- **Auth**: Google Sign-In + Anonymous
- **Remote Config**: Feature flags (`isLeaderboardEnabled`), `ai_coach_url`
- **Storage**: Paid audio call assets
- **App Check**: Active for security

### API Gateway Pattern (`api_gateway.dart`)
- `FirebaseApiGateway`: Mobile (cache-first for docs, server-first for collections/rankings)
- `FiredartApiGateway`: Desktop (Firedart for Linux/Windows)
- Server-first with cache fallback for ranking queries

---

## Developer Environment

### Windows Setup
- **JDK**: Required for Android builds, verify with `java -version`
- **Flutter SDK**: Located at `C:\flutter`
- **Terminal**: Oh My Posh + Caskaydia Cove Nerd Font, theme: `paragon`
- **PowerShell Aliases**:
  ```powershell
  function hc { Set-Location "C:\Users\neo31\Hunting_Call" }
  function fbr { flutter build appbundle --release }
  function fapk { flutter build apk --release }
  function fan { flutter analyze }
  ```

### Common Issues
- **Parallel builds FAIL on Windows** — Gradle file locks. Always build APK and AAB sequentially
- **Git "NUL" file error**: Avoid `git add -A` when stray reserved filenames exist
- **Dart Analysis Server stalls**: Clear `.dart_tool` cache, restart analysis server
- **Unicode in Python scripts**: Wrap `sys.stdout`/`sys.stderr` with `utf-8` encoding

---

## Build & Release Automation

### Debug APK (Quick)
```powershell
flutter build apk --debug --split-per-abi --target-platform android-arm64
rclone copyto "build\app\outputs\flutter-apk\app-arm64-v8a-debug.apk" "gdrive:OUTCALL/dev-builds/app-debug.apk" --progress --drive-chunk-size 64M --no-check-dest
```

### Release Build
```powershell
flutter clean
flutter build appbundle --release
python scripts/upload_play.py --track alpha --aab build/.../app-release.aab --name "Release Name" --notes "..."
```

### Versioning
- Format: `major.minor.patch+buildNumber` (e.g., `1.8.0+33`)
- Build number MUST increment for every Play Console upload
- Verify: `grep "version:" pubspec.yaml`

### GitHub Actions
| Workflow | Trigger | Purpose |
|---|---|---|
| `build-apk.yml` | Push to `main` | Auto-builds debug APK |
| `train-model.yml` | Manual dispatch | Runs training pipeline, uploads models to GCS |
| `flutter_ci.yml` | PR to `main` | Analysis + unit tests |
| `deploy_release.yml` | Version tag push | Signed AAB → Play Store |

### Secrets (GitHub)
| Secret | Purpose |
|---|---|
| `SERVICE_ACCOUNT_JSON` | Google Play API publishing |
| `SIGNING_KEY` | Base64-encoded JKS keystore |
| `KEY_PROPERTIES` | Gradle signing metadata |
| `GCP_SERVICE_ACCOUNT_KEY` | GCS model uploads (training pipeline) |

### Play Store Upload (`upload_play.py`)
- Python wrapper around Android Publisher API v3
- OAuth2 flow with browser-based login, token cached in `scripts/play_token.json`
- Supports: internal, alpha, beta, production tracks
- Resumable uploads for large AABs

---

## Audio Analysis Pipeline

### Recording → Analysis Flow
1. **Record** audio on phone (WAV)
2. **Local analysis** (`_analyzeUseCase.execute()`) — FFT, MFCC, spectrogram on device
3. **Reference analysis** — cached per animal, loaded from bundled assets (free) or Firebase Storage (paid)
4. **Fingerprint match** — sends audio to backend `/api/fingerprint` (10s timeout, optional)
5. **Score calculation** — pitch, timbre, rhythm, duration, envelope, formant, noise scoring
6. **Personality feedback** — `PersonalityFeedbackService` generates critique
7. **Save** to profile history, submit to leaderboard if score ≥ 60

### Scoring Components
- Pitch score (Hz comparison to reference)
- Timbre/tone quality score
- Rhythm/cadence score
- Duration score
- Pitch contour score
- Envelope (attack/sustain/decay) score
- Formant score
- Noise floor score
- Fingerprint match percentage (from backend)

### Fingerprint System (Backend)
- Audio → `extract_fingerprint()` → hash matching against DB
- IDF-weighted scoring (inverse document frequency)
- DB built from reference audio with pre-computed IDF weights
- 30s timeout on Flutter side, 10s outer timeout in `RealRatingService`
- 45s global timeout on entire `rateCall()` to prevent infinite spinner

### Cloud Audio Service
- Free calls: served from bundled assets (instant, offline)
- Paid calls: downloaded from Firebase Storage, cached locally in `audio_cache/`
- `resolveFilePath()` for analysis, `resolveAudioSource()` for playback

---

## AI Coaching System

### Current: Gemini API via Cloud Backend
- Model: `gemini-2.0-flash`
- Endpoint: `POST /api/coaching`
- Response time: ~1.2 seconds
- System prompt embedded in backend `services.py`

### Previous: Local Ollama (DEPRECATED)
- Model: `outcall-coach` (Gemma 3 base)
- Exposed via Cloudflare Quick Tunnels
- Required `OLLAMA_ORIGINS="*"` environment variable
- **NOW DELETED** — Gemini API is the replacement

### AI Coach Knowledge Base (Species-Specific)
- **Waterfowl**: Mallard hail call (5-6 quacks decreasing), feeding chuckle rhythm, Canada goose honk
- **Elk**: Bugle technique (low→high→sharp drop), cow calls, rut strategy
- **Whitetail**: Grunt types (contact/tending/challenger), snort-wheeze usage
- **Turkey**: Yelp fundamentals, cutting technique, purr for final approach
- **Moose**: Cow call (3-5s nasal moan), bull grunt series
- **Predators**: Coyote interrogation howls (45s apart), bear distress sequences (30-40 min)

### Technical Metrics Diagnosed
1. **Pitch**: Tongue pressure / throat tension
2. **Timbre**: Equipment fit, mouth positioning
3. **Rhythm**: Cadence (often more critical than pitch for realism)
4. **Air consistency**: Diaphragm control

---

## Quality & Security

### Input Sanitization (`InputSanitizer`)
- XSS/HTML tag stripping
- Control character removal (`0x00-0x1F`, `0x7F`)
- Length enforcement: names (50 chars), feedback (500 chars)
- Profanity filtering via `ProfanityFilter`

### Profanity Filter
Multi-stage approach:
1. **Normalization**: Leet-speak collapse (`0→o`, `3→e`, `4→a`, `5→s`, `7→t`)
2. **Delimiter removal**: Strips spaces/dots/underscores between letters
3. **Hidden character stripping**: Zero-width chars
4. **10-category blocklist**: Profanity, slurs, sexual, drugs, hate, violence, ableist, troll, impersonation, leet-speak

### Spam & Bot Prevention (`SpamFilter`)
- Bot-farm email pattern: `firstname.lastname.NNNNN@gmail.com`
- Domain blocklist: mailinator, guerrillamail, tempmail, yopmail, etc.
- Ghost account detection: no email + zero activity + >7 days old

### Content Moderation Audit (March 4, 2026)
- Firebase Auth: 63 accounts scanned → 0 flagged (Google filters effective)
- Firestore Profiles: 41 scanned → 5 flagged (custom nicknames are the risk)
- Remediation: Reset to name="Hunter", cleared nicknames via Firestore REST API

### Firestore Audit Pattern
- Auth: Firebase CLI refresh token → OAuth2 access token
- Scan: Firestore REST API with pagination (`pageSize=300`)
- Remediate: `PATCH` with `updateMask` for targeted field updates

---

## Localization

### Setup
- `.arb` files in `lib/l10n/`, template: `app_en.arb`
- 230+ ARB keys, 15+ screens fully localized
- Generated class: `S.of(context)`

### Key Rules
- Widgets using `S.of(context)` CANNOT be `const`
- Private helper methods need `BuildContext` parameter for locale access
- Batch extract 20-30 keys at once, then run `flutter gen-l10n`
- Search for missed strings: `Text\('[A-Z][A-Z]` regex

---

## Web Assets & Wiki

### Landing Page (`docs/index.html`)
- Public-facing website with AI chatbot
- `chatbot.js`: FAQ-first check (regex), then LLM routing
- Quick-reply chips, typing indicator, floating action button

### Wiki (`docs/wiki.html`)
- Encyclopedia of hunting calls with animal profiles
- Maintained by Python scripts in `/scripts/`:
  - `update_wiki.py`, `update_wiki_encyclopedia.py`
  - `update_wiki_profiles.py`, `update_wiki_more.py`, `update_wiki_extreme.py`

### Chatbot (UPDATED)
- **Previous**: Local Ollama via Cloudflare tunnel (DEPRECATED)
- **Current**: Uses Gemini API via cloud backend endpoint

---

## Known Patterns & Gotchas

### Flutter
- `Navigator.canPop(context)` — guard back buttons in tab contexts to avoid black screen
- `StaggeredFadeSlide` — smooth screen loading animations
- Font tree-shaking: reduces MaterialIcons from 1.6MB to 16KB in release builds
- `.withOpacity()` → `.withValues(alpha: x)` migration for performance
- `FutureProvider.autoDispose` — use for data that should re-fetch on screen re-entry

### Android
- Manual icon generation: Pillow script for all 10 density buckets
- `ic_launcher.xml` in `mipmap-anydpi-v26` for adaptive icons
- Never build APK + AAB in parallel on Windows

### Backend
- LFS pointer files: `_ensure_models()` checks file size <1000 bytes to detect pointers
- Backend reads `PORT` from `os.environ` (no shell expansion)
- `docker-compose.yml` for local development parity

### Accessibility
- `Semantics` widgets on all interactive elements with descriptive labels
- `MergeSemantics` for grouping, `ExcludeSemantics` for decorative elements
- 44x44px minimum touch targets
- WCAG contrast standards

### Static Analysis
- Zero `print()` calls — all logging via `AppLogger` gated behind `kDebugMode`
- Zero `TODO` comments in production
- Maintain 0 errors/warnings/infos from `flutter analyze`
