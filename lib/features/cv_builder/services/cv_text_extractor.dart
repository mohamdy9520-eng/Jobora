import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../home/cv_completeness_analyzer.dart';

enum CvFileAnalysisStatus {
  /// النص اتقرا واتفحص، [CvFileAnalysis.input] موجود.
  ready,

  /// مفيش نص قابل للقراءة (PDF ممسوح ضوئيًا / صورة / ملف محمي).
  unreadable,

  /// نوع ملف مش مدعوم دلوقتي (مثلاً Word). مفيش نصيحة بتظهر.
  unsupported,
}

class CvFileAnalysis {
  const CvFileAnalysis._(this.status, this.input);

  factory CvFileAnalysis.ready(CvCompletenessInput input) =>
      CvFileAnalysis._(CvFileAnalysisStatus.ready, input);

  static const unreadable =
  CvFileAnalysis._(CvFileAnalysisStatus.unreadable, null);
  static const unsupported =
  CvFileAnalysis._(CvFileAnalysisStatus.unsupported, null);

  final CvFileAnalysisStatus status;
  final CvCompletenessInput? input;
}

// Top-level عشان compute() يشغلها في Isolate ومتقفلش الـ UI.
String _extractPdfText(Uint8List bytes) {
  final document = PdfDocument(inputBytes: bytes);
  try {
    return PdfTextExtractor(document).extractText();
  } finally {
    document.dispose();
  }
}

class CvTextExtractor {
  CvTextExtractor._();

  /// أقل عدد حروف (عربي/إنجليزي) عشان نعتبر إن الملف فيه نص حقيقي.
  static const _minLetters = 40;
  static final _letters = RegExp(r'[A-Za-z\u0600-\u06FF]');

  static Future<CvFileAnalysis> analyzePdf(Uint8List bytes) async {
    try {
      final text = await compute(_extractPdfText, bytes);
      if (_letters.allMatches(text).length < _minLetters) {
        return CvFileAnalysis.unreadable; // سكان/صورة
      }
      return CvFileAnalysis.ready(CvCompletenessInput.fromText(text));
    } catch (e) {
      // ملف تالف أو محمي بباسورد: نفس معاملة الملف غير المقروء.
      debugPrint('[CvTextExtractor] pdf parse failed: $e');
      return CvFileAnalysis.unreadable;
    }
  }
}