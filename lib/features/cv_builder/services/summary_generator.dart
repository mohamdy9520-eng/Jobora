import 'dart:math';

enum CvExperienceLevel { entry, mid, senior }

/// Local, rule-based Professional Summary generator — no external API.
/// Builds a 3-part summary (identity → value/impact → closing) from
/// phrase banks, so the same input can produce a few different natural
/// variations instead of one rigid sentence every time.
class SummaryGenerator {
  SummaryGenerator._();

  static const int _minWords = 30;
  static const int _maxWords = 60;

  static CvExperienceLevel levelForYears(int years) {
    if (years <= 2) return CvExperienceLevel.entry;
    if (years <= 6) return CvExperienceLevel.mid;
    return CvExperienceLevel.senior;
  }

  /// [variantSeed] lets the UI offer a "Regenerate" button — pass a new
  /// seed (e.g. increment a counter) to get a different natural phrasing
  /// of the same facts instead of the same text every time.
  static String generate({
    required String jobTitle,
    required int yearsOfExperience,
    required List<String> topSkills,
    String? topAchievement,
    required bool isArabic,
    int variantSeed = 0,
  }) {
    final level = levelForYears(yearsOfExperience);
    final skills = topSkills.where((s) => s.trim().isNotEmpty).toList();
    final skill1 = skills.isNotEmpty ? skills[0] : (isArabic ? 'مجال عملك' : 'your field');
    final skill2 = skills.length > 1 ? skills[1] : skill1;
    final skill3 = skills.length > 2 ? skills[2] : skill2;
    final title = jobTitle.trim().isEmpty
        ? (isArabic ? 'محترف' : 'professional')
        : jobTitle.trim();

    final random = Random(_seedFrom(title, variantSeed));

    final part1 = _fill(
      _pick(_openers(level, isArabic), random),
      {
        'jobTitle': title,
        'years': yearsOfExperience.toString(),
        'skill1': skill1,
        'skill2': skill2,
      },
    );

    final hasAchievement = (topAchievement ?? '').trim().isNotEmpty;
    final part2 = hasAchievement
        ? _fill(
      _pick(_achievementLines(isArabic), random),
      {'achievement': topAchievement!.trim()},
    )
        : _fill(
      _pick(_valueLines(level, isArabic), random),
      {'skill3': skill3},
    );

    final part3 = _fill(
      _pick(_closers(level, isArabic), random),
      {'skill3': skill3},
    );

    var summary = [part1, part2, part3].join(' ');
    summary = _fitToLength(summary, part1, part2, part3, isArabic);
    return summary;
  }

  static int _seedFrom(String title, int variantSeed) =>
      title.hashCode ^ (variantSeed * 7919);

  static String _pick(List<String> options, Random random) =>
      options[random.nextInt(options.length)];

  static String _fill(String template, Map<String, String> vars) {
    var result = template;
    vars.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }

  static int _wordCount(String s) =>
      s.trim().isEmpty ? 0 : s.trim().split(RegExp(r'\s+')).length;

  /// Keeps the final summary within [_minWords]–[_maxWords]. If it's too
  /// long, drop the closing sentence (part1+part2 alone still reads
  /// fine). If somehow too short, that's already handled by always
  /// including all 3 parts — this only trims, never pads with filler.
  static String _fitToLength(
      String full,
      String part1,
      String part2,
      String part3,
      bool isArabic,
      ) {
    if (_wordCount(full) <= _maxWords) return full;
    final shorter = [part1, part2].join(' ');
    if (_wordCount(shorter) <= _maxWords && _wordCount(shorter) >= _minWords) {
      return shorter;
    }
    return full; // both versions imperfect — prefer the complete one
  }

  // ── Phrase banks ────────────────────────────────────────────────

