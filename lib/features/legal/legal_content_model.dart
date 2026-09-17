import 'package:cloud_firestore/cloud_firestore.dart';

class LegalContentModel {
  final String contentEn;
  final String contentAr;
  final String version;
  final DateTime? updatedAt;

  const LegalContentModel({
    required this.contentEn,
    required this.contentAr,
    required this.version,
    this.updatedAt,
  });

  factory LegalContentModel.fromMap(Map<String, dynamic> map) {
    final ts = map['updated_at'];

    return LegalContentModel(
      contentEn: map['content_en'] as String? ?? '',
      contentAr: map['content_ar'] as String? ?? '',
      version: map['version']?.toString() ?? '',
      updatedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  String localized(String languageCode) {
    return languageCode == 'ar' ? contentAr : contentEn;
  }
}