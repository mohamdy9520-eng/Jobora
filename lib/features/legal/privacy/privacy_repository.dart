import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Real account-data actions (not UI stubs): a data-export request
/// document the backend picks up, and account deletion that marks
/// intent in Firestore then deletes the Firebase Auth user.
class PrivacyRepository {
  final _db = FirebaseFirestore.instance;

  Future<void> requestDataExport(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('data_export_requests')
        .add({
      'requestedAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  Future<void> reauthenticateWithPassword(String password) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      throw Exception('No authenticated email/password user');
    }
    final credential = EmailAuthProvider.credential(email: user.email!, password: password);
    await user.reauthenticateWithCredential(credential);
  }

  Future<void> deleteAccount(String uid) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');
    // Mark intent first so a backend job can clean up dependent data
    // (applications, interviews, notifications) even if anything after
    // this point fails partway.
    await _db.collection('users').doc(uid).set({
      'deletionRequestedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await user.delete(); // throws FirebaseAuthException('requires-recent-login') if session is stale
  }
}