  static List<String> _openers(CvExperienceLevel level, bool ar) {
    switch (level) {
      case CvExperienceLevel.entry:
        return ar
            ? [
          '{jobTitle} طموح يمتلك أساسًا قويًا في {skill1} و{skill2}، ويتطلع للمساهمة في مشاريع ذات تأثير حقيقي.',
          '{jobTitle} متحمس لديه خبرة عملية في {skill1} و{skill2}، ويسعى للنمو ضمن فريق عمل ديناميكي.',
          '{jobTitle} حديث التخرج، شغوف بمجال {skill1}، ويمتلك مهارات جيدة في {skill2}.',
        ]
            : [
          '{jobTitle} with a solid foundation in {skill1} and {skill2}, eager to contribute to impactful projects.',
          'Motivated {jobTitle} with hands-on experience in {skill1} and {skill2}, ready to grow within a dynamic team.',
          'Early-career {jobTitle} passionate about {skill1}, with growing proficiency in {skill2}.',
        ];
      case CvExperienceLevel.mid:
        return ar
            ? [
          '{jobTitle} بخبرة {years} سنوات في {skill1} و{skill2}، معروف بتقديم حلول موثوقة ومتقنة.',
          '{jobTitle} يمتلك {years} سنوات من الخبرة العملية في {skill1} و{skill2}، ويركز دائمًا على تحقيق نتائج ملموسة.',
          '{jobTitle} محترف بخبرة {years} سنوات، جمع بين إتقان {skill1} والقدرة على العمل الجماعي في {skill2}.',
        ]
            : [
          '{jobTitle} with {years}+ years of experience in {skill1} and {skill2}, known for delivering reliable, well-crafted solutions.',
          'Results-driven {jobTitle} with {years} years of hands-on experience across {skill1} and {skill2}.',
          '{jobTitle} with a proven track record over {years} years, combining strong {skill1} skills with a collaborative approach to {skill2}.',
        ];
      case CvExperienceLevel.senior:
        return ar
            ? [
          '{jobTitle} متمرس بخبرة تتجاوز {years} سنوات، يقود مبادرات {skill1} ويرتقي بجودة {skill2}.',
          '{jobTitle} صاحب سجل حافل يمتد لأكثر من {years} سنوات في {skill1} و{skill2}.',
          '{jobTitle} خبير بخبرة {years}+ سنوات، يجمع بين الرؤية الاستراتيجية في {skill1} والتنفيذ العملي في {skill2}.',
        ]
            : [
          'Seasoned {jobTitle} with over {years} years of experience leading {skill1} initiatives and driving {skill2} excellence.',
          'Accomplished {jobTitle} with a strong track record spanning {years}+ years in {skill1} and {skill2}.',
          'Expert {jobTitle} with {years}+ years combining strategic thinking in {skill1} with hands-on execution in {skill2}.',
        ];
    }
  }

  static List<String> _achievementLines(bool ar) {
    return ar
        ? [
      'من أبرز إنجازاته أنه {achievement}، وهو ما يعكس قدرته على تحقيق نتائج ملموسة.',
      'قام مؤخرًا بـ{achievement}، مما يبرز التزامه بالجودة والتنفيذ الفعّال.',
      'نجح في {achievement}، وهي شهادة عملية على مهاراته وقدرته على الإنجاز.',
    ]
        : [
      'A standout achievement includes having {achievement}, reflecting a real ability to deliver measurable results.',
      'Recently {achievement}, demonstrating strong follow-through and attention to quality.',
      'Successfully {achievement} — a practical example of consistent, results-oriented work.',
    ];
  }

  static List<String> _valueLines(CvExperienceLevel level, bool ar) {
    return ar
        ? [
      'يتميز بقدرته على التعاون الفعّال ضمن فرق العمل وتقديم قيمة حقيقية في كل مهمة يتولاها.',
      'معروف بالاهتمام بالتفاصيل والحرص على تسليم عمل عالي الجودة في المواعيد المحددة.',
      'يجمع بين المهارات التقنية القوية في {skill3} والقدرة على التواصل الواضح والفعّال.',
    ]
        : [
      'Known for collaborating effectively across teams and delivering real value in every task undertaken.',
      'Recognized for attention to detail and a consistent commitment to on-time, high-quality delivery.',
      'Combines strong technical skills in {skill3} with clear, effective communication.',
    ];
  }

  static List<String> _closers(CvExperienceLevel level, bool ar) {
    return ar
        ? [
      'يتطلع لتقديم هذه الخبرة في فريق عمل طموح يقدّر الجودة والنمو المستمر.',
      'شغوف بحل المشكلات الواقعية من خلال {skill3}، ولديه التزام حقيقي بالتعلّم المستمر.',
      'يبحث عن فرصة للمساهمة بخبرته وتطوير مهاراته ضمن بيئة عمل محفّزة.',
    ]
        : [
      'Looking to bring this expertise to a forward-thinking team where quality and growth matter.',
      'Passionate about solving real-world problems through {skill3}, with a genuine commitment to continuous learning.',
      'Seeking an opportunity to contribute this experience and keep growing within a motivating environment.',
    ];
  }
}