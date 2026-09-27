import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/cv_builder_model.dart';
import 'cv_template.dart';

/// Single-column, text-first layout with clear section headers and no
/// graphics/icons in the PDF itself — this is the safest layout for
/// ATS (Applicant Tracking System) parsers, which is why it's the
/// default/first template.
class ClassicCvTemplate extends CvTemplate {
  const ClassicCvTemplate();

  @override
  String get id => 'classic_ats';

  @override
  String nameFor({required bool isArabic}) =>
      isArabic ? 'كلاسيكي (متوافق مع الـ ATS)' : 'Classic (ATS-friendly)';

  @override
  String descriptionFor({required bool isArabic}) => isArabic
      ? 'تصميم بسيط وواضح، الأنسب لأنظمة الفرز الآلي والشركات الكبيرة.'
      : 'Clean and simple — the safest choice for ATS systems and corporate applications.';

  static const PdfColor _accent = PdfColor.fromInt(0xFF1E3A5F);
  static const PdfColor _muted = PdfColor.fromInt(0xFF5B6472);

  @override
  Future<Uint8List> build(CvBuilderModel model, {required bool isArabic}) async {
    final regular = await PdfGoogleFonts.cairoRegular();
    final bold = await PdfGoogleFonts.cairoBold();
    final semiBold = await PdfGoogleFonts.cairoSemiBold();

    final doc = pw.Document();
    final dir = isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr;
    final align = isArabic ? pw.TextAlign.right : pw.TextAlign.left;
    final crossStart =
    isArabic ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start;

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 48),
          // Sets the ambient Directionality for everything inside this
          // page — nested Row/Wrap widgets pick their direction up from
          // this automatically, so they must NOT pass their own
          // `textDirection:` (pw.Row/pw.Flex don't expose that param).
          textDirection: dir,
          theme: pw.ThemeData.withFont(base: regular, bold: bold),
        ),
        build: (_) => [
          _header(model, isArabic: isArabic, bold: bold, regular: regular, align: align, crossStart: crossStart),
          pw.SizedBox(height: 18),
          if (model.summary.trim().isNotEmpty) ...[
            _sectionTitle(isArabic ? 'ملخص احترافي' : 'Professional Summary', semiBold: semiBold, align: align),
            pw.SizedBox(height: 6),
            pw.Text(model.summary.trim(),
                textAlign: align, style: pw.TextStyle(font: regular, fontSize: 10.5, lineSpacing: 3)),
            pw.SizedBox(height: 16),
          ],
          if (model.experiences.isNotEmpty) ...[
            _sectionTitle(isArabic ? 'الخبرة العملية' : 'Work Experience', semiBold: semiBold, align: align),
            pw.SizedBox(height: 8),
            for (final exp in model.experiences)
              _experienceBlock(exp, isArabic: isArabic, bold: bold, regular: regular, align: align, crossStart: crossStart),
            pw.SizedBox(height: 8),
          ],
          if (model.education.isNotEmpty) ...[
            _sectionTitle(isArabic ? 'التعليم' : 'Education', semiBold: semiBold, align: align),
            pw.SizedBox(height: 8),
            for (final edu in model.education)
              _educationBlock(edu, isArabic: isArabic, bold: bold, regular: regular, align: align, crossStart: crossStart),
            pw.SizedBox(height: 8),
          ],
          if (model.skills.isNotEmpty) ...[
            _sectionTitle(isArabic ? 'المهارات' : 'Skills', semiBold: semiBold, align: align),
            pw.SizedBox(height: 6),
            pw.Wrap(
              alignment: isArabic ? pw.WrapAlignment.end : pw.WrapAlignment.start,
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final skill in model.skills) _pill(skill, regular: regular),
              ],
            ),
            pw.SizedBox(height: 16),
          ],
          if (model.languages.isNotEmpty) ...[
            _sectionTitle(isArabic ? 'اللغات' : 'Languages', semiBold: semiBold, align: align),
            pw.SizedBox(height: 6),
            pw.Wrap(
              alignment: isArabic ? pw.WrapAlignment.end : pw.WrapAlignment.start,
              spacing: 14,
              runSpacing: 6,
              children: [
                for (final lang in model.languages)
                  pw.Text(
                    '${lang.name} — ${_levelLabel(lang.level, isArabic: isArabic)}',
                    style: pw.TextStyle(font: regular, fontSize: 10.5),
                  ),
              ],
            ),
            pw.SizedBox(height: 16),
          ],
          if (model.certifications.isNotEmpty) ...[
            _sectionTitle(isArabic ? 'الشهادات' : 'Certifications', semiBold: semiBold, align: align),
            pw.SizedBox(height: 6),
            for (final cert in model.certifications)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(
                  cert.date != null
                      ? '${cert.name} — ${cert.issuer} (${cert.date!.year})'
                      : '${cert.name} — ${cert.issuer}',
                  textAlign: align,
                  style: pw.TextStyle(font: regular, fontSize: 10.5),
                ),
              ),
            pw.SizedBox(height: 16),
          ],
          if (model.projects.isNotEmpty) ...[
            _sectionTitle(isArabic ? 'المشاريع' : 'Projects', semiBold: semiBold, align: align),
            pw.SizedBox(height: 6),
            for (final proj in model.projects)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Column(
                  crossAxisAlignment: crossStart,
                  children: [
                    pw.Text(proj.name, style: pw.TextStyle(font: bold, fontSize: 11)),
                    if ((proj.description ?? '').trim().isNotEmpty)
                      pw.Text(proj.description!.trim(),
                          textAlign: align, style: pw.TextStyle(font: regular, fontSize: 10, color: _muted)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _header(
      CvBuilderModel model, {
        required bool isArabic,
        required pw.Font bold,
        required pw.Font regular,
        required pw.TextAlign align,
        required pw.CrossAxisAlignment crossStart,
      }) {
    final info = model.personalInfo;
    final contactParts = [
      if (info.email.trim().isNotEmpty) info.email.trim(),
      if (info.phone.trim().isNotEmpty) info.phone.trim(),
      if ((info.location ?? '').trim().isNotEmpty) info.location!.trim(),
      if ((info.linkedinUrl ?? '').trim().isNotEmpty) info.linkedinUrl!.trim(),
    ];

    return pw.Column(
      crossAxisAlignment: crossStart,
      children: [
        pw.Text(info.fullName.trim().isEmpty ? '—' : info.fullName.trim(),
            style: pw.TextStyle(font: bold, fontSize: 22, color: _accent)),
        if (info.jobTitle.trim().isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Text(info.jobTitle.trim(),
              style: pw.TextStyle(font: regular, fontSize: 12.5, color: _muted)),
        ],
        if (contactParts.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Text(contactParts.join('   •   '),
              textAlign: align,
              style: pw.TextStyle(font: regular, fontSize: 9.5, color: _muted)),
        ],
        pw.SizedBox(height: 10),
        pw.Container(height: 1.2, color: _accent),
      ],
    );
  }

  pw.Widget _sectionTitle(String title, {required pw.Font semiBold, required pw.TextAlign align}) {
    return pw.Text(
      title.toUpperCase(),
      textAlign: align,
      style: pw.TextStyle(font: semiBold, fontSize: 11.5, color: _accent, letterSpacing: 0.6),
    );
  }

  pw.Widget _experienceBlock(
      ExperienceEntry exp, {
        required bool isArabic,
        required pw.Font bold,
        required pw.Font regular,
        required pw.TextAlign align,
        required pw.CrossAxisAlignment crossStart,
      }) {
    final range = _dateRange(exp.startDate, exp.endDate, exp.isCurrent, isArabic: isArabic);
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: crossStart,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('${exp.jobTitle} — ${exp.company}',
                  style: pw.TextStyle(font: bold, fontSize: 11)),
              pw.Text(range, style: pw.TextStyle(font: regular, fontSize: 9.5, color: _muted)),
            ],
          ),
          if ((exp.location ?? '').trim().isNotEmpty)
            pw.Text(exp.location!.trim(),
                style: pw.TextStyle(font: regular, fontSize: 9.5, color: _muted)),
          if (exp.bullets.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            for (final bullet in exp.bullets)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('•  ', style: pw.TextStyle(font: regular, fontSize: 10)),
                    pw.Expanded(
                      child: pw.Text(bullet,
                          textAlign: align, style: pw.TextStyle(font: regular, fontSize: 10, lineSpacing: 2)),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  pw.Widget _educationBlock(
      EducationEntry edu, {
        required bool isArabic,
        required pw.Font bold,
        required pw.Font regular,
        required pw.TextAlign align,
        required pw.CrossAxisAlignment crossStart,
      }) {
    final range = _dateRange(edu.startDate, edu.endDate, false, isArabic: isArabic);
    final degreeLine = (edu.fieldOfStudy ?? '').trim().isEmpty
        ? edu.degree
        : '${edu.degree} — ${edu.fieldOfStudy!.trim()}';

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: crossStart,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(edu.institution, style: pw.TextStyle(font: bold, fontSize: 11)),
              if (range.isNotEmpty)
                pw.Text(range, style: pw.TextStyle(font: regular, fontSize: 9.5, color: _muted)),
            ],
          ),
          pw.Text(degreeLine, style: pw.TextStyle(font: regular, fontSize: 10)),
          if ((edu.grade ?? '').trim().isNotEmpty)
            pw.Text(edu.grade!.trim(), style: pw.TextStyle(font: regular, fontSize: 9.5, color: _muted)),
        ],
      ),
    );
  }

  pw.Widget _pill(String text, {required pw.Font regular}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _accent, width: 0.7),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(text, style: pw.TextStyle(font: regular, fontSize: 9.5, color: _accent)),
    );
  }

  String _levelLabel(LanguageLevel level, {required bool isArabic}) {
    switch (level) {
      case LanguageLevel.basic:
        return isArabic ? 'أساسي' : 'Basic';
      case LanguageLevel.conversational:
        return isArabic ? 'محادثة' : 'Conversational';
      case LanguageLevel.fluent:
        return isArabic ? 'طلاقة' : 'Fluent';
      case LanguageLevel.native:
        return isArabic ? 'اللغة الأم' : 'Native';
    }
  }

  String _dateRange(DateTime? start, DateTime? end, bool isCurrent, {required bool isArabic}) {
    if (start == null) return '';
    final startLabel = _monthYear(start, isArabic: isArabic);
    final endLabel = isCurrent
        ? (isArabic ? 'حتى الآن' : 'Present')
        : (end != null ? _monthYear(end, isArabic: isArabic) : '');
    if (endLabel.isEmpty) return startLabel;
    return '$startLabel – $endLabel';
  }

  String _monthYear(DateTime date, {required bool isArabic}) {
    const monthsEn = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const monthsAr = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    final month = isArabic ? monthsAr[date.month - 1] : monthsEn[date.month - 1];
    return '$month ${date.year}';
  }
}