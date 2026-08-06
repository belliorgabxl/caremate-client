import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const _sessionCookieKey = 'cm_session_cookie';
  static const _pdpaConsentAtKey = 'cm_pdpa_consent_at';
  static const _pdpaConsentVersionKey = 'cm_pdpa_consent_version';

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

  // Backend has no PDPA consent field yet (see CLAUDE.md) — recorded locally
  // only, enforced client-side before the register API call fires. `version`
  // identifies which copy of the policy text (from `GET /legal/pdpa`, or the
  // bundled fallback) the user actually agreed to.
  Future<void> savePdpaConsentGiven(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _pdpaConsentAtKey,
      DateTime.now().toUtc().toIso8601String(),
    );
    await prefs.setString(_pdpaConsentVersionKey, version);
  }

  Future<bool> readPdpaConsentGiven() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_pdpaConsentAtKey);
  }

  Future<String?> readPdpaConsentVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pdpaConsentVersionKey);
  }
}

final localStorageProvider = Provider<LocalStorage>((ref) => LocalStorage());
