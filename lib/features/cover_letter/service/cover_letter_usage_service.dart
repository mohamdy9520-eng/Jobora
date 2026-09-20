import 'package:cloud_firestore/cloud_firestore.dart';

/// Daily limit for AI cover letters, stored per user in Firestore:
/// users/{uid}/usage/coverLetterAi = { date: 'YYYY-MM-DD' (UTC), count: n }
class CoverLetterUsageService {
  CoverLetterUsageService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  static const dailyLimit = 3;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _ref(String uid) => _db
      .collection('users')
      .doc(uid)
      .collection('usage')
      .doc('coverLetterAi');

  static String _todayUtc() {
    final n = DateTime.now().toUtc();
    final m = n.month.toString().padLeft(2, '0');
    final d = n.day.toString().padLeft(2, '0');
    return '${n.year}-$m-$d';
  }

  /// How many AI letters the user can still generate today.
  Future<int> remaining(String uid) async {
    final data = (await _ref(uid).get()).data();
    if (data == null || data['date'] != _todayUtc()) return dailyLimit;
    final used = (data['count'] as num?)?.toInt() ?? 0;
    return (dailyLimit - used).clamp(0, dailyLimit);
  }

  /// Records one successful AI letter. Call it ONLY after the AI succeeded.
  /// Returns the remaining count after consuming.
  Future<int> consume(String uid) async {
    final ref = _ref(uid);
    final today = _todayUtc();
    return _db.runTransaction<int>((tx) async {
      final data = (await tx.get(ref)).data();
      final used = (data != null && data['date'] == today)
          ? ((data['count'] as num?)?.toInt() ?? 0)
          : 0;
      final next = used + 1;
      tx.set(ref, {'date': today, 'count': next});
      return (dailyLimit - next).clamp(0, dailyLimit);
    });
  }
}