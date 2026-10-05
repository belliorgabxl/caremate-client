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

  /// `POST /authentication/otp/request` — asks the backend to send a real
  /// SMS OTP (via ThaiBulkSMS). `purpose` is `login` or `register`; the
  /// backend namespaces codes separately per purpose so one can't be
  /// replayed for the other. For `login` on an unregistered phone the
  /// backend answers 404 before sending any SMS; for `register` on an
  /// already-registered phone it answers 409.
  Future<void> _requestOtp(String phone, String purpose) async {
    try {
      await _api.dio.post(
        '/authentication/otp/request',
        data: {'phone': phone, 'purpose': purpose},
      );
    } on DioException catch (e) {
      _api.throwApiException(e);
    }
  }

  Future<void> requestLoginOtp(String phone) => _requestOtp(phone, 'login');

  Future<void> requestRegisterOtp(String phone) =>
      _requestOtp(phone, 'register');

  Future<AppUser> login(String phone, String code) async {
    try {
      final response = await _api.dio.post(
        '/authentication/login',
        data: {'phone': phone, 'code': code},
      );
      await _saveSessionCookie(response);
      return await fetchMe();
    } on DioException catch (e) {
      _api.throwApiException(e);
    }
  }

  Future<AppUser> register({
    required String phone,
    required String code,
    required String firstName,
    required String lastName,
    required String nickname,
    required String gender,
    required String dateOfBirth,
    required String email,
    String? pdpaConsentVersion,
    String? referralCode,
  }) async {
    try {
      final response = await _api.dio.post(
        '/authentication/register',
        data: {
          'phone': phone,
          'code': code,
          'firstName': firstName,
          'lastName': lastName,
          'nickname': nickname,
          'gender': gender,
          'dateOfBirth': dateOfBirth,
          'email': email,
          if (pdpaConsentVersion != null) ...{
            'pdpaConsent': true,
            'pdpaConsentVersion': pdpaConsentVersion,
          },
          if (referralCode != null && referralCode.isNotEmpty)
            'referralCode': referralCode,
        },
      );
      await _saveSessionCookie(response);
      return await fetchMe();
    } on DioException catch (e) {
      _api.throwApiException(e);
    }
  }

  Future<PdpaPolicy> fetchPdpaPolicy() async {
    try {
      final response = await _api.dio.get('/pdpa');
      final data = _api.unwrap(response.data) as Map<String, dynamic>;
      return PdpaPolicy.fromJson(data);
    } on DioException catch (e) {
      _api.throwApiException(e);
    }
  }

  Future<PdpaPolicy> fetchPdpaPolicyVersion(String version) async {
    try {
      final response = await _api.dio.get('/pdpa/$version');
      final data = _api.unwrap(response.data) as Map<String, dynamic>;
      return PdpaPolicy.fromJson(data);
    } on DioException catch (e) {
      _api.throwApiException(e);
    }
  }

  Future<List<PdpaVersionSummary>> fetchPdpaVersions() async {
    try {
      final response = await _api.dio.get('/pdpa/versions');
      final data = _api.unwrap(response.data) as List<dynamic>;
      return data
          .map((e) => PdpaVersionSummary.fromJson(e as Map<String, dynamic>))
          .toList();
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
  return AuthRepository(
    ref.read(apiClientProvider),
    ref.read(localStorageProvider),
  );
});
