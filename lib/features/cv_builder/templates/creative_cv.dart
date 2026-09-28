import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/cv_builder_model.dart';
import 'cv_template.dart';
import 'cv_template_utils.dart';

/// بانر ملوّن في الهيدر، وعناوين أقسام بشريط لون صغير، والمهارات على
/// شكل chips ملوّنة. الأنسب للمجالات الإبداعية أكتر من الشركات الكبيرة.
class CreativeCvTemplate extends CvTemplate {
  const CreativeCvTemplate();

  @override
  String get id => 'creative';

  @override
  String nameFor({required bool isArabic}) => isArabic ? 'إبداعي' : 'Creative';

  @override
  String descriptionFor({required bool isArabic}) => isArabic
      ? 'هيدر ملوّن ومهارات على شكل بطاقات، للمجالات الإبداعية.'
      : 'Colored header and skill chips — great for creative roles.';

  static const PdfColor _accent = PdfColor.fromInt(0xFF0F766E);
  static const PdfColor _accentLight = PdfColor.fromInt(0xFFD9F2EF);
  static const PdfColor _ink = PdfColor.fromInt(0xFF1F2937);
  static const PdfColor _muted = PdfColor.fromInt(0xFF5B6472);
  static const PdfColor _bannerMuted = PdfColor.fromInt(0xFFD1F0EC);

  @override
  Future<Uint8List> build(CvBuilderModel model, {required bool isArabic}) async {
    final f = await CvPdfFonts.load();
    final doc = pw.Document();
    final dir = isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr;
    final align = isArabic ? pw.TextAlign.right : pw.TextAlign.left;
    final wrapAlign = isArabic ? pw.WrapAlignment.end : pw.WrapAlignment.start;

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 40),
          textDirection: dir,
          theme: pw.ThemeData.withFont(base: f.regular, bold: f.bold),
        ),
        build: (_) => [
          _banner(model, isArabic: isArabic, f: f),
          pw.SizedBox(height: 18),
          if (model.summary.trim().isNotEmpty) ...[
            _title(CvLabels.summary(isArabic), f: f),
            pw.SizedBox(height: 6),
            pw.Text(
              model.summary.trim(),
              textAlign: align,
              style: pw.TextStyle(font: f.regular, fontSize: 10.5, lineSpacing: 3, color: _ink),
            ),
            pw.SizedBox(height: 16),
          ],
          if (model.experiences.isNotEmpty) ...[
            _title(CvLabels.experience(isArabic), f: f),
            pw.SizedBox(height: 8),
            for (final exp in model.experiences)
              CvBlocks.experience(exp, isArabic: isArabic, f: f, muted: _muted),
            pw.SizedBox(height: 8),
          ],
          if (model.education.isNotEmpty) ...[
            _title(CvLabels.education(isArabic), f: f),
            pw.SizedBox(height: 8),
            for (final edu in model.education)
              CvBlocks.education(edu, isArabic: isArabic, f: f, muted: _muted),
            pw.SizedBox(height: 8),
          ],
          if (model.skills.isNotEmpty) ...[
            _title(CvLabels.skills(isArabic), f: f),
            pw.SizedBox(height: 8),
            pw.Wrap(
              alignment: wrapAlign,
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final skill in model.skills) _chip(skill, f: f),
              ],
            ),
            pw.SizedBox(height: 16),
          ],
          if (model.languages.isNotEmpty) ...[
            _title(CvLabels.languages(isArabic), f: f),
            pw.SizedBox(height: 8),
            pw.Wrap(
              alignment: wrapAlign,
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final lang in model.languages)
                  _chip(
                    '${lang.name} — ${CvFormat.levelLabel(lang.level, isArabic: isArabic)}',
                    f: f,
                  ),
              ],
            ),
            pw.SizedBox(height: 16),
          ],
          if (model.certifications.isNotEmpty) ...[
            _title(CvLabels.certifications(isArabic), f: f),
            pw.SizedBox(height: 8),
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
            _title(CvLabels.projects(isArabic), f: f),
            pw.SizedBox(height: 8),
            for (final proj in model.projects)
              CvBlocks.project(proj, isArabic: isArabic, f: f, muted: _muted),
          ],
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _banner(
      CvBuilderModel model, {
        required bool isArabic,
        required CvPdfFonts f,
      }) {
    final crossStart =
    isArabic ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start;
    final info = model.personalInfo;
    final contact = CvFormat.contactLines(info);

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: pw.BoxDecoration(
        color: _accent,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: crossStart,
        children: [
          pw.Text(
            info.fullName.trim().isEmpty ? '—' : info.fullName.trim(),
            style: pw.TextStyle(font: f.bold, fontSize: 25, color: PdfColors.white),
          ),
          if (info.jobTitle.trim().isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              info.jobTitle.trim(),
              style: pw.TextStyle(font: f.regular, fontSize: 13, color: _bannerMuted),
            ),
          ],
          if (contact.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              contact.join('   •   '),
              textAlign: isArabic ? pw.TextAlign.right : pw.TextAlign.left,
              style: pw.TextStyle(font: f.regular, fontSize: 9.5, color: PdfColors.white),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _title(String title, {required CvPdfFonts f}) {
    // Row بيتعكس تلقائيًا في العربي من الـ textDirection بتاع الصفحة،
    // فالشريط الصغير بيبقى دايمًا في بداية العنوان.
    return pw.Row(
      children: [
        pw.Container(width: 4, height: 14, color: _accent),
        pw.SizedBox(width: 8),
        pw.Text(
          title,
          style: pw.TextStyle(font: f.bold, fontSize: 12.5, color: _accent),
        ),
      ],
    );
  }

  pw.Widget _chip(String text, {required CvPdfFonts f}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: pw.BoxDecoration(
        color: _accentLight,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: f.regular, fontSize: 9.5, color: _accent),
      ),
    );
  }
}