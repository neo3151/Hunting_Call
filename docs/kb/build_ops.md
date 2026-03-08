# Android Build & Operations Log

## Android Release Troubleshooting
Production builds (APKs/AABs) are generated via `./scripts/build_app.sh`.
- **Firebase Config:** Valid `android/app/google-services.json` required. 
- **Gradle OOMs:** Out of Memory errors during assembly.
  - **Fix:** Update `android/gradle.properties`:
  ```properties
  org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=1G
  org.gradle.workers.max=1
  ```
- **Deadlock Cleanup:** If builds fail with timeouts or hung lock files:
  ```bash
  cd android && ./gradlew --stop
  rm -f .gradle/noVersion/buildLogic.lock
  ```

## Release Workflows
- **Upload scripts:** `upload_play.py` and `upload_apk_gdrive.py` used for Alpha/Drive uploads.
- **Tagging:** Use `vX.Y.Z` tags to trigger automated GitHub Action releases.
- **Analytics:** Post-release track conversion and performance via `AnalyticsService` events.
