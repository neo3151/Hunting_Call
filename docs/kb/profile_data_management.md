# Profile Data Management & History Ordering

Ensuring consistent data ordering across multiple platforms and storage backends (Firebase, Firedart, SQLite) is a core requirement for OUTCALL.

## 1. History Item Ordering Discrepancy
A critical discrepancy was discovered between the local and cloud history storage implementations:
- **Local / Secure Data Sources:** Used `insert(0, item)` to prepend new entries (newest-first).
- **Cloud (Unified Profile Repository):** Used `.add(data)`, which appended entries to the end (newest-last).

Since the UI (e.g., `HistoryDashboardScreen`) and logic consistently expect the history to be in newest-first order, this resulted in an "upside-down" list for cloud-synced profiles.

## 2. Resolving the Mismatch
The `UnifiedProfileRepository.saveResultForUser` method was updated to match the local sources by using `history.insert(0, data)`. All new recordings saved to Firestore will now be correctly ordered.

## 3. Read-time Migration (Sort-on-Read)
To avoid a complex one-time conversion script or an offline migration, a **sort-on-read** strategy was implemented in the `_sanitizeProfileData` method in `UnifiedProfileRepository`.

### Implementation:
- Every time a profile is loaded from any cloud source, the `history` list is explicitly sorted by its `timestamp` field in **descending order** (newest first).
- This ensures that existing users with reversed history data see their records fixed immediately upon loading, without requiring any write-back to the database.

## 4. Best Practices
- **Data sources should be consistent** in their entry-point logic (always prepend for chronological lists).
- **Sanitize on Load:** When data structure or ordering might be unreliable (e.g. from foreign backends), use a sanitization method to enforce the expected format before the data reaches the entities/UI.
- **Unified Achievement Persistence:** Use `profileNotifier.saveAchievementsForUser` when triggering achievement saves from outside the profile feature (e.g., from `RatingScreen`) to ensure consistent persistence.
