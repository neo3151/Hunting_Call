# 🗺️ OUTCALL Ecosystem Roadmap — Moonshot Edition

**Timeframe:** October 2026 – March 2027
**Last updated:** September 30, 2026

> Covers all three repos:
> - **[App]** `Hunting_Call` — Flutter app (v3.3.0+219 in flight)
> - **[Backend]** `Hunting_Call_AI_Backend` — FastAPI scoring swarm + Coach Buck
> - **[Sentinel]** `Sentinel_Orchestrator` — community/marketing agents

---

## Vision

Today Outcall scores practice calls. By April 2027, Outcall is the
**bioacoustic intelligence layer for hunting**: it hears the woods, identifies
what's out there, tells you which call to answer with, and coaches you while
you make it. Every scored call makes the system smarter — a flywheel no
competitor can shortcut, because they'll have the app but not the data.

**The bet:** audio + agents + a growing fingerprint corpus = the "Shazam for
animal calls" with a coach built in. Nobody else is close.

---

## Current State (Sept 30, 2026)

| Area | Status |
|------|--------|
| Android | Live on Play Store, v3.2.6+218; v3.3.0+219 committed (audit remediation, security hardening) |
| iOS | Launch prep in flight — fastlane + Apple Sign-In configured, not yet shipped |
| Uncommitted app work | Bioacoustic scorer platform split (`_native` TFLite / `_web` stub), connectivity + auth refactors |
| Scoring | 13-dimension client pipeline + 7-agent backend swarm; cadence-sequence scoring added (uncommitted) |
| Species | ~40+ species, 111 audio assets, 60+ backend bioacoustic fingerprints |
| Monetization | Premium gating live (library locks, daily challenge), Play Billing verified server-side |
| Infra | Single DO droplet, ~5–10 concurrent scoring capacity; uptime monitoring + HTTPS unchecked |
| Demo funnel | Signed prospect demo invites implemented (uncommitted) — latent B2B machinery |

---

## Phase 0 — Land the Plane (October 2026)

*Ship everything already in flight. Peak deer/elk season is NOW — a stable
dual-store launch is the highest-leverage move before any moonshot work.*

- [x] **[App]** Commit and push v3.3.0 work — bioacoustic scorer platform
      split, demo mode, macOS scaffold, auth/connectivity hardening all landed
      (`940f9c5` + `3c5fae1`). Play production upload still pending —
      `android/fastlane/play-store-key.json` missing
- [ ] **[App]** Ship iOS App Store launch — first season on both stores
- [x] **[Backend]** Demo invites + cadence-sequence scoring committed, pushed,
      and **deployed live** on the droplet (`/v1/demo/invites` responding)
- [x] **[Backend]** HTTPS already live via Caddy (`outcallbackend.xyz` → 200).
      Added `restart: unless-stopped` + a 5-min health watchdog cron on the
      droplet. Still open: external UptimeRobot monitor (needs account signup)
- [x] **[App]** Analytics instrumentation — wired all 8 dead events:
      screen_view per tab, recording_started, daily_challenge started/completed,
      achievement_unlocked, leaderboard_viewed, share_score, library_browse,
      calibration_performed (`a7bfa1d`)
- [ ] **[App]** Decide the web story for `bioacoustic_scorer_web.dart`
      (currently returns empty) — real web scoring or explicit native-only gating
- [ ] **[Sec]** Rotate the Google OAuth desktop client secret — it briefly
      lived in source (unpushed); now loaded from git-ignored
      `assets/secrets/oauth_desktop.json`

**Exit criteria:** iOS live, v3.3.0 on Play, HTTPS + alerts on, analytics
flowing, zero uncommitted feature work on `main`/`master`.

---

## Phase 1 — Field Mode: Real-Time Hearing (October – December 2026)

*The flagship bet. Move scoring from "record → wait → read" to "the app is
listening with you."*

