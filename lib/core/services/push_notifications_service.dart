import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_router.dart';
import '../../app/router/app_routes.dart';
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
  static const _apnsRetryLimit = 10;
  static const _apnsRetryDelay = Duration(milliseconds: 500);

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

      // App was backgrounded (not terminated) when the notification was tapped.
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // App was terminated and this tap is what launched it — the router
      // isn't attached to a live widget tree yet at this point in `init()`,
      // so defer the actual navigation a tick via _handleNotificationTap's
      // own retry loop.
      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) _handleNotificationTap(initialMessage);

      _initialized = true;
    } catch (e) {
      debugPrint(
        'PushNotificationsService.init failed (Firebase not configured?): $e',
      );
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
    if (!_initialized) {
      return; // Firebase genuinely unavailable — nothing to do.
    }

    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _waitForApnsToken();
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _register(api, token);

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _register(api, newToken);
      });
    } catch (e) {
      debugPrint('PushNotificationsService.syncToken failed: $e');
    }
  }

  /// On iOS, FCM's `getToken()` needs a native APNs device token first —
  /// right after `requestPermission()` the OS hasn't finished its APNs
  /// handshake yet, so `getToken()` throws `apns-token-not-set` on a cold
  /// start. That exception would otherwise skip the `onTokenRefresh`
  /// listener below entirely, meaning this device's token never gets
  /// (re)registered for the rest of the app session. Poll briefly instead.
  /// Tapping a notification should land the user directly on that booking's
  /// status page, not just open the app to wherever it was left. `bookingId`
  /// rides in the FCM data payload (see backend's `pushViaFCM`). The router's
  /// `BuildContext` may not exist yet if this app was launched cold by the
  /// tap itself, so poll briefly for it the same way [_waitForApnsToken]
  /// polls for the APNs token.
  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    final bookingId = message.data['bookingId'];
    if (bookingId == null || bookingId.isEmpty) return;

    for (var attempt = 0; attempt < _apnsRetryLimit; attempt++) {
      final context = rootNavigatorKey.currentContext;
      if (context != null) {
        // Not a widget's own context that can go stale across the await
        // above — this re-reads the live root navigator's context fresh on
        // every loop iteration.
        // ignore: use_build_context_synchronously
        context.go(AppRoutes.bookingStatusPath(bookingId));
        return;
      }
      await Future.delayed(_apnsRetryDelay);
    }
  }

  static Future<void> _waitForApnsToken() async {
    for (var attempt = 0; attempt < _apnsRetryLimit; attempt++) {
      if (await FirebaseMessaging.instance.getAPNSToken() != null) return;
      await Future.delayed(_apnsRetryDelay);
    }
  }

  static Future<void> _register(ApiClient api, String token) async {
    try {
      await api.dio.post(
        '/devices/register',
        data: {
          'token': token,
          'platform': defaultTargetPlatform == TargetPlatform.iOS
              ? 'ios'
              : 'android',
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
