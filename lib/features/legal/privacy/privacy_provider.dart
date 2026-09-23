// lib/features/legal/privacy/privacy_provider.dart
import 'package:flutter/material.dart';
import 'privacy_repository.dart';

/// Holds only account-actions state (export/delete). The privacy
/// policy text itself is no longer fetched here — it's shown directly
/// from GitHub Pages via LegalWebViewScreen.
class PrivacyProvider extends ChangeNotifier {
  final _actionsRepository = PrivacyRepository();

  bool isSubmitting = false;
  String? error;

  Future<bool> requestDataExport(String uid) async {
    isSubmitting = true;
    error = null;
    notifyListeners();
    try {
      await _actionsRepository.requestDataExport(uid);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> deleteAccount(String uid) => _actionsRepository.deleteAccount(uid);

  Future<void> reauthenticate(String password) =>
      _actionsRepository.reauthenticateWithPassword(password);
}