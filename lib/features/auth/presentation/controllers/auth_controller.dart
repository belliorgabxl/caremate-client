import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../data/auth_exception.dart';
import '../../data/auth_repository.dart';
import '../../data/models/app_user.dart';

enum AuthStep { checking, phoneEntry, otpSent, needsRegistration, authenticated }

class AuthController extends ChangeNotifier {
  AuthController(this._repo);

  final AuthRepository _repo;

  AuthStep _step = AuthStep.checking;
  AppUser? _user;
  String? _pendingPhone;
  String? _lastOtpForDemo;
  bool _isSubmitting = false;

  AuthStep get step => _step;
  AppUser? get user => _user;
  String? get pendingPhone => _pendingPhone;
  String? get lastOtpForDemo => _lastOtpForDemo;
  bool get isSubmitting => _isSubmitting;

  bool get isChecking => _step == AuthStep.checking;
  bool get isLoggedIn => _step == AuthStep.authenticated;

  Future<void> checkSession() async {
    if (_step != AuthStep.checking) return;

    final user = await _repo.restoreSession();
    _user = user;
    _step = user != null ? AuthStep.authenticated : AuthStep.phoneEntry;
    notifyListeners();
  }

  Future<void> requestOtp(String phone) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final code = await _repo.requestOtp(phone);
      _pendingPhone = phone;
      _lastOtpForDemo = code;
      _step = AuthStep.otpSent;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  bool canResendOtp() => _repo.canResendOtp();

  Future<void> verifyOtp(String code) async {
    final phone = _pendingPhone;
    if (phone == null) throw const AuthException('กรุณาเริ่มต้นใหม่อีกครั้ง');

    _isSubmitting = true;
    notifyListeners();

    try {
      final result = await _repo.verifyOtp(phone: phone, code: code);
      if (result.isLoginSuccess) {
        _user = result.user;
        _step = AuthStep.authenticated;
      } else {
        _step = AuthStep.needsRegistration;
      }
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> register({required String displayName}) async {
    final phone = _pendingPhone;
    if (phone == null) throw const AuthException('กรุณาเริ่มต้นใหม่อีกครั้ง');

    _isSubmitting = true;
    notifyListeners();

    try {
      final user = await _repo.register(phone: phone, displayName: displayName);
      _user = user;
      _step = AuthStep.authenticated;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void backToPhoneEntry() {
    _pendingPhone = null;
    _lastOtpForDemo = null;
    _step = AuthStep.phoneEntry;
    notifyListeners();
  }

  Future<void> logout() async {
    await _repo.logout();
    _user = null;
    _pendingPhone = null;
    _lastOtpForDemo = null;
    _step = AuthStep.phoneEntry;
    notifyListeners();
  }
}

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  return AuthController(ref.read(authRepositoryProvider));
});
