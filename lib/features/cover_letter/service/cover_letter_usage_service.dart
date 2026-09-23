import 'package:cloud_firestore/cloud_firestore.dart';

// Adjust the path if this file lives somewhere else than
// lib/features/cover_letter/services/.
import '../../../core/constants/usage_limits.dart';

/// Daily limit for AI cover letters, stored per user in Firestore:
/// users/{uid}/usage/coverLetterAi = { date: 'YYYY-MM-DD' (UTC), count: n }
///
/// Limits: [dailyLimit] (3) for free users, [proDailyLimit] (10) for Pro.
/// The Firestore rules cap the counter at 10 for everyone as a hard ceiling;
/// the 3-vs-10 split is decided here from the RevenueCat entitlement.
class CoverLetterUsageService {
  CoverLetterUsageService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  /// Free-plan limit (kept under the old name so existing references work).
  static const dailyLimit = UsageLimits.freeCoverLettersPerDay;

  /// Pro-plan limit.
  static const proDailyLimit = UsageLimits.proCoverLettersPerDay;

  /// The limit that applies to a user, based on their plan.
  static int limitFor({required bool isPro}) =>
      isPro ? proDailyLimit : dailyLimit;

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
  Future<int> remaining(String uid, {bool isPro = false}) async {
    final limit = limitFor(isPro: isPro);
    final data = (await _ref(uid).get()).data();
    if (data == null || data['date'] != _todayUtc()) return limit;
    final used = (data['count'] as num?)?.toInt() ?? 0;
    return (limit - used).clamp(0, limit);
  }

  /// Records one successful AI letter. Call it ONLY after the AI succeeded,
  /// and only after checking [remaining] > 0 before generating.
  /// Returns the remaining count after consuming. If the user is already at
  /// their limit, nothing is written and 0 is returned.
  Future<int> consume(String uid, {bool isPro = false}) async {
    final limit = limitFor(isPro: isPro);
    final ref = _ref(uid);
    final today = _todayUtc();
    return _db.runTransaction<int>((tx) async {
      final data = (await tx.get(ref)).data();
      final used = (data != null && data['date'] == today)
          ? ((data['count'] as num?)?.toInt() ?? 0)
          : 0;
      if (used >= limit) return 0;
      final next = used + 1;
      tx.set(ref, {'date': today, 'count': next});
      return (limit - next).clamp(0, limit);
    });
  }
}