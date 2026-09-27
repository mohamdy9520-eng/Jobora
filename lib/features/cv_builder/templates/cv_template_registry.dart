import 'classic_cv_template.dart';
import 'cv_template.dart';

/// Central place every screen (Template Picker, PDF export...) reads
/// from instead of hardcoding template classes. Adding a new template
/// later = create the class + add one line here.
class CvTemplateRegistry {
  CvTemplateRegistry._();

  static const List<CvTemplate> all = [
    ClassicCvTemplate(),
    // ModernSidebarCvTemplate(),  // next template
    // MinimalCvTemplate(),
    // CreativeCvTemplate(),
  ];

  static CvTemplate byId(String id) {
    return all.firstWhere(
          (t) => t.id == id,
      orElse: () => all.first,
    );
  }
}