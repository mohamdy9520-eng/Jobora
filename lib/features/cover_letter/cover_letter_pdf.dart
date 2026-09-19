import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CoverLetterPdf {
  /// Uses Cairo (covers Arabic + Latin). Fonts are fetched once from Google
  /// Fonts and cached by `printing`; to work fully offline, bundle a TTF in
  /// assets and load it with rootBundle instead.
  static Future<Uint8List> build(String text, {required bool rtl}) async {
    final regular = await PdfGoogleFonts.cairoRegular();
    final bold = await PdfGoogleFonts.cairoBold();

    final doc = pw.Document();
    final paragraphs = text.split(RegExp(r'\n\s*\n'));

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 56, vertical: 64),
          textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          theme: pw.ThemeData.withFont(base: regular, bold: bold),
        ),
        build: (_) => [
          for (final p in paragraphs)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 14),
              child: pw.Text(
                p.trim(),
                textAlign: rtl ? pw.TextAlign.right : pw.TextAlign.left,
                style: const pw.TextStyle(fontSize: 12, lineSpacing: 4),
              ),
            ),
        ],
      ),
    );
    return doc.save();
  }
}