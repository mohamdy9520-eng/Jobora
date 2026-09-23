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

  // True only if this account can sign in with email/password (as
  // opposed to Google-only accounts). Used to hide the "change
  // password" tab for Google-only users, since there's no password
  // to change.
  bool get hasPasswordProvider =>
      _user?.providerData.any((p) => p.providerId == 'password') ?? false;

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

  /// Creates the initial 'users' profile document right after signup
  /// (email/password or Google), so username/jobTitle exist from the
  /// first login instead of staying null forever because nothing ever
  /// wrote the doc. Uses SetOptions(merge: true) under the hood
  /// (see UserProfileRepository.saveProfile), so calling this again
  /// later (e.g. from a profile-edit screen) won't wipe out fields it
  /// doesn't pass.
  Future<void> ensureProfile({String? username, String? jobTitle}) async {
    if (_user == null) return;

    // Don't overwrite an existing profile (e.g. a returning Google user
    // who already set a username before) with a freshly-derived default.
    if (_profile != null && (_profile!.username?.isNotEmpty ?? false)) {
      return;
    }

    final resolvedUsername = username ?? _deriveUsernameFromEmail(_user!.email);

    await _profileRepository.saveProfile(
      UserProfileModel(
        uid: _user!.uid,
        username: resolvedUsername,
        jobTitle: jobTitle,
      ),
    );
    await refreshProfile();
  }

  /// "mohamed.ali@gmail.com" -> "mohamed.ali". Returns null if there's
  /// no email to derive from (shouldn't happen for email/password or
  /// Google sign-in, but stay safe).
  String? _deriveUsernameFromEmail(String? email) {
    if (email == null || !email.contains('@')) return null;
    final prefix = email.split('@').first.trim();
    return prefix.isEmpty ? null : prefix;
  }

  /// Updates the Firebase Auth displayName and refreshes the local
  /// `_user` so `displayName` reflects the change immediately, without
  /// needing a logout/login. Used by EditProfileScreen's "name" tab —
  /// also fixes legacy accounts whose displayName was never set
  /// correctly at signup.
  Future<void> updateDisplayName(String name) async {
    final user = _user;
    if (user == null) return;
    await user.updateDisplayName(name);
    await user.reload();
    _user = FirebaseAuth.instance.currentUser;
    notifyListeners();
  }

  /// Changes the password for email/password accounts. Firebase requires
  /// a recent sign-in for this, so we reauthenticate with the current
  /// password first — otherwise this throws 'requires-recent-login'.
  /// Only call this when [hasPasswordProvider] is true.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _user;
    if (user == null || user.email == null) {
      throw FirebaseAuthException(code: 'no-current-user');
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
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