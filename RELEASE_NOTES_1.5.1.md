# OUTCALL v1.5.1 — Patch Release

## Play Console Description (under 500 chars)

```
🔐 Security & Stability Update

• Fixed profile creation bug — your hunter name now displays correctly after signup
• Upgraded to real email/password authentication on all platforms
• Personal data now stored in encrypted storage
• Firestore & Storage rules hardened for document-level security
• Improved error messages for sign-in issues
• General stability improvements
```

---

## Full Release Notes

## 🔐 Security Hardening

- **Firestore rules** now enforce document-level ownership — your data is yours alone
- **Firebase Storage rules** restrict uploads/reads to authenticated users
- **PII migration** — all personal data (email, birthday) moved from SharedPreferences to encrypted storage via `flutter_secure_storage`
- Removed hardcoded admin emails from build scripts; replaced with environment variables

## 🛡️ Authentication Overhaul

- **Real email/password authentication** on Linux & desktop via Firedart — no more profile-lookup impersonation
- Proper sign-up and sign-in flows with password validation and error feedback
- Session persistence across app restarts on Linux
- Normalized error codes between Firebase SDK and Firedart REST API for consistent UX

## 🐛 Bug Fixes

- **Fixed "Guest Handler" profile bug** — new accounts now reliably display your chosen hunter name immediately after registration
- Fixed race condition where the home screen could load before the profile was written to the database
- Improved `OPERATION_NOT_ALLOWED` error handling with actionable user-facing messages

## 🧹 Maintenance

- Added admin utility for bulk Firebase Authentication cleanup
- Sensitive credentials excluded from version control via updated `.gitignore`
