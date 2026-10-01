import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/usage_limits.dart';

/// Tracks the LIFETIME free Practice Interview allowance.
///
/// Stored at: users/{uid}/usage/practiceSessions  ->  { freeUsed: n }
///
/// - Free users: [UsageLimits.freePracticeSessionsLifetime] session, ever.
/// - Pro users: unlimited. Callers skip this service entirely for them.
///
/// The counter only ever goes up by exactly 1 (enforced by firestore.rules),
/// and the document can never be deleted, so it can't be reset.
class PracticeUsageService {
  PracticeUsageService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Total free sessions a non-Pro user gets (lifetime, not per day).
  static const int freeSessions = UsageLimits.freePracticeSessionsLifetime;

  DocumentReference<Map<String, dynamic>> _ref(String uid) => _db
      .collection('users')
      .doc(uid)
      .collection('usage')
      .doc('practiceSessions');

  static int _used(Map<String, dynamic>? data) {
    final v = data?['freeUsed'];
    return v is int ? v : (v is num ? v.toInt() : 0);
  }

  /// How many free sessions are left (never negative).
  Future<int> freeRemaining(String uid) async {
    final snap = await _ref(uid).get();
    return math.max(0, freeSessions - _used(snap.data()));
  }

  /// Consumes one free session atomically.
  /// Returns true if it was consumed, false if the allowance was already
  /// used up (nothing is written in that case).
  Future<bool> tryConsumeFree(String uid) {
    final ref = _ref(uid);
    return _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(ref);
      final used = _used(snap.data());

      if (used >= freeSessions) return false;

      if (snap.exists) {
        // Rule: only `freeUsed` changes, and by exactly +1.
        tx.update(ref, {'freeUsed': used + 1});
      } else {
        // Rule: first write must be exactly { freeUsed: 1 }.
        tx.set(ref, {'freeUsed': 1});
      }
      return true;
    });
  }
}