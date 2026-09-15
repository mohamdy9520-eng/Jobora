import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../core/models/interview_model.dart';
import '../../../core/repostories/interviews_repository.dart';

/// Real Firestore-backed provider. Subscribes to
/// InterviewsRepository.watchAll(uid) whenever a user signs in, and
/// tears the subscription down + clears local state on sign-out.
class InterviewProvider extends ChangeNotifier {
  InterviewProvider({InterviewsRepository? repository})
      : _repository = repository ?? InterviewsRepository();

  final InterviewsRepository _repository;

  String? _uid;
  List<InterviewModel> _interviews = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<InterviewModel>>? _subscription;

  List<InterviewModel> get interviews => List.unmodifiable(_interviews);
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<InterviewModel> get upcoming {
    final list = _interviews.where((i) => i.isUpcoming).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return list;
  }

  InterviewModel? byId(String id) {
    for (final interview in _interviews) {
      if (interview.id == id) return interview;
    }
    return null;
  }

  void updateAuth(String? uid) {
    if (_uid == uid) return;
    _uid = uid;

    _subscription?.cancel();
    _subscription = null;
    _interviews = [];
    _error = null;

    if (uid == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _subscription = _repository.watchAll(uid).listen(
          (interviews) {
        _interviews = interviews;
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

  /// Creates [interview] in Firestore. Any id on [interview] is ignored —
  /// the repository always assigns the real Firestore id. Returns the
  /// saved model so the caller can navigate using the real id.
  Future<InterviewModel> create(InterviewModel interview) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Cannot create an interview while signed out.');
    }
    try {
      return await _repository.create(uid, interview);
    } catch (err) {
      _error = err.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> update(InterviewModel interview) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Cannot update an interview while signed out.');
    }
    try {
      await _repository.update(uid, interview);
    } catch (err) {
      _error = err.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Cannot delete an interview while signed out.');
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