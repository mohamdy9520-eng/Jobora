import 'classic_cv_template.dart';
import 'creative_cv.dart';
import 'cv_template.dart';
import 'minimal_cv.dart';
import 'modern_sidebar_cv.dart';

/// Central place every screen (Template Picker, PDF export...) reads
/// from instead of hardcoding template classes. Adding a new template
/// later = create the class + add one line here.
///
/// الترتيب هنا هو نفس ترتيب الكروت في الـ picker، والأول (Classic)
/// هو الـ default لأي CV محفوظ بـ templateId مش موجود.
class CvTemplateRegistry {
  CvTemplateRegistry._();

  static const List<CvTemplate> all = [
    ClassicCvTemplate(),
    ModernSidebarCvTemplate(),
    MinimalCvTemplate(),
    CreativeCvTemplate(),
  ];

  static CvTemplate byId(String id) {
    return all.firstWhere(
          (t) => t.id == id,
      orElse: () => all.first,
    );
  }
}