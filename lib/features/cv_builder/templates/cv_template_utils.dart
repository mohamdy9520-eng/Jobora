import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/cv_builder_model.dart';

/// الخطوط المستخدمة في كل الـ templates الجديدة. مكان واحد بس للتحكم
/// فيها: لو عايز تستخدم خطوط جوه الـ assets بدل التنزيل من النت،
/// عدّل دالة load() دي بس.
class CvPdfFonts {
  const CvPdfFonts({
    required this.regular,
    required this.bold,
    required this.semiBold,
  });

  final pw.Font regular;
  final pw.Font bold;
  final pw.Font semiBold;

  static Future<CvPdfFonts> load() async {
    final regular = await PdfGoogleFonts.cairoRegular();
    final bold = await PdfGoogleFonts.cairoBold();
    final semiBold = await PdfGoogleFonts.cairoSemiBold();
    return CvPdfFonts(regular: regular, bold: bold, semiBold: semiBold);
  }
}

class CvLabels {
  CvLabels._();

  static String contact(bool isArabic) => isArabic ? 'التواصل' : 'Contact';
  static String summary(bool isArabic) =>
      isArabic ? 'ملخص احترافي' : 'Professional Summary';
  static String experience(bool isArabic) =>
      isArabic ? 'الخبرة العملية' : 'Work Experience';
  static String education(bool isArabic) => isArabic ? 'التعليم' : 'Education';
  static String skills(bool isArabic) => isArabic ? 'المهارات' : 'Skills';
  static String languages(bool isArabic) => isArabic ? 'اللغات' : 'Languages';
  static String certifications(bool isArabic) =>
      isArabic ? 'الشهادات' : 'Certifications';
  static String projects(bool isArabic) => isArabic ? 'المشاريع' : 'Projects';
}

class CvFormat {
  CvFormat._();

  static String levelLabel(LanguageLevel level, {required bool isArabic}) {
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

  static String monthYear(DateTime date, {required bool isArabic}) {
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

  static String dateRange(
      DateTime? start,
      DateTime? end,
      bool isCurrent, {
        required bool isArabic,
      }) {
    if (start == null) return '';
    final startLabel = monthYear(start, isArabic: isArabic);
    final endLabel = isCurrent
        ? (isArabic ? 'حتى الآن' : 'Present')
        : (end != null ? monthYear(end, isArabic: isArabic) : '');
    if (endLabel.isEmpty) return startLabel;
    return '$startLabel – $endLabel';
  }

  /// يشيل https:// و www. والـ / الأخيرة عشان اللينكات الطويلة
  /// تكون أقصر (مهم في الشريط الجانبي الضيق).
  static String shortUrl(String url) {
    return url
        .trim()
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceFirst(RegExp(r'^www\.'), '')
        .replaceFirst(RegExp(r'/$'), '');
  }

  static List<String> contactLines(PersonalInfoData info, {bool shorten = false}) {
    String url(String s) => shorten ? shortUrl(s) : s.trim();
    return [
      if (info.email.trim().isNotEmpty) info.email.trim(),
      if (info.phone.trim().isNotEmpty) info.phone.trim(),
      if ((info.location ?? '').trim().isNotEmpty) info.location!.trim(),
      if ((info.linkedinUrl ?? '').trim().isNotEmpty) url(info.linkedinUrl!),
      if ((info.websiteUrl ?? '').trim().isNotEmpty) url(info.websiteUrl!),
    ];
  }
}

/// Blocks مشتركة (خبرة/تعليم/مشروع) بنفس الهيكل في كل الـ templates،
/// والاختلاف بس في الألوان والأحجام.
class CvBlocks {
  CvBlocks._();

  static pw.Widget experience(
      ExperienceEntry exp, {
        required bool isArabic,
        required CvPdfFonts f,
        required PdfColor muted,
        double titleSize = 11,
      }) {
    final align = isArabic ? pw.TextAlign.right : pw.TextAlign.left;
    final crossStart =
    isArabic ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start;
    final range = CvFormat.dateRange(
      exp.startDate,
      exp.endDate,
      exp.isCurrent,
      isArabic: isArabic,
    );

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: crossStart,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  '${exp.jobTitle} — ${exp.company}',
                  textAlign: align,
                  style: pw.TextStyle(font: f.bold, fontSize: titleSize),
                ),
              ),
              if (range.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                  child: pw.Text(
                    range,
                    style: pw.TextStyle(font: f.regular, fontSize: 9.5, color: muted),
                  ),
                ),
            ],
          ),
          if ((exp.location ?? '').trim().isNotEmpty)
            pw.Text(
              exp.location!.trim(),
              textAlign: align,
              style: pw.TextStyle(font: f.regular, fontSize: 9.5, color: muted),
            ),
          if (exp.bullets.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            for (final bullet in exp.bullets)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('•  ', style: pw.TextStyle(font: f.regular, fontSize: 10)),
                    pw.Expanded(
                      child: pw.Text(
                        bullet,
                        textAlign: align,
                        style: pw.TextStyle(font: f.regular, fontSize: 10, lineSpacing: 2),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  static pw.Widget education(
      EducationEntry edu, {
        required bool isArabic,
        required CvPdfFonts f,
        required PdfColor muted,
        double titleSize = 11,
      }) {
    final align = isArabic ? pw.TextAlign.right : pw.TextAlign.left;
    final crossStart =
    isArabic ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start;
    final range = CvFormat.dateRange(edu.startDate, edu.endDate, false, isArabic: isArabic);
    final degreeLine = (edu.fieldOfStudy ?? '').trim().isEmpty
        ? edu.degree
        : '${edu.degree} — ${edu.fieldOfStudy!.trim()}';

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: crossStart,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  edu.institution,
                  textAlign: align,
                  style: pw.TextStyle(font: f.bold, fontSize: titleSize),
                ),
              ),
              if (range.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                  child: pw.Text(
                    range,
                    style: pw.TextStyle(font: f.regular, fontSize: 9.5, color: muted),
                  ),
                ),
            ],
          ),
          pw.Text(
            degreeLine,
            textAlign: align,
            style: pw.TextStyle(font: f.regular, fontSize: 10),
          ),
          if ((edu.grade ?? '').trim().isNotEmpty)
            pw.Text(
              edu.grade!.trim(),
              textAlign: align,
              style: pw.TextStyle(font: f.regular, fontSize: 9.5, color: muted),
            ),
        ],
      ),
    );
  }

  static pw.Widget project(
      ProjectEntry proj, {
        required bool isArabic,
        required CvPdfFonts f,
        required PdfColor muted,
      }) {
    final align = isArabic ? pw.TextAlign.right : pw.TextAlign.left;
    final crossStart =
    isArabic ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start;
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: crossStart,
        children: [
          pw.Text(
            proj.name,
            textAlign: align,
            style: pw.TextStyle(font: f.bold, fontSize: 11),
          ),
          if ((proj.description ?? '').trim().isNotEmpty)
            pw.Text(
              proj.description!.trim(),
              textAlign: align,
              style: pw.TextStyle(font: f.regular, fontSize: 10, color: muted),
            ),
        ],
      ),
    );
  }
}