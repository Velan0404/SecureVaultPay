import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Registered via [FirebaseMessaging.onBackgroundMessage] in `main()`. Must be
/// a top-level (or static) function — the plugin runs it on a separate
/// isolate, so it cannot be a class method or closure.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[PushNotificationService] background message: ${message.messageId} ${message.data}');
}

/// Prepares the app to RECEIVE push notifications — requests permission,
/// logs the FCM token for debugging, and watches for token rotation and
/// incoming messages in every app state (foreground, background, terminated).
/// Sending notifications is a separate, not-yet-built module; this only
/// verifies delivery readiness.
class PushNotificationService {
  const PushNotificationService();

  Future<void> requestPermissionAndLogToken() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[PushNotificationService] permission status: ${settings.authorizationStatus}');

    try {
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('[PushNotificationService] FCM token: $token');
    } catch (e) {
      debugPrint('[PushNotificationService] failed to obtain FCM token: $e');
    }
  }

  /// Calls [onRefresh] whenever Firebase rotates the token, so the backend's
  /// copy (Device.fcmToken) doesn't go stale between logins.
  void listenForTokenRefresh(void Function(String token) onRefresh) {
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      debugPrint('[PushNotificationService] FCM token refreshed: $token');
      onRefresh(token);
    });
  }

  /// Logs messages that arrive while the app is in the foreground. `onMessage`
  /// never fires for background/terminated delivery — those are covered by
  /// [firebaseMessagingBackgroundHandler] and [checkInitialMessage].
  void listenForForegroundMessages() {
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[PushNotificationService] foreground message: ${message.messageId} ${message.data}');
    });
  }

  /// Checks whether the app was cold-started by tapping a notification while
  /// terminated, so that path is verifiable even though it isn't handled yet.
  Future<void> checkInitialMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) {
      debugPrint('[PushNotificationService] launched from terminated state by message: ${message.messageId}');
    }
  }
}
