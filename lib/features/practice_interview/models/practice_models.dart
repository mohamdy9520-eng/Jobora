import 'package:cloud_firestore/cloud_firestore.dart';

enum PracticeRole { interviewer, candidate }

enum PracticePhase { interviewing, evaluating, done }

enum PracticeError { network, unavailable }

enum AnswerRating { good, okay, weak }

String _str(dynamic v) => v == null ? '' : v.toString().trim();

List<String> _strings(dynamic v, {int max = 8}) {
  if (v is! List) return const [];
  return v
      .map((e) => _str(e))
      .where((e) => e.isNotEmpty)
      .take(max)
      .toList();
}

/// One chat bubble in the interview.
class PracticeMessage {
  const PracticeMessage(this.role, this.text);

  final PracticeRole role;
  final String text;

  factory PracticeMessage.fromMap(Map<String, dynamic> map) {
    return PracticeMessage(
      PracticeRole.values.firstWhere(
            (r) => r.name == map['role'],
        orElse: () => PracticeRole.interviewer,
      ),
      _str(map['text']),
    );
  }

  Map<String, dynamic> toMap() => {'role': role.name, 'text': text};
}

/// A question together with the candidate's answer to it.
class PracticePair {
  const PracticePair(this.question, this.answer);

  final String question;
  final String answer;
}

/// Messages alternate interviewer -> candidate, so a pair is a question
/// followed by its answer. A trailing unanswered question is ignored.
List<PracticePair> buildPracticePairs(List<PracticeMessage> messages) {
  final pairs = <PracticePair>[];
  String? pending;
  for (final m in messages) {
    if (m.role == PracticeRole.interviewer) {
      pending = m.text;
    } else if (pending != null) {
      pairs.add(PracticePair(pending, m.text));
      pending = null;
    }
  }
  return pairs;
}

/// Everything the AI needs to run the interview. Passed from the setup
/// screen to the chat screen through go_router's `extra`.
class PracticeSetup {
  const PracticeSetup({
    required this.applicationId,
    required this.jobTitle,
    required this.company,
    required this.isArabic,
    this.jobDescription = '',
    this.cvText = '',
    this.notes = '',
  });

  final String applicationId;
  final String jobTitle;
  final String company;
  final bool isArabic;
  final String jobDescription;
  final String cvText;
  final String notes;
}

class AnswerReview {
  const AnswerReview({
    required this.n,
    required this.rating,
    this.issue = '',
    this.better = '',
  });

  /// 1-based question number this review refers to.
  final int n;
  final AnswerRating rating;
  final String issue;
  final String better;

  factory AnswerReview.fromMap(Map<String, dynamic> map) {
    final rawN = map['n'];
    final n = rawN is num ? rawN.toInt() : int.tryParse('$rawN') ?? 0;
    final ratingName = _str(map['rating']).toLowerCase();
    return AnswerReview(
      n: n,
      rating: AnswerRating.values.firstWhere(
            (r) => r.name == ratingName,
        orElse: () => AnswerRating.okay,
      ),
      issue: _str(map['issue']),
      better: _str(map['better']),
    );
  }

  Map<String, dynamic> toMap() => {
    'n': n,
    'rating': rating.name,
    'issue': issue,
    'better': better,
  };
}

class PracticeFeedback {
  const PracticeFeedback({
    required this.score,
    required this.summary,
    required this.strengths,
    required this.weaknesses,
    required this.reviews,
    required this.say,
    required this.avoid,
    required this.tips,
  });

  static const empty = PracticeFeedback(
    score: 0,
    summary: '',
    strengths: [],
    weaknesses: [],
    reviews: [],
    say: [],
    avoid: [],
    tips: [],
  );

  final int score; // 0-100
  final String summary;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<AnswerReview> reviews;

  /// What the candidate SHOULD say in the real interview.
  final List<String> say;

  /// What the candidate should NOT say / do.
  final List<String> avoid;
  final List<String> tips;

  AnswerReview? reviewFor(int n) {
    for (final r in reviews) {
      if (r.n == n) return r;
    }
    return null;
  }

  factory PracticeFeedback.fromMap(Map<String, dynamic> map) {
    final rawScore = map['score'];
    final score =
    rawScore is num ? rawScore.round() : int.tryParse('$rawScore') ?? 0;

    final reviews = <AnswerReview>[];
    final rawReviews = map['reviews'];
    if (rawReviews is List) {
      for (final r in rawReviews) {
        if (r is Map) {
          final review = AnswerReview.fromMap(Map<String, dynamic>.from(r));
          if (review.n > 0) reviews.add(review);
        }
      }
    }

    return PracticeFeedback(
      score: score.clamp(0, 100).toInt(),
      summary: _str(map['summary']),
      strengths: _strings(map['strengths']),
      weaknesses: _strings(map['weaknesses']),
      reviews: reviews,
      say: _strings(map['say']),
      avoid: _strings(map['avoid']),
      tips: _strings(map['tips']),
    );
  }

  Map<String, dynamic> toMap() => {
    'score': score,
    'summary': summary,
    'strengths': strengths,
    'weaknesses': weaknesses,
    'reviews': reviews.map((r) => r.toMap()).toList(),
    'say': say,
    'avoid': avoid,
    'tips': tips,
  };
}

/// Firestore path: users/{uid}/practiceSessions/{id}
class PracticeSession {
  const PracticeSession({
    required this.id,
    required this.applicationId,
    required this.jobTitle,
    required this.company,
    required this.isArabic,
    required this.createdAt,
    required this.messages,
    required this.feedback,
  });

  final String id;
  final String applicationId;
  final String jobTitle;
  final String company;
  final bool isArabic;
  final DateTime createdAt;
  final List<PracticeMessage> messages;
  final PracticeFeedback feedback;

  List<PracticePair> get pairs => buildPracticePairs(messages);

  String get dateLabel {
    final d = createdAt;
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }

  PracticeSession copyWith({String? id}) {
    return PracticeSession(
      id: id ?? this.id,
      applicationId: applicationId,
      jobTitle: jobTitle,
      company: company,
      isArabic: isArabic,
      createdAt: createdAt,
      messages: messages,
      feedback: feedback,
    );
  }

  factory PracticeSession.fromMap(String id, Map<String, dynamic> map) {
    final created = map['createdAt'];
    final rawMessages = map['messages'];
    final rawFeedback = map['feedback'];

    final DateTime createdAt;
    if (created is Timestamp) {
      createdAt = created.toDate();
    } else if (created is String) {
      createdAt = DateTime.tryParse(created) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return PracticeSession(
      id: id,
      applicationId: _str(map['applicationId']),
      jobTitle: _str(map['jobTitle']),
      company: _str(map['company']),
      isArabic: map['isArabic'] == true,
      createdAt: createdAt,
      messages: rawMessages is List
          ? rawMessages
          .whereType<Map>()
          .map((m) => PracticeMessage.fromMap(Map<String, dynamic>.from(m)))
          .toList()
          : const [],
      feedback: rawFeedback is Map
          ? PracticeFeedback.fromMap(Map<String, dynamic>.from(rawFeedback))
          : PracticeFeedback.empty,
    );
  }

  Map<String, dynamic> toMap() => {
    'applicationId': applicationId,
    'jobTitle': jobTitle,
    'company': company,
    'isArabic': isArabic,
    'createdAt': Timestamp.fromDate(createdAt),
    'messages': messages.map((m) => m.toMap()).toList(),
    'feedback': feedback.toMap(),
  };
}