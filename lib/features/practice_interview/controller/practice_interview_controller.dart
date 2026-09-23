import 'package:flutter/foundation.dart';

import '../models/practice_models.dart';
import '../repository/practice_session_repository.dart';
import '../services/practice_interview_ai_service.dart';

/// Drives one interview: asks the AI for each question, collects the
/// candidate's answers, then asks it to evaluate and saves the session.
class PracticeInterviewController extends ChangeNotifier {
  PracticeInterviewController({
    required this.setup,
    required this.uid,
    PracticeInterviewAiService? ai,
    PracticeSessionRepository? repository,
  })  : _ai = ai ?? PracticeInterviewAiService(),
        _repository = repository ?? PracticeSessionRepository();

  /// Total number of interviewer messages (questions + follow-ups).
  static const totalQuestions = 8;

  /// The candidate can end early once this many answers were given.
  static const minAnswersToFinish = 3;

  final PracticeSetup setup;
  final String? uid;
  final PracticeInterviewAiService _ai;
  final PracticeSessionRepository _repository;

  final List<PracticeMessage> _messages = [];
  PracticePhase _phase = PracticePhase.interviewing;
  bool _isThinking = false;
  PracticeError? _error;
  PracticeSession? _session;
  bool _saveFailed = false;
  bool _disposed = false;

  List<PracticeMessage> get messages => List.unmodifiable(_messages);
  PracticePhase get phase => _phase;
  bool get isThinking => _isThinking;
  PracticeError? get error => _error;
  PracticeSession? get session => _session;
  bool get saveFailed => _saveFailed;

  int get questionsAsked =>
      _messages.where((m) => m.role == PracticeRole.interviewer).length;
  int get answersGiven =>
      _messages.where((m) => m.role == PracticeRole.candidate).length;
  double get progress => (answersGiven / totalQuestions).clamp(0.0, 1.0);

  bool get _lastIsInterviewer =>
      _messages.isNotEmpty && _messages.last.role == PracticeRole.interviewer;

  bool get canAnswer =>
      _phase == PracticePhase.interviewing &&
          !_isThinking &&
          _error == null &&
          _lastIsInterviewer;

  bool get canFinishEarly =>
      _phase == PracticePhase.interviewing &&
          !_isThinking &&
          answersGiven >= minAnswersToFinish;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Asks for the first question. Safe to call once after creation.
  Future<void> start() async {
    if (_messages.isEmpty && !_isThinking) await _requestNext();
  }

  Future<void> submitAnswer(String text) async {
    final answer = text.trim();
    if (answer.isEmpty || !canAnswer) return;

    _messages.add(PracticeMessage(PracticeRole.candidate, answer));
    _notify();

    if (questionsAsked >= totalQuestions) {
      await _evaluate();
    } else {
      await _requestNext();
    }
  }

  Future<void> finishEarly() async {
    if (!canFinishEarly) return;
    await _evaluate();
  }

  /// Retries whichever step failed (next question or evaluation).
  Future<void> retry() async {
    if (_isThinking) return;
    if (_phase == PracticePhase.evaluating) {
      await _evaluate();
    } else if (_phase == PracticePhase.interviewing) {
      await _requestNext();
    }
  }

  Future<void> _requestNext() async {
    _isThinking = true;
    _error = null;
    _notify();

    try {
      final question = await _ai.nextQuestion(
        setup,
        List.of(_messages),
        questionNumber: questionsAsked + 1,
        total: totalQuestions,
      );
      _messages.add(PracticeMessage(PracticeRole.interviewer, question));
    } on PracticeAiException catch (e) {
      _error = e.kind;
    } catch (_) {
      _error = PracticeError.unavailable;
    }

    _isThinking = false;
    _notify();
  }

  /// The transcript without a trailing question the candidate never answered.
  List<PracticeMessage> _answeredTranscript() {
    if (_lastIsInterviewer) {
      return List.of(_messages.sublist(0, _messages.length - 1));
    }
    return List.of(_messages);
  }

  Future<void> _evaluate() async {
    _phase = PracticePhase.evaluating;
    _isThinking = true;
    _error = null;
    _notify();

    final transcript = _answeredTranscript();
    final pairs = buildPracticePairs(transcript);

    try {
      final feedback = await _ai.evaluate(setup, pairs);

      var session = PracticeSession(
        id: '',
        applicationId: setup.applicationId,
        jobTitle: setup.jobTitle,
        company: setup.company,
        isArabic: setup.isArabic,
        createdAt: DateTime.now(),
        messages: transcript,
        feedback: feedback,
      );

      final userId = uid;
      if (userId != null && userId.isNotEmpty) {
        try {
          session = await _repository.save(userId, session);
        } catch (e) {
          _saveFailed = true;
          debugPrint('[PracticeInterview] save failed: $e');
        }
      } else {
        _saveFailed = true;
      }

      _session = session;
      _phase = PracticePhase.done;
    } on PracticeAiException catch (e) {
      _error = e.kind;
    } catch (_) {
      _error = PracticeError.unavailable;
    }

    _isThinking = false;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}