import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../network/api_client.dart';
import 'local_notifications.dart';

/// Real FCM push. Registers this device's token against the already-real
/// `POST /devices/register` endpoint (existed before this file did) and
/// shows an immediate local notification for messages that arrive while
/// the app is foregrounded (FCM payloads don't auto-display in that state).
///
/// Requires `android/app/google-services.json` to be present — without it
/// `Firebase.initializeApp()` throws, which is why every entry point here
/// is wrapped in try/catch and never blocks the rest of the app.
class PushNotificationsService {
  PushNotificationsService._();

  static bool _initialized = false;

  /// Call once at app startup, before login state is known — this only
  /// sets up Firebase + message listeners. Token registration with the
  /// backend happens separately, once a session exists (see [syncToken]).
  static Future<void> init() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

      FirebaseMessaging.onMessage.listen((message) {
        final title = message.notification?.title ?? message.data['title'];
        final body = message.notification?.body ?? message.data['body'];
        if (title == null && body == null) return;
        LocalNotificationsService.showNow(
          id: message.hashCode,
          title: title ?? 'CareMate',
          body: body ?? '',
        );
      });

      _initialized = true;
    } catch (e) {
      debugPrint('PushNotificationsService.init failed (Firebase not configured?): $e');
    }
  }

  /// Requests notification permission, fetches the current FCM token, and
  /// registers it against `POST /devices/register` for the signed-in user.
  /// Call this once auth state becomes authenticated (login/register/session
  /// restore) — the endpoint requires a session cookie. Safe to call
  /// repeatedly (e.g. on every app start while already logged in); it also
  /// re-registers on token refresh.
  static Future<void> syncToken(ApiClient api) async {
    if (!_initialized) await init();
    if (!_initialized) return; // Firebase genuinely unavailable — nothing to do.

    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _register(api, token);

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _register(api, newToken);
      });
    } catch (e) {
      debugPrint('PushNotificationsService.syncToken failed: $e');
    }
  }

  static Future<void> _register(ApiClient api, String token) async {
    try {
      await api.dio.post(
        '/devices/register',
        data: {
          'token': token,
          'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
          'app': 'client_app',
        },
      );
    } catch (e) {
      debugPrint('PushNotificationsService: device registration failed: $e');
    }
  }
}

/// Must be a top-level (or static) function — FCM invokes this in a
/// separate isolate when a message arrives while the app is backgrounded
/// or terminated.
@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {
  // Nothing to do here for now: on Android, a notification-type FCM payload
  // already auto-displays via the system tray while backgrounded/terminated
  // with zero extra code. This handler exists so `onBackgroundMessage` has
  // something registered, which FCM requires even for that default case.
}
