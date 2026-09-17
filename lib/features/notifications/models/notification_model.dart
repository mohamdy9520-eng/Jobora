import 'package:cloud_firestore/cloud_firestore.dart';

enum AppNotificationType { applicationUpdate, interviewReminder, weeklySummary, system, marketing }

class AppNotificationModel {
  final String id;
  final String title;
  final String body;
  final AppNotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final String? relatedApplicationId;

  const AppNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.relatedApplicationId,
  });

  factory AppNotificationModel.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['createdAt'];
    return AppNotificationModel(
      id: id,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      type: AppNotificationType.values.firstWhere(
            (t) => t.name == map['type'],
        orElse: () => AppNotificationType.system,
      ),
      isRead: map['isRead'] as bool? ?? false,
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      relatedApplicationId: map['relatedApplicationId'] as String?,
    );
  }
}