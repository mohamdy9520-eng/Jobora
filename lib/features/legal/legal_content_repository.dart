import 'package:cloud_firestore/cloud_firestore.dart';
import 'legal_content_model.dart';

/// Reads static-but-editable legal text from Firestore
/// (`app_content/{docId}`), so Privacy Policy / Terms can be updated
/// from the backend without an app release — never hardcoded in the app.
class LegalContentRepository {
  final _db = FirebaseFirestore.instance;

  Future<LegalContentModel> fetch(String docId) async {
    final doc = await _db.collection('app_content').doc(docId).get();
    if (!doc.exists || doc.data() == null) {
      throw Exception('Content "$docId" not found in app_content');
    }
    return LegalContentModel.fromMap(doc.data()!);
  }
}