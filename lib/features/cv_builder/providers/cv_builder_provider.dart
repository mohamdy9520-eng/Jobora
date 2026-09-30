import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/repostories/cv_builder_repository.dart';
import '../models/cv_builder_model.dart';

/// Same auth-lifecycle pattern as CvProvider / ApplicationProvider:
/// subscribes to the user's generated CVs on sign-in, tears down and
/// clears local state on sign-out.
class CvBuilderProvider extends ChangeNotifier {
  CvBuilderProvider({CvBuilderRepository? repository})
      : _repository = repository ?? CvBuilderRepository();

  final CvBuilderRepository _repository;

  String? _uid;
  List<CvBuilderModel> _cvs = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  StreamSubscription<List<CvBuilderModel>>? _subscription;

  List<CvBuilderModel> get cvs => List.unmodifiable(_cvs);
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  CvBuilderModel? byId(String id) {
    for (final cv in _cvs) {
      if (cv.id == id) return cv;
    }
    return null;
  }

  void updateAuth(String? uid) {
    if (_uid == uid) return;
    _uid = uid;

    _subscription?.cancel();
    _subscription = null;
    _cvs = [];
    _error = null;

    if (uid == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _subscribe(uid);
  }

  /// Re-attaches the Firestore listener if it died. A Firestore snapshot
  /// stream ends after an error and never restarts by itself, so without
  /// this the data would stay frozen. No-op while the stream is healthy.
  void ensureSubscribed() {
    final uid = _uid;
    if (uid == null || _subscription != null) return;
    _subscribe(uid);
  }

  void _subscribe(String uid) {
    _isLoading = true;
    notifyListeners();

    _subscription = _repository.watchAll(uid).listen(
          (cvs) {
        _cvs = cvs;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object err, StackTrace _) {
        debugPrint('[CvBuilderProvider] watchAll error: $err');
        // The stream is dead after an error: drop it so
        // ensureSubscribed() can attach a fresh one.
        _subscription?.cancel();
        _subscription = null;
        _isLoading = false;
        _error = err.toString();
        notifyListeners();
      },
    );
  }

  Future<CvBuilderModel> createDraft({required String templateId}) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Cannot create a CV draft while signed out.');
    }
    return _repository.createDraft(uid, templateId: templateId);
  }

  Future<void> save(CvBuilderModel model) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Cannot save a CV while signed out.');
    }
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.save(uid, model);
      _isSaving = false;
      notifyListeners();
    } catch (err) {
      debugPrint('[CvBuilderProvider] save failed: $err');
      _isSaving = false;
      _error = err.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Cannot delete a CV while signed out.');
    }
    try {
      await _repository.delete(uid, id);
    } catch (err) {
      debugPrint('[CvBuilderProvider] delete failed: $err');
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