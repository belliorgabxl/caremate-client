import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/demo_backend.dart';
import '../../../../core/network/demo_mode.dart';
import '../../../../core/services/push_notifications_service.dart';
import '../../data/auth_repository.dart';
import '../../data/models/app_user.dart';

enum AuthStep { checking, loggedOut, authenticated }

class AuthController extends ChangeNotifier {
  AuthController(this._repo, this._api);

  final AuthRepository _repo;
  final ApiClient _api;

  /// Best-effort — a failed/unavailable push setup should never affect the
  /// actual auth flow, hence the swallowed error.
  void _syncPushToken() {
    PushNotificationsService.syncToken(_api).catchError((_) {});
  }

  AuthStep _step = AuthStep.checking;
  AppUser? _user;
  bool _isSubmitting = false;

  AuthStep get step => _step;
  AppUser? get user => _user;
  bool get isSubmitting => _isSubmitting;

  bool get isChecking => _step == AuthStep.checking;
  bool get isLoggedIn => _step == AuthStep.authenticated;

  Future<void> checkSession() async {
    if (_step != AuthStep.checking) return;

    final user = await _repo.restoreSession();
    _user = user;
    _step = user != null ? AuthStep.authenticated : AuthStep.loggedOut;
    if (user != null) _syncPushToken();
    notifyListeners();
  }

  /// Sends the real SMS OTP for the login flow. Throws [ApiException] (e.g.
  /// malformed phone, or 404 when the phone isn't registered) — caller shows
  /// the error and never opens the OTP sheet.
  Future<void> requestLoginOtp(String phone) => _repo.requestLoginOtp(phone);

  /// Sends the real SMS OTP for the register flow. Unlike login's, an
  /// already-registered phone throws [ApiException] here (409) instead of
  /// staying silent.
  Future<void> requestRegisterOtp(String phone) =>
      _repo.requestRegisterOtp(phone);

  Future<void> login(String phone, String code) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      _user = await _repo.login(phone, code);
      _step = AuthStep.authenticated;
      _syncPushToken();
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> register({
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
    _isSubmitting = true;
    notifyListeners();

    try {
      _user = await _repo.register(
        phone: phone,
        code: code,
        firstName: firstName,
        lastName: lastName,
        nickname: nickname,
        gender: gender,
        dateOfBirth: dateOfBirth,
        email: email,
        pdpaConsentVersion: pdpaConsentVersion,
        referralCode: referralCode,
      );
      _step = AuthStep.authenticated;
      _syncPushToken();
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    _user = await _repo.fetchMe();
    notifyListeners();
  }

  Future<void> logout() async {
    await _repo.logout();
    if (DemoMode.enabled.value) {
      DemoMode.enabled.value = false;
      DemoBackend.reset();
    }
    _user = null;
    _step = AuthStep.loggedOut;
    notifyListeners();
  }
}

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  return AuthController(
    ref.read(authRepositoryProvider),
    ref.read(apiClientProvider),
  );
});
