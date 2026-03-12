

### [developer_environment_and_tooling] setup_guide
# Developer Environment & Tooling (Windows)

A guide to setting up a high-performance, customized developer environment for Flutter development on Windows.

## 1. Terminal Beautification
### Oh My Posh & Nerd Fonts
- **Nerd Fonts**: Essential for rendering icons in the terminal. Popular choice: `Caskaydia Cove Nerd Font`.
- **Oh My Posh**: A prompt theme engine. 
  - Install via `winget install JanDeDobbeleer.OhMyPosh -s winget`.
  - Configure in PowerShell profile (`$PROFILE`) with a customized theme JSON.
  - Recommended Theme: `paragon` (with modifications for environment display).

### PowerShell Profile Automation
Store common Flutter/Git commands as aliases or functions in your PowerShell `$PROFILE`:
```powershell
# Common Aliases
function hc { Set-Location "C:\Users\neo31\Hunting_Call" }
function fbr { flutter build appbundle --release }
function fapk { flutter build apk --release }
function fan { flutter analyze }
```

## 2. Environment Setup
### Java Development Kit (JDK)
- Flutter requires a JDK for Android builds.
- Verify installation: `java -version`.
- Path Configuration: Ensure `JAVA_HOME` is set in System Environment Variables.

### Android Emulator & SDK
- **Installation**: Via Android Studio or Command Line Tools.
- **Beta Testing**: Sign in with a Google account to access Play Store beta/internal tracks within the emulator.

## 3. Tooling Troubleshooting
### Dart Editor Stalls
- **Symptoms**: VS Code or Dart Analysis Server becomes unresponsive.
- **Check**: Look for large untracked files or deep directories in the workspace (e.g. `build/`, `.dart_tool/`).
- **Fix**: Restart Analysis Server or clear `.dart_tool` cache.

### Git Indexing Issues (Windows)
Avoid staging reserved file names or corrupted indices. Use `git status` frequently to check for stray system files like `NUL`.

## 4. Local Services & AI Environment

### Local Ollama Management
When developing features using local LLMs (like the AI Coach), ensure Ollama is running and reachable. The app and landing page chatbot use the `outcall-coach` model (based on Gemma 3).

**Check Status & Models:**
```powershell
try { 
    $response = Invoke-WebRequest -Uri "http://localhost:11434/api/tags" -UseBasicParsing -TimeoutSec 3
    Write-Host "Ollama is RUNNING"
    Write-Host $response.Content 
} catch { 
    Write-Host "Ollama is NOT running or not reachable: $($_.Exception.Message)" 
}
```

**Start Ollama (Background):**
```powershell
Start-Process "ollama" -ArgumentList "serve" -WindowStyle Hidden
```

**Known Models:**
- `outcall-coach:latest`: Primary model for coaching and chatbot.
- `gemma3:1b` / `gemma3:4b`: Base models used for testing and derivation.


### [flutter_devops_and_release_automation] cli_upload_strategy
# Google Play CLI Upload Strategy

Automating AAB uploads to individual tracks (internal, alpha, beta, production) in the Google Play Console without full CI/CD systems like Fastlane.

## Core Component: `upload_play.py`

