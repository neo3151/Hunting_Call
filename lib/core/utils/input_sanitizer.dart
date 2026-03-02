/// Input sanitization utilities for user-facing text fields.
///
/// Provides basic protection against injection attacks, XSS, and malformed
/// input in user-submitted strings (usernames, feedback, etc.).
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
  /// - Truncates to [maxNameLength]
  static String sanitizeName(String input) {
    var clean = input.trim();
    clean = _removeControlCharacters(clean);
    clean = _stripHtmlTags(clean);
    if (clean.length > maxNameLength) {
      clean = clean.substring(0, maxNameLength);
    }
    return clean;
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
