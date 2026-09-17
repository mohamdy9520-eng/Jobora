import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../models/notification_settings_model.dart';
import '../repostory/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final _repository = NotificationRepository();

  String? _uid;
  StreamSubscription<NotificationSettingsModel>? _settingsSub;
  StreamSubscription<List<AppNotificationModel>>? _notificationsSub;

  NotificationSettingsModel _settings = NotificationSettingsModel.defaults();
  List<AppNotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _error;

  NotificationSettingsModel get settings => _settings;
  List<AppNotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void updateAuth(String? uid) {
    if (_uid == uid) return;
    _uid = uid;
    _settingsSub?.cancel();
    _notificationsSub?.cancel();

    if (uid == null) {
      _settings = NotificationSettingsModel.defaults();
      _notifications = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _settingsSub = _repository.watchSettings(uid).listen((s) {
      _settings = s;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      notifyListeners();
    });

    _notificationsSub = _repository.watchNotifications(uid).listen((list) {
      _notifications = list;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> updateSettings(NotificationSettingsModel newSettings) async {
    final uid = _uid;
    if (uid == null) return;
    final previous = _settings;
    _settings = newSettings; // optimistic
    notifyListeners();
    try {
      await _repository.updateSettings(uid, newSettings);
    } catch (e) {
      _settings = previous; // roll back on failure
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _repository.markAsRead(uid, id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    final uid = _uid;
    if (uid == null) return;
    final unreadIds = _notifications.where((n) => !n.isRead).map((n) => n.id).toList();
    try {
      await _repository.markAllAsRead(uid, unreadIds);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String id) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _repository.deleteNotification(uid, id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _settingsSub?.cancel();
    _notificationsSub?.cancel();
    super.dispose();
  }
}