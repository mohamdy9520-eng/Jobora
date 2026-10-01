/// المصدر الوحيد لروابط الصفحات القانونية (GitHub Pages).
/// أي شاشة محتاجة Terms أو Privacy تستخدم الثوابت دي،
/// ومفيش رابط يتكتب يدويًا في أي مكان تاني.
///
/// ملاحظة: الروابط من غير ?lang، لأن كل شاشة/دالة بتضيفه حسب لغة التطبيق.
class LegalUrls {
  LegalUrls._();

  static const String _base = 'https://mohamdy9520-eng.github.io/jobora-legal';

  static const String terms = '$_base/terms.html';
  static const String privacy = '$_base/privacy.html';
}