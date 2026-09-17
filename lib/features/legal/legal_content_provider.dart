import 'package:flutter/material.dart';
import 'legal_content_model.dart';
import 'legal_content_repository.dart';

class LegalContentProvider extends ChangeNotifier {
  final String docId;
  final _repository = LegalContentRepository();

  LegalContentModel? _content;
  bool _isLoading = true;
  String? _error;

  LegalContentProvider(this.docId) {
    load();
  }

  LegalContentModel? get content => _content;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _content = await _repository.fetch(docId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}