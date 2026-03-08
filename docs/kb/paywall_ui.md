# Paywall UI & UX Design

The `PaywallScreen` is the primary monetization touchpoint, designed to match the app's charcoal and gold luxury aesthetic.

## Visual Design
- **Gradient Buttons**: Uses a transitioning gold gradient (`accentGoldDark` to `accentGoldLight`) with a shimmer animation controller.
- **Glassmorphism**: The screen is often shown as a modal bottom sheet with a deep charcoal surface and subtle borders.
- **Icons**: Prominent gold "workspace_premium" crown icon.

## Subscription Tiers
The screen currently promotes two tiers:
1. **Monthly**: $4.99/mo
2. **Yearly**: $29.99/yr (labeled with a "Save 50%" badge to encourage conversion).

## Interactive Logic
- **Comparison Matrix**: A clean list showing the difference between Free (e.g., "Limited Call Library", "Basic Info") and Pro (e.g., "All 135+ Calls", "Detailed Scoring", "Offline Mode").
- **State Handling**: The "Upgrade" button transforms into a `CircularProgressIndicator` while the purchase is processing to prevent double-billing.
- **Auto-Dismiss**: If a purchase or restore succeeds, the screen automatically pops itself.

## Price Parsing & Sandbox Handling
Store price strings (from Google Play/Apple Store) vary by locale and environment. In sandbox testing, periods like `/30 min` or `/5 minutes` frequently leak into price strings.

The `PaywallScreen` uses a robust `_stripBillingPeriod` method to clean these strings:
- Uses regex to isolate the currency and numeric amount (e.g., `$24.99`).
- Handles both `/` and ` per ` separators.
- Ensures the UI consistently appends the intended period (e.g., `/yr`) regardless of how the store formatted the original string.

This prevents the confusing "/30mins" or "/5mins" labels from appearing to users in test tracks.
