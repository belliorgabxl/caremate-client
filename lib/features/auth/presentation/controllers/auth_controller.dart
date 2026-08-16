import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/network/api_client.dart';
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

  Future<void> login(String phone) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      _user = await _repo.login(phone);
      _step = AuthStep.authenticated;
      _syncPushToken();
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String phone,
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
    _user = null;
    _step = AuthStep.loggedOut;
    notifyListeners();
  }
}

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  return AuthController(ref.read(authRepositoryProvider), ref.read(apiClientProvider));
});
