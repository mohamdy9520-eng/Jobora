import 'package:flutter/material.dart';
import '../legal_content_model.dart';
import '../legal_content_repository.dart';
import 'privacy_repository.dart';

class PrivacyProvider extends ChangeNotifier {
  final _contentRepository = LegalContentRepository();
  final _actionsRepository = PrivacyRepository();

  LegalContentModel? _content;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  PrivacyProvider() {
    load();
  }

  LegalContentModel? get content => _content;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _content = await _contentRepository.fetch('privacy_policy');
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> requestDataExport(String uid) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      await _actionsRepository.requestDataExport(uid);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> deleteAccount(String uid) => _actionsRepository.deleteAccount(uid);

  Future<void> reauthenticate(String password) => _actionsRepository.reauthenticateWithPassword(password);
}