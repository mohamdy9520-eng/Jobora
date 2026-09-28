import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/cv_builder_model.dart';
import 'cv_template.dart';
import 'cv_template_utils.dart';

/// عمود واحد، أبيض وأسود تقريبًا، مسافات واسعة وخطوط رفيعة. المهارات
/// واللغات كسطر نصي واحد مفصول بنقط بدل الـ pills.
class MinimalCvTemplate extends CvTemplate {
  const MinimalCvTemplate();

  @override
  String get id => 'minimal';

  @override
  String nameFor({required bool isArabic}) => isArabic ? 'بسيط' : 'Minimal';

  @override
  String descriptionFor({required bool isArabic}) => isArabic
      ? 'أبيض وأسود ومسافات واسعة، شكل هادئ ونظيف.'
      : 'Black & white with generous spacing — calm and clean.';

  static const PdfColor _ink = PdfColor.fromInt(0xFF111827);
  static const PdfColor _muted = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _line = PdfColor.fromInt(0xFFE5E7EB);

  @override
  Future<Uint8List> build(CvBuilderModel model, {required bool isArabic}) async {
    final f = await CvPdfFonts.load();
    final doc = pw.Document();
    final dir = isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr;
    final align = isArabic ? pw.TextAlign.right : pw.TextAlign.left;

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 56, vertical: 50),
          textDirection: dir,
          theme: pw.ThemeData.withFont(base: f.regular, bold: f.bold),
        ),
        build: (_) => [
          _header(model, isArabic: isArabic, f: f),
          pw.SizedBox(height: 24),
          if (model.summary.trim().isNotEmpty) ...[
            _title(CvLabels.summary(isArabic), isArabic: isArabic, f: f),
            pw.Text(
              model.summary.trim(),
              textAlign: align,
              style: pw.TextStyle(font: f.regular, fontSize: 10.5, lineSpacing: 3.5, color: _ink),
            ),
            pw.SizedBox(height: 20),
          ],
          if (model.experiences.isNotEmpty) ...[
            _title(CvLabels.experience(isArabic), isArabic: isArabic, f: f),
            for (final exp in model.experiences)
              CvBlocks.experience(exp, isArabic: isArabic, f: f, muted: _muted, titleSize: 11.5),
            pw.SizedBox(height: 10),
          ],
          if (model.education.isNotEmpty) ...[
            _title(CvLabels.education(isArabic), isArabic: isArabic, f: f),
            for (final edu in model.education)
              CvBlocks.education(edu, isArabic: isArabic, f: f, muted: _muted, titleSize: 11.5),
            pw.SizedBox(height: 10),
          ],
          if (model.skills.isNotEmpty) ...[
            _title(CvLabels.skills(isArabic), isArabic: isArabic, f: f),
            pw.Text(
              model.skills.join('  •  '),
              textAlign: align,
              style: pw.TextStyle(font: f.regular, fontSize: 10.5, lineSpacing: 4, color: _ink),
            ),
            pw.SizedBox(height: 20),
          ],
          if (model.languages.isNotEmpty) ...[
            _title(CvLabels.languages(isArabic), isArabic: isArabic, f: f),
            pw.Text(
              model.languages
                  .map((l) => '${l.name} (${CvFormat.levelLabel(l.level, isArabic: isArabic)})')
                  .join('  •  '),
              textAlign: align,
              style: pw.TextStyle(font: f.regular, fontSize: 10.5, lineSpacing: 4, color: _ink),
            ),
            pw.SizedBox(height: 20),
          ],
          if (model.certifications.isNotEmpty) ...[
            _title(CvLabels.certifications(isArabic), isArabic: isArabic, f: f),
            for (final cert in model.certifications)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(
                  cert.date != null
                      ? '${cert.name} — ${cert.issuer} (${cert.date!.year})'
                      : '${cert.name} — ${cert.issuer}',
                  textAlign: align,
                  style: pw.TextStyle(font: f.regular, fontSize: 10.5, color: _ink),
                ),
              ),
            pw.SizedBox(height: 16),
          ],
          if (model.projects.isNotEmpty) ...[
            _title(CvLabels.projects(isArabic), isArabic: isArabic, f: f),
            for (final proj in model.projects)
              CvBlocks.project(proj, isArabic: isArabic, f: f, muted: _muted),
          ],
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _header(
      CvBuilderModel model, {
        required bool isArabic,
        required CvPdfFonts f,
      }) {
    final crossStart =
    isArabic ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start;
    final info = model.personalInfo;
    final contact = CvFormat.contactLines(info);
    return pw.Column(
      crossAxisAlignment: crossStart,
      children: [
        pw.Text(
          info.fullName.trim().isEmpty ? '—' : info.fullName.trim(),
          style: pw.TextStyle(font: f.bold, fontSize: 26, color: _ink),
        ),
        if (info.jobTitle.trim().isNotEmpty) ...[
          pw.SizedBox(height: 3),
          pw.Text(
            info.jobTitle.trim(),
            style: pw.TextStyle(font: f.regular, fontSize: 12, color: _muted),
          ),
        ],
        if (contact.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Text(
            contact.join('   |   '),
            textAlign: isArabic ? pw.TextAlign.right : pw.TextAlign.left,
            style: pw.TextStyle(font: f.regular, fontSize: 9, color: _muted),
          ),
        ],
      ],
    );
  }

  pw.Widget _title(String title, {required bool isArabic, required CvPdfFonts f}) {
    final crossStart =
    isArabic ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start;
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: crossStart,
        children: [
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              font: f.semiBold,
              fontSize: 9.5,
              color: _muted,
              letterSpacing: isArabic ? 0 : 1.4,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Container(height: 0.6, color: _line),
        ],
      ),
    );
  }
}