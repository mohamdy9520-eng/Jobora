import 'package:flutter/foundation.dart';

/// TODO(step-5 Interviews / reminders): placeholder only, so that
/// main.dart's MultiProvider compiles. Will be replaced once local
/// notifications / FCM reminders are wired.
class NotificationProvider extends ChangeNotifier {
  String? _uid;

  void updateAuth(String? uid) {
    if (_uid == uid) return;
    _uid = uid;
    notifyListeners();
    // TODO(step-5 Interviews): register/cancel scheduled reminders here.
  }
}