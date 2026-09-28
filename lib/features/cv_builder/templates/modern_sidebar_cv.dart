import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/cv_builder_model.dart';
import 'cv_template.dart';
import 'cv_template_utils.dart';

/// شريط جانبي ملوّن (بيانات التواصل + المهارات + اللغات + الشهادات)
/// وعمود رئيسي للاسم والملخص والخبرة والتعليم والمشاريع.
///
/// الشريط بيترسم كـ background لكل صفحة، ومحتواه بيظهر في الصفحة الأولى
/// بس، والعمود الرئيسي بيتكمّل على صفحات تانية عادي (MultiPage). في
/// العربي الشريط بيبقى على اليمين.
class ModernSidebarCvTemplate extends CvTemplate {
  const ModernSidebarCvTemplate();

  @override
  String get id => 'modern_sidebar';

  @override
  String nameFor({required bool isArabic}) =>
      isArabic ? 'عصري بشريط جانبي' : 'Modern Sidebar';

  @override
  String descriptionFor({required bool isArabic}) => isArabic
      ? 'شريط جانبي ملوّن للبيانات والمهارات، وعمود رئيسي للخبرة.'
      : 'Colored sidebar for contact & skills, main column for experience.';

  static const PdfColor _sidebarColor = PdfColor.fromInt(0xFF1F2A44);
  static const PdfColor _accent = PdfColor.fromInt(0xFF2A9D8F);
  static const PdfColor _muted = PdfColor.fromInt(0xFF5B6472);
  static const PdfColor _line = PdfColor.fromInt(0xFFD5DAE1);
  static const PdfColor _sideText = PdfColors.white;
  static const PdfColor _sideMuted = PdfColor.fromInt(0xFFCBD5E1);

  static const double _sidebarWidth = 190;
  static const double _gap = 26;
  static const double _outer = 34;

