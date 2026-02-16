import 'package:flutter/foundation.dart';

/// Centralized logger that only outputs in debug mode.
///
/// In release builds, all log calls are no-ops, preventing
/// sensitive information from leaking to logcat.
class AppLogger {
  /// Debug log — stripped in release builds.
  static void d(String message) {
    if (kDebugMode) debugPrint(message);
  }

  /// Warning log — stripped in release builds.
  static void w(String message) {
    if (kDebugMode) debugPrint('⚠️ $message');
  }

  /// Error log — stripped in release builds.
  static void e(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('❌ $message');
      if (error != null) debugPrint('Error: $error');
      if (stackTrace != null) debugPrint('Stack: $stackTrace');
    }
  }
}
