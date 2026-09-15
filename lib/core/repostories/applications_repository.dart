import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/application_model.dart';

/// Firestore-backed repository for [ApplicationModel].
/// Path: users/{uid}/applications/{id}
class ApplicationsRepository {
  ApplicationsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String uid) {
    return _firestore.collection('users').doc(uid).collection('applications');
  }

  /// Real-time stream of every application for [uid], ordered by
  /// updatedAt desc (most recently touched first).
  Stream<List<ApplicationModel>> watchAll(String uid) {
    return _collection(uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => ApplicationModel.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  /// Creates a new application document. A Firestore-generated id is
  /// always used (any id on [application] is ignored) so the client-side
  /// placeholder id used while the form is open never leaks into storage.
  /// Returns the saved model with its final Firestore id.
  Future<ApplicationModel> create(
      String uid,
      ApplicationModel application,
      ) async {
    final docRef = _collection(uid).doc();
    final now = DateTime.now();
    final toSave = application.copyWith(
      id: docRef.id,
      createdAt: now,
      updatedAt: now,
    );
    await docRef.set(toSave.toMap());
    return toSave;
  }

  /// Updates an existing application document. [updatedAt] is always
  /// refreshed to now, regardless of what's on [application].
  Future<void> update(String uid, ApplicationModel application) async {
    final toSave = application.copyWith(updatedAt: DateTime.now());
    await _collection(uid).doc(application.id).update(toSave.toMap());
  }

  Future<void> delete(String uid, String id) async {
    await _collection(uid).doc(id).delete();
  }
}