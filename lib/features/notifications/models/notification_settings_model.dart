class NotificationSettingsModel {
  final bool pushEnabled;
  final bool applicationUpdates;
  final bool interviewReminders;
  final bool weeklySummary;
  final bool marketingEmails;

  const NotificationSettingsModel({
    required this.pushEnabled,
    required this.applicationUpdates,
    required this.interviewReminders,
    required this.weeklySummary,
    required this.marketingEmails,
  });

  factory NotificationSettingsModel.defaults() => const NotificationSettingsModel(
    pushEnabled: true,
    applicationUpdates: true,
    interviewReminders: true,
    weeklySummary: false,
    marketingEmails: false,
  );

  factory NotificationSettingsModel.fromMap(Map<String, dynamic> map) {
    final d = NotificationSettingsModel.defaults();
    return NotificationSettingsModel(
      pushEnabled: map['pushEnabled'] as bool? ?? d.pushEnabled,
      applicationUpdates: map['applicationUpdates'] as bool? ?? d.applicationUpdates,
      interviewReminders: map['interviewReminders'] as bool? ?? d.interviewReminders,
      weeklySummary: map['weeklySummary'] as bool? ?? d.weeklySummary,
      marketingEmails: map['marketingEmails'] as bool? ?? d.marketingEmails,
    );
  }

  Map<String, dynamic> toMap() => {
    'pushEnabled': pushEnabled,
    'applicationUpdates': applicationUpdates,
    'interviewReminders': interviewReminders,
    'weeklySummary': weeklySummary,
    'marketingEmails': marketingEmails,
  };

  NotificationSettingsModel copyWith({
    bool? pushEnabled,
    bool? applicationUpdates,
    bool? interviewReminders,
    bool? weeklySummary,
    bool? marketingEmails,
  }) {
    return NotificationSettingsModel(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      applicationUpdates: applicationUpdates ?? this.applicationUpdates,
      interviewReminders: interviewReminders ?? this.interviewReminders,
      weeklySummary: weeklySummary ?? this.weeklySummary,
      marketingEmails: marketingEmails ?? this.marketingEmails,
    );
  }
}