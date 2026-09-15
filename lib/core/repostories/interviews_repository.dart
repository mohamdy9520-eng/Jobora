import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/interview_model.dart';

/// Firestore-backed repository for [InterviewModel].
/// Path: users/{uid}/interviews/{id}
class InterviewsRepository {
  InterviewsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String uid) {
    return _firestore.collection('users').doc(uid).collection('interviews');
  }

  /// Real-time stream of every interview for [uid], ordered by
  /// dateTime asc (soonest first). Filtering to "upcoming only" stays a
  /// client-side concern (InterviewProvider.upcoming), so the repository
  /// always exposes the full list.
  Stream<List<InterviewModel>> watchAll(String uid) {
    return _collection(uid)
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => InterviewModel.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  /// Creates a new interview document. A Firestore-generated id is
  /// always used (any id on [interview] is ignored). Returns the saved
  /// model with its final Firestore id.
  Future<InterviewModel> create(String uid, InterviewModel interview) async {
    final docRef = _collection(uid).doc();
    final toSave = interview.copyWith(id: docRef.id);
    await docRef.set(toSave.toMap());
    return toSave;
  }

  Future<void> update(String uid, InterviewModel interview) async {
    await _collection(uid).doc(interview.id).update(interview.toMap());
  }

  Future<void> delete(String uid, String id) async {
    await _collection(uid).doc(id).delete();
  }
}