  @override
  Future<Uint8List> build(CvBuilderModel model, {required bool isArabic}) async {
    final f = await CvPdfFonts.load();
    final doc = pw.Document();
    final dir = isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr;
    final align = isArabic ? pw.TextAlign.right : pw.TextAlign.left;

    // الهامش على ناحية الشريط بيساوي عرضه + مسافة، عشان العمود
    // الرئيسي ميدخلش تحت الشريط.
    final margin = isArabic
        ? const pw.EdgeInsets.fromLTRB(_outer, _outer, _sidebarWidth + _gap, _outer)
        : const pw.EdgeInsets.fromLTRB(_sidebarWidth + _gap, _outer, _outer, _outer);

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: margin,
          textDirection: dir,
          theme: pw.ThemeData.withFont(base: f.regular, bold: f.bold),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Stack(
              fit: pw.StackFit.expand,
              children: [
                pw.Positioned(
                  left: isArabic ? null : 0,
                  right: isArabic ? 0 : null,
                  top: 0,
                  bottom: 0,
                  child: pw.Container(
                    width: _sidebarWidth,
                    color: _sidebarColor,
                    padding: const pw.EdgeInsets.fromLTRB(20, 40, 20, 30),
                    child: context.pageNumber == 1
                        ? _sidebarContent(model, isArabic: isArabic, f: f)
                        : pw.SizedBox(),
                  ),
                ),
              ],
            ),
          ),
        ),
        build: (_) => [
          _mainHeader(model, isArabic: isArabic, f: f),
          pw.SizedBox(height: 18),
          if (model.summary.trim().isNotEmpty) ...[
            _mainTitle(CvLabels.summary(isArabic), isArabic: isArabic, f: f),
            pw.SizedBox(height: 6),
            pw.Text(
              model.summary.trim(),
              textAlign: align,
              style: pw.TextStyle(font: f.regular, fontSize: 10.5, lineSpacing: 3),
            ),
            pw.SizedBox(height: 16),
          ],
          if (model.experiences.isNotEmpty) ...[
            _mainTitle(CvLabels.experience(isArabic), isArabic: isArabic, f: f),
            pw.SizedBox(height: 8),
            for (final exp in model.experiences)
              CvBlocks.experience(exp, isArabic: isArabic, f: f, muted: _muted),
            pw.SizedBox(height: 8),
          ],
          if (model.education.isNotEmpty) ...[
            _mainTitle(CvLabels.education(isArabic), isArabic: isArabic, f: f),
            pw.SizedBox(height: 8),
            for (final edu in model.education)
              CvBlocks.education(edu, isArabic: isArabic, f: f, muted: _muted),
            pw.SizedBox(height: 8),
          ],
          if (model.projects.isNotEmpty) ...[
            _mainTitle(CvLabels.projects(isArabic), isArabic: isArabic, f: f),
            pw.SizedBox(height: 8),
            for (final proj in model.projects)
              CvBlocks.project(proj, isArabic: isArabic, f: f, muted: _muted),
          ],
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _mainHeader(
      CvBuilderModel model, {
        required bool isArabic,
        required CvPdfFonts f,
      }) {
    final crossStart =
    isArabic ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start;
    final info = model.personalInfo;
    return pw.Column(
      crossAxisAlignment: crossStart,
      children: [
        pw.Text(
          info.fullName.trim().isEmpty ? '—' : info.fullName.trim(),
          style: pw.TextStyle(font: f.bold, fontSize: 24, color: _sidebarColor),
        ),
        if (info.jobTitle.trim().isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            info.jobTitle.trim(),
            style: pw.TextStyle(font: f.regular, fontSize: 13, color: _accent),
          ),
        ],
      ],
    );
  }

  pw.Widget _mainTitle(
      String title, {
        required bool isArabic,
        required CvPdfFonts f,
      }) {
    final crossStart =
    isArabic ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start;
    return pw.Column(
      crossAxisAlignment: crossStart,
      children: [
        pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            font: f.semiBold,
            fontSize: 12,
            color: _accent,
            letterSpacing: isArabic ? 0 : 0.8,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Container(height: 1, color: _line),
      ],
    );
  }

  pw.Widget _sideTitle(String title, {required bool isArabic, required CvPdfFonts f}) {
    return pw.Text(
      title.toUpperCase(),
      style: pw.TextStyle(
        font: f.semiBold,
        fontSize: 10.5,
        color: _sideText,
        letterSpacing: isArabic ? 0 : 0.8,
      ),
    );
  }

  pw.Widget _sideLine(String text, {required bool isArabic, required CvPdfFonts f, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Text(
        text,
        textAlign: isArabic ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(font: f.regular, fontSize: 8.5, color: color ?? _sideMuted),
      ),
    );
  }

  pw.Widget _sidebarContent(
      CvBuilderModel model, {
        required bool isArabic,
        required CvPdfFonts f,
      }) {
    final crossStart =
    isArabic ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start;
    final contact = CvFormat.contactLines(model.personalInfo, shorten: true);

    return pw.Column(
      crossAxisAlignment: crossStart,
      mainAxisAlignment: pw.MainAxisAlignment.start,
      children: [
        if (contact.isNotEmpty) ...[
          _sideTitle(CvLabels.contact(isArabic), isArabic: isArabic, f: f),
          pw.SizedBox(height: 6),
          for (final line in contact) _sideLine(line, isArabic: isArabic, f: f),
          pw.SizedBox(height: 14),
        ],
        if (model.skills.isNotEmpty) ...[
          _sideTitle(CvLabels.skills(isArabic), isArabic: isArabic, f: f),
          pw.SizedBox(height: 6),
          for (final skill in model.skills)
            _sideLine(skill, isArabic: isArabic, f: f, color: _sideText),
          pw.SizedBox(height: 14),
        ],
        if (model.languages.isNotEmpty) ...[
          _sideTitle(CvLabels.languages(isArabic), isArabic: isArabic, f: f),
          pw.SizedBox(height: 6),
          for (final lang in model.languages)
            _sideLine(
              '${lang.name} — ${CvFormat.levelLabel(lang.level, isArabic: isArabic)}',
              isArabic: isArabic,
              f: f,
            ),
          pw.SizedBox(height: 14),
        ],
        if (model.certifications.isNotEmpty) ...[
          _sideTitle(CvLabels.certifications(isArabic), isArabic: isArabic, f: f),
          pw.SizedBox(height: 6),
          for (final cert in model.certifications)
            _sideLine(
              cert.issuer.trim().isEmpty ? cert.name : '${cert.name} — ${cert.issuer}',
              isArabic: isArabic,
              f: f,
            ),
        ],
      ],
    );
  }
}