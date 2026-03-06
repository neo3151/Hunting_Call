import 'package:outcall/core/utils/profanity_filter.dart';


/// Input sanitization utilities for user-facing text fields.
///
/// Provides basic protection against injection attacks, XSS, malformed
/// input, and inappropriate content in user-submitted strings.
class InputSanitizer {
  InputSanitizer._();

  /// Maximum allowed length for user display names.
  static const int maxNameLength = 50;

  /// Maximum allowed length for free-text feedback/comments.
  static const int maxFeedbackLength = 500;

  /// Sanitize a user display name.
  ///
  /// - Trims whitespace
  /// - Removes control characters
  /// - Strips HTML/script tags
  /// - Replaces profane/inappropriate names with [fallback]
  /// - Truncates to [maxNameLength]
  static String sanitizeName(String input, {String fallback = 'Hunter'}) {
    var clean = input.trim();
    clean = _removeControlCharacters(clean);
    clean = _stripHtmlTags(clean);
    if (clean.length > maxNameLength) {
      clean = clean.substring(0, maxNameLength);
    }
    // Replace offensive names with the fallback
    clean = ProfanityFilter.cleanName(clean, fallback: fallback);
    return clean;
  }

  /// Returns `true` if [name] contains inappropriate content (local filter only).
  static bool containsInappropriateContent(String? name) {
    return ProfanityFilter.containsProfanity(name);
  }



  /// Sanitize free-text input (feedback, comments).
  ///
  /// - Trims whitespace
  /// - Removes control characters
  /// - Strips HTML/script tags
  /// - Truncates to [maxFeedbackLength]
  static String sanitizeFreeText(String input) {
    var clean = input.trim();
    clean = _removeControlCharacters(clean);
    clean = _stripHtmlTags(clean);
    if (clean.length > maxFeedbackLength) {
      clean = clean.substring(0, maxFeedbackLength);
    }
    return clean;
  }

  /// Validate that a string is a plausible email format.
  static bool isValidEmail(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email.trim());
  }

  /// Remove ASCII control characters (0x00-0x1F, 0x7F) except newline/tab.
  static String _removeControlCharacters(String input) {
    return input.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
  }

  /// Strip HTML tags to prevent XSS in rendered text.
  static String _stripHtmlTags(String input) {
    return input.replaceAll(RegExp(r'<[^>]*>'), '');
  }
}
