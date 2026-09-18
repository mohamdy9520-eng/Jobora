import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_profile_model.dart';
import 'user_profile_repository.dart';

/// Wraps authentication state for the router's redirect logic and the UI.
///
/// Wired in `main.dart` via:
///
/// FirebaseAuth.instance.authStateChanges().listen(authController.setUser);
class AuthController extends ChangeNotifier {
  final UserProfileRepository _profileRepository = UserProfileRepository();

  User? _user;
  bool _isInitializing = true;
  UserProfileModel? _profile;

  bool get isAuthenticated => _user != null;
  bool get isInitializing => _isInitializing;
  User? get user => _user;

  // Convenience getters for the UI (profile screen, greetings, etc.)
  String? get uid => _user?.uid;
  String? get email => _user?.email;
  String? get displayName => _user?.displayName;
  bool get isEmailVerified => _user?.emailVerified ?? false;

  // From the Firestore 'users' profile document — null until that
  // document exists (no signup/onboarding screen writes it yet).
  String? get username => _profile?.username;
  String? get jobTitle => _profile?.jobTitle;

  Future<void> setUser(User? user) async {
    _user = user;
    _isInitializing = false;
    _profile = null;
    notifyListeners(); // fast UI/router update, profile loads separately

    if (user != null) {
      _profile = await _profileRepository.getProfile(user.uid);
      notifyListeners();
    }
  }

  /// Call after the profile screen (or a future onboarding step) writes
  /// username/jobTitle, so the UI reflects the change immediately.
  Future<void> refreshProfile() async {
    if (_user == null) return;
    _profile = await _profileRepository.getProfile(_user!.uid);
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
    _profile = null;
    notifyListeners();
  }
}