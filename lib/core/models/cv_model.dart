import 'package:cloud_firestore/cloud_firestore.dart';

/// Broad category inferred from the file extension, used only for
/// choosing an icon in the UI — upload itself accepts any extension.
enum CvFileType { pdf, word, image, other }

class CvModel {
  const CvModel({
    required this.id,
    required this.fileName,
    required this.downloadUrl,
    required this.storagePath,
    required this.fileSizeBytes,
    required this.uploadedAt,
    required this.fileType,
  });

  final String id;
  final String fileName;
  final String downloadUrl;
  final String storagePath;
  final int fileSizeBytes;
  final DateTime uploadedAt;
  final CvFileType fileType;

  factory CvModel.fromMap(String id, Map<String, dynamic> map) {
    final timestamp = map['uploadedAt'];
    return CvModel(
      id: id,
      fileName: (map['fileName'] as String?) ?? 'CV',
      downloadUrl: (map['downloadUrl'] as String?) ?? '',
      storagePath: (map['storagePath'] as String?) ?? '',
      fileSizeBytes: (map['fileSizeBytes'] as num?)?.toInt() ?? 0,
      uploadedAt: timestamp is Timestamp
          ? timestamp.toDate()
          : DateTime.now(),
      fileType: _typeFromName((map['fileType'] as String?) ?? ''),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fileName': fileName,
      'downloadUrl': downloadUrl,
      'storagePath': storagePath,
      'fileSizeBytes': fileSizeBytes,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'fileType': fileType.name,
    };
  }

  /// Infers a [CvFileType] from a file name's extension. Used at upload
  /// time so the stored 'fileType' matches the actual file, and as a
  /// fallback when parsing older documents that might not have it.
  static CvFileType inferType(String fileName) {
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';
    switch (ext) {
      case 'pdf':
        return CvFileType.pdf;
      case 'doc':
      case 'docx':
        return CvFileType.word;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'heic':
      case 'webp':
        return CvFileType.image;
      default:
        return CvFileType.other;
    }
  }

  static CvFileType _typeFromName(String name) {
    return CvFileType.values.firstWhere(
          (t) => t.name == name,
      orElse: () => CvFileType.other,
    );
  }

  String get formattedSize {
    if (fileSizeBytes <= 0) return '';
    const kb = 1024;
    const mb = kb * 1024;
    if (fileSizeBytes >= mb) {
      return '${(fileSizeBytes / mb).toStringAsFixed(1)} MB';
    }
    return '${(fileSizeBytes / kb).toStringAsFixed(0)} KB';
  }
}