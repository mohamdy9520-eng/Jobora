import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show compute, debugPrint;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

import '../../../core/models/cv_model.dart';

enum CvUnavailableReason { unsupportedType, download, unreadable }

/// Thrown when the CV's text can't be obtained. The setup screen then asks
/// the user to paste a short summary of their experience instead.
class CvTextUnavailable implements Exception {
  const CvTextUnavailable(this.reason);

  final CvUnavailableReason reason;

  @override
  String toString() => 'CvTextUnavailable($reason)';
}

/// Runs in a background isolate (via `compute`), so it must be top-level.
String _extractPdfText(Uint8List bytes) {
  final doc = sf.PdfDocument(inputBytes: bytes);
  try {
    return sf.PdfTextExtractor(doc).extractText();
  } finally {
    doc.dispose();
  }
}

/// Downloads a CV from its stored URL and extracts its text on the device.
/// Only PDFs are supported (Word files and images have no reliable
/// on-device extraction), scanned PDFs without a text layer come back
/// nearly empty and are reported as unreadable.
class CvTextExtractor {
  CvTextExtractor({Dio? dio})
      : _dio = dio ??
      Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
      ));

  final Dio _dio;

  static const maxBytes = 8 * 1024 * 1024;
  static const minChars = 150;
  static const maxChars = 6000;

  Future<String> extract(CvModel cv) async {
    if (cv.fileType != CvFileType.pdf) {
      throw const CvTextUnavailable(CvUnavailableReason.unsupportedType);
    }
    if (cv.downloadUrl.isEmpty) {
      throw const CvTextUnavailable(CvUnavailableReason.download);
    }

    final Uint8List bytes;
    try {
      final response = await _dio.get<List<int>>(
        cv.downloadUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      final data = response.data;
      if (data == null || data.isEmpty || data.length > maxBytes) {
        throw const CvTextUnavailable(CvUnavailableReason.download);
      }
      bytes = Uint8List.fromList(data);
    } on CvTextUnavailable {
      rethrow;
    } catch (e) {
      debugPrint('[CvTextExtractor] download failed: $e');
      throw const CvTextUnavailable(CvUnavailableReason.download);
    }

    String raw;
    try {
      raw = await compute(_extractPdfText, bytes);
    } catch (e) {
      debugPrint('[CvTextExtractor] parse failed: $e');
      throw const CvTextUnavailable(CvUnavailableReason.unreadable);
    }

    final text = raw.replaceAll(RegExp(r'[ \t]+'), ' ').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
    if (text.length < minChars) {
      throw const CvTextUnavailable(CvUnavailableReason.unreadable);
    }
    return text.length <= maxChars ? text : text.substring(0, maxChars);
  }
}