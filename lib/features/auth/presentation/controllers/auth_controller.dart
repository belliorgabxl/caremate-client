import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../core/notifications/push_service.dart';
import '../../data/auth_repository.dart';
import '../../data/models/app_user.dart';

enum AuthStep { checking, loggedOut, authenticated }

class AuthController extends ChangeNotifier {
  AuthController(this._repo, this._pushService);

  final AuthRepository _repo;
  final PushService _pushService;

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
    if (_step == AuthStep.authenticated) _registerDeviceForPush();
    notifyListeners();
  }

  Future<void> login(String phone) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      _user = await _repo.login(phone);
      _step = AuthStep.authenticated;
      _registerDeviceForPush();
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
      );
      _step = AuthStep.authenticated;
      _registerDeviceForPush();
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
    await _pushService.unregisterCurrentDevice();
    await _repo.logout();
    _user = null;
    _step = AuthStep.loggedOut;
    notifyListeners();
  }

  // Fire-and-forget: called at the exact moment auth state actually flips to
  // authenticated (session restore, login, or register alike), so there's no
  // separate listener trying to infer that transition after the fact and
  // racing the widget tree's build order to do it.
  void _registerDeviceForPush() {
    _pushService.init().then((_) => _pushService.registerCurrentDevice());
  }
}

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  return AuthController(
    ref.read(authRepositoryProvider),
    ref.read(pushServiceProvider),
  );
});
