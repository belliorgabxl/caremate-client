import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter/foundation.dart';

/// Home-screen app-icon badge (the numbered dot on the launcher icon, like
/// LINE/Messenger) via `app_badge_plus`. Always synced from an authoritative
/// unread count fetched from the backend (`GET /notifications`'s
/// `unread_count`) — never incremented locally on a raw push receipt, so it
/// can't drift from the real count.
///
/// Real limitation, not fixable from this repo alone: the badge only
/// updates while some Dart code actually runs (foreground use, or a
/// background isolate woken by a data push). A pure "notification" FCM
/// payload arriving while the app is fully killed auto-displays via the
/// system tray with zero Dart code involved, so it can't call this. Once
/// device push registration works again (`POST /devices/register` is
/// currently 500ing — see CLAUDE.md), true always-live badge updates would
/// need the backend to include a badge count in the push payload itself
/// (`aps.badge` on iOS). What this service gives is the badge reflecting
/// unread state as of the last time the app was actually open — same
/// behavior most apps show right after being force-closed.
class AppBadgeService {
  AppBadgeService._();

  static Future<void> setCount(int count) async {
    try {
      await AppBadgePlus.updateBadge(count < 0 ? 0 : count);
    } catch (e) {
      debugPrint('AppBadgeService.setCount failed: $e');
    }
  }
}
