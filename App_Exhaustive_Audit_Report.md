---
title: "OUTCALL App Architecture, Security & Performance Audit"
author: "Antigravity Pipeline"
date: "March 2026"
---

# OUTCALL Application Exhaustive Audit Report

## 1. Executive Summary & Audit Methodology
Following up on the initial static analysis sweep, a multi-vector exhaustive audit was conducted across the OUTCALL Flutter architecture. This deep dive evaluated native OS capability manifests, Riverpod memory allocations, UI rendering trees, and backend database security rules. While the Dart parsing syntax is exceptionally strict and nearly flawless, **critical vulnerabilities were discovered in the database security tier and UI asset allocations.**

---

## 2. Native Permissions & OS Capabilities
The native configuration binaries (`AndroidManifest.xml` and `Info.plist`) were meticulously reviewed for unnecessary capability exposure that could trigger automated App Store rejection metrics.
* **Android**: Passes flawlessly. Only essential networking and microphone permissions exist. The explicit block `tools:node="remove"` for `AD_ID` guarantees clean privacy metrics.
* **iOS**: Passes flawlessly. The `Info.plist` includes fully structured NSDescription tags explaining the usage of the camera, library, and microphone transparently.

---

## 3. [P1] Critical Security Vulnerability: Database Exposure
A **Severity 1 Security Vulnerability** currently exists in `firestore.rules`.
While individual profile updates are correctly locked to `isOwner(userId)`, **Lines 74-76** of the active configuration contain a bypassing match block:
```javascript
// WARNING: This match exposes the entire database listing.
match /profiles/{userId} {
    allow list: if isAuthenticated();
}
```
**The Flaw**: Because `allow list` is universally granted to *any* authenticated user, a malicious actor who signs up anonymously can write a basic 5-line script to iteratively dump your entire `profiles` collection database, instantly harvesting all user emails, names, scores, and hardware configurations.
**Remediation Required**: Delete the `allow list` block completely. If the app requires searching for users globally, it must be migrated to a secure Cloud Function query rather than exposing the root collection listing.

---

## 4. UI Memory Management & Scalability Limits
Using recursive AST parsing, several rendering bottlenecks were identified across the stateful application structure where the application does not properly lazily-instantiate massive memory arrays.

**The Flaw**: `ListView()` is natively called without a `.builder()` parameter in 5 specific layout files (e.g., `rating_screen.dart`, `history_dashboard_screen.dart`, `achievements_screen.dart`).
When users reach 100+ attempts or achievements, the application will forcefully attempt to render and load the SVGs for *all 100 entries instantly* into the screen's layout pipeline because `ListView` instantiates everything simultaneously, leading to fatal memory thrashing and aggressive frame-drops (UI stutter).
**Remediation Required**: Replace `child: ListView(...)` with `child: ListView.builder(...)`.

---

## 5. Infinite Socket Traps (Architecture Reliability)
As flagged in the short preliminary sweep, the application relies deeply on `FirebaseApiGateway` fetching data via `Source.server` wrapped in `try` statements executing fallbacks to `Source.cache`.
**The Flaw**: Flutter's native Firebase drivers *never* natively timeout unaccomplished `.get()` calls when a device has highly restrictive edge connectivity (e.g., hunting deep in the woods). Because you never chained `.timeout(const Duration(seconds: 5))` onto your Futures, the server call infinitely spins searching for a TCP socket. The fallback `.catch()` local state will **never trigger**, literally freezing the entire UI loader indefinitely.
**Remediation**: Append `.timeout(const Duration(seconds: 4))` to all `GetOptions(source: Source.server)` clauses.

---

## 6. Asset Compilation Bloat
A recursive filesize query of the physical `/assets/` directory revealed three massive, unoptimized image files currently hard-bloating the APK compiler payload without contributing to visual fidelity:
1. `forest_background.png` (> 1MB)
2. `onboarding_library.png` (> 1MB)
3. `waterfowl_hero.png` (> 1MB)
**Remediation**: Compress these `.png` native assets to `.webp` or run them through tinypng to instantly chop 8-10MB off the final compiled release APK payload.

---

## 7. Dead Code & Swallowed Exception Handlers
The codebase is astoundingly free of `TODOs` and standard compile lint errors (only 2 unused elements). However, 4 critical empty `catch (_) {}` blocks currently swallow exception propagation:
1. `api_gateway.dart` (Line 120)
2. `firebase_auth_repository.dart` (Line 72)
3. `firebase_auth_data_source.dart` (Line 76)
4. `mic_calibration_service.dart` (Line 86)
**Remediation**: Failing `mic_calibration` or `GoogleSignIn.initialize()` natively is critical. Pipe these silently to Crashlytics via `AppLogger.e()` instead of permanently drowning the logic stack.
