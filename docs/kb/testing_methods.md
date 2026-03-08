# Testing & Quality Assurance Methodology

Maintaining the "luxury" and "premium" feel of OUTCALL requires rigorous testing, specifically targeting the complexities of cross-platform audio processing and high-concurrency Firestore interactions.

## 1. Automated Testing Stack
- **Domain Logic**: Unit tests cover core logic (`ProfanityFilter`, `SpamFilter`, `CalibrationProfile`).
- **CI Enforcement**: All tests must pass in the `quality-gate` job of the GitHub Actions pipeline before a deployment is allowed.

## 2. Manual "Stress Test" Checklist
Before major releases, a manual check is performed on real hardware.

### Recording Edge Cases
- Home/Back button behavior during active recording.
- Rapid start/stop stress (hammering the record button).
- System interruptions (phone calls, alarms) during recording.
- Storage capacity limits (graceful failure when device is full).

### Audio Playback
- Rapid play/stop toggling (10× quickly on the same track).
- Cloud audio behavior under "Airplane Mode" constraints.
- Audio lifecycle logic (ensuring background audio stops when navigating to "Home").

### Navigation & UX
- Split-screen mode and orientation rotation during analysis processing.
- "Tab hammering": Rapidly switching between Home, Library, and Record.
- Long session stability (30+ minutes of continuous UI interaction).

## 3. Firestore Backend Stress Testing
OUTCALL utilizes a custom Python stress tester (`scripts/stress_test_firestore.py`) to find backend breaking points.

### Key Metrics Tracked
- **Profile Write Latency**: Simulates concurrent users creating/updating profiles. Target P95 latency is <800ms.
- **Leaderboard Contention**: Simulates multiple users submitting scores to the same leaderboard document simultaneously to test transactional isolation.
- **Burst Reads**: Measures duration to fetch 50+ documents across multiple collections.

## 4. Release Protocol
- Any **❌ Fail** in the manual checklist is a hard blocker for production.
- Any **⚠️ Warning** requires a flagged issue and developer sign-off.
- Target is a **100% pass rate** before promoting a build from Alpha to Production.