> **Feasibility spike (Sept 30, prod hardware):** fingerprint match alone is
> **0.12–0.23s** — far under budget. The real cost is audio *ingestion*:
> `librosa.load` on an 11s MP3 takes ~3s; on a 3.9s clip it's 0.16s. Full
> quick-mode swarm: 0.83s on a short clip. **Verdict: <2s live species ID is
> feasible** on 2–4s rolling windows fed as raw PCM (skip file decode). The
> SpeechGuardian f0 path (~1s on 11s audio) needs window bounding for live
> scoring. Weak match scores (elk bugle → "deer fawn", 53) confirm the
> fingerprint-DB coverage work below is load-bearing.

- [ ] **[App]** **Live listen mode** — continuous ambient analysis on-device:
      rolling buffer → local fingerprint match → "that's a hen yelp, 80m
      northeast of typical range" in <2s. BirdNET TFLite plumbing exists;
      this is an engineering push, not a research project
- [ ] **[App + Backend]** **"Answer this call" recommendations** — identified
      vocalization → species KB → suggest the correct response call, then
      score the user's answer in real time
- [ ] **[App]** **Live coaching overlay** — pitch/timbre feedback *during* the
      call (<500ms loop) using the on-device 13-dimension pipeline, not the
      network round-trip
- [ ] **[Backend]** Sub-second scoring path — dedicated fast lane in the swarm
      (DSP + Fingerprint only) for live mode; full 7-agent analysis stays for
      deep reviews
- [ ] **[Backend]** DTW contour matching for structured calls — elk bugle
      biphonation, turkey yelp sequences, coyote howl FM (KB already flags
      this gap)
- [ ] **[App]** Field HUD: minimal, dark, glanceable UI — hunters won't stare
      at screens in the stand

**Exit criteria:** Live species ID demoable on real field audio for ≥10 core
species; coaching feedback lands while the call is still in progress; p95
live-mode latency < 2s end-to-end.

---

## Phase 2 — Coach Buck Becomes a Guide (November 2026 – January 2027)

*From "feedback text under a score" to a coach with memory, ears, and a voice.*

- [ ] **[Backend + App]** **Coach Buck speaks** — TTS voice output tuned to the
      40-year-guide persona; voice-first coaching loop (hear critique → retry
      → hear confirmation) usable hands-free in the field
