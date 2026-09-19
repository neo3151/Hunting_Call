---
name: health-check
description: Run Flutter analyze + tests and summarize recent changes
allowed-tools:
  - exec
  - read
  - grep
  - glob
---

Run a health check on the Hunting_Call project.

Steps:
1. Run `pwd` and `cd ~/Hunting_Call` if not already there.
2. Run `flutter analyze` and report any errors or warnings. Note if it's clean.
3. Run `flutter test` and report the results (pass/fail counts).
4. Run `git log --oneline -10` and summarize the last 10 commits in one sentence each.
5. Check `pubspec.yaml` for the current version string and report it.
6. Produce a short summary:
   - Version
   - Analyze: clean or N issues
   - Tests: N passed, N failed
   - Last commit and when
   - Any recommended actions
