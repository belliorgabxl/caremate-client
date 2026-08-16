import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Local (device-only) booking reminder notifications — no server/Firebase
/// involved. Wraps `flutter_local_notifications` with the two things this
/// app actually needs: one-time init (called from `main.dart`) and
/// scheduling a single reminder ahead of a booking's scheduled time.
class LocalNotificationsService {
  LocalNotificationsService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Call once at app startup. Safe to call more than once (no-ops after
  /// the first successful run).
  static Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    // `tz.local` defaults to UTC unless `tz.setLocalLocation()` is called,
    // which needs a device-timezone lookup plugin we don't have (e.g.
    // flutter_timezone) — not added here to keep this dependency-light.
    // That's fine: `TZDateTime.from()` derives the absolute fire instant
    // from the source `DateTime`'s own `.toUtc()` value regardless of which
    // `Location` is passed, so scheduling still fires at the correct wall-
    // clock moment even though `tz.local`'s *label* stays "UTC".

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _plugin.initialize(settings: settings);

      // Android 13+ (API 33+) requires runtime POST_NOTIFICATIONS permission.
      // The plugin exposes this directly — no need for a separate
      // permission_handler dependency.
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.requestNotificationsPermission();

      _initialized = true;
    } catch (e) {
      // Never let a notification-setup failure block app startup.
      debugPrint('LocalNotificationsService.init failed: $e');
    }
  }

  /// Schedules a one-off local reminder 30 minutes before [scheduledFor]
  /// (a booking's scheduled start time). If that fire time has already
  /// passed, this silently does nothing — there's nothing useful to remind
  /// the user of anymore.
  ///
  /// Uses [AndroidScheduleMode.inexactAllowWhileIdle] deliberately — exact
  /// alarms need the Android 12+ "exact alarm" special permission, which is
  /// overkill for a reminder that can be a few minutes off.
  static Future<void> scheduleBookingReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledFor,
  }) async {
    if (!_initialized) await init();

    final fireAt = scheduledFor.subtract(const Duration(minutes: 30));
    if (fireAt.isBefore(DateTime.now())) return;

    final tzFireAt = tz.TZDateTime.from(fireAt, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'booking_reminders',
      'การแจ้งเตือนการจอง',
      channelDescription: 'แจ้งเตือนก่อนถึงเวลานัดหมายบริการที่จองไว้',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzFireAt,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Displays a notification immediately — used for real push (FCM)
  /// messages that arrive while the app is in the foreground, since FCM
  /// notification payloads don't auto-display in that state on either
  /// platform, unlike background/terminated.
  static Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_initialized) await init();

    const androidDetails = AndroidNotificationDetails(
      'push_messages',
      'การแจ้งเตือนทั่วไป',
      channelDescription: 'การแจ้งเตือนเกี่ยวกับการจองและบริการของคุณ',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(id: id, title: title, body: body, notificationDetails: details);
  }
}
