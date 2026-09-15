import 'package:cloud_firestore/cloud_firestore.dart';

enum InterviewStage {
  hrScreening,
  hrInterview,
  technicalInterview,
  assessment,
  finalInterview;

  String get localizationKey => 'interview_stage_$name';
}

enum InterviewFormat {
  onsite,
  online,
  phone;

  String get localizationKey => 'interview_format_$name';
}

/// Firestore path: users/{uid}/interviews/{id}
class InterviewModel {
  InterviewModel({
    required this.id,
    required this.applicationId,
    required this.companyName,
    required this.position,
    required this.dateTime,
    this.location,
    this.meetingUrl,
    this.interviewerName,
    this.format = InterviewFormat.online,
    required this.stage,
    this.notes,
    this.preparationNotes,
    this.reminderEnabled = true,
  });

  final String id;
  final String applicationId;
  final String companyName;
  final String position;
  final DateTime dateTime;
  final String? location;
  final String? meetingUrl;
  final String? interviewerName;
  final InterviewFormat format;
  final InterviewStage stage;
  final String? notes;
  final String? preparationNotes;
  final bool reminderEnabled;

  bool get isUpcoming => dateTime.isAfter(DateTime.now());

  bool get isTomorrow {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return dateTime.year == tomorrow.year &&
        dateTime.month == tomorrow.month &&
        dateTime.day == tomorrow.day;
  }

  /// Returns a copy of this interview with the given fields replaced.
  InterviewModel copyWith({
    String? id,
    String? applicationId,
    String? companyName,
    String? position,
    DateTime? dateTime,
    String? location,
    String? meetingUrl,
    String? interviewerName,
    InterviewFormat? format,
    InterviewStage? stage,
    String? notes,
    String? preparationNotes,
    bool? reminderEnabled,
  }) {
    return InterviewModel(
      id: id ?? this.id,
      applicationId: applicationId ?? this.applicationId,
      companyName: companyName ?? this.companyName,
      position: position ?? this.position,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      meetingUrl: meetingUrl ?? this.meetingUrl,
      interviewerName: interviewerName ?? this.interviewerName,
      format: format ?? this.format,
      stage: stage ?? this.stage,
      notes: notes ?? this.notes,
      preparationNotes: preparationNotes ?? this.preparationNotes,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    );
  }

  factory InterviewModel.fromMap(String id, Map<String, dynamic> map) {
    return InterviewModel(
      id: id,
      applicationId: map['applicationId'] ?? '',
      companyName: map['companyName'] ?? '',
      position: map['position'] ?? '',
      dateTime: _parseDate(map['dateTime']),
      location: map['location'],
      meetingUrl: map['meetingUrl'],
      interviewerName: map['interviewerName'],
      format: InterviewFormat.values.firstWhere(
            (f) => f.name == map['format'],
        orElse: () => InterviewFormat.online,
      ),
      stage: InterviewStage.values.firstWhere(
            (s) => s.name == map['stage'],
        orElse: () => InterviewStage.hrScreening,
      ),
      notes: map['notes'],
      preparationNotes: map['preparationNotes'],
      reminderEnabled: map['reminderEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'applicationId': applicationId,
      'companyName': companyName,
      'position': position,
      'dateTime': dateTime.toIso8601String(),
      'location': location,
      'meetingUrl': meetingUrl,
      'interviewerName': interviewerName,
      'format': format.name,
      'stage': stage.name,
      'notes': notes,
      'preparationNotes': preparationNotes,
      'reminderEnabled': reminderEnabled,
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }
}