import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

enum AuthStatus {
  checking,
  authenticated,
  unauthenticated,
}

class MockAuthUser {
  const MockAuthUser({
    required this.id,
    required this.displayName,
    required this.phone,
  });

  final String id;
  final String displayName;
  final String phone;
}

class AuthController extends ChangeNotifier {
  AuthStatus _status = AuthStatus.checking;
  MockAuthUser? _user;
  bool _isLoggingIn = false;

  AuthStatus get status => _status;
  MockAuthUser? get user => _user;
  bool get isChecking => _status == AuthStatus.checking;
  bool get isLoggedIn => _status == AuthStatus.authenticated;
  bool get isLoggingIn => _isLoggingIn;

  Future<void> checkSession() async {
    if (_status != AuthStatus.checking) return;

    await Future.delayed(const Duration(milliseconds: 800));

    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> mockLogin(String phone) async {
    if (_isLoggingIn) return;

    _isLoggingIn = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 700));

    _user = MockAuthUser(
      id: 'mock-user-001',
      displayName: 'Gabel',
      phone: phone,
    );

    _status = AuthStatus.authenticated;
    _isLoggingIn = false;
    notifyListeners();
  }

  void logout() {
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  return AuthController();
});