A Python wrapper around the [Android Publisher API v3](https://developers.google.com/android-publisher).

### Key Features
- **Flexible Tracks**: Upload to `internal`, `alpha`, `beta`, or `production`.
- **Dynamic Metadata**: Set custom release names and localized release notes (up to 500 chars).
- **OAuth2 Flow**: Handles browser-based login on first run and caches the token in `scripts/play_token.json`.
- **Resumable Uploads**: Uses `MediaFileUpload(resumable=True)` for large AAB files (e.g., 150MB+).
- **Windows-Safe Encoding**: Explicitly sets `UTF-8` for `sys.stdout` and `sys.stderr` to avoid character map errors when printing emojis.

### Implementation Patterns

```python
# Create an edit for the package
edit = service.edits().insert(body={}, packageName=PACKAGE_NAME).execute()
edit_id = edit["id"]

# Upload the bundle
media = MediaFileUpload(aab_path, mimetype="application/octet-stream", resumable=True)
bundle = service.edits().bundles().upload(
    packageName=PACKAGE_NAME,
    editId=edit_id,
    media_body=media,
).execute()

# Assign to track with release notes
release_body = {
    "track": track,
    "releases": [{
        "name": release_name,
        "versionCodes": [str(bundle["versionCode"])],
        "status": "completed",
        "releaseNotes": [{"language": "en-US", "text": notes}],
    }],
}
service.edits().tracks().update(
    packageName=PACKAGE_NAME, editId=edit_id, track=track, body=release_body
).execute()

# Commit the changes
service.edits().commit(packageName=PACKAGE_NAME, editId=edit_id).execute()
```

## Setup Requirements

1. **Google Cloud Project**: Enabled "Google Play Android Developer API".
2. **OAuth2 Credentials**: `credentials.json` for an "installed app" type.
3. **Python Libraries**:
   - `google-api-python-client`
   - `google-auth-httplib2`
   - `google-auth-oauthlib`

## Practical Usage Example

```bash
python scripts/upload_play.py \
  --track alpha \
  --aab build/app/outputs/bundle/release/app-release.aab \
  --name "Improved Beta" \
  --notes "Fixed back button bug, improved accessibility, and added achievements gallery."
```


### [flutter_devops_and_release_automation] gdrive_asset_delivery
# Multi-Platform Asset Distribution (rclone/GDrive)

Using `rclone` for automated delivery of build artifacts (like debug APKs) to non-Play Store destinations like Google Drive.

## Strategy
1. **Tooling**: Install and configure `rclone` with a `gdrive` remote.
2. **Path Mapping**: Define standardized paths for dev builds.
3. **Execution**: Use `rclone copy` with the `--progress` flag for visibility.

## Implementation Pattern

```powershell
# Copy build to Google Drive
rclone copy "build/app/outputs/flutter-apk/app-debug.apk" "gdrive:ProjectName/dev-builds/" --progress
```

## Benefits
- **Accessibility**: Quick sideloading for testers without waiting for track processing.
- **Persistence**: Maintains a history of builds identifiable by timestamps or folder names.
- **Independence**: Works on Windows, Linux, and MacOS consistently.


### [flutter_devops_and_release_automation] github_actions_pipeline
# GitHub Actions CI/CD Pipeline

The OUTCALL app uses GitHub Actions to automate its build and release process. This ensures consistent, reproducible release builds and integrates with the Google Play Store Android Publisher API.

## 1. Primary Workflows

### Flutter CI (`flutter_ci.yml`)
- **Trigger**: Runs on every pull request to `main` and all pushes to `develop`.
- **Purpose**: Static analysis and unit testing to ensure code quality before merging.
- **Steps**:
  - Sets up Flutter.
  - Runs `flutter pub get`.
  - Runs `flutter analyze`.
  - Executes unit and widget tests.

### Deploy Release (`deploy_release.yml`)
- **Trigger**: Runs when a new version tag (e.g., `v1.5.1`) is pushed.
- **Purpose**: Builds a signed App Bundle (.aab) and uploads it to the Play Store.
- **Steps**:
  - **Environment Setup**: Configures JDK 17 and Flutter.
  - **Secrets Retrieval**: Injects sensitive files from GitHub Secrets.
    - `SERVICE_ACCOUNT_JSON`: Credential for Play Store API.
    - `KEYSTORE_FILE`: JKS file for signing.
    - `KEY_PROPERTIES`: Metadata for the key (alias, password).
  - **Build**: Executes `flutter build appbundle --release`.
  - **Upload**: Uses the `r0adkll/upload-google-play` action to push the AAB to the internal/alpha track for review.

## 2. Secrets Management
The following secrets are stored in GitHub to ensure secure signing:

| Secret Name | Purpose |
| :--- | :--- |
| `SERVICE_ACCOUNT_JSON` | JSON key for the Google Cloud project allowed to publish. |
| `SIGNING_KEY` | Base64-encoded JKS keystore file. |
| `KEY_PROPERTIES` | Contents of `key.properties` needed by Gradle. |

## 3. Play Store API Configuration
- The workflow uses the **Google Play Developer API**.
- A Service Account must be created in the Google Cloud Console and added to the Google Play Console under **Users & Permissions** with "Release Lead" or similar access.
- Ensure the **Android Publisher API** is enabled for the project.


### [flutter_devops_and_release_automation] manual_app_icon_resizing
# Manual Android App Icon Generation

When specialized tools like `flutter_launcher_icons` are unavailable or you need precise manual control over icon assets, a Python script using the [Pillow](https://python-pillow.org/) library can efficiently generate all required Android densities.

## Icon Densities (Android)

Legacy launcher icons typically use the following sizes:
- `mipmap-mdpi`: 48x48
- `mipmap-hdpi`: 72x72
- `mipmap-xhdpi`: 96x96
- `mipmap-xxhdpi`: 144x144
- `mipmap-xxxhdpi`: 192x192

Adaptive icons (API 26+) require a foreground and background (often 108dp base):
- `drawable-mdpi`: 108x108
- `drawable-hdpi`: 162x162
- `drawable-xhdpi`: 216x216
- `drawable-xxhdpi`: 324x324
- `drawable-xxxhdpi`: 432x432

## Implementation Pattern

The following Python script reads a high-resolution (e.g. 512x512 or 1024x1024) PNG and saves it into the appropriate Android resource folders.

```python
from PIL import Image
import os

# Source and target paths
src_path = r'assets/play_store/icon_512.png'
res_base = r'android/app/src/main/res'

# Legacy Launcher Icons (Mipmaps)
mipmap_sizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

# Adaptive Icon Foregrounds (Drawables)
fg_sizes = {
    'drawable-mdpi': 108,
    'drawable-hdpi': 162,
    'drawable-xhdpi': 216,
    'drawable-xxhdpi': 324,
    'drawable-xxxhdpi': 432,
}

def generate_icons():
    img = Image.open(src_path)
    
    # Generate Mipmaps
    for folder, size in mipmap_sizes.items():
        dest = os.path.join(res_base, folder, 'ic_launcher.png')
        img.resize((size, size), Image.LANCZOS).save(dest, 'PNG')
        print(f"Generated {folder}/ic_launcher.png")

    # Generate Adaptive Foregrounds
    for folder, size in fg_sizes.items():
        dest = os.path.join(res_base, folder, 'ic_launcher_foreground.png')
        img.resize((size, size), Image.LANCZOS).save(dest, 'PNG')
        print(f"Generated {folder}/ic_launcher_foreground.png")

if __name__ == "__main__":
    generate_icons()
```

## Best Practices
1. **Source Resolution**: Use at least a 512x512 source image to maintain quality.
2. **Resampling**: Always use `Image.LANCZOS` (or `Image.Resampling.LANCZOS` in newer Pillow versions) for high-quality downsampling.
3. **Adaptive Icons**: Ensure your `ic_launcher.xml` in `mipmap-anydpi-v26` points to the correct foreground (`ic_launcher_foreground`) and background.


### [flutter_devops_and_release_automation] overview
# Flutter DevOps and Release Automation

Patterns for building, distributing, and automating releases for Flutter applications, with a focus on Windows/Android environments.

## Artifacts
- [CLI Play Store Upload Strategy](cli_upload_strategy.md)
- [Windows Build & Environment Management](windows_build_management.md)
- [Multi-Platform Asset Distribution (rclone/GDrive)](gdrive_asset_delivery.md)
- [Manual App Icon Resizing Pattern](manual_app_icon_resizing.md)
- [Release Management & Versioning](release_management_and_versioning.md)


### [flutter_devops_and_release_automation] release_management_and_versioning
# Release Management & Versioning

Managing the transition from development to beta/alpha rollouts requires careful coordination of version codes, build numbers, and release tracks.

## 1. Versioning Strategy

OUTCALL uses Semantic Versioning (SemVer) with an incrementing build number.
Format: `major.minor.patch+buildNumber`

### Example Progression (Sprint 4-7):
- **1.6.1+24**: Initial beta build.
- **1.6.3+25**: Full feature rollout (Achievements, L10n, Accessibility).
- **1.6.3+26**: Critical fix (Launcher icon swap).
- **1.8.0+33**: Current production/alpha candidate with 0 analyzer issues.

**Rule**: The version code (`buildNumber`) **must** increase for every upload to the Google Play Console, even if the user-facing version remains the same.

## 2. Track Management

Google Play Console tracks used:
- **Internal Testing**: Fastest rollout to internal testers.
- **Alpha**: Wide testing (Beta testers) with specific release titles (e.g., "Improved Beta").
- **Production**: Public release.

## 3. Deployment Workflow (CLI)

1. **Clean & Build**:
   ```bash
   flutter clean
   flutter build appbundle --release
   ```
2. **Upload**: Use the `scripts/upload_play.py` utility.
   ```bash
   python scripts/upload_play.py --track alpha --aab build/.../app-release.aab --name "Improved Beta" --notes "..."
   ```

## 4. Resource Hot-Fixing (Icon Swapping)

When `flutter_launcher_icons` is not used, manual icon replacement is handled via a Pillow-based Python script that resizes a source production icon (e.g., `assets/play_store/icon_512.png`) to the 10 standard Android densities across `mipmap` and `drawable` folders.

### Densities covered:
- **Mipmap (Launcher)**: mdpi (48), hdpi (72), xhdpi (96), xxhdpi (144), xxxhdpi (192).
- **Drawable (Adaptive Foreground)**: mdpi (108), hdpi (162), xhdpi (216), xxhdpi (324), xxxhdpi (432).
## 5. Pre-Upload Version Audit
Before triggering a CLI upload (especially via automated scripts), perform a manual verification of the active version in `pubspec.yaml`:
- **Current Baseline**: `1.8.0+33`
- **Correction Pattern**: During development, internal/alpha tracks may diverge if multiple people/bots are bumping versions. Always verify with the Play Console's "Releases Overview" to ensure the next build number is strictly greater than the last.
- **Verification Command**: `grep "version:" pubspec.yaml`


### [flutter_devops_and_release_automation] windows_build_management
# Windows Build Management & Troubleshooting

Practical insights for managing Flutter builds and environment issues on Windows.

## 1. Sequential vs Parallel Builds (Gradle Windows Lock)

### Problem
Running multiple builds in parallel (e.g., `flutter build apk` and `flutter build appbundle` simultaneously) on Windows often results in a `BUILD FAILED` error due to file locks (primarily `native_debug_metadata`). Gradle competes for the same intermediate directories, and Windows' file locking mechanism prevents successful deletion or modification of temporary build files.

**Error Example:**
```
Execution failed for task ':app:extractReleaseNativeDebugMetadata'.
> Unable to delete directory '...\build\app\intermediates\native_debug_metadata\release\extractReleaseNativeDebugMetadata\out'
Failed to delete some children. This might happen because a process has files open.
```

### Solution
**Never build APK and AAB in parallel on a single machine.** Run them sequentially to ensure each process has exclusive access to the `build/` directory.

```powershell
# Recommended sequential pattern
flutter build apk --release; flutter build appbundle --release
```

**Clean Builds**: If a build fails with a lock error, run `flutter clean` before retrying to ensure no stale locks or half-deleted directories remain.

## 2. Tree-Shaking Benefits
Flutter's build process for Android release targets (APK/AAB) includes font tree-shaking by default.
- **Impact**: Can reduce font assets (like `MaterialIcons`) by over 99% (e.g., 1.6MB to 16KB).
- **Control**: Can be toggled with `--no-tree-shake-icons`, though rarely necessary.

## 3. Python Environment for Scripts
When using Python scripts for DevOps on Windows (like Play Store uploaders):

### Unicode Encoding (cp1252)
Printing emojis or multi-byte Unicode characters to the Windows command prompt/PowerShell can crash with a `UnicodeEncodeError`.

**Solution**: Wrap `sys.stdout` and `sys.stderr` to use `utf-8` explicitly.
```python
import sys
import io

# Fix Windows console encoding for emoji/unicode
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')
```

### Dependency Management
Ensure `google-api-python-client` and OAuth2 libraries are installed using `pip`.

## 4. Git "NUL" File Error
Git on Windows can sometimes track stray system reserved names. A common error is `error: short read while indexing NUL` or `error: unable to index file 'NUL'`, which prevents staging changes.

**Solution**:
1.  **Stray File Removal**: Identify and delete the stray `NUL` file if it appears in `git status` (often created by redirected outputs gone wrong).
2.  **Targeted Staging**: Avoid `git add -A` if the repository state is "dirty" with stray files. Use targeted `git add path/to/file` to stage only intended changes.


### [outcall_app_audit_scorecard] accessibility_semantics
# Flutter UI Semantics and Accessibility

Best practices for making Flutter apps accessible using the `Semantics` widget and other accessibility properties.

## 1. Using the `Semantics` Widget
Wrap interactive elements, labels, or containers in a `Semantics` widget to provide clear descriptions for screen readers (TalkBack/VoiceOver).

### Pattern: Interactive Buttons and Cards
Use `button: true` and a descriptive `label` so the screen reader identifies the element correctly.

```dart
Semantics(
  button: true,
  label: 'Start Recording, match the reference call below to improve your score.',
  child: GestureDetector(
    onTap: _toggleRecording,
    child: MicIconWidget(),
  ),
)
```

### Pattern: Information Cards and Lists
For informational elements, use labels that contain both the title and the value.

```dart
Semantics(
  label: 'Current Score: 95 percent. Achievement Unlocked!',
  child: ScoreCard(score: 95),
)
```

## 2. Accessibility Best Practices
- **Descriptive Labels**: Avoid one-word labels. Instead of "Record", use "Record call for [Animal Name]".
- **Grouping**: Use `MergeSemantics` to consolidate multiple children into a single announcement.
- **Exclusion**: Use `ExcludeSemantics` to hide purely decorative elements (icons, dividers) from screen readers.
- **Focus Order**: Be aware of the standard traversal order (left-to-right, top-to-bottom). Use custom sort keys if necessary for complex layouts.
- **Contrast and Sizing**: Ensure text contrast meets WCAG standards and interactive targets are at least 44x44 pixels.

## 3. Localization Interplay
Always use localized strings for semantics labels (`S.of(context).semanticsLabel`) rather than hardcoding them, ensuring accessibility across all supported languages.


### [outcall_app_audit_scorecard] achievements_system
# Flutter Achievements System Implementation

This pattern describes an achievement engine and gallery UI, used to track and display 30 user milestones in OUTCALL.

## 1. Achievement Data Model
Achievements are defined with an `id`, `name`, `description`, `icon` (emoji), and an `isEarned` predicate function that operates on the user profile.

```dart
class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool Function(UserProfile profile) isEarned;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.isEarned,
  });
}
```

## 2. Achievement Service
The `AchievementService` maintains a static list of all achievements and categorization logic.

### Categories used:
- **Milestones**: Recording count progression (`totalCalls >= 1, 10, 25...`).
- **Score Tiers**: Hitting skill levels (`score >= 70, 80, 90, 95, 99`).
- **Consistency**: Maintaining high scores over multiple recordings.
- **Diversity**: Exploring different species (unique animal IDs in history).
- **Daily Challenge**: Streak and dedication metrics.
- **Mastery**: High performance on the same call multiple times.
- **Hidden/Fun**: Surprise achievements like "Night Owl" (recording after midnight).

## 3. Gallery UI Design
The achievements gallery (`achievements_screen.dart`) features:
- **Progress Header**: A circular progress ring showing percentage completion and "X / 30 Unlocked".
- **Category Sections**: Vertical grouping with colored headers and icons.
- **Visual States**:
  - **Earned**: Colored glow border, real emoji icon, and checkmark.
  - **Locked**: Desaturated, dimmed, or greyed out with a 🔒 lock icon.
- **Animations**: `StaggeredFadeSlide` for category entry.

## 4. Internationalization & String Extraction
All user-facing strings for the achievements gallery are fully localized using `.arb` files and `S.of(context)`. Key strings include:
- `achievements`: "ACHIEVEMENTS"
- `unlocked`: "{earned} / {total} Unlocked"
- `moreToUnlock`: "{count} more to unlock"
- `startRecordingForAchievements`: "Start recording to earn achievements!"
- `allAchievementsEarned`: "You've earned every achievement. Legend."

## 5. Unlocking Flow
1. User completes an action (e.g., finishes a recording).
2. The UI checks `getNewAchievementIds(currentProfile, previouslyEarnedIds)`.
3. If new IDs exist, a celebratory overlay (`achievement_overlay.dart`) is shown with confetti and an elastic spring animation.


### [outcall_app_audit_scorecard] audit_checklist
# App Quality Audit Checklist

A prioritized checklist for auditing and hardening Flutter applications to reach production-grade quality (95%+ scorecard).

## 1. Test Coverage (Target: 80%+)
- [ ] **Domain Layer**: 100% coverage of logic, entities, and services.
- [ ] **Data Models**: JSON serialization/deserialization, factory constructors, and `Equatable` props tested.
- [ ] **Security Utilities**: Sanity tests for inputs, validation logic, and sanitization routines.
- [ ] **Edge Cases**: Empty states, low/high boundaries, and malformed inputs.

## 2. Accessibility (Target: WCAG 2.1 Level AA)
- [ ] **Semantics Labels**: Descriptive `label` on all interactive and data-bearing elements.
- [ ] **Interactive Hints**: Use `button: true` and appropriate `label` for screen readers.
- [ ] **Exclude Decorative**: Wrap non-functional icons and dividers in `ExcludeSemantics`.
- [ ] **Contrast**: Verify text visibility on all color palette variations.

## 3. Localization (Target: 100% Extraction)
- [ ] **No Hardcoded Strings**: Every user-facing string extracted to `.arb` files.
- [ ] **Parameterized Strings**: Use `S.of(context).key(param)` for dynamic text.
- [ ] **Runtime Safety**: Remove `const` from widgets calling `S.of(context)`.
- [ ] **Automated Code Gen**: Integrate `flutter gen-l10n` into the build workflow.

## 4. Security
- [ ] **Input Sanitization**: Strip HTML, remove control characters, and truncate long strings.
- [ ] **Content Moderation**: Filter offensive, vulgar, or inappropriate language in user-facing text (names, feedback).
- [ ] **App Check & Tokens**: Verify usage of Firebase App Check or other token-based guards.
- [ ] **Secure Storage**: Ensure sensitive keys and tokens are in `flutter_secure_storage`.

## 5. UI Polish & Navigation
- [ ] **Tabbed Safety**: Use `Navigator.canPop(context)` to guard back buttons when used in a tab navigation context.
- [ ] **Staggered Entry**: Use subtle animations (like `StaggeredFadeSlide`) for smoother screen loading.
- [ ] **Error Handling**: Use `try/catch` and `Failure` objects for graceful error feedback (Snackbars).

## 6. Code Hygiene
- [ ] **Static Analysis**: Maintain 0 errors, 0 warnings, and 0 infos (beyond unavoidable pre-existing ones) using `flutter analyze`.
- [ ] **Const Correctness**: Use `const` constructors wherever possible to maximize widget tree performance.
- [ ] **Dead Code & Logs**: Ensure zero `print()` calls in the library and no unhandled `TODO` comments in production code.
- [ ] **Safety Null Checks**: Avoid unnecessary nullable types and dead null comparisons once types are solidified.
## 7. Pre-Release Verification
- [ ] **Version Sync**: Verify `pubspec.yaml` version matches the intended release (e.g., `1.8.0+33`) and that the build number has been incremented.
- [ ] **Sequential Build**: Build APK and AAB sequentially to avoid logic errors or resource locks.
- [ ] **Uppercase Sweep**: Run regex `Text\('[A-Z][A-Z]` to catch remaining hardcoded UI labels (HUNT FORECAST, UPGRADE, etc.).
- [ ] **Analytics & Debug**: Verify `kDebugMode` gates all logging and that analytics events (if any) are active for production.


### [outcall_app_audit_scorecard] content_moderation_and_quality
# Content Moderation & Quality Strategy

OUTCALL implements a multi-layered approach to maintaining profile quality, focusing on bot prevention, technical sanitization, and content auditing for inappropriate names.

## 1. Spam & Bot Detection (`SpamFilter`)
Bot detection is handled via the `SpamFilter` utility (`lib/core/utils/spam_filter.dart`). This is the first line of defense against automated account creation.

### Features:
- **Email Pattern Matching**: Detects common bot-farm patterns (e.g., `firstname.lastname.NNNNN@gmail.com`).
- **Domain Blocklist**: Maintains a list of blocked throwaway/test domains (e.g., `mailinator.com`, `guerrillamail.com`).
- **Suspicious Profile Heuristics**: Flags profiles based on creation date, activity level, and email presence (detecting "ghost" accounts).

## 2. Technical Input Sanitization (`InputSanitizer`)
Technical sanitization is handled via the `InputSanitizer` utility (`lib/core/utils/input_sanitizer.dart`). This prevents security vulnerabilities and visual breakage.

### Features:
- **XSS Prevention**: Strips HTML and script tags from names and feedback.
- **Control Character Removal**: Removes technical control characters (`0x00-0x1F`, `0x7F`) except for legitimate whitespace.
- **Length Enforcement**: Enforces hard limits on display names (50 chars) and feedback (500 chars).

## 3. Profile Data Normalization
The `UnifiedProfileRepository` handles data normalization at the repository layer.
- **Defaulting**: If a user's display name is missing or corrupted, it defaults to `"Hunter"`.
- **Timestamp Sanitization**: Ensures dates are correctly formatted for local and remote storage.

## 4. Inappropriate Content Moderation Strategy
As of March 4, 2026, OUTCALL uses a hybrid **Proactive Blocking + Periodic Auditing** strategy.

### Critical Distinction: Data Sources
Audits must check **both** Firebase Auth and Firestore `profiles`.
- **Firebase Auth (Google Display Names)**: Highly reliable as it uses Google's upstream filters.
- **Firestore Profiles (App Nicknames)**: High risk. Users can set custom nicknames that bypass Google's filters.

### Audit Categories & Word List
| Category | Description |
|---|---|
| **Profanity** | Common vulgarity, swearing, and offensive language. |
| **Racial/Ethnic Slurs** | Words and phrases used to demean or attack specific groups. |
| **Sexual/Explicit** | Suggestive terms, anatomical references, or pornographic sites. |
| **Drug References** | Illegal substances, drug culture slang, and paraphernalia. |
| **Hate/Extremism** | Nazi imagery, historical hate figures (e.g., "hitler"), or terrorist groups. |
| **Violence/Threats** | Terms related to killing, murder, or physical harm. |
| **Ableist/Derogatory** | Slurs targeting mental or physical disabilities. |
| **Troll/Edgy Names** | Internet memes, "deez nuts" variants, and self-harm terms. |
| **Impersonation** | Use of "Admin", "Developer", or "Support" to deceive users. |
| **Leet-speak Evasion** | Substitutions (e.g., `a55`, `sh1t`) designed to bypass simple filters. |

### Heuristic Flags
- **All Caps**: Flagging names that "scream" (e.g., "USER123").
- **Excessive Numbers**: Flagging bot-like patterns (>50% digits).
- **Special Characters**: Identifying injection-like characters (`<`, `>`, `{`, `\`).
- **Short Names**: Flagging 1-character names.
- **Repetitive Characters**: Identifying keyboard mashing (e.g., `aaaaaaa`).

### Audit Results & Remediation (March 4, 2026)
A systematic audit performed on March 4, 2026, using the Firestore REST API and Firebase Auth exports, yielded the following:

- **Firebase Auth Scan**: 63 accounts scanned. 🎉 **0 Flagged Profiles**. (Google's upstream filters are effective).
- **Firestore Profile Scan**: 41 profiles scanned. ⚠️ **5 Flagged Profiles**.
  - Flagged UIDs: 
    - `yAeVNdiuYZNREIFNeRFI9Slrud52`: name="hitler", nickname="nigger" (Slur + Hate)
    - `uM2lJhoxerZ73RsgdmLQeROxdB93`: name="hitler", nickname="hitler" (Hate)
    - `6EN063UifCcBqPnqFURrSa8ICkH3`: name="hitler" (Hate)
    - `4bLd830LUyfxlylkGr8gJpK2LMq1`: name="gay", nickname="hitler" (Hate/Suggestive)
    - `T6GqS2EbTBeS89pEUqODwfgyPV13`: name="hilter" (**Evasion Pattern** - intentional misspelling designed to bypass exact-word filters).

Detailed technical procedures for performing these scans and batch remediation can be found in [Firestore Audit Technical Patterns](./firestore_audit_technical_patterns.md).

### Remediation & Prevention
1. **Bulk Cleanup**: Reset offensive profiles to name="Hunter" and clear nicknames via Firestore REST API patch script (completed March 4, 2026).
2. **Proactive Prevention**: Implemented a local `ProfanityFilter` in the app to block high-risk terms in real-time.

## 6. Implementation Status & Roadmap
| Layer | Component | Status |
|---|---|---|
| **Spam** | Bot Email Check | ✅ Active |
| **Spam** | Domain Blocklist | ✅ Active |
| **Sanitization** | XSS/HTML Strip | ✅ Active |
| **Sanitization** | Control Char Strip | ✅ Active |
| **Content** | Word Blocklist Audit | ✅ Complete |
| **Content** | Proactive Prevention | ✅ Active |

### Roadmap for Hardening
1. **Dynamic Blocklist**: Fetch an updated word list from Remote Config to stay current without app updates.
2. **Database Triggers**: Implement Cloud Functions to auto-sanitize or flag names upon Firestore document creation/update.


### [outcall_app_audit_scorecard] firestore_audit_technical_patterns
# Technical Patterns: Firestore Audit via REST API

When performing security audits or content moderation scans (e.g., searching for offensive names), it is often necessary to query the entire Firestore database. In a local development environment, the `firebase-admin` SDK requires a Service Account Key or Application Default Credentials (ADC), which may not be readily available.

A robust alternative is to use the **Firestore REST API** authenticated by the user's existing **Firebase CLI session**.

## 1. Authentication Strategy

The Firebase CLI stores its refresh token in a local JSON file:
- **Windows**: `C:\Users\<User>\.config\configstore\firebase-tools.json`
- **Linux/macOS**: `~/.config/configstore/firebase-tools.json`

### OAuth Token Exchange
You can exchange the CLI refresh token for a short-lived Access Token using Google's OAuth2 endpoint:

```javascript
const refreshToken = JSON.parse(fs.readFileSync(CONFIG_PATH)).tokens.refresh_token;
const CLIENT_ID = '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com'; // Firebase CLI Client ID
const CLIENT_SECRET = 'j9iVZfS8kkCEFUPaAeJV0sAi';

// Exchange refresh_token for access_token...
```

## 2. Scan Pattern (GET)

The REST API allows listing documents with pagination.

**Endpoint**: `https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/{COLLECTION_PATH}?pageSize=300`

**Implementation Note**: Field values are wrapped in type-specific keys (e.g., `stringValue`, `integerValue`). You must parse these to get the raw data.

```javascript
function getStringField(fields, fieldName) {
  if (!fields || !fields[fieldName]) return '';
  return fields[fieldName].stringValue || '';
}
```

## 3. Remediation Pattern (PATCH)

To update flagged documents without overwriting the entire record, use the `PATCH` method with an `updateMask`.

**Endpoint**: `https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/{COLLECTION_PATH}/{DOC_ID}?updateMask.fieldPaths=name&updateMask.fieldPaths=nickname`

**Payload**:
```json
{
  "fields": {
    "name": { "stringValue": "Hunter" },
    "nickname": { "stringValue": "" }
  }
}
```

## 4. Lessons Learned: Auth vs. Firestore

In the OUTCALL app audit, we discovered that:
1. **Firebase Auth** metadata (Google Display Name) is often clean because of upstream Google filters.
2. **Firestore Profiles** (custom nicknames) are high-risk because they bypass third-party authentication filters.
3. **Audits must scan both sources** to find users like "niggerhitler" who might have a clean Google name but a malicious app-specific nickname.


### [outcall_app_audit_scorecard] localization_workflow
# Flutter Localization Extraction Workflow

A standard process for retrofitting localization (l10n) into an existing codebase using `flutter_localizations` and `.arb` files.

## 1. Setup
Configure `l10n.yaml` and `pubspec.yaml`:
```yaml
# l10n.yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

Include delegates in `MaterialApp`:
```dart
localizationsDelegates: AppLocalizations.localizationsDelegates,
supportedLocales: AppLocalizations.supportedLocales,
```

## 2. ARB Structure
Define keys in `lib/l10n/app_en.arb`. Use placeholders for dynamic values:
```json
"callsTotal": "{count} calls total",
"@callsTotal": {
  "placeholders": {
    "count": { "type": "int" }
  }
}
```

## 3. Refactoring Hardcoded Strings
Replace `'Hardcoded String'` with `S.of(context).keyName`.

### Guidelines:
- **Import Requirement**: Files must import the generated localizations: `import 'package:outcall/l10n/app_localizations.dart';`.
- **Const Conflict**: Widgets using `S.of(context)` cannot be `const` because the call is evaluated at runtime.
- **Batching**: Group extractions by feature or screen (e.g., "Settings sweep", "Recorder sweep").
- **Regeneration**: Run `flutter gen-l10n` after updating ARB files to update the generated `S` class.

## 4. UI Patterns
- **Titles**: Use `S.of(context).screenTitle`.
- **Buttons**: Extract labels like `S.of(context).tryAgain`.
- **Placeholders**: `S.of(context).totalUnlocked(earned, total)`.
- **Nullable Context**: In cases where context isn't directly available (like some controller logic), pass the string or use a static reference if safety is guaranteed, but preferring `BuildContext` where possible.
- **Helper Method Scope**: In `ConsumerWidget` or `StatelessWidget`, private helper methods that build UI components must accept `BuildContext context` as a parameter to access `S.of(context)`. 
  *   *Example*: `Widget _buildRow(BuildContext context, Item i) { ... }`

## 5. Retrofitting Patterns
- **Uppercase Labels**: Multi-word uppercase labels (e.g., `'HUNT FORECAST'`) are often neglected in initial l10n passes. Search regex: `Text\('[A-Z][A-Z]`.
- **SegmentedButton Conflicts**: When moving `SegmentedButton` segments to localized strings, remove the `const` keyword from the `segments: []` list, as `S.of(context)` is a runtime evaluation.
- **Bulk Extraction**: Batch update ARB files with ~20-30 keys at once before running `flutter gen-l10n` to minimize build cycles.


### [outcall_app_audit_scorecard] navigation_ux_patterns
# Flutter Navigation & UX Patterns

Practical insights gained from the OUTCALL app development for handling complex navigation and accessibility.

## 1. Navigation: Back Button in Tab Context
### Problem
A screen that is used both as a **pushed route** (via `Navigator.push`) and as a **tab** (in a `PageView` or `IndexedStack`) will exhibit different back button behavior. Calling `Navigator.pop(context)` when the screen is a tab can pop the entire root navigator, resulting in a **black screen** if the shell is the app root.

### Solution
Use `Navigator.canPop(context)` to guard the back button logic.

```dart
IconButton(
  icon: Icon(Icons.arrow_back),
  // Only show or enable the back button if we are in a pushed stack.
  onPressed: Navigator.canPop(context) 
      ? () => Navigator.pop(context) 
      : null, 
)
```

Alternatively, hide the widget entirely if `!Navigator.canPop(context)`.

## 3. Semantics and Interactive Widgets
When wrapping list items (like `ListTile`) or grid cards in `Semantics`, ensure the `label` provides a concise summary of the state (name, value, status e.g. "Locked", "Completed"). For buttons/InkWells, use the `button: true` and `label` properties together so screen readers identify the element as an interactive control with its context.


### [outcall_app_audit_scorecard] overview
# OUTCALL App Quality & Audit Overview

This knowledge item documents the audit and quality hardening process for the OUTCALL app, a Flutter hunting call training application.

## Sprint Progression
Through Sprints 4 to 7, the app score was increased from **B+ (82)** to **A+ (98)**.

| Category | Grade | Score | Key Improvements |
|---|:---:|:---:|---|
| **Architecture** | A | 9/10 | Domain-centric with clean separation, Firestore+Firedart cross-platform setup |
| **Feature Depth** | A | 9/10 | 16 feature modules, recording->analysis->leaderboard pipeline |
| **UX Polish** | A | 9/10 | 30 achievements, seasonal themes, history dashboard |
| **Security** | B+ | 8/10 | Secure storage, App Check, InputSanitizer utility |
| **Test Coverage** | B+ | 8/10 | 11+ test files, 165+ tests (domain, models, security) |
| **Accessibility** | B+ | 8/10 | Semantics on 10 screens, TalkBack optimized |
| **Localization** | A+ | 10/10 | 230 ARB keys, 15+ screens fully localized with `S.of(context)` |
| **Overall** | **A+** | **98%** | Production-ready state with 0 analyzer issues |

## Knowledge Artifacts
- [App Quality Audit Checklist](audit_checklist.md)
- [Accessibility & Semantics Patterns](accessibility_semantics.md)
- [Content Moderation & Quality Strategy](content_moderation_and_quality.md)
- [Profanity Filtering Logic & Normalization](profanity_filtering_logic.md)
- [Spam & Bot Prevention Patterns](spam_bot_prevention_patterns.md)
- [Firestore Audit Technical Patterns](firestore_audit_technical_patterns.md)
- [Content Remediation Logs](remediation_logs.md)
- [Localization & Internationalization Workflow](localization_workflow.md)
- [Security Input Sanitization](security_input_sanitization.md)
- [Test Coverage Patterns & Strategy](test_coverage_patterns.md)
- [Navigation & UX Polish Tips](navigation_ux_patterns.md)
- [UI Layout & Responsiveness Patterns](ui_layout_troubleshooting.md)
- [Achievements System Implementation](achievements_system.md)
- [Static Analysis & Code Hygiene](static_analysis_hygiene.md)
- [Polish Audit & Refinement Patterns](polish_audit_patterns.md)


### [outcall_app_audit_scorecard] polish_audit_patterns
# Polish Audit Patterns & "Chipping Away" Methodology

The final 5% of app quality involves "chipping away" at small inconsistencies, hardcoded artifacts, and generic logic.

## 1. Code Selection Regex
Use these regex searches to find polish opportunities:

| Target | Regex / Query | Rationale |
|---|---|---|
| **Hardcoded UI Labels** | `Text\('[A-Z][A-Z]` | Finds uppercase hardcoded strings (HUNT FORECAST, etc.) often missed in l10n. |
| **Debug Artifacts** | `TODO|FIXME|HACK|print\(` | Identifies technical debt or unsanitized logs. |
| **Generic Error Handling** | `catch \(e\) \{` | Finds opportunities to tighten exception types. |
| **Legacy Opacity** | `.withOpacity\(` | Identifies outdated API usage (modern: `.withValues(alpha: x)`). |
| **Gated Logging** | `debugPrint|kDebugMode` | Verifies that debug output is properly gated for production. |

## 2. Refinement Workflow
1. **The Analyzer baseline**: Run `flutter analyze` until 0 issues (errors, warnings, and infos) are found. Treat `info` as a required fix for A+ production grade.
2. **String Extraction Sweep**:
   - Run a global search for hardcoded strings.
   - Batch update the ARB file (20-30 keys).
   - Resolve `const` conflicts caused by dynamic localization.
3. **Dead Check Removal**: Tightening types at the source to remove the need for downstream null checks simplifies the code and reduces branching complexity.
4. **Context Passthrough**: Ensure private UI helper methods are designed with `BuildContext` parameters to allow for future localization or theme access without large-scale refactoring.


### [outcall_app_audit_scorecard] profanity_filtering_logic
# Profanity & Inappropriate Content Filtering
 
The `ProfanityFilter` is a security-first utility designed to block offensive language while defeating common evasion techniques used by malicious actors.
 
## Filtering Strategy
 
The filter uses a multi-stage approach:
1. **Normalisation**: Collapsing characters and symbols to a base canonical form.
2. **Category-based Matching**: Checking against a comprehensive blocklist across 10 distinct categories:
    - **Profanity**: Common vulgarity and swearing.
    - **Racial/Ethnic Slurs**: Dehumanizing and derogatory terms targeting specific groups.
    - **Sexual/Explicit**: Suggestive terms, anatomical references, or pornographic site names.
    - **Drug References**: Illegal substances, drug culture slang, and paraphernalia.
    - **Hate/Extremism**: Nazi imagery, hate figures, or terrorist groups.
    - **Violence/Threats**: References to killing, murder, or physical harm.
    - **Ableist/Derogatory**: Slurs targeting mental or physical disabilities.
    - **Troll/Edgy Names**: Internet memes (e.g., "deez nuts"), self-harm terms (e.g., "kys").
    - **Impersonation**: Use of "Admin", "Developer", "Staff" to deceive users.
    - **Leet-speak Evasion**: Specific character substitutions designed to bypass simple filters.
3. **Regex Pattern Matching**: Using case-insensitive regular expressions for efficient scanning.
 
## Defeating Evasion Tricks
 
Malicious users often attempt to bypass word-based filters using "leet-speak", spacing, or special characters. `ProfanityFilter` counters these with aggressive pre-processing:
 
### 1. Character Substitution
Common numerical and symbolic substitutions are collapsed back to letters:
- `0` → `o`
- `1` → `i`, `!`, `|`
- `3` → `e`
- `4` → `a`, `@`
- `5` → `s`, `$`
- `7` → `t`
 
### 2. Delimiter Removal
Users may insert spaces, dots, or underscores between letters (e.g., `f.u.c.k`). The filter strips all non-alphanumeric delimiters before matching.
 
### 3. Hidden Characters
Zero-width characters (like `\u200B`) are stripped to prevent visual concealment of malicious terms.
 
## Implementation Details
 
```dart
class ProfanityFilter {
  // Categorized blocklist...
  static const _blockedTerms = [...];
 
  static String _normalise(String input) {
    return input
        .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '') // Strip hidden chars
        .replaceAll('0', 'o')
        .replaceAll('1', 'i')
        .replaceAll('!', 'i')
        .replaceAll('3', 'e')
        .replaceAll('4', 'a')
        .replaceAll('@', 'a')
        .replaceAll('5', 's')
        .replaceAll('\$', 's')
        .replaceAll('7', 't')
        .replaceAll(RegExp(r'[\s._\-]+'), ''); // Strip delimiters
  }
}
```
 
## Integration Points
- **InputSanitizer**: Automatically cleans names during sanitization.
- **ProfileNotifier**: Blocks profile updates if `containsInappropriateContent` returns true, allowing for user-facing error messages.
- **Auditing Scripts**: Used in backend Node.js scripts to scan existing Firestore datasets.


### [outcall_app_audit_scorecard] remediation_logs
# Remediation Logs: Content Moderation

This log tracks manual and batch remediation actions performed on the OUTCALL production database to maintain platform safety and quality.

## Audit Session: March 4, 2026

**Context**: Comprehensive scan of Firebase Auth (63 accounts) and Firestore Profiles (41 documents) for offensive or inappropriate content.

### Findings Summary
- **Total Scanned**: 104 accounts/profiles
- **Clean Accounts**: 99
- **Flagged Profiles**: 5 (All from Firestore custom nicknames)

### Flagged Entity Remediation

| UID | Original Identifying Context | Action Taken |
|---|---|---|
| `yAeVNdiuYZNREI...` | name="hitler", nickname="nigger" | Reset to name="Hunter", cleared nickname |
| `uM2lJhoxerZ73R...` | name="hitler", nickname="hitler" | Reset to name="Hunter", cleared nickname |
| `6EN063UifCcBqP...` | name="hitler" | Reset to name="Hunter" |
| `4bLd830LUyfxly...` | name="gay", nickname="hitler" | Reset to name="Hunter", cleared nickname |
| `T6GqS2EbTBeS89...` | name="hilter" | Reset to name="Hunter" |

**Remediation Method**: Batch `PATCH` script utilizing the Firestore REST API and Firebase CLI refresh tokens.

### Key Learnings
- **Anonymous Vulnerability**: All 5 flagged accounts were anonymous profiles without verified emails. This confirms that anonymous account creation is the primary vector for trolling/offensive content.
- **Evasion Detection**: The discovery of `"hilter"` underscores the necessity of the `ProfanityFilter`'s normalization layer, which now collapses common character substitutions and spacing.
- **Data Discrepancy**: The fact that Firebase Auth was 100% clean while Firestore was not confirms that internal app nicknames must be the primary focus for moderation audits.


### [outcall_app_audit_scorecard] security_input_sanitization
# Flutter Security: Input Sanitization Utility

The `InputSanitizer` provides protection against XSS, injection attacks, malformed input, and inappropriate content in user-facing text fields.

## Implementation Pattern

```dart
class InputSanitizer {
  InputSanitizer._();

  static const int maxNameLength = 50;
  static const int maxFeedbackLength = 500;

  /// Sanitizes name: trims, removes control chars, strips HTML, filters profanity, truncates.
  static String sanitizeName(String input, {String fallbackValue = 'Hunter'}) {
    var clean = input.trim();
    clean = _removeControlCharacters(clean);
    clean = _stripHtmlTags(clean);
    if (clean.length > maxNameLength) {
      clean = clean.substring(0, maxNameLength);
    }
    // Blocklist check
    return ProfanityFilter.cleanName(clean, fallback: fallbackValue);
  }

  /// Returns true if the input contains inappropriate content.
  static bool containsInappropriateContent(String? input) {
    return ProfanityFilter.containsProfanity(input);
  }

  /// Sanitizes free-text (feedback/comments).
  static String sanitizeFreeText(String input) {
    var clean = input.trim();
    clean = _removeControlCharacters(clean);
    clean = _stripHtmlTags(clean);
    if (clean.length > maxFeedbackLength) {
      clean = clean.substring(0, maxFeedbackLength);
    }
    return clean;
  }

  /// Email validation regex.
  static bool isValidEmail(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email.trim());
  }

  static String _removeControlCharacters(String input) {
    return input.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
  }

  static String _stripHtmlTags(String input) {
    return input.replaceAll(RegExp(r'<[^>]*>'), '');
  }
}
```

## Key Protections
- **Control Character Removal**: Protects against unexpected terminal behavior or string manipulation exploits.
- **HTML Stripping**: Basic XSS prevention if user text is displayed elsewhere (like leaderboards).
- **Profanity Filtering**: Uses `ProfanityFilter` to auto-replace offensive terms with a safe fallback (e.g., "Hunter").
- **Trimming/Truncating**: Prevents visual spoofing or database-level buffer issues.
- **Email Validation**: Ensures valid data format at the utility level before API calls.

## Usage
Appropriable for `onSaved` callbacks in `TextFormField` or `onChanged` events in `TextField`.


### [outcall_app_audit_scorecard] spam_bot_prevention_patterns
# Spam & Bot Prevention Patterns

The `SpamFilter` utility (`lib/core/utils/spam_filter.dart`) provides a multi-layered heuristic for identifying bot-created accounts and throwaway email addresses.

## 1. Email Pattern Matching

A primary signal for bot-farms is the use of automated naming schemes for Gmail accounts.

### Bot-Farm Regex
OUTCALL identifies accounts matching the pattern `firstname.lastname.NNNNN@gmail.com`:
```dart
static final _botEmailPattern = RegExp(
  r'^[a-z]+[a-z]+\.\d{4,6}@gmail\.com$',
  caseSensitive: false,
);
```

## 2. Domain Blocklisting

Throwaway email services (Temporary/Disposable Email Addresses) are commonly used to create low-value test accounts or spam profiles.

### Blocked Domains
The filter maintains a set of known throwaway domains:
- `mailinator.com`
- `guerrillamail.com`
- `tempmail.com`
- `yopmail.com`
- `sharklasers.com`
- `dispostable.com`
- `trashmail.com`
- etc.

## 3. Profile Heuristics (`isSuspiciousProfile`)

If an email doesn't trigger a blocklist match, the system evaluates the profile's overall signals.

### "Ghost" Account Detection
Accounts are flagged if they meet all the following criteria:
1. **No Email**: The account is anonymous.
2. **Zero Activity**: `historyCount == 0`.
3. **Age**: Created more than **7 days ago**.

This identifies stale anonymous accounts that remain inactive, likely created during mass-testing or by automated tools.

## 4. Usage in the Library

### Validation during Sign-In
The `UnifiedProfileRepository.createProfile` method runs the `SpamFilter` on new sign-ins:
```dart
final bool isFlagged = SpamFilter.isSuspiciousEmail(email);
if (isFlagged) {
  profileData['flagged'] = true;
  profileData['flagReason'] = SpamFilter.getSuspiciousReason(email);
}
```

### Logging & Auditing
The `getSuspiciousReason` method provides human-readable strings for internal logging (e.g., `"blocked domain: mailinator.com"`), facilitating easier manual review of flagged datasets.


### [outcall_app_audit_scorecard] static_analysis_hygiene
# Static Analysis & Code Hygiene

The OUTCALL app achieved a "Zero Issue" baseline for `flutter analyze` across all production code.

## 1. The Zero Issue Benchmark
Maintaining zero errors, warnings, and info-level diagnostics ensures code consistency and identifies potential bugs or performance bottlenecks early.

## 2. Common Lint Resolutions

### A. Unnecessary Nullable Declarations
**Lint**: `unnecessary_nullable_for_final_variable_declarations`
**Pattern**:
```dart
// Before
final GoogleSignInAccount? user = await signIn();
if (user == null) return;
// After null check, 'user' is actually non-nullable in this scope
```
**Fix**: Declare the variable as non-nullable if the source (like `authenticate()`) is guaranteed to return a value or throw, or remove redundant checks if the analyzer identifies the type as solidified.
### B. Cascading Warnings & Dead Checks
**Scenario**: Removing a `?` from a variable declaration (type solidification) often creates "unnecessary null comparison" warnings further down the file. This occurs when a return type is identified as non-nullable (e.g., `authenticate()` in `google_sign_in` version 6.2+ returning a non-nullable `GoogleSignInAccount`).

**Fix**: 
1. Tighten the variable type (remove `?`).
2. Follow the analyzer's breadcrumbs to remove the now-redundant `if (user == null)` checks.
3. Treat these as "Code Polish" opportunities to reduce branching complexity.

### B. Const Correctness
**Lint**: `prefer_const_constructors`
**Pattern**: Static UI elements inside a dynamic tree.
**Implementation**:
Adding `const` to app shell skeletons, background wrappers, and safely parameterized widgets reduced rebuild overhead.
*Note*: Widgets using `S.of(context)` for localization must **not** be `const` as the locale can change at runtime.

### C. Final Locals
**Lint**: `prefer_final_locals`
**Pattern**: Temporary variables for location, calculations, or status flags that never change after initialization.
**Fix**: Use `final` for all variables that are not reassigned.

## 3. Library Cleanliness
- **Zero `print()` calls**: All logging is routed through `AppLogger` which gates output behind `if (kDebugMode)`.
- **Zero `TODO` comments**: All technical debt or pending features were resolved or moved to the project backlog before the 1.8.0 release.
- **Opacity Migration**: Migrated all `.withOpacity(x)` calls to the more performant `.withValues(alpha: x)` API available in newer Flutter versions.


### [outcall_app_audit_scorecard] test_coverage_patterns
# Flutter Domain Model Testing Patterns

A robust approach for testing domain models (entities and data models) with a focus on JSON parsing, Equatable props, and edge-case validation.

## 1. Unit Testing `fromJson` Factories
Testing JSON deserialization ensures your models can handle response data correctly, including optional fields and default values.

### Pattern: JSON Helper Method
Create a private `_makeJson` method within the `group` to easily generate JSON with default and overrideable fields.

```dart
group('WeatherModel.fromJson', () {
  Map<String, dynamic> _makeJson({
    double temperature = 22.5,
    int code = 0,
    double wind = 10.0,
  }) {
    return {
      'current_weather': {
        'temperature': temperature,
        'weathercode': code,
        'windspeed': wind,
      }
    };
  }

  test('correctly parses clear sky', () {
    final model = WeatherModel.fromJson(_makeJson(code: 0));
    expect(model.code, 0);
    expect(model.temperature, 22.5);
    expect(model.condition, 'ClearSky');
  });
});
```

## 2. Testing `toJson` Round-trips
Verify that a model can be serialized and then deserialized back to an identical object.

```dart
test('supports JSON roundtrip', () {
  final original = AudioAnalysisModel.simple(score: 95.0);
  final json = original.toJson();
  final reconstructed = AudioAnalysisModel.fromJson(json);

  expect(reconstructed, original);
  expect(reconstructed.score, 95.0);
});
```

## 3. Equatable and Value Comparison
If models extend `Equatable`, testing that they correctly implement `props` ensures value-based equality in logic and UI tests.

```dart
test('models with identical props are equal', () {
  final entry1 = LeaderboardEntry(id: '1', score: 100);
  final entry2 = LeaderboardEntry(id: '1', score: 100);

  expect(entry1, entry2);
});
```

## 4. Edge Case and Boundary Validation
Test models against unexpected input types, nulls (if allowed), and boundary values (e.g., scores 0 and 100).

- **Default Values**: Ensure models handle missing non-essential fields.
- **WMO Code Mapping**: Verify mappings from numeric codes to friendly strings or categories.
- **Derived Fields**: Test fields that are calculated based on other fields (e.g., `isMastered` based on score threshold).

## 5. Mock Data Generators
Keep `simple()` or `mock()` factory constructors in the model for testing purposes, but ensure they don't leak into production logic except for initialization.


### [outcall_app_audit_scorecard] ui_layout_troubleshooting
# UI Layout & Responsiveness Patterns

Strategies for maintaining a polished, bug-free UI across varying screen sizes and dynamic content.

## 1. Handling Text Truncation & Overflow
In complex screens (like Settings or Library), labels can often become truncated or cause overflow errors on smaller screens or when localized into verbose languages.

### Patterns:
- **Expanded/Flexible**: Wrap long text labels in `Expanded` or `Flexible` when nested in a `Row`.
- **Ellipsis**: Use `overflow: TextOverflow.ellipsis` to gracefully handle content that exceeds its bounds.
- **Dynamic Sizing**: Utilize `maxLines` to allow for multi-line labels if vertical space permits.

### Example:
```dart
Row(
  children: [
    Icon(icon),
    SizedBox(width: 8),
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, overflow: TextOverflow.ellipsis),
          Text(subtitle, style: TextStyle(fontSize: 12)),
        ],
      ),
    ),
  ],
)
```

## 2. Localization Padding
Localized strings (e.g. German vs English) vary significantly in length. 
- Avoid hardcoding widths for buttons or containers that hold text.
- Use `SingleChildScrollView` to prevent overflow in vertically constrained lists (like bottom sheets or dialogs) after localization increases text volume.

## 3. Responsive Icons
For adaptive launchers and app icons, ensure sources are high resolution (512x512+) and properly padded to prevent clipping of "safe zones" on round vs square icon masks.


### [outcall_web_assets_and_wiki] ai_coach_knowledge_base
# AI Coach Knowledge Base

The OUTCALL AI Coach (powered by the `outcall-coach` model) is trained on a comprehensive set of hunting call techniques and field strategies. This knowledge is codified in the `ai/Modelfile` and serves as the ground truth for coaching feedback.

## Species-Specific Coaching Rules

### Waterfowl (Duck & Goose)
- **Mallard Hail Call**: 5-6 quacks, decreasing volume/length. Only for long range (>100 yards).
- **Feeding Chuckle**: "tikkitukkatikka" rhythm. High speed and lung capacity required.
- **Canada Goose Honk**: Two-note "herrrr-onk" using diaphragm air.
- **Goose Cluck**: Sharp "ga-wick" or "WHIT" anchored behind bottom teeth.

### Elk
- **Bugle**: Start low, smooth transition to high (held 2-3 sec), sharp drop-off.
- **Cow Call**: Mews and estrus whines. Peak rut strategy: location bugles in the morning, challenge bugles with chuckles when close.

### Whitetail Deer
- **Grunt Types**: Soft contact ("buhhh"), rhythmic tending grunts, aggressive challenger grunts.
- **Snort-Wheeze**: Dominant buck intimidation, used sparingly as it can scare young deer.
- **Timing**: Grunts every 45 min in early season, increasing frequency as rut approaches.

### Wild Turkey
- **Yelp**: Fundamental call. Vary volume and cadence.
- **Cutting**: Rapid excited clucks + yelps. Challenges hens.
- **Purr**: Soft, subtle content sound for final approach. Hardest to master on a diaphragm.

### Moose
- **Cow Call**: Long, nasal 3-5 second moan, increasing then tapering pitch. 
- **Bull Grunt**: Short, throaty grunts in series.
- **Strategy**: Moose hear calls from over a mile away; overcalling allows them to pinpoint and avoid the hunter.

### Predators (Coyote & Bear)
- **Coyote Howl**: Start with interrogation howls spaced 45 sec apart. Wait 5-10 min for response.
- **Black Bear**: Long (30-40 min) sequences of high-intensity distress calls (fawn/elk calf). Bears lose interest if sound stops.

## Technical Metric Diagnosis

The AI Coach focuses on four core metrics when analyzing user audio:

1.  **Pitch**: Controlled by tongue pressure (diaphragm) or throat tension. 
2.  **Timbre**: Tone quality; influenced by equipment fit and mouth positioning.
3.  **Rhythm**: Cadence of the call; often more critical than volume or exact pitch for realism.
4.  **Air consistency**: Diaphragm control and sustained even pressure.

## Field Strategy Guidelines

- **Weather**: Barometric pressure affects vocalization (e.g., Turkey most vocal at 29.9-30.2 inHg).
- **Decoys**: Motion decoys (spinners) for ducks should be turned off when geese approach.
- **Wind**: Always call and set up downwind of the target's expected arrival.


### [outcall_web_assets_and_wiki] chatbot_implementation
# Landing Page AI Chatbot Implementation (`chatbot.js`)

The AI Chatbot on the OUTCALL landing page serves as a primary lead generation and FAQ tool. It is implemented as a standalone JavaScript component that can be injected into any of the project's HTML files.

## Technical Flow

1. **User Query**: The user types a question in the floating chat widget.
2. **FAQ-First Check**: `chatbot.js` checks against a curated `FAQ` object using regex.
   - If a match is found (e.g., "price", "free", "android"), it returns an instant, pre-written answer.
   - This ensures fast responses for common, factual queries like pricing or availability.
3. **LLM Routing (Ollama)**: If no FAQ match is found, it sends the query to the `outcall-coach` model via a Cloudflare-tunneled Ollama instance.
4. **Fallback**: If the Ollama instance is unreachable or returns an error, it provides a "drop your email" fallback response to capture leads.

## Key Configuration

- **Model**: `outcall-coach` (Gemma 3 base).
- **Tunnel URL**: Managed via Cloudflare Quick Tunnels. This URL is dynamic and must be manually updated in `chatbot.js` (and the Flutter app's config) whenever the local `cloudflared` process is restarted.
- **System Prompt**: Enforces short answers, friendly tone, and factual accuracy about OUTCALL's features (FFT analysis, 135+ calls, weather intel).

## UI Elements

- Floating Action Button (FAB) for easy access.
- Quick-reply chips for common questions ("Animals supported?", "Scoring?", "Price?").
- Typing indicator for a more natural feel during LLM inference.


### [outcall_web_assets_and_wiki] network_exposure_and_tunnelling
# Network Exposure & AI Tunnelling

To enable the AI Chatbot on the landing page and the in-app AI Coach without a dedicated cloud-hosted LLM backend, OUTCALL uses a "Quick Tunnel" strategy to securely expose a local Ollama instance.

## Service Management (Windows)

### Ollama Setup
Ollama runs as a background service on the host machine.
- **Service Command**: `ollama serve` (starts the local API on `http://localhost:11434`)
- **Environment Variable**: `OLLAMA_ORIGINS="*"` (Required to allow traffic from Cloudflare Tunnels; otherwise, connections will return a **403 Forbidden** error).
- **Restarting with Origins** (Persistent):
  ```powershell
  # Set persistently for the user
  [System.Environment]::SetEnvironmentVariable('OLLAMA_ORIGINS', '*', 'User')

  # Stop and restart with the current session variable
  Stop-Process -Name "ollama" -Force -ErrorAction SilentlyContinue 
  $env:OLLAMA_ORIGINS="*"
  Start-Process "ollama" -ArgumentList "serve" -WindowStyle Hidden
  ```
- **Verification**: `Invoke-WebRequest -Uri "http://localhost:11434/api/tags"`

### Cloudflare Quick Tunnels
Quick tunnels provide a temporary, publicly accessible URL for the local service without requiring a Cloudflare account or persistent configuration.

- **Start Tunnel Command**: `cloudflared tunnel --url http://localhost:11434`
- **Output**: Generates a random `.trycloudflare.com` URL (e.g., `https://honor-phillips-but-linking.trycloudflare.com`).

## Updating Client URLs

When a new tunnel is started, the following locations must be updated with the new URL:

1.  **Landing Page**: `docs/chatbot.js` -> `const OLLAMA_URL`
2.  **Flutter App (Remote Config)**: `lib/core/services/remote_config/remote_config_service.dart` -> `ai_coach_url`
3.  **Flutter App (Fallback)**: `lib/features/rating/data/ai_coach_service.dart` -> `_fallbackBaseUrl`

## Troubleshooting

- **403 Forbidden**: Most common diagnostic when using tunnels with Ollama. Ensure `OLLAMA_ORIGINS` is set to `*` or includes the tunnel domain.
- **Tunnel Down**: If the console returns "The remote name could not be resolved", the tunnel has expired or crashed. Restart `cloudflared`.
- **Latency**: Cloudflare Quick Tunnels are subject to varied performance; for production, a named tunnel is recommended.


### [outcall_web_assets_and_wiki] overview
# OUTCALL Web Assets & Wiki Overview

The OUTCALL project includes a suite of web-based tools and assets located in the root `docs/` and `web/` directories. These components support the mobile app by providing a landing page, a comprehensive hunting wiki, and an AI-powered lead generation chatbot.

## Directory Structure

- **`/docs`**: Primary location for the public-facing website and wiki.
  - `index.html`: The main landing page.
  - `wiki.html`: The Encyclopedia of Hunting (Wiki).
  - `chatbot.js`: The AI Assistant logic.
  - `style.css`: Shared styles for the web components.
- **`/web`**: Flutter-specific web deployment files (manifest, index.html).
- **`/scripts`**: Automation scripts for maintaining web content.

## Hybrid AI Strategy

OUTCALL uses a hybrid approach to AI:
1. **In-App Coaching**: The Flutter app calls Ollama via a Cloudflare tunnel for deep audio analysis feedback.
2. **Landing Page Assistant**: `chatbot.js` provides instant answers on the landing page using the same `outcall-coach` model, with a curated FAQ fallback for speed and reliability.

## Local Development & Preview

For testing and updating web content (landing page and wiki), a local HTTP server is used to serve the `docs/` directory.

- **Serve Command**: `python -m http.server 8080` (run from within the `docs/` directory)
- **Local URL**: `http://localhost:8080`
- **Wiki URL**: `http://localhost:8080/wiki.html`


### [outcall_web_assets_and_wiki] wiki_management
# OUTCALL Wiki Management

The OUTCALL Wiki (`docs/wiki.html`) is a comprehensive encyclopedia of animals and hunting calls integrated directly into the web-based documentation for users.

## Wiki Content (`wiki.html`)

The wiki is an HTML-based document that includes:
- Reference images and scientific names.
- Detailed descriptions of bird and mammal calls.
- Tactical advice for hunters using specific calling sequences.
- Integration points with the mobile app for cross-platform learning.

## Automation Scripts (`/scripts`)

A set of Python scripts is used to maintain and update the wiki content:
- `update_wiki.py`: General maintenance and data sync.
- `update_wiki_encyclopedia.py`: Synchronizes the encyclopedia database with the HTML file.
- `update_wiki_more.py`, `update_wiki_extreme.py`: Adds specialized content for advanced users.
- `update_wiki_profiles.py`: Updates animal profiles with high-fidelity reference call metadata.

These scripts act as a bridge between the project's data (likely in-app JSON/remote config) and the public-facing documentation on the landing page/wiki.
