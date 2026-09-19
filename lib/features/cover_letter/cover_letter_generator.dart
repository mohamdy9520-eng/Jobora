enum CoverLetterTone { formal, friendly, confident }

class CoverLetterInput {
  const CoverLetterInput({
    required this.applicantName,
    required this.jobTitle,
    required this.company,
    this.hiringManager = '',
    this.jobDescription = '',
    this.skills = const [],
    this.experience = '',
    this.achievements = '',
    this.tone = CoverLetterTone.formal,
    this.isArabic = false,
  });

  final String applicantName;
  final String jobTitle;
  final String company;
  final String hiringManager;
  final String jobDescription;
  final List<String> skills;
  final String experience;
  final String achievements;
  final CoverLetterTone tone;
  final bool isArabic;
}

class CoverLetterAnalysis {
  const CoverLetterAnalysis({required this.matched, required this.suggested});

  /// User skills that appear in the job description.
  final List<String> matched;

  /// Frequent keywords in the job description the user didn't list.
  final List<String> suggested;
}

class CoverLetterGenerator {
  static const _stopWords = {
    'the', 'and', 'for', 'with', 'you', 'our', 'are', 'will', 'have', 'has',
    'this', 'that', 'from', 'your', 'who', 'was', 'were', 'they', 'their',
    'about', 'able', 'can', 'all', 'any', 'more', 'other', 'such', 'than',
    'work', 'working', 'team', 'role', 'job', 'must', 'should', 'strong',
    'good', 'well', 'including', 'within', 'across', 'into', 'over', 'also',
    'years', 'year', 'experience', 'skills', 'ability', 'knowledge', 'plus',
    'looking', 'join', 'company', 'candidate', 'required', 'requirements',
    'responsibilities', 'preferred', 'etc', 'new', 'using', 'use',
  };

  static CoverLetterAnalysis analyze(String jobDescription, List<String> skills) {
    final jd = jobDescription.toLowerCase();
    if (jd.trim().isEmpty) {
      return const CoverLetterAnalysis(matched: [], suggested: []);
    }

    final matched =
    skills.where((s) => jd.contains(s.toLowerCase())).toList();

    final owned = skills.map((s) => s.toLowerCase()).toSet();
    final counts = <String, int>{};
    for (final m in RegExp(r'[a-zA-Z][a-zA-Z+#.]{2,}').allMatches(jd)) {
      final w = m.group(0)!;
      if (_stopWords.contains(w) || owned.contains(w)) continue;
      counts[w] = (counts[w] ?? 0) + 1;
    }
    final ranked = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final suggested = ranked
        .where((e) => e.value >= 2)
        .take(6)
        .map((e) => e.key)
        .toList();

    return CoverLetterAnalysis(matched: matched, suggested: suggested);
  }

  // ── Prompt for the AI ────────────────────────────────────────────
  static String buildPrompt(CoverLetterInput i) {
    final lang = i.isArabic ? 'Arabic' : 'English';
    final tone = switch (i.tone) {
      CoverLetterTone.formal => 'formal and professional',
      CoverLetterTone.friendly => 'warm and friendly but professional',
      CoverLetterTone.confident => 'confident and results-driven',
    };
    return '''
Write a tailored cover letter in $lang. Tone: $tone.
Length: 250-320 words, 3-4 short paragraphs, plain text only (no markdown, no placeholders, no brackets).
Use ONLY the facts below. Never invent employers, numbers, degrees or achievements.
Connect the candidate's skills to the job requirements when a job description is given.
Start with a salutation and end with a sign-off and the candidate's name.

Candidate name: ${i.applicantName}
Target job title: ${i.jobTitle}
Company: ${i.company}
Hiring manager: ${i.hiringManager.isEmpty ? 'unknown' : i.hiringManager}
Skills: ${i.skills.isEmpty ? 'not provided' : i.skills.join(', ')}
Experience summary: ${i.experience.isEmpty ? 'not provided' : i.experience}
Key achievements: ${i.achievements.isEmpty ? 'not provided' : i.achievements}
Job description: ${i.jobDescription.isEmpty ? 'not provided' : i.jobDescription}
''';
  }

