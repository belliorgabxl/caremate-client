import 'dart:developer' as developer;
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';

/// Must be top-level (not a class member) — the background isolate calls
/// this directly, with no access to anything built during `main()`.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No local-notification work needed here: a data-only or notification
  // payload delivered while the app is backgrounded is shown by the OS
  // itself from the FCM payload's `notification` block (see the Android
  // manifest's default_notification_channel_id/_icon). This handler exists
  // so Firebase doesn't warn about a missing one, and as the place to add
  // background data processing later (e.g. silently refreshing cached
  // booking status) if that's ever needed.
}

/// FCM wiring: local-notification display while foregrounded (FCM does not
/// auto-show those — only background/terminated notifications are shown by
/// the OS), token registration with the backend, and token-refresh handling.
///
/// **Android only for now** — iOS additionally needs an APNs key uploaded to
/// the Firebase project and the Push Notifications / Background Modes
/// capabilities enabled in Xcode before any of this does anything there.
class PushService {
  PushService(this._apiClient);

  static const _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'การแจ้งเตือนสำคัญ',
    description: 'แจ้งเตือนสถานะการจองและการชำระเงิน',
    importance: Importance.high,
  );

  final ApiClient _apiClient;
  final _localPlugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Android only for now (see class doc) — iOS needs an APNs key uploaded
    // to the Firebase project plus Push Notifications/Background Modes
    // capabilities in Xcode first. `flutter_local_notifications.initialize()`
    // also outright throws on iOS without Darwin settings, which we're not
    // providing yet since there's nothing to configure them against.
    if (!Platform.isAndroid) return;

    await _localPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    await _localPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/launcher_icon'),
      ),
    );

    await FirebaseMessaging.instance.requestPermission();

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  /// Call once after login/register/session-restore succeeds.
  Future<void> registerCurrentDevice() async {
    final token = await _currentToken();
    if (token != null) await _registerToken(token);
  }

  /// `getToken()` throws on iOS when no APNs token is available yet (always
  /// true on Simulator, and briefly true on a real device right after
  /// install) — iOS push isn't wired up yet regardless (see class doc), so
  /// this just needs to not crash the Android-only flow it's called from.
  Future<String?> _currentToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } on Exception catch (e) {
      if (kDebugMode) developer.log('getToken failed: $e');
      return null;
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      await _apiClient.dio.post(
        '/devices/register',
        data: {
          'token': token,
          'platform': Platform.isAndroid ? 'android' : 'ios',
          'app': 'customer',
        },
      );
    } on Exception catch (e) {
      // Backend endpoint doesn't exist yet (see CareMate FCM setup notes) —
      // never let this block login. Remove this guard once /devices/register
      // ships server-side.
      if (kDebugMode) developer.log('device token registration failed: $e');
    }
  }

  /// Call on logout so this device stops receiving pushes for the account
  /// that just signed out.
  Future<void> unregisterCurrentDevice() async {
    final token = await _currentToken();
    if (token == null) return;

    try {
      await _apiClient.dio.delete('/devices/${Uri.encodeComponent(token)}');
    } on Exception catch (e) {
      if (kDebugMode) developer.log('device token unregistration failed: $e');
    }
  }
}

final pushServiceProvider = Provider<PushService>((ref) {
  return PushService(ref.read(apiClientProvider));
});
