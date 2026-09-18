import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile_model.dart';

/// Reads/writes the 'users' Firestore collection: profile fields
/// (username, jobTitle, ...) that Firebase Auth's User object doesn't carry.
class UserProfileRepository {
  final FirebaseFirestore _firestore;

  UserProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users');

  Future<UserProfileModel?> getProfile(String uid) async {
    final doc = await _collection.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfileModel.fromMap(uid, doc.data()!);
  }

  Future<void> saveProfile(UserProfileModel profile) {
    return _collection
        .doc(profile.uid)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  Stream<UserProfileModel?> watchProfile(String uid) {
    return _collection.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserProfileModel.fromMap(uid, doc.data()!);
    });
  }
}