import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum ApplicationStatus {
  saved,
  applied,
  screening,
  interview,
  offer,
  rejected,
  withdrawn;

  String get localizationKey => 'status_$name';

  Color get color {
    switch (this) {
      case ApplicationStatus.saved:
        return AppColors.statusSaved;
      case ApplicationStatus.applied:
        return AppColors.statusApplied;
      case ApplicationStatus.screening:
        return AppColors.statusScreening;
      case ApplicationStatus.interview:
        return AppColors.statusInterview;
      case ApplicationStatus.offer:
        return AppColors.statusOffer;
      case ApplicationStatus.rejected:
        return AppColors.statusRejected;
      case ApplicationStatus.withdrawn:
        return AppColors.statusWithdrawn;
    }
  }
}

enum WorkType { onsite, hybrid, remote }

enum ApplicationSource {
  linkedin,
  indeed,
  companyWebsite,
  referral,
  glassdoor,
  jobBoard,
  email,
  other;

  // Mapped explicitly (not just 'source_$name') because companyWebsite
  // and jobBoard are camelCase enum values but the localization keys are
  // snake_case (source_company_website, source_job_board) — a plain
  // interpolation would silently miss those two.
  String get localizationKey => switch (this) {
    ApplicationSource.companyWebsite => 'source_company_website',
    ApplicationSource.jobBoard => 'source_job_board',
    _ => 'source_$name',
  };
}

/// Firestore path: users/{uid}/applications/{id}
class ApplicationModel {
  ApplicationModel({
    required this.id,
    required this.companyName,
    required this.position,
    required this.status,
    this.jobDescription,
    this.jobUrl,
    required this.applicationDate,
    this.interviewDate,
    this.salaryMin,
    this.salaryMax,
    this.currency = 'USD',
    this.location,
    this.workType,
    this.source,
    this.recruiterName,
    this.recruiterEmail,
    this.recruiterPhone,
    this.recruiterLinkedIn,
    this.cvId,
    this.coverLetterId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String companyName;
  final String position;
  final ApplicationStatus status;
  final String? jobDescription;
  final String? jobUrl;
  final DateTime applicationDate;
  final DateTime? interviewDate;
  final double? salaryMin;
  final double? salaryMax;
  final String currency;
  final String? location;
  final WorkType? workType;
  final ApplicationSource? source;
  final String? recruiterName;
  final String? recruiterEmail;
  final String? recruiterPhone;
  final String? recruiterLinkedIn;
  final String? cvId;
  final String? coverLetterId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get daysSinceApplied => DateTime.now().difference(applicationDate).inDays;

  /// Returns a copy of this application with the given fields replaced.
  ApplicationModel copyWith({
    String? id,
    String? companyName,
    String? position,
    ApplicationStatus? status,
    String? jobDescription,
    String? jobUrl,
    DateTime? applicationDate,
    DateTime? interviewDate,
    double? salaryMin,
    double? salaryMax,
    String? currency,
    String? location,
    WorkType? workType,
    ApplicationSource? source,
    String? recruiterName,
    String? recruiterEmail,
    String? recruiterPhone,
    String? recruiterLinkedIn,
    String? cvId,
    String? coverLetterId,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ApplicationModel(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      position: position ?? this.position,
      status: status ?? this.status,
      jobDescription: jobDescription ?? this.jobDescription,
      jobUrl: jobUrl ?? this.jobUrl,
      applicationDate: applicationDate ?? this.applicationDate,
      interviewDate: interviewDate ?? this.interviewDate,
      salaryMin: salaryMin ?? this.salaryMin,
      salaryMax: salaryMax ?? this.salaryMax,
      currency: currency ?? this.currency,
      location: location ?? this.location,
      workType: workType ?? this.workType,
      source: source ?? this.source,
      recruiterName: recruiterName ?? this.recruiterName,
      recruiterEmail: recruiterEmail ?? this.recruiterEmail,
      recruiterPhone: recruiterPhone ?? this.recruiterPhone,
      recruiterLinkedIn: recruiterLinkedIn ?? this.recruiterLinkedIn,
      cvId: cvId ?? this.cvId,
      coverLetterId: coverLetterId ?? this.coverLetterId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ApplicationModel.fromMap(String id, Map<String, dynamic> map) {
    return ApplicationModel(
      id: id,
      companyName: map['companyName'] ?? '',
      position: map['position'] ?? '',
      status: ApplicationStatus.values.firstWhere(
            (s) => s.name == map['status'],
        orElse: () => ApplicationStatus.saved,
      ),
      jobDescription: map['jobDescription'],
      jobUrl: map['jobUrl'],
      applicationDate: DateTime.parse(map['applicationDate']),
      interviewDate:
      map['interviewDate'] != null ? DateTime.parse(map['interviewDate']) : null,
      salaryMin: (map['salaryMin'] as num?)?.toDouble(),
      salaryMax: (map['salaryMax'] as num?)?.toDouble(),
      currency: map['currency'] ?? 'USD',
      location: map['location'],
      workType: map['workType'] != null
          ? WorkType.values.firstWhere((w) => w.name == map['workType'])
          : null,
      source: map['source'] != null
          ? ApplicationSource.values.firstWhere((s) => s.name == map['source'])
          : null,
      recruiterName: map['recruiterName'],
      recruiterEmail: map['recruiterEmail'],
      recruiterPhone: map['recruiterPhone'],
      recruiterLinkedIn: map['recruiterLinkedIn'],
      cvId: map['cvId'],
      coverLetterId: map['coverLetterId'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyName': companyName,
      'position': position,
      'status': status.name,
      'jobDescription': jobDescription,
      'jobUrl': jobUrl,
      'applicationDate': applicationDate.toIso8601String(),
      'interviewDate': interviewDate?.toIso8601String(),
      'salaryMin': salaryMin,
      'salaryMax': salaryMax,
      'currency': currency,
      'location': location,
      'workType': workType?.name,
      'source': source?.name,
      'recruiterName': recruiterName,
      'recruiterEmail': recruiterEmail,
      'recruiterPhone': recruiterPhone,
      'recruiterLinkedIn': recruiterLinkedIn,
      'cvId': cvId,
      'coverLetterId': coverLetterId,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}