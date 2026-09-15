import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Wraps authentication state for the router's redirect logic and the UI.
///
/// Wired in `main.dart` via:
///
/// FirebaseAuth.instance.authStateChanges().listen(authController.setUser);
class AuthController extends ChangeNotifier {
  User? _user;
  bool _isInitializing = true;

  bool get isAuthenticated => _user != null;
  bool get isInitializing => _isInitializing;
  User? get user => _user;

  // Convenience getters for the UI (profile screen, greetings, etc.)
  String? get uid => _user?.uid;
  String? get email => _user?.email;
  String? get displayName => _user?.displayName;
  bool get isEmailVerified => _user?.emailVerified ?? false;

  void setUser(User? user) {
    _user = user;
    _isInitializing = false;
    notifyListeners();
  }

  void finishInitializing() {
    _isInitializing = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    // _user is also cleared by the authStateChanges listener in main.dart,
    // but we set it here too so isAuthenticated flips immediately for the UI.
    _user = null;
    notifyListeners();
  }
}