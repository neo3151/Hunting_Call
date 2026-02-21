import 'dart:io';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hunting_calls_perfection/core/utils/app_logger.dart';

final loggerServiceProvider = Provider<LoggerService>((ref) {
  return LoggerService();
});

/// A central logging service that writes to the local console and,
/// if on a supported platform, leaves breadcrumbs in Firebase Crashlytics.
class LoggerService {
  final bool _isCrashlyticsSupported = Platform.isAndroid || Platform.isIOS;

  /// Log a UI event, state change, or user action
  void log(String message) {
    AppLogger.d('[BREADCRUMB] $message');
    if (_isCrashlyticsSupported) {
      FirebaseCrashlytics.instance.log(message);
    }
  }

  /// Record a caught exception (non-fatal)
  void recordError(dynamic error, StackTrace? stack, {String? reason}) {
    AppLogger.d('[ERROR] ${reason ?? ''}: $error\n$stack');
    if (_isCrashlyticsSupported) {
      FirebaseCrashlytics.instance.recordError(error, stack, reason: reason);
    }
  }

  /// Record a fatal exception that caused a crash
  void recordFatalError(dynamic error, StackTrace? stack) {
    AppLogger.d('[FATAL ERROR] $error\n$stack');
    if (_isCrashlyticsSupported) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
  }
}
