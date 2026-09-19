---
name: release
description: Bump version, tag, and push a Hunting_Call release
argument-hint: "<version> <build_number> [release_notes]"
allowed-tools:
  - exec
  - read
---

Cut a new release of the Hunting_Call Flutter app.

The user provides: `$1` = version (e.g. `1.8.3`), `$2` = build number (e.g. `38`), `$3` (optional) = release notes.

Steps:
1. Confirm the arguments are present. If missing, ask the user: "Please provide version and build number, e.g. `/release 1.8.4 39`"
2. Run `pwd` and `cd ~/Hunting_Call` if not already there.
3. Show the current version from `pubspec.yaml` and ask the user to confirm before proceeding.
4. Run: `bash scripts/release.sh $1 $2 "$3"`
5. Report what was committed and tagged.
6. Ask if the user wants to push: if yes, run `git push && git push --tags`
7. Remind the user to upload the AAB to the Play Store: `build/app/outputs/bundle/release/app-release.aab`
