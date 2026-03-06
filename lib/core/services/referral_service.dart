import 'dart:math';

/// Service for generating and managing referral codes.
/// Referral codes are deterministic — derived from the user ID.
class ReferralService {
  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No I/O/0/1 to avoid confusion

  /// Generate a deterministic referral code from a user ID.
  /// Format: OUTCALL-XXXX (e.g. OUTCALL-K7M2)
  static String generateCode(String userId) {
    if (userId.isEmpty) return 'OUTCALL-0000';

    // Use a hash of the user ID to generate a stable 4-char suffix
    final hash = userId.hashCode.abs();
    final random = Random(hash);
    final suffix = List.generate(4, (_) => _chars[random.nextInt(_chars.length)]).join();

    return 'OUTCALL-$suffix';
  }

  /// Build a shareable referral message.
  static String shareMessage(String referralCode) {
    return '🦌 I\'m using OUTCALL to master my hunting calls — '
        'real-time audio analysis, AI scoring, and 135+ pro calls.\n\n'
        'Use my code $referralCode when you sign up!\n\n'
        'Download: https://hunting-call-perfection.web.app';
  }
}
