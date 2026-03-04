# OUTCALL Stress Test Checklist

Walk through this on a real device before each major release. Mark items ✅ pass, ❌ fail, or ⚠️ partial.

---

## 1. Recording Edge Cases

| # | Test | Steps | Expected | Result |
|---|------|-------|----------|--------|
| R1 | Home during recording | Start recording → press home → return to app | Recording stopped, no crash | |
| R2 | Rapid start/stop | Tap record/stop 5× quickly | No crash, UI stays responsive | |
| R3 | Phone call interrupt | Start recording → have someone call you | Recording paused/stopped gracefully | |
| R4 | Max duration hit | Let recording run to auto-stop limit | Auto-stops, navigates to rating | |
| R5 | Back-to-back recordings | Complete recording → go back → immediately record again (5×) | No memory leak, all recordings work | |
| R6 | Reference + record | Play reference sound → immediately tap record | Reference stops, recording starts | |
| R7 | Double-tap record | Tap record button twice rapidly | Single recording starts, no crash | |
| R8 | Low storage | Fill device to <50MB free → try recording | Graceful error message | |

---

## 2. Audio Playback

| # | Test | Steps | Expected | Result |
|---|------|-------|----------|--------|
| A1 | Rapid play/stop | On Call Detail, tap play/stop 10× quickly | No crash, button state stays sync'd | |
| A2 | Play → navigate away | Play reference → press back immediately | Audio stops | |
| A3 | Play → home button | Play reference → press home | Audio stops (lifecycle fix) | |
| A4 | Play all calls | Go through library, play every reference call | All play without error | |
| A5 | Cloud audio (paid) | Play a paid (cloud) call on first load | Downloads and plays, spinner shown | |
| A6 | Cloud audio offline | Airplane mode → play a paid call not yet cached | Error message, no crash | |

---

## 3. Navigation & Memory

| # | Test | Steps | Expected | Result |
|---|------|-------|----------|--------|
| N1 | Tab hammering | Switch tabs rapidly 20× (Home→Library→Record→Profile) | No crash, no visual glitch | |
| N2 | Deep stack | Home → Library → Call Detail → Record → Rating → back ×5 | All screens pop correctly | |
| N3 | Paywall spam | Open Profile → Upgrade → close → repeat 10× | No crash, no memory leak | |
| N4 | Long session | Use app normally for 30+ minutes | No slowdown or crash | |
| N5 | Rotate screen | Rotate device during recording, playback, and analysis | UI rebuilds, state preserved | |
| N6 | Split screen | Open app in split-screen mode (Android) | UI adapts, no crash | |

---

## 4. Network Resilience

| # | Test | Steps | Expected | Result |
|---|------|-------|----------|--------|
| W1 | Full offline | Airplane mode → open app → navigate all tabs | App works with local data, no crash | |
| W2 | Offline recording | Airplane mode → record → analyze | Analysis may fail but shows error, doesn't crash | |
| W3 | Mid-analysis disconnect | Start analysis → toggle airplane mode | Analysis fails gracefully with retry option | |
| W4 | Offline paywall | Airplane mode → open paywall | Shows fallback prices or error, no crash | |
| W5 | Reconnect | Use offline → re-enable WiFi → submit score | Score syncs after reconnect | |
| W6 | Slow network | Use network throttling (dev options) → navigate app | Loading states shown, no timeouts without feedback | |

---

## 5. Payment Flow

| # | Test | Steps | Expected | Result |
|---|------|-------|----------|--------|
| P1 | Cancel purchase | Tap Subscribe → cancel Google Play dialog | Returns to paywall, no error | |
| P2 | Kill during purchase | Tap Subscribe → force-kill app from recents | App recovers on relaunch | |
| P3 | Restore (nothing) | Tap Restore Purchases with no prior purchases | Shows "No purchases found" message | |
| P4 | Paywall → back | Open paywall → press back button | Returns to previous screen cleanly | |
| P5 | Multiple plan switches | Toggle monthly/yearly selection rapidly | UI stays responsive, correct plan selected | |

---

## 6. Authentication

| # | Test | Steps | Expected | Result |
|---|------|-------|----------|--------|
| U1 | Sign out → sign in | Profile → Sign Out → sign back in | Profile data restored | |
| U2 | Google sign-in cancel | Tap Google Sign-In → cancel the popup | Returns to login, no crash | |
| U3 | Fresh install | Uninstall → reinstall → open | Onboarding shown, clean start | |

---

## 7. Data Integrity

| # | Test | Steps | Expected | Result |
|---|------|-------|----------|--------|
| D1 | Score persistence | Record → get score → close app → reopen | Score shows in history | |
| D2 | Streak tracking | Record on consecutive days → verify streak | Streak increments correctly | |
| D3 | Leaderboard | Get high score → check leaderboard | Score appears in correct position | |
| D4 | Achievement unlock | Trigger an achievement condition | Overlay shown, persisted in profile | |

---

## How to Run

1. Install the latest APK on a real device (not emulator)
2. Walk through each section in order
3. Document results in the Result column
4. Any ❌ = file a bug, any ⚠️ = note for follow-up
5. Target: 100% ✅ before promoting to production
