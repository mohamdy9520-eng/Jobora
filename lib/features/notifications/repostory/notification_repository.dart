import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../models/notification_settings_model.dart';


class NotificationRepository {
  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _settingsDoc(String uid) =>
      _db.collection('users').doc(uid).collection('settings').doc('notifications');

  CollectionReference<Map<String, dynamic>> _notificationsCol(String uid) =>
      _db.collection('users').doc(uid).collection('notifications');

  Stream<NotificationSettingsModel> watchSettings(String uid) {
    return _settingsDoc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return NotificationSettingsModel.defaults();
      return NotificationSettingsModel.fromMap(doc.data()!);
    });
  }

  Future<void> updateSettings(String uid, NotificationSettingsModel settings) {
    return _settingsDoc(uid).set(settings.toMap(), SetOptions(merge: true));
  }

  Stream<List<AppNotificationModel>> watchNotifications(String uid) {
    return _notificationsCol(uid)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AppNotificationModel.fromMap(d.id, d.data())).toList());
  }

  Future<void> markAsRead(String uid, String notificationId) {
    return _notificationsCol(uid).doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllAsRead(String uid, List<String> ids) async {
    if (ids.isEmpty) return;
    final batch = _db.batch();
    for (final id in ids) {
      batch.update(_notificationsCol(uid).doc(id), {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String uid, String notificationId) {
    return _notificationsCol(uid).doc(notificationId).delete();
  }
}