import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Prepares the app to RECEIVE push notifications — requests permission,
/// logs the FCM token for debugging, and watches for token rotation.
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
}
