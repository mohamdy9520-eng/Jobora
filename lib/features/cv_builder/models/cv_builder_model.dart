import 'package:cloud_firestore/cloud_firestore.dart';

enum LanguageLevel { basic, conversational, fluent, native }

class PersonalInfoData {
  const PersonalInfoData({
    required this.fullName,
    required this.jobTitle,
    required this.email,
    required this.phone,
    this.location,
    this.linkedinUrl,
    this.websiteUrl,
    this.photoUrl,
  });

  final String fullName;
  final String jobTitle;
  final String email;
  final String phone;
  final String? location;
  final String? linkedinUrl;
  final String? websiteUrl;
  final String? photoUrl;

  factory PersonalInfoData.empty() => const PersonalInfoData(
    fullName: '',
    jobTitle: '',
    email: '',
    phone: '',
  );

  factory PersonalInfoData.fromMap(Map<String, dynamic> map) {
    return PersonalInfoData(
      fullName: (map['fullName'] as String?) ?? '',
      jobTitle: (map['jobTitle'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      location: map['location'] as String?,
      linkedinUrl: map['linkedinUrl'] as String?,
      websiteUrl: map['websiteUrl'] as String?,
      photoUrl: map['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'fullName': fullName,
    'jobTitle': jobTitle,
    'email': email,
    'phone': phone,
    'location': location,
    'linkedinUrl': linkedinUrl,
    'websiteUrl': websiteUrl,
    'photoUrl': photoUrl,
  };

  PersonalInfoData copyWith({
    String? fullName,
    String? jobTitle,
    String? email,
    String? phone,
    String? location,
    String? linkedinUrl,
    String? websiteUrl,
    String? photoUrl,
  }) {
    return PersonalInfoData(
      fullName: fullName ?? this.fullName,
      jobTitle: jobTitle ?? this.jobTitle,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}

class ExperienceEntry {
  const ExperienceEntry({
    required this.company,
    required this.jobTitle,
    this.location,
    required this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.bullets = const [],
  });

  final String company;
  final String jobTitle;
  final String? location;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final List<String> bullets;

  factory ExperienceEntry.fromMap(Map<String, dynamic> map) {
    return ExperienceEntry(
      company: (map['company'] as String?) ?? '',
      jobTitle: (map['jobTitle'] as String?) ?? '',
      location: map['location'] as String?,
      startDate: _dateFromMap(map['startDate']) ?? DateTime.now(),
      endDate: _dateFromMap(map['endDate']),
      isCurrent: (map['isCurrent'] as bool?) ?? false,
      bullets: (map['bullets'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }

  Map<String, dynamic> toMap() => {
    'company': company,
    'jobTitle': jobTitle,
    'location': location,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
    'isCurrent': isCurrent,
    'bullets': bullets,
  };
}

class EducationEntry {
  const EducationEntry({
    required this.institution,
    required this.degree,
    this.fieldOfStudy,
    this.startDate,
    this.endDate,
    this.grade,
  });

  final String institution;
  final String degree;
  final String? fieldOfStudy;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? grade;

  factory EducationEntry.fromMap(Map<String, dynamic> map) {
    return EducationEntry(
      institution: (map['institution'] as String?) ?? '',
      degree: (map['degree'] as String?) ?? '',
      fieldOfStudy: map['fieldOfStudy'] as String?,
      startDate: _dateFromMap(map['startDate']),
      endDate: _dateFromMap(map['endDate']),
      grade: map['grade'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'institution': institution,
    'degree': degree,
    'fieldOfStudy': fieldOfStudy,
    'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
    'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
    'grade': grade,
  };
}

class LanguageEntry {
  const LanguageEntry({required this.name, required this.level});

  final String name;
  final LanguageLevel level;

  factory LanguageEntry.fromMap(Map<String, dynamic> map) {
    return LanguageEntry(
      name: (map['name'] as String?) ?? '',
      level: LanguageLevel.values.firstWhere(
            (l) => l.name == map['level'],
        orElse: () => LanguageLevel.conversational,
      ),
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'level': level.name};
}

class CertificationEntry {
  const CertificationEntry({required this.name, required this.issuer, this.date});

  final String name;
  final String issuer;
  final DateTime? date;

  factory CertificationEntry.fromMap(Map<String, dynamic> map) {
    return CertificationEntry(
      name: (map['name'] as String?) ?? '',
      issuer: (map['issuer'] as String?) ?? '',
      date: _dateFromMap(map['date']),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'issuer': issuer,
    'date': date != null ? Timestamp.fromDate(date!) : null,
  };
}

class ProjectEntry {
  const ProjectEntry({required this.name, this.description, this.link});

  final String name;
  final String? description;
  final String? link;

  factory ProjectEntry.fromMap(Map<String, dynamic> map) {
    return ProjectEntry(
      name: (map['name'] as String?) ?? '',
      description: map['description'] as String?,
      link: map['link'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'link': link,
  };
}

/// The full, structured "Create CV" data set. Rendered by a chosen
/// template into a PDF — nothing here is tied to any specific template's
/// layout.
class CvBuilderModel {
  const CvBuilderModel({
    required this.id,
    required this.templateId,
    required this.personalInfo,
    required this.summary,
    this.experiences = const [],
    this.education = const [],
    this.skills = const [],
    this.languages = const [],
    this.certifications = const [],
    this.projects = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String templateId;
  final PersonalInfoData personalInfo;
  final String summary;
  final List<ExperienceEntry> experiences;
  final List<EducationEntry> education;
  final List<String> skills;
  final List<LanguageEntry> languages;
  final List<CertificationEntry> certifications;
  final List<ProjectEntry> projects;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CvBuilderModel.empty({required String id, required String templateId}) {
    final now = DateTime.now();
    return CvBuilderModel(
      id: id,
      templateId: templateId,
      personalInfo: PersonalInfoData.empty(),
      summary: '',
      createdAt: now,
      updatedAt: now,
    );
  }

  factory CvBuilderModel.fromMap(String id, Map<String, dynamic> map) {
    return CvBuilderModel(
      id: id,
      templateId: (map['templateId'] as String?) ?? '',
      personalInfo: PersonalInfoData.fromMap(
        (map['personalInfo'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      summary: (map['summary'] as String?) ?? '',
      experiences: (map['experiences'] as List?)
          ?.map((e) => ExperienceEntry.fromMap((e as Map).cast<String, dynamic>()))
          .toList() ??
          const [],
      education: (map['education'] as List?)
          ?.map((e) => EducationEntry.fromMap((e as Map).cast<String, dynamic>()))
          .toList() ??
          const [],
      skills: (map['skills'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      languages: (map['languages'] as List?)
          ?.map((e) => LanguageEntry.fromMap((e as Map).cast<String, dynamic>()))
          .toList() ??
          const [],
      certifications: (map['certifications'] as List?)
          ?.map((e) => CertificationEntry.fromMap((e as Map).cast<String, dynamic>()))
          .toList() ??
          const [],
      projects: (map['projects'] as List?)
          ?.map((e) => ProjectEntry.fromMap((e as Map).cast<String, dynamic>()))
          .toList() ??
          const [],
      createdAt: _dateFromMap(map['createdAt']) ?? DateTime.now(),
      updatedAt: _dateFromMap(map['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'templateId': templateId,
    'personalInfo': personalInfo.toMap(),
    'summary': summary,
    'experiences': experiences.map((e) => e.toMap()).toList(),
    'education': education.map((e) => e.toMap()).toList(),
    'skills': skills,
    'languages': languages.map((e) => e.toMap()).toList(),
    'certifications': certifications.map((e) => e.toMap()).toList(),
    'projects': projects.map((e) => e.toMap()).toList(),
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  CvBuilderModel copyWith({
    String? templateId,
    PersonalInfoData? personalInfo,
    String? summary,
    List<ExperienceEntry>? experiences,
    List<EducationEntry>? education,
    List<String>? skills,
    List<LanguageEntry>? languages,
    List<CertificationEntry>? certifications,
    List<ProjectEntry>? projects,
    DateTime? updatedAt,
  }) {
    return CvBuilderModel(
      id: id,
      templateId: templateId ?? this.templateId,
      personalInfo: personalInfo ?? this.personalInfo,
      summary: summary ?? this.summary,
      experiences: experiences ?? this.experiences,
      education: education ?? this.education,
      skills: skills ?? this.skills,
      languages: languages ?? this.languages,
      certifications: certifications ?? this.certifications,
      projects: projects ?? this.projects,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Total years of experience, computed from the earliest experience
  /// entry to today (or to the latest end date if none is "current").
  /// Used by the summary generator instead of asking the user to type
  /// a number that could go stale.
  int get totalYearsOfExperience {
    if (experiences.isEmpty) return 0;
    final earliest = experiences
        .map((e) => e.startDate)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final latestEnd = experiences.any((e) => e.isCurrent)
        ? DateTime.now()
        : experiences
        .map((e) => e.endDate ?? e.startDate)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final days = latestEnd.difference(earliest).inDays;
    return (days / 365).floor().clamp(0, 60);
  }
}

DateTime? _dateFromMap(dynamic value) {
  if (value is Timestamp) return value.toDate();
  return null;
}