import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/usage_limits.dart';

/// Daily limit for practice interview sessions (Pro only), stored per user:
/// users/{uid}/usage/practiceSessions = { date: 'YYYY-MM-DD' (UTC), count: n }
///
/// Put this file at: lib/features/practice_interview/services/
class PracticeUsageService {
  PracticeUsageService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  static const dailyLimit = UsageLimits.proPracticeSessionsPerDay;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _ref(String uid) => _db
      .collection('users')
      .doc(uid)
      .collection('usage')
      .doc('practiceSessions');

  static String _todayUtc() {
    final n = DateTime.now().toUtc();
    final m = n.month.toString().padLeft(2, '0');
    final d = n.day.toString().padLeft(2, '0');
    return '${n.year}-$m-$d';
  }

  /// How many practice sessions the user can still start today.
  Future<int> remaining(String uid) async {
    final data = (await _ref(uid).get()).data();
    if (data == null || data['date'] != _todayUtc()) return dailyLimit;
    final used = (data['count'] as num?)?.toInt() ?? 0;
    return (dailyLimit - used).clamp(0, dailyLimit);
  }

  /// Consumes one of today's sessions atomically. Called by
  /// PracticeChatScreen once the first question has reached the user.
  /// Returns how many are left AFTER consuming, or null if the user has
  /// already used all of today's sessions (nothing is written in that case).
  Future<int?> tryConsume(String uid) async {
    final ref = _ref(uid);
    final today = _todayUtc();
    return _db.runTransaction<int?>((tx) async {
      final data = (await tx.get(ref)).data();
      final used = (data != null && data['date'] == today)
          ? ((data['count'] as num?)?.toInt() ?? 0)
          : 0;
      if (used >= dailyLimit) return null;
      final next = used + 1;
      tx.set(ref, {'date': today, 'count': next});
      return dailyLimit - next;
    });
  }
}