import 'package:flutter/material.dart';

/// Everything the analyzer needs to know about a CV, as plain values.
/// Build it from CvBuilderModel (structured data) or from extracted text.
class CvCompletenessInput {
  final bool hasEmail;
  final bool hasPhone;
  final bool hasLink; // LinkedIn / portfolio / GitHub
  final int summaryLength; // characters, 0 = none
  final int experienceCount;
  final bool experienceHasNumbers; // any bullet with a figure (%, count...)
  final int educationCount;
  final int skillsCount;
  final int projectsCount;
  final int certificationsCount;
  final int languagesCount;

  const CvCompletenessInput({
    this.hasEmail = false,
    this.hasPhone = false,
    this.hasLink = false,
    this.summaryLength = 0,
    this.experienceCount = 0,
    this.experienceHasNumbers = false,
    this.educationCount = 0,
    this.skillsCount = 0,
    this.projectsCount = 0,
    this.certificationsCount = 0,
    this.languagesCount = 0,
  });

  /// Best-effort analysis from raw CV text (English + Arabic keywords).
  /// Use it once you extract text from an uploaded PDF locally
  /// (e.g. with syncfusion_flutter_pdf) — no API needed. Section counts
  /// are approximations: "section found" is treated as 1 item (5 skills).
  factory CvCompletenessInput.fromText(String raw) {
    final text = raw.toLowerCase();

    bool has(List<String> words) => words.any(text.contains);

    final hasEmail =
    RegExp(r'[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,}').hasMatch(text);
    final hasPhone = RegExp(r'(\+?\d[\d\s\-()]{7,}\d)').hasMatch(text);
    final hasLink = has(['linkedin.com', 'github.com', 'behance.net']);
    final hasSummary =
    has(['summary', 'profile', 'objective', 'ملخص', 'نبذة', 'الهدف']);
    final hasExperience =
    has(['experience', 'employment', 'الخبرات', 'الخبرة', 'خبرة']);
    final hasEducation =
    has(['education', 'university', 'التعليم', 'المؤهلات', 'جامعة']);
    final hasSkills = has(['skills', 'المهارات', 'مهارات']);
    final hasProjects = has(['projects', 'المشاريع', 'مشاريع']);
    final hasCerts =
    has(['certification', 'certificate', 'courses', 'شهادات', 'دورات']);
    final hasLanguages = has(['languages', 'اللغات', 'لغات']);
    final hasNumbers = RegExp(r'\d+\s?%|\b\d{2,}\b').hasMatch(text);

    return CvCompletenessInput(
      hasEmail: hasEmail,
      hasPhone: hasPhone,
      hasLink: hasLink,
      summaryLength: hasSummary ? 120 : 0,
      experienceCount: hasExperience ? 1 : 0,
      experienceHasNumbers: hasNumbers,
      educationCount: hasEducation ? 1 : 0,
      skillsCount: hasSkills ? 5 : 0,
      projectsCount: hasProjects ? 1 : 0,
      certificationsCount: hasCerts ? 1 : 0,
      languagesCount: hasLanguages ? 1 : 0,
    );
  }
}

/// A missing/weak part of the CV. Text lives under
/// cv_gap_<key>_title and cv_gap_<key>_message in the language files.
enum CvGap {
  email('email', Icons.alternate_email),
  phone('phone', Icons.phone_outlined),
  summary('summary', Icons.person_outline),
  experience('experience', Icons.work_outline),
  achievements('achievements', Icons.bar_chart_outlined),
  skills('skills', Icons.category_outlined),
  education('education', Icons.school_outlined),
  link('link', Icons.link),
  projects('projects', Icons.folder_special_outlined),
  certifications('certifications', Icons.workspace_premium_outlined),
  languages('languages', Icons.translate);

  final String key;
  final IconData icon;
  const CvGap(this.key, this.icon);
}

/// Pure, rule-based CV checker. Returns gaps ordered by importance
/// (the enum order above is the priority order).
class CvCompletenessAnalyzer {
  CvCompletenessAnalyzer._();

  static const int minSummaryLength = 80;
  static const int minSkills = 5;

  static List<CvGap> analyze(CvCompletenessInput cv) {
    final gaps = <CvGap>[];

    if (!cv.hasEmail) gaps.add(CvGap.email);
    if (!cv.hasPhone) gaps.add(CvGap.phone);
    if (cv.summaryLength < minSummaryLength) gaps.add(CvGap.summary);
    if (cv.experienceCount == 0) {
      gaps.add(CvGap.experience);
    } else if (!cv.experienceHasNumbers) {
      gaps.add(CvGap.achievements);
    }
    if (cv.skillsCount < minSkills) gaps.add(CvGap.skills);
    if (cv.educationCount == 0) gaps.add(CvGap.education);
    if (!cv.hasLink) gaps.add(CvGap.link);
    if (cv.projectsCount == 0 && cv.experienceCount < 2) {
      gaps.add(CvGap.projects);
    }
    if (cv.certificationsCount == 0) gaps.add(CvGap.certifications);
    if (cv.languagesCount == 0) gaps.add(CvGap.languages);

    return gaps;
  }
}