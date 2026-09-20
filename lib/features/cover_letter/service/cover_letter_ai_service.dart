import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import '../cover_letter_generator.dart';

class CoverLetterAiService {
  CoverLetterAiService({Dio? dio})
      : _dio = dio ??
      Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 40),
      ));

  final Dio _dio;

  // Run with: flutter run --dart-define-from-file=env.json
  static const _apiKey = String.fromEnvironment('OPENROUTER_API_KEY');

  // Free model ids change over time. If a model starts returning 404, replace
  // it with another ":free" model from openrouter.ai/models.
  static const model = 'deepseek/deepseek-v4-flash-0731:free';

  // Tried in order, ONE request each (plus one re-send without the reasoning
  // switch if a model rejects it). Different providers on purpose.
  static const models = [
    model,
    'qwen/qwen3.8-27b:free',
    'google/gemma-4-31b-it:free',
    // Free router: picks any available free model. Bad replies are rejected
    // by the checks below and the app falls back to the local generator.
    'openrouter/free',
    // Optional PAID last resort (a few cents per 1000 letters, capped by the
    // key's $1 limit). Uncomment ONLY if you decide to allow paid usage:
    // 'meta-llama/llama-3.3-70b-instruct',
  ];

  // Hard deadline for ONE request. Dio's receiveTimeout only measures the
  // gap between chunks, so it does not stop a request that just keeps waiting.
  static const _perRequestTimeout = Duration(seconds: 30);

  // Don't start another model after this much time has already passed.
  static const _totalBudget = Duration(seconds: 45);

  bool get isConfigured => _apiKey.isNotEmpty;

  static final _letterTag =
  RegExp(r'<letter>([\s\S]*?)</letter>', caseSensitive: false);
  static final _arabicChar = RegExp(r'[\u0600-\u06FF]');

  static const _extraRules = '''

Extra rules:
- Fix obvious spelling mistakes in technology names and the company name, and capitalize them properly (for example "subabase" -> "Supabase", "paython" -> "Python"). Do not change any facts.
- If the hiring manager is missing, "HR" or generic, address the letter to "Hiring Manager" (Arabic: "السادة فريق التوظيف").
- Do NOT show your reasoning, drafts, notes, word counts or explanations.
- Output ONLY the final letter wrapped exactly like this: <letter>the full letter here</letter>
''';

  String _rulesFor(CoverLetterInput input) {
    if (!input.isArabic) return _extraRules;
    return '$_extraRules'
        '- Write the whole letter in Arabic, but keep the candidate\'s name exactly as written in Latin letters: "${input.applicantName}". '
        'Do not translate or transliterate it, and use it in the sign-off. '
        'Keep technology names (like Flutter, Python) in Latin letters.\n';
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[CoverLetterAI] $message');
  }

  static String _short(Object? v, [int max = 300]) {
    final s = '$v';
    return s.length <= max ? s : '${s.substring(0, max)}…';
  }

  Never _reject(String reason, String raw) {
    _log('REJECTED: $reason\n--- RAW ---\n$raw\n-----------');
    throw FormatException(reason);
  }

  /// Returns a clean letter or throws (the screen then falls back to the
  /// local generator without consuming the user's daily quota).
  Future<String> generate(CoverLetterInput input) async {
    final clock = Stopwatch()..start();
    Object? lastError;

    for (final m in models) {
      if (clock.elapsed > _totalBudget) {
        _log('stopping: time budget exceeded');
        break;
      }
      final started = clock.elapsed;
      String took() => '${(clock.elapsed - started).inSeconds}s';

      try {
        final letter = await _attempt(input, m);
        _log('[$m] OK in ${took()}');
        return letter;
      } on FormatException catch (e) {
        lastError = e;
        _log('[$m] rejected after ${took()}: ${e.message}');
      } on DioException catch (e) {
        lastError = e;
        final code = e.response?.statusCode;
        _log('[$m] failed after ${took()}: ${e.type.name} status=$code');
        // Key/account problems affect every model: don't try the others.
        if (code == 401 || code == 402 || code == 403) rethrow;
      }
    }
    throw lastError ?? const FormatException('AI unavailable');
  }

  /// One model: first with reasoning switched off (fast, and the whole token
  /// budget goes to the letter). Some models refuse that switch (HTTP 400):
  /// then the same model is tried once more as-is.
  Future<String> _attempt(CoverLetterInput input, String modelId) async {
    try {
      return await _requestOnce(input, modelId, reasoningOff: true);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        _log('[$modelId] refused reasoning=none, retrying without it');
        return _requestOnce(input, modelId, reasoningOff: false);
      }
      rethrow;
    }
  }

  Future<String> _requestOnce(
      CoverLetterInput input,
      String modelId, {
        required bool reasoningOff,
      }) async {
    final cancel = CancelToken();
    final timer = Timer(_perRequestTimeout, () {
      cancel.cancel('deadline ${_perRequestTimeout.inSeconds}s');
    });

    final Response res;
    try {
      res = await _dio.post(
        'https://openrouter.ai/api/v1/chat/completions',
        cancelToken: cancel,
        options: Options(headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'X-Title': 'JobMate',
        }),
        data: {
          'model': modelId,
          'temperature': 0.6,
          // Reasoning tokens share this budget, so an unlimited "thinking"
          // model can eat all of it and return an empty letter.
          'max_tokens': 3500,
          if (reasoningOff) 'reasoning': {'effort': 'none'},
          // Only route to providers that don't store/train on user data.
          'provider': {'data_collection': 'deny'},
          'messages': [
            {
              'role': 'system',
              'content':
              'You are an expert career coach who writes concise, tailored, truthful cover letters. '
                  'You never reveal your reasoning; you output only the final letter inside <letter></letter> tags.',
            },
            {
              'role': 'user',
              'content':
              CoverLetterGenerator.buildPrompt(input) + _rulesFor(input),
            },
          ],
        },
      );
    } on DioException catch (e) {
      if (e.response != null) {
        _log('[$modelId] HTTP ${e.response?.statusCode}: ${_short(e.response?.data)}');
      }
      rethrow;
    } finally {
      timer.cancel();
    }

    final choices = res.data['choices'];
    if (choices is! List || choices.isEmpty) {
      _reject('Empty AI response', _short(res.data, 600));
    }
    final choice = choices[0];
    final message = choice['message'];
    final raw = (message?['content'] as String?) ?? '';
    final reasoning = message?['reasoning'];
    _log('[$modelId] served by: ${res.data['model']}, '
        'reasoning ${reasoningOff ? 'OFF' : 'default'}, '
        'finish_reason: ${choice['finish_reason']}, '
        'content chars: ${raw.length}, '
        'reasoning chars: ${reasoning is String ? reasoning.length : 0}');

    return _extractLetter(raw, input);
  }

  String _extractLetter(String raw, CoverLetterInput input) {
    final matches = _letterTag.allMatches(raw).toList();
    if (matches.isEmpty) _reject('No <letter> block', raw);

    final text = matches.last
        .group(1)!
        .replaceAll('```', '')
        .replaceAll('**', '')
        .replaceAll(RegExp(r'^#+\s*', multiLine: true), '')
        .trim();

    final lower = text.toLowerCase();
    const leakMarkers = [
      'we need to',
      "let's draft",
      'the user wants',
      'word count',
      'draft:',
    ];

    if (text.length < 500) _reject('Too short (${text.length} chars)', raw);

    if (input.isArabic) {
      // The model may write the name in Arabic script, so instead of
      // looking for the Latin name, make sure the letter really is Arabic.
      final arabicCount = _arabicChar.allMatches(text).length;
      if (arabicCount < text.length * 0.4) {
        _reject('Not written in Arabic ($arabicCount arabic chars)', raw);
      }
    } else if (!lower.contains(input.applicantName.toLowerCase())) {
      _reject('Applicant name missing', raw);
    }

    final leak = leakMarkers.where(lower.contains).toList();
    if (leak.isNotEmpty) _reject('Reasoning leak: $leak', raw);

    return text;
  }
}