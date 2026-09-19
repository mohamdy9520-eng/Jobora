import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/models/cv_model.dart';
import '../../../core/repostories/cv_repository.dart';

/// Real Firestore/Storage-backed provider for the user's CVs. Same
/// auth-lifecycle pattern as ApplicationProvider: subscribes on sign-in,
/// tears down + clears local state on sign-out.
class CvProvider extends ChangeNotifier {
  CvProvider({CvRepository? repository})
      : _repository = repository ?? CvRepository();

  final CvRepository _repository;

  String? _uid;
  List<CvModel> _cvs = [];
  bool _isLoading = false;
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _error;
  StreamSubscription<List<CvModel>>? _subscription;

  List<CvModel> get cvs => List.unmodifiable(_cvs);
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String? get error => _error;

  CvModel? byId(String id) {
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
        debugPrint('[CvProvider] watchAll error: $err');
        _isLoading = false;
        _error = err.toString();
        notifyListeners();
      },
    );
  }

  Future<CvModel> upload(File file, String fileName) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Cannot upload a CV while signed out.');
    }
    _isUploading = true;
    _uploadProgress = 0;
    _error = null;
    notifyListeners();
    try {
      final cv = await _repository.upload(
        uid,
        file,
        fileName,
        onProgress: (p) {
          _uploadProgress = p;
          notifyListeners();
        },
      );
      _isUploading = false;
      notifyListeners();
      return cv;
    } catch (err, st) {
      debugPrint('[CvProvider] upload failed: $err\n$st');
      _isUploading = false;
      _error = err.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> delete(CvModel cv) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Cannot delete a CV while signed out.');
    }
    try {
      await _repository.delete(uid, cv);
    } catch (err) {
      debugPrint('[CvProvider] delete failed: $err');
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