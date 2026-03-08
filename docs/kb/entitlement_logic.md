# Premium Entitlement & Hybrid Persistence

Premium status is not just a boolean in memory; it is a persistently verified state managed by the `UnifiedProfileRepository`.

## Hybrid Verification Logic
To ensure robustness against network issues or Cloud latency, the repository implements a hybrid check in `getProfile()`:
1. **Cloud Source**: Fetch the user document from the `profiles` Firestore collection.
2. **Local Backup**: If `isPremium` is `false` (or the fetch fails partially), the repository checks the `LocalProfileDataSource` (Secure Storage).
3. **Override**: If the local cache says the user is premium, the returned `UserProfile` entity has `isPremium: true` even if the Cloud document isn't updated yet.

## Reliability of `setPremiumStatus`
When a purchase is verified:
- **Local Write**: The status is immediately saved to local secure storage.
- **Cloud Write**: An update is sent to Firestore.
- This ensures that if the user loses internet immediately after a successful purchase, their "Pro" features remain unlocked on the next app restart.

## Guest Users
Users operating as "guest" cannot have their premium status synced to the Cloud, but the repository still attempts to handle their state via the local data source if possible.
