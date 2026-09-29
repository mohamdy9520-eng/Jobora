import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../../../core/models/cv_model.dart';
import '../../../core/repostories/cv_repository.dart';
import '../../cv_builder/services/cv_text_extractor.dart';

/// Real Firestore/Storage-backed provider for the user's CVs. Same
/// auth-lifecycle pattern as ApplicationProvider: subscribes on sign-in,
/// tears down + clears local state on sign-out.
///
/// كمان بيفحص أحدث CV مرفوع (نص الـ PDF محليًا، بدون أي API) ويحتفظ
/// بالنتيجة في الذاكرة حسب id الملف.
class CvProvider extends ChangeNotifier {
  CvProvider({CvRepository? repository})
      : _repository = repository ?? CvRepository();

  static const _maxDownloadBytes = 10 * 1024 * 1024; // 10 MB

  final CvRepository _repository;

  String? _uid;
  List<CvModel> _cvs = [];
  bool _isLoading = false;
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _error;
  StreamSubscription<List<CvModel>>? _subscription;

  final Map<String, CvFileAnalysis> _analyses = {};
  final Set<String> _analysisInFlight = {};

  List<CvModel> get cvs => List.unmodifiable(_cvs);
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String? get error => _error;

  /// null = لسه بيتفحص (أو فشل التحميل وهيتعاد لاحقًا).
  CvFileAnalysis? analysisFor(String cvId) => _analyses[cvId];

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
    _analyses.clear();
    _analysisInFlight.clear();

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
        // watchAll مرتبة بـ uploadedAt تنازلي، فـ first = الأحدث.
        if (cvs.isNotEmpty) unawaited(_analyze(cvs.first));
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

      // عندنا الملف محليًا، فنفحصه منه بدل ما نحمّله تاني.
      Uint8List? bytes;
      if (cv.fileType == CvFileType.pdf) {
        try {
          bytes = await file.readAsBytes();
        } catch (_) {}
      }
      unawaited(_analyze(cv, bytes: bytes));
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
      _analyses.remove(cv.id);
    } catch (err) {
      debugPrint('[CvProvider] delete failed: $err');
      _error = err.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _analyze(CvModel cv, {Uint8List? bytes}) async {
    if (_analyses.containsKey(cv.id) || !_analysisInFlight.add(cv.id)) return;
    final uidAtStart = _uid;
    try {
      final CvFileAnalysis result;
      switch (cv.fileType) {
        case CvFileType.pdf:
          final data = bytes ??
              await FirebaseStorage.instance
                  .ref(cv.storagePath)
                  .getData(_maxDownloadBytes);
          if (data == null) return; // هيتعاد مع أول تحديث للـ stream
          result = await CvTextExtractor.analyzePdf(data);
        case CvFileType.image:
          result = CvFileAnalysis.unreadable;
        case CvFileType.word:
        case CvFileType.other:
          result = CvFileAnalysis.unsupported;
      }
      if (_uid != uidAtStart) return; // المستخدم عمل sign-out أثناء الفحص
      _analyses[cv.id] = result;
      notifyListeners();
    } catch (e) {
      // غالبًا شبكة. منخزنش حاجة عشان يتعاد بعدين.
      debugPrint('[CvProvider] analyze failed: $e');
    } finally {
      _analysisInFlight.remove(cv.id);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}