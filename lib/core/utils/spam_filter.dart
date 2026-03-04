/// Spam & bot-account detection utilities.
///
/// Checks email patterns, display names, and account metadata for signals
/// that a profile was created by automated tools or bot farms.
class SpamFilter {
  SpamFilter._();

  // ── Email patterns ──────────────────────────────────────────────────

  /// Classic bot-farm pattern: firstname.lastname.NNNNN@gmail.com
  /// e.g. vernagomez.70967@gmail.com, bryantbarrett.60557@gmail.com
  static final _botEmailPattern = RegExp(
    r'^[a-z]+[a-z]+\.\d{4,6}@gmail\.com$',
    caseSensitive: false,
  );

  /// Domains used for throw-away / test accounts.
  static const _blockedDomains = <String>{
    'test.com',
    'test.test',
    'example.com',
    'mailinator.com',
    'guerrillamail.com',
    'tempmail.com',
    'throwaway.email',
    'yopmail.com',
    'sharklasers.com',
    'guerrillamailblock.com',
    'grr.la',
    'dispostable.com',
    'trashmail.com',
  };

  // ── Public API ──────────────────────────────────────────────────────

  /// Returns `true` if the email matches a known spam / bot pattern.
  static bool isSuspiciousEmail(String? email) {
    if (email == null || email.isEmpty) return false;

    final lower = email.toLowerCase().trim();
    final parts = lower.split('@');
    if (parts.length != 2) return false;

    final domain = parts[1];

    // Check blocked domains
    if (_blockedDomains.contains(domain)) return true;

    // Check firstname.lastname.NNNNN@gmail.com bot-farm pattern
    if (_botEmailPattern.hasMatch(lower)) return true;

    return false;
  }

  /// Lightweight heuristic check on a profile's overall signals.
  ///
  /// Combines email pattern, account age, and activity level.
  static bool isSuspiciousProfile({
    required String? email,
    required String? displayName,
    required DateTime createdAt,
    required int historyCount,
  }) {
    // Suspicious email is an immediate flag
    if (isSuspiciousEmail(email)) return true;

    // Account older than 7 days with zero activity and no email
    // (anonymous ghost accounts)
    if (email == null &&
        historyCount == 0 &&
        DateTime.now().difference(createdAt).inDays > 7) {
      return true;
    }

    return false;
  }

  /// Human-readable reason string (useful for logging).
  static String? getSuspiciousReason(String? email) {
    if (email == null || email.isEmpty) return null;

    final lower = email.toLowerCase().trim();
    final parts = lower.split('@');
    if (parts.length != 2) return null;

    final domain = parts[1];

    if (_blockedDomains.contains(domain)) {
      return 'blocked domain: $domain';
    }
    if (_botEmailPattern.hasMatch(lower)) {
      return 'bot-farm email pattern: $lower';
    }
    return null;
  }
}
