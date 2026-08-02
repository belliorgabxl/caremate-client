import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const _sessionCookieKey = 'cm_session_cookie';

  Future<void> saveSessionCookie(String cookieHeaderValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionCookieKey, cookieHeaderValue);
  }

  Future<String?> readSessionCookie() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionCookieKey);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionCookieKey);
  }
}

final localStorageProvider = Provider<LocalStorage>((ref) => LocalStorage());
