import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/cv_model.dart';

/// Firestore (metadata) + Cloudinary (file storage) repository for CVs.
///
/// Firestore layout: users/{uid}/cvs/{cvId} (metadata only — the file
/// itself lives on Cloudinary; Firestore just points at it).
class CvRepository {
  CvRepository({FirebaseFirestore? firestore, Dio? dio})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _dio = dio ?? Dio();

  // TODO: paste your real Cloud name from the Cloudinary dashboard.
  static const String _cloudName = 'ucyu1gqf';

  // Must match the preset name exactly (case-sensitive) and be Unsigned.
  static const String _uploadPreset = 'Jobora_CV';

  final FirebaseFirestore _firestore;
  final Dio _dio;

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

  /// Extracts Cloudinary's error message from a failed response, if any.
  String? _extractServerMessage(dynamic body) {
    if (body is Map) {
      final error = body['error'];
      if (error is Map) {
        final message = error['message'];
        if (message != null) return message.toString();
      }
    }
    return null;
  }

  /// Uploads [file] to Cloudinary, writes its metadata to Firestore, and
  /// returns the saved [CvModel]. [onProgress] reports 0.0–1.0.
  Future<CvModel> upload(
      String uid,
      File file,
      String fileName, {
        void Function(double progress)? onProgress,
      }) async {
    final docRef = _collection(uid).doc();
    final ext = fileName.contains('.') ? fileName.split('.').last : '';

    // For "raw" uploads Cloudinary keeps the extension as part of the
    // public ID, so the delivered URL ends with the real file extension.
    final publicId =
        'cvs/$uid/${docRef.id}${ext.isNotEmpty ? '.$ext' : ''}';

    if (kDebugMode) {
      debugPrint('[CvRepository] cloud = $_cloudName, preset = $_uploadPreset');
      debugPrint('[CvRepository] uploading to = $publicId');
    }

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
      'upload_preset': _uploadPreset,
      'public_id': publicId,
    });

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'https://api.cloudinary.com/v1_1/$_cloudName/raw/upload',
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0) {
            onProgress?.call(sent / total);
          }
        },
      );

      final data = response.data ?? <String, dynamic>{};
      final downloadUrl = (data['secure_url'] as String?) ?? '';
      final storagePath = (data['public_id'] as String?) ?? publicId;
      final sizeBytes =
          (data['bytes'] as num?)?.toInt() ?? await file.length();

      if (downloadUrl.isEmpty) {
        throw Exception('Upload succeeded but no URL was returned.');
      }

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
    } on DioException catch (e) {
      final serverMsg = _extractServerMessage(e.response?.data);
      final message = serverMsg ?? e.message ?? 'Upload failed';
      debugPrint('[CvRepository] Cloudinary error: $message');
      throw Exception(message);
    }
  }

  /// Removes the Firestore record. Deleting the file itself from Cloudinary
  /// requires a signed request (API secret), which must never live inside
  /// the app, so the file stays on Cloudinary. That's fine for an MVP.
  Future<void> delete(String uid, CvModel cv) async {
    await _collection(uid).doc(cv.id).delete();
  }
}