  // ── Local fallback (free, offline, never fails) ──────────────────
  static String generate(CoverLetterInput i) {
    final ar = i.isArabic;
    final analysis = analyze(i.jobDescription, i.skills);
    final highlight = (analysis.matched.isNotEmpty ? analysis.matched : i.skills)
        .take(4)
        .toList();

    String join(List<String> xs) {
      if (xs.length <= 1) return xs.join();
      final and = ar ? ' و' : ' and ';
      return '${xs.sublist(0, xs.length - 1).join(ar ? '، ' : ', ')}$and${xs.last}';
    }

    final m = i.hiringManager.trim();
    final greeting = ar
        ? (m.isEmpty ? 'السادة فريق التوظيف في ${i.company} المحترمين،' : 'السيد/ة $m المحترم/ة،')
        : 'Dear ${m.isEmpty ? 'Hiring Manager' : m},';

    final opening = ar
        ? switch (i.tone) {
      CoverLetterTone.formal =>
      'أكتب إليكم للتعبير عن رغبتي في التقدّم لوظيفة ${i.jobTitle} في ${i.company}.',
      CoverLetterTone.friendly =>
      'سعدت جدًا برؤية فرصة ${i.jobTitle} في ${i.company}، وأتمنى أن أكون جزءًا من فريقكم.',
      CoverLetterTone.confident =>
      'أثق بأن خلفيتي المهنية تجعلني مرشحًا مناسبًا جدًا لوظيفة ${i.jobTitle} في ${i.company}.',
    }
        : switch (i.tone) {
      CoverLetterTone.formal =>
      'I am writing to express my interest in the ${i.jobTitle} position at ${i.company}.',
      CoverLetterTone.friendly =>
      'I was excited to see the ${i.jobTitle} opening at ${i.company}, and I would love to be part of your team.',
      CoverLetterTone.confident =>
      'I am confident that my background makes me an excellent fit for the ${i.jobTitle} role at ${i.company}.',
    };

    final closing = ar
        ? switch (i.tone) {
      CoverLetterTone.formal =>
      'أشكركم على وقتكم واهتمامكم، وأرحب بفرصة مناقشة كيف يمكنني الإضافة إلى ${i.company}.',
      CoverLetterTone.friendly =>
      'شكرًا لقراءتكم رسالتي، وسأكون سعيدًا بالتحدث معكم عن كيف يمكنني مساعدة ${i.company}.',
      CoverLetterTone.confident =>
      'أتطلع لمناقشة كيف يمكنني تحقيق نتائج ملموسة لصالح ${i.company}.',
    }
        : switch (i.tone) {
      CoverLetterTone.formal =>
      'Thank you for your time and consideration. I would welcome the opportunity to discuss how I can contribute to ${i.company}.',
      CoverLetterTone.friendly =>
      'Thank you for reading. I would love to chat about how I can help ${i.company}.',
      CoverLetterTone.confident =>
      'I look forward to discussing how I can deliver results for ${i.company}.',
    };

    final paragraphs = <String>[
      greeting,
      opening,
      if (highlight.isNotEmpty)
        ar
            ? 'تشمل خبرتي ${join(highlight)}، وهو ما يتوافق مع متطلبات هذه الوظيفة.'
            : 'My experience includes ${join(highlight)}, which aligns closely with the requirements of this role.',
      if (i.experience.trim().isNotEmpty) i.experience.trim(),
      if (i.achievements.trim().isNotEmpty)
        ar
            ? 'من أبرز إنجازاتي: ${i.achievements.trim()}'
            : 'Some highlights of my work: ${i.achievements.trim()}',
      closing,
      ar ? 'مع خالص التقدير،\n${i.applicantName}' : 'Sincerely,\n${i.applicantName}',
    ];
    return paragraphs.join('\n\n');
  }
}