import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../core/models/application_model.dart';
import '../../../core/repostories/applications_repository.dart';

/// Real Firestore-backed provider. Subscribes to
/// ApplicationsRepository.watchAll(uid) whenever a user signs in, and
/// tears the subscription down + clears local state on sign-out.
class ApplicationProvider extends ChangeNotifier {
  ApplicationProvider({ApplicationsRepository? repository})
      : _repository = repository ?? ApplicationsRepository();

  final ApplicationsRepository _repository;

  String? _uid;
  List<ApplicationModel> _applications = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<ApplicationModel>>? _subscription;

  List<ApplicationModel> get applications => List.unmodifiable(_applications);
  bool get isLoading => _isLoading;
  String? get error => _error;

  ApplicationModel? byId(String id) {
    for (final app in _applications) {
      if (app.id == id) return app;
    }
    return null;
  }

  void updateAuth(String? uid) {
    if (_uid == uid) return;
    _uid = uid;

    _subscription?.cancel();
    _subscription = null;
    _applications = [];
    _error = null;

    if (uid == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _subscription = _repository.watchAll(uid).listen(
          (applications) {
        _applications = applications;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object err, StackTrace _) {
        _isLoading = false;
        _error = err.toString();
        notifyListeners();
      },
    );
  }

  /// Creates [application] in Firestore. Any id on [application] (e.g. a
  /// client-side temporary timestamp) is ignored — the repository always
  /// assigns the real Firestore id. Returns the saved model so the caller
  /// (e.g. add_application_screen) can navigate using the real id.
  Future<ApplicationModel> create(ApplicationModel application) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Cannot create an application while signed out.');
    }
    try {
      return await _repository.create(uid, application);
    } catch (err) {
      _error = err.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> update(ApplicationModel application) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Cannot update an application while signed out.');
    }
    try {
      await _repository.update(uid, application);
    } catch (err) {
      _error = err.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Cannot delete an application while signed out.');
    }
    try {
      await _repository.delete(uid, id);
    } catch (err) {
      _error = err.toString();
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}