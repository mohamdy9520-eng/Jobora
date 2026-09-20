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
  /// Wrap Latin-only text inside Arabic letters with Unicode LTR isolates so
  /// numbers and English words keep their reading order. Set to false if the
  /// invisible marks cause any trouble (e.g. in the PDF).
  static const isolateLatinInArabic = true;

  static const _lri = '\u2066';
  static const _pdi = '\u2069';
  static final _arabicChars = RegExp(r'[\u0600-\u06FF]');

  static const _genericManagers = {
    'hr',
    'hr manager',
    'hr team',
    'human resources',
    'recruiter',
    'hiring manager',
    'talent acquisition',
    'unknown',
    'n/a',
    'na',
    'none',
    '-',
    'الموارد البشرية',
    'فريق التوظيف',
  };

  /// Returns '' when the hiring manager is missing or just a generic label
  /// like "HR", so the letter is addressed to the hiring team instead.
  static String cleanManager(String s) {
    final t = s.trim();
    return _genericManagers.contains(t.toLowerCase()) ? '' : t;
  }

  static String _ltr(String s) {
    final t = s.trim();
    if (!isolateLatinInArabic || t.isEmpty) return t;
    return t.split('\n').map((line) {
      final l = line.trim();
      if (l.isEmpty || _arabicChars.hasMatch(l)) return l;
      return '$_lri$l$_pdi';
    }).join('\n');
  }

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
    final manager = cleanManager(i.hiringManager);
    return '''
Write a tailored cover letter in $lang. Tone: $tone.
Length: 250-320 words, 3-4 short paragraphs, plain text only (no markdown, no placeholders, no brackets).
Use ONLY the facts below. Never invent employers, numbers, degrees or achievements.
Connect the candidate's skills to the job requirements when a job description is given.
Start with a salutation and end with a sign-off and the candidate's name.

Candidate name: ${i.applicantName}
Target job title: ${i.jobTitle}
Company: ${i.company}
Hiring manager: ${manager.isEmpty ? 'unknown' : manager}
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

    // Latin text inside an Arabic letter gets isolated so it keeps its order.
    String ltr(String s) => ar ? _ltr(s) : s.trim();
    final job = ltr(i.jobTitle);
    final co = ltr(i.company);

    String join(List<String> xs) {
      if (ar && xs.every((x) => !_arabicChars.hasMatch(x))) {
        return _ltr(xs.join(', '));
      }
      if (xs.length <= 1) return xs.join();
      final and = ar ? ' و' : ' and ';
      return '${xs.sublist(0, xs.length - 1).join(ar ? '، ' : ', ')}$and${xs.last}';
    }

    final m = cleanManager(i.hiringManager);
    final greeting = ar
        ? (m.isEmpty
        ? 'السادة فريق التوظيف في $co المحترمين،'
        : 'السيد/ة ${ltr(m)} المحترم/ة،')
        : 'Dear ${m.isEmpty ? 'Hiring Manager' : m},';

    final opening = ar
        ? switch (i.tone) {
      CoverLetterTone.formal =>
      'أكتب إليكم للتعبير عن رغبتي في التقدّم لوظيفة $job في $co.',
      CoverLetterTone.friendly =>
      'سعدت جدًا برؤية فرصة $job في $co، وأتمنى أن أكون جزءًا من فريقكم.',
      CoverLetterTone.confident =>
      'أثق بأن خلفيتي المهنية تجعلني مرشحًا مناسبًا جدًا لوظيفة $job في $co.',
    }
        : switch (i.tone) {
      CoverLetterTone.formal =>
      'I am writing to express my interest in the $job position at $co.',
      CoverLetterTone.friendly =>
      'I was excited to see the $job opening at $co, and I would love to be part of your team.',
      CoverLetterTone.confident =>
      'I am confident that my background makes me an excellent fit for the $job role at $co.',
    };

    final closing = ar
        ? switch (i.tone) {
      CoverLetterTone.formal =>
      'أشكركم على وقتكم واهتمامكم، وأرحب بفرصة مناقشة كيف يمكنني الإضافة إلى $co.',
      CoverLetterTone.friendly =>
      'شكرًا لقراءتكم رسالتي، وسأكون سعيدًا بالتحدث معكم عن كيف يمكنني مساعدة $co.',
      CoverLetterTone.confident =>
      'أتطلع لمناقشة كيف يمكنني تحقيق نتائج ملموسة لصالح $co.',
    }
        : switch (i.tone) {
      CoverLetterTone.formal =>
      'Thank you for your time and consideration. I would welcome the opportunity to discuss how I can contribute to $co.',
      CoverLetterTone.friendly =>
      'Thank you for reading. I would love to chat about how I can help $co.',
      CoverLetterTone.confident =>
      'I look forward to discussing how I can deliver results for $co.',
    };

    final paragraphs = <String>[
      greeting,
      opening,
      if (highlight.isNotEmpty)
        ar
            ? 'تشمل خبرتي ${join(highlight)}، وهو ما يتوافق مع متطلبات هذه الوظيفة.'
            : 'My experience includes ${join(highlight)}, which aligns closely with the requirements of this role.',
      if (i.experience.trim().isNotEmpty) ltr(i.experience),
      if (i.achievements.trim().isNotEmpty)
        ar
            ? 'من أبرز إنجازاتي:\n${ltr(i.achievements)}'
            : 'Some highlights of my work: ${i.achievements.trim()}',
      closing,
      ar ? 'مع خالص التقدير،\n${i.applicantName}' : 'Sincerely,\n${i.applicantName}',
    ];
    return paragraphs.join('\n\n');
  }
}