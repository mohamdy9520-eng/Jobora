import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/cv_builder/models/cv_builder_model.dart';

/// Firestore-only repository for "Create CV" drafts/generated CVs.
/// Unlike CvRepository (uploaded files on Cloudinary), everything here
/// is structured data the app itself renders into a PDF later — so it
/// lives entirely in Firestore.
///
/// Firestore layout: users/{uid}/generatedCvs/{cvId}
class CvBuilderRepository {
  CvBuilderRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _firestore.collection('users').doc(uid).collection('generatedCvs');

  Stream<List<CvBuilderModel>> watchAll(String uid) {
    return _collection(uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => CvBuilderModel.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  Future<CvBuilderModel?> getById(String uid, String id) async {
    final doc = await _collection(uid).doc(id).get();
    if (!doc.exists) return null;
    return CvBuilderModel.fromMap(doc.id, doc.data()!);
  }

  /// Creates a new empty draft and returns it with its real Firestore id.
  Future<CvBuilderModel> createDraft(String uid, {required String templateId}) async {
    final docRef = _collection(uid).doc();
    final model = CvBuilderModel.empty(id: docRef.id, templateId: templateId);
    await docRef.set(model.toMap());
    return model;
  }

  /// Upserts the full model (used on every "Save" step of the form and
  /// whenever the template selection changes).
  Future<void> save(String uid, CvBuilderModel model) async {
    await _collection(uid)
        .doc(model.id)
        .set(model.copyWith(updatedAt: DateTime.now()).toMap());
  }

  Future<void> delete(String uid, String id) async {
    await _collection(uid).doc(id).delete();
  }
}