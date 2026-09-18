import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/cv_model.dart';

/// Firestore + Firebase Storage backed repository for CVs.
///
/// Storage layout: users/{uid}/cvs/{cvId}.{ext}
/// Firestore layout: users/{uid}/cvs/{cvId} (metadata only — the file
/// itself lives in Storage; Firestore just points at it).
class CvRepository {
  CvRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _firestore.collection('users').doc(uid).collection('cvs');

  Stream<List<CvModel>> watchAll(String uid) {
    return _collection(uid)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => CvModel.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  /// Uploads [file] to Storage, writes its metadata to Firestore, and
  /// returns the saved [CvModel]. [onProgress] reports 0.0–1.0.
  Future<CvModel> upload(
      String uid,
      File file,
      String fileName, {
        void Function(double progress)? onProgress,
      }) async {
    final docRef = _collection(uid).doc();
    final ext = fileName.contains('.') ? fileName.split('.').last : '';
    final storagePath =
        'users/$uid/cvs/${docRef.id}${ext.isNotEmpty ? '.$ext' : ''}';
    final storageRef = _storage.ref().child(storagePath);

    final uploadTask = storageRef.putFile(file);
    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((snapshot) {
        if (snapshot.totalBytes > 0) {
          onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
        }
      });
    }

    final snapshot = await uploadTask;
    final downloadUrl = await storageRef.getDownloadURL();
    final sizeBytes = snapshot.metadata?.size ?? await file.length();

    final model = CvModel(
      id: docRef.id,
      fileName: fileName,
      downloadUrl: downloadUrl,
      storagePath: storagePath,
      fileSizeBytes: sizeBytes,
      uploadedAt: DateTime.now(),
      fileType: CvModel.inferType(fileName),
    );

    await docRef.set(model.toMap());
    return model;
  }

  Future<void> delete(String uid, CvModel cv) async {
    // Storage deletion failure (e.g. file already gone) shouldn't block
    // removing the Firestore record the user is looking at.
    try {
      await _storage.ref().child(cv.storagePath).delete();
    } catch (_) {}
    await _collection(uid).doc(cv.id).delete();
  }
}