- [ ] **[Backend]** **Session memory** — persistent coaching history per user;
      Buck references past sessions ("your gobble air pressure has been
      climbing for two weeks"). QA Guardian stays on all output
- [ ] **[Backend]** **Personal baseline engine** — finish the user-calibration
      work hinted at in v1.5.3: per-user mouth/air fingerprints so scoring
      adapts to *their* instrument (the call), not just the species ideal
- [ ] **[App]** **Adaptive practice programs** — Buck builds multi-week drill
      plans from score history; weak on cadence → cadence drills tomorrow
- [ ] **[Backend + App]** **Field conditions advisor** — weather + solunar +
      season phase + species KB → "use a soft tree yelp this morning"
      (weather feature exists today; this makes it prescriptive)

**Exit criteria:** Voice coaching live; Buck demonstrably recalls prior
sessions; practice programs auto-generate from score history.

---

## Phase 3 — The Data Moat (December 2026 – February 2027)

*Every call a user submits trains the machine. Build the corpus competitors
can't replicate.*

- [ ] **[Backend]** **Custom call classifier** — fine-tune beyond generic
      BirdNET: train on hunting-call domain audio (mouth calls vs. wild calls
      vs. everything else). This is the moat; bird classifiers are a commodity
- [ ] **[App + Backend]** **Crowdsourced fingerprint pipeline** — users submit
      "verified wild call" recordings (with location/context metadata) →
      swarm validates → enters fingerprint DB. Gamify it: contributors earn
      badges/premium time
- [ ] **[Backend]** Consent-based training data collection — explicit opt-in,
      anonymized, documented; every scored call improves the corpus
- [ ] **[Backend]** Fingerprint DB 60+ → **500+ signatures** via combination of
      procurement (`tools/` already has audio pipeline scripts), UGC, and
      model-assisted signature extraction
- [ ] **[Backend]** **Confidence transparency** — every score ships with
      explainability: which dimensions dragged it down, how reliable the
      match was, audio quality caveats. Trust is a feature.

**Exit criteria:** Custom classifier beats BirdNET baseline on a labeled
hunting-call test set checked into `tools/`; UGC submissions flowing;
≥500 signatures.

---

## Phase 4 — The Network & The Business (January – March 2027)

*Product depth is paid for by a platform and a B2B line.*

- [ ] **[App]** **Head-to-head duels** — async call-offs (same species, same
      prompt, swarm adjudicates), plus live duels if Phase 1 latency holds
- [ ] **[App]** **Season leagues** — weekly leaderboards with divisions and
      promotion/relegation; retire `mock_leaderboard_data` for good
- [ ] **[App]** **Full web app** — real scoring in browser (the web stub is
      empty today); demo invites convert to real accounts on the same surface
- [ ] **[App]** **Watch companion** — record/score from wrist, haptic feedback
      on live mode hits
- [ ] **[Backend]** **B2B scoring API** — productize the swarm: documented
      endpoints, API keys, usage tiers. First customers: call manufacturers
      ("Outcall Verified" stamp on their product audio) and outfitter apps.
      The demo-invite machinery built last month is literally the onboarding
      path for this
- [ ] **[Sentinel]** **Autonomous growth engine** — expand beyond Reddit to
      YouTube/TikTok comment scouting and forum monitoring; seasonal content
      calendar synced to hunting seasons; UGC-wild-call submission drives
      promoted by agents
- [ ] **[App]** Species expansion wave 2 — deep waterfowl (mallard variants,
      speckelebelly, diver ducks), predator pack expansion, and international
      entries (roe deer, red stag, moose) where reference audio exists

**Exit criteria:** Duels live with real adjudication; web scoring beta; ≥1
B2B pilot conversation signed via demo invite; Sentinel running
multi-platform.

---

## Phase 5 — Spring Turkey Onslaught (March 2027)

*Turkey season opens ~April — the biggest call-training moment of the year.
Everything above converges here.*

- [ ] **[App]** Turkey flagship release: cadence scoring tuned for yelp/cutting
      sequences (bioacoustic ranges already in the KB), live yelp-sequence
      coaching, turkey league season
- [ ] **[Sentinel]** Full-funnel turkey campaign: field-mode demo clips,
      league promotion, "hear what you missed this winter" reactivation
- [ ] **[Backend]** Pre-season capacity review — Cloud Run migration
      (Tier 3b) executed if winter traction warrants; live mode is the load
      multiplier
- [ ] **[App]** Returning-user reactivation: "welcome back, Buck remembers
      you — here's where you left off"

**Exit criteria:** Turkey content + field mode live ≥2 weeks before opener;
backend sized for 10x current load; reactivation campaign shipped.

---

## North Star Metrics (March 2027)

| Metric | Baseline today | Moonshot target |
|--------|---------------|-----------------|
| Live species-ID latency (p95) | n/a | < 2s |
| Deep scoring latency (p95) | 3–8s | < 3s |
| Fingerprint signatures | ~60 | 500+ |
| Scored calls in training corpus (opt-in) | 0 | 50K+ |
| Species covered | ~40 | 60+ |
| Platforms | Android | Android + iOS + Web + Watch |
| B2B pilots | 0 | ≥ 1 signed |
| Retention W4 (off-season) | unmeasured | instrument → 2x whatever it is |
| Custom classifier accuracy vs BirdNET | baseline | measurably better on hunting calls |

---

## Key Risks (be honest about these)

| Risk | Mitigation |
|------|-----------|
| Live mode murders battery in the field | Duty-cycle the rolling buffer; "field mode" session toggle, not always-on |
| UGC audio quality poisons the corpus | Swarm validation gate + human review queue; never auto-merge |
| TTS voice sounds cheap → persona breaks | Prototype early; fall back to text if voice quality isn't field-grade |
| Custom classifier needs labeled data we don't have | Phase 3 starts with building the labeled test set; UGC + procurement fill it |
| B2B distracts from consumer product | Cap B2B effort at API docs + pilot onboarding; no custom builds |
| Scope exceeds capacity | Phase 0 is non-negotiable; Phases 1–2 deliver standalone value even if 3–5 slip |

---

## Explicitly Out of Scope (still)

- Social graph / friends / DMs (duels + leagues cover competition)
- Video/photo analysis — audio is the moat
- Hardware (mic accessories) — revisit after B2B traction
- Marketplace for third-party call packs
