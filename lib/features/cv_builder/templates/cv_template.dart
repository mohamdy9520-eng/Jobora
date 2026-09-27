import 'dart:typed_data';
import '../models/cv_builder_model.dart';

/// Common contract every CV template implements. The Template Picker
/// screen lists whatever CvTemplateRegistry.all returns, and each one
/// renders the SAME CvBuilderModel into a different PDF layout.
abstract class CvTemplate {
  const CvTemplate();

  /// Stable id stored on CvBuilderModel.templateId — never rename this
  /// once a template ships, or previously-saved CVs will lose their
  /// template reference.
  String get id;

  String nameFor({required bool isArabic});

  /// Short one-line description shown under the template name in the
  /// picker (e.g. "Best for corporate & ATS systems").
  String descriptionFor({required bool isArabic});

  Future<Uint8List> build(CvBuilderModel model, {required bool isArabic});
}