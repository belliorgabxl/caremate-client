import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/storage/local_storage.dart';
import 'auth_exception.dart';
import 'models/app_user.dart';
import 'models/otp_verify_result.dart';

/// Fully client-side simulation of a phone+OTP login, standing in for a real
/// backend OTP endpoint. Generates a code, "delivers" it back to the caller
/// (since there is no SMS provider), and verifies it against local state.
class AuthRepository {
  AuthRepository(this._localStorage) {
    _usersByPhone[AppConfig.demoExistingPhone] = const AppUser(
      id: 'user-demo-1',
      phone: AppConfig.demoExistingPhone,
      displayName: 'สมชาย ใจดี',
    );
  }

  final LocalStorage _localStorage;
  final Map<String, AppUser> _usersByPhone = {};
  final _random = Random();

  String? _generatedOtp;
  DateTime? _otpExpiresAt;
  DateTime? _otpSentAt;

  Future<String> requestOtp(String phone) async {
    await Future.delayed(AppConfig.mockNetworkDelay);

    final code = List.generate(AppConfig.otpLength, (_) => _random.nextInt(10)).join();
    _generatedOtp = code;
    _otpExpiresAt = DateTime.now().add(AppConfig.otpTtl);
    _otpSentAt = DateTime.now();

    return code;
  }

  bool canResendOtp() {
    if (_otpSentAt == null) return true;
    return DateTime.now().difference(_otpSentAt!) >= AppConfig.otpResendCooldown;
  }

  Future<OtpVerifyResult> verifyOtp({required String phone, required String code}) async {
    await Future.delayed(AppConfig.mockNetworkDelay);

    if (_generatedOtp == null || _otpExpiresAt == null) {
      throw const AuthException('กรุณาขอรหัส OTP ใหม่อีกครั้ง');
    }
    if (DateTime.now().isAfter(_otpExpiresAt!)) {
      throw const AuthException('รหัส OTP หมดอายุ กรุณาขอรหัสใหม่');
    }
    if (code != _generatedOtp) {
      throw const AuthException('รหัส OTP ไม่ถูกต้อง');
    }

    _generatedOtp = null;

    final existing = _usersByPhone[phone];
    if (existing != null) {
      await _persistSession(existing);
      return OtpVerifyResult.loginSuccess(existing);
    }

    return OtpVerifyResult.registerRequired(phone);
  }

  Future<AppUser> register({required String phone, required String displayName}) async {
    await Future.delayed(AppConfig.mockNetworkDelay);

    final user = AppUser(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      phone: phone,
      displayName: displayName,
    );
    _usersByPhone[phone] = user;
    await _persistSession(user);
    return user;
  }

  Future<AppUser?> restoreSession() async {
    await Future.delayed(AppConfig.mockNetworkDelay);

    final json = await _localStorage.readUser();
    if (json == null) return null;

    final user = AppUser.fromJson(json);
    _usersByPhone[user.phone] = user;
    return user;
  }

  Future<void> logout() => _localStorage.clearSession();

  Future<void> _persistSession(AppUser user) async {
    final token = 'sim-token-${user.id}-${DateTime.now().millisecondsSinceEpoch}';
    await _localStorage.saveSession(token: token, user: user.toJson());
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(localStorageProvider));
});
