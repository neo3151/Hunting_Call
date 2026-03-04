import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:outcall/core/utils/app_logger.dart';
import 'package:outcall/core/services/simple_storage.dart';

/// Top-level handler for background FCM messages (required by Firebase).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.d('FCM: Background message: ${message.messageId}');
}

/// Service for managing push notifications via Firebase Cloud Messaging.
///
/// Handles initialization, permission requests, topic subscriptions,
/// and daily challenge reminders.
class NotificationService {
  static const _keyFcmToken = 'fcm_token';
  static const _keyEnabled = 'notifications_enabled';

  final ISimpleStorage _storage;

  NotificationService(this._storage);

  /// Initialize FCM and request permissions.
  Future<void> initialize() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      AppLogger.d('NotificationService: Skipped (desktop)');
      return;
    }

    final enabled = await _storage.getBool(_keyEnabled) ?? true;
    if (!enabled) {
      AppLogger.d('NotificationService: Disabled by user');
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;

      // Request permission (iOS shows prompt, Android auto-grants)
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get and persist FCM token
        final token = await messaging.getToken();
        if (token != null) {
          await _storage.setString(_keyFcmToken, token);
          AppLogger.d('NotificationService: FCM token obtained');
        }

        // Subscribe to topics
        await messaging.subscribeToTopic('daily_challenge');
        await messaging.subscribeToTopic('app_updates');

        // Handle background messages
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen((message) {
          AppLogger.d('FCM: Foreground message: ${message.notification?.title}');
        });

        AppLogger.d('NotificationService: Fully initialized');
      } else {
        AppLogger.d('NotificationService: Permission denied');
      }
    } catch (e) {
      AppLogger.d('NotificationService: Init failed: $e');
    }
  }

  /// Toggle notifications on/off.
  Future<void> setEnabled(bool enabled) async {
    await _storage.setBool(_keyEnabled, enabled);
    if (!Platform.isAndroid && !Platform.isIOS) return;
    
    try {
      final messaging = FirebaseMessaging.instance;
      if (enabled) {
        await messaging.subscribeToTopic('daily_challenge');
        await messaging.subscribeToTopic('app_updates');
      } else {
        await messaging.unsubscribeFromTopic('daily_challenge');
        await messaging.unsubscribeFromTopic('app_updates');
      }
    } catch (e) {
      AppLogger.d('NotificationService: Toggle failed: $e');
    }
  }

  /// Get current notification enabled state.
  Future<bool> isEnabled() async {
    return await _storage.getBool(_keyEnabled) ?? true;
  }
}
