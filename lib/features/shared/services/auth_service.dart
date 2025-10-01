import 'package:flutter/material.dart';

class AuthService {
  static bool _isLoggedIn = false;
  static String? _currentUser;

  static bool get isLoggedIn => _isLoggedIn;
  static String? get currentUser => _currentUser;

  static void login(String username) {
    _isLoggedIn = true;
    _currentUser = username;
  }

  static void logout() {
    _isLoggedIn = false;
    _currentUser = null;
  }
}

class AuthGuard extends StatelessWidget {
  final Widget child;
  final Widget loginPage;

  const AuthGuard({
    super.key,
    required this.child,
    required this.loginPage,
  });

  @override
  Widget build(BuildContext context) {
    return AuthService.isLoggedIn ? child : loginPage;
  }
}