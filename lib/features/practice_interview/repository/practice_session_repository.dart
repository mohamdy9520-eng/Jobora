import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/practice_models.dart';

/// Firestore layout: users/{uid}/practiceSessions/{sessionId}
class PracticeSessionRepository {
  PracticeSessionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _firestore.collection('users').doc(uid).collection('practiceSessions');

  Stream<List<PracticeSession>> watchAll(String uid, {int limit = 30}) {
    return _collection(uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => PracticeSession.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  /// Saves [session] under a fresh id and returns it with that id.
  Future<PracticeSession> save(String uid, PracticeSession session) async {
    final ref = _collection(uid).doc();
    final saved = session.copyWith(id: ref.id);
    await ref.set(saved.toMap());
    return saved;
  }

  Future<void> delete(String uid, String id) => _collection(uid).doc(id).delete();
}