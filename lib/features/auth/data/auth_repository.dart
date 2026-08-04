import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage.dart';
import 'models/app_user.dart';
import 'models/pdpa_policy.dart';

class AuthRepository {
  AuthRepository(this._api, this._localStorage);

  final ApiClient _api;
  final LocalStorage _localStorage;

  /// Restores a previously-saved session by re-validating it against the
  /// backend. Returns null (and clears the stored cookie) if it's gone/expired.
  Future<AppUser?> restoreSession() async {
    final cookie = await _localStorage.readSessionCookie();
    if (cookie == null) return null;

    try {
      return await fetchMe();
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _localStorage.clearSession();
      }
      return null;
    }
  }

  /// `POST /auth/login` with just a phone number. Backend sets
  /// `caremate_session` via `Set-Cookie`; we lift it from the response
  /// headers (there's no WebView/browser here to store it for us) and hand
  /// back the freshly-authenticated user.
  Future<AppUser> login(String phone) async {
    try {
      final response = await _api.dio.post('/authentication/login', data: {'phone': phone});
      await _saveSessionCookie(response);
      return await fetchMe();
    } on DioException catch (e) {
      _api.throwApiException(e);
    }
  }

  /// `POST /auth/register`. The backend's `RegisterRequest` only requires
  /// phone/firstName/lastName (nickname/gender/dateOfBirth/email are
  /// nullable there) — the app's register form requires all of them
  /// up front regardless, so address/health-info/emergency-contact remain
  /// the only things deferred to the profile pages.
  ///
  /// `pdpaConsentVersion` is sent as `pdpaConsent`/`pdpaConsentVersion` —
  /// **proposed fields, not yet present on the backend's `RegisterRequest`**
  /// (see CLAUDE.md). Until the backend adds them they're harmlessly
  /// ignored/dropped server-side; consent is still recorded locally via
  /// `LocalStorage.savePdpaConsentGiven()` regardless.
  Future<AppUser> register({
    required String phone,
    required String firstName,
    required String lastName,
    required String nickname,
    required String gender,
    required String dateOfBirth,
    required String email,
    String? pdpaConsentVersion,
  }) async {
    try {
      final response = await _api.dio.post('/authentication/register', data: {
        'phone': phone,
        'firstName': firstName,
        'lastName': lastName,
        'nickname': nickname,
        'gender': gender,
        'dateOfBirth': dateOfBirth,
        'email': email,
        if (pdpaConsentVersion != null)
          ...{'pdpaConsent': true, 'pdpaConsentVersion': pdpaConsentVersion},
      });
      await _saveSessionCookie(response);
      return await fetchMe();
    } on DioException catch (e) {
      _api.throwApiException(e);
    }
  }

  /// `GET /legal/pdpa` — **proposed endpoint, not yet implemented on the
  /// backend** (see CLAUDE.md). Returns the current PDPA consent copy so it
  /// can be updated without an app release; callers should fall back to a
  /// bundled copy of the policy if this throws (e.g. 404 until the backend
  /// adds it, or any network failure).
  Future<PdpaPolicy> fetchPdpaPolicy() async {
    try {
      final response = await _api.dio.get('/legal/pdpa');
      final data = _api.unwrap(response.data) as Map<String, dynamic>;
      return PdpaPolicy.fromJson(data);
    } on DioException catch (e) {
      _api.throwApiException(e);
    }
  }

  Future<void> _saveSessionCookie(Response response) async {
    final setCookieHeaders = response.headers['set-cookie'];
    if (setCookieHeaders == null) return;

    for (final raw in setCookieHeaders) {
      if (!raw.startsWith('caremate_session=')) continue;
      await _localStorage.saveSessionCookie(raw.split(';').first);
      return;
    }
  }

  Future<AppUser> fetchMe() async {
    try {
      final response = await _api.dio.get('/authentication/me');
      final data = _api.unwrap(response.data) as Map<String, dynamic>;
      return AppUser.fromJson(data);
    } on DioException catch (e) {
      _api.throwApiException(e);
    }
  }

  Future<void> logout() => _localStorage.clearSession();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(apiClientProvider), ref.read(localStorageProvider));
});
