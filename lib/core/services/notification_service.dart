import 'package:outcall/core/utils/app_logger.dart';
import 'package:outcall/core/services/simple_storage.dart';

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
    final enabled = await _storage.getBool(_keyEnabled) ?? true;
    if (!enabled) {
      AppLogger.d('NotificationService: Notifications disabled by user');
      return;
    }

    try {
      // TODO: Uncomment when firebase_messaging is added to pubspec
      // final messaging = FirebaseMessaging.instance;
      //
      // // Request permission (iOS)
      // final settings = await messaging.requestPermission(
      //   alert: true,
      //   badge: true,
      //   sound: true,
      // );
      //
      // if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      //   final token = await messaging.getToken();
      //   if (token != null) {
      //     await _storage.setString(_keyFcmToken, token);
      //     AppLogger.d('NotificationService: FCM token: $token');
      //   }
      //
      //   // Subscribe to topics
      //   await messaging.subscribeToTopic('daily_challenge');
      //   await messaging.subscribeToTopic('app_updates');
      //
      //   // Handle foreground messages
      //   FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      // }

      AppLogger.d('NotificationService: Initialized (pending FCM setup)');
    } catch (e) {
      AppLogger.d('NotificationService: Init failed: $e');
    }
  }

  /// Schedule a daily challenge reminder.
  Future<void> scheduleDailyChallengeReminder() async {
    // TODO: Use flutter_local_notifications for scheduled notifications
    // final flnp = FlutterLocalNotificationsPlugin();
    // await flnp.zonedSchedule(
    //   0, 'Daily Challenge', 'New challenge available!',
    //   tz.TZDateTime.now(tz.local).add(Duration(hours: 24)),
    //   NotificationDetails(...),
    //   androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    //   matchDateTimeComponents: DateTimeComponents.time,
    // );
    AppLogger.d('NotificationService: Daily reminder scheduled (pending setup)');
  }

  /// Toggle notifications on/off.
  Future<void> setEnabled(bool enabled) async {
    await _storage.setBool(_keyEnabled, enabled);
    if (!enabled) {
      // TODO: Unsubscribe from topics
      // await FirebaseMessaging.instance.unsubscribeFromTopic('daily_challenge');
    }
  }

  /// Get current notification enabled state.
  Future<bool> isEnabled() async {
    return await _storage.getBool(_keyEnabled) ?? true;
  }
}
