import 'package:dio/dio.dart';
import '../cover_letter_generator.dart';

class CoverLetterAiService {
  CoverLetterAiService({Dio? dio})
      : _dio = dio ??
      Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 90),
      ));

  final Dio _dio;

  // Run with: flutter run --dart-define-from-file=env.json
  static const _apiKey = String.fromEnvironment('OPENROUTER_API_KEY');

  // A regular (non-reasoning) free model. Free model ids change over time:
  // if requests start failing, pick another non-reasoning ":free" model from
  // openrouter.ai/models (filter: Free) and update this line. Until then the
  // app simply falls back to the local generator.
  static const model = 'meta-llama/llama-3.3-70b-instruct:free';

  bool get isConfigured => _apiKey.isNotEmpty;

  static final _letterTag =
  RegExp(r'<letter>([\s\S]*?)</letter>', caseSensitive: false);

  static const _extraRules = '''

Extra rules:
- Fix obvious spelling mistakes in technology names and the company name, and capitalize them properly (for example "subabase" -> "Supabase", "paython" -> "Python"). Do not change any facts.
- If the hiring manager is missing, "HR" or generic, address the letter to "Hiring Manager" (Arabic: "السادة فريق التوظيف").
- Do NOT show your reasoning, drafts, notes, word counts or explanations.
- Output ONLY the final letter wrapped exactly like this: <letter>the full letter here</letter>
''';

  Future<String> generate(CoverLetterInput input) async {
    final res = await _dio.post(
      'https://openrouter.ai/api/v1/chat/completions',
      options: Options(headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      }),
      data: {
        'model': model,
        'temperature': 0.6,
        'max_tokens': 1600,
        'messages': [
          {
            'role': 'system',
            'content':
            'You are an expert career coach who writes concise, tailored, truthful cover letters. '
                'You never reveal your reasoning; you output only the final letter inside <letter></letter> tags.',
          },
          {
            'role': 'user',
            'content': CoverLetterGenerator.buildPrompt(input) + _extraRules,
          },
        ],
      },
    );

    final raw = res.data['choices'][0]['message']['content'] as String? ?? '';
    return _extractLetter(raw, input);
  }

  /// Returns the clean letter or throws, so the screen falls back to the
  /// local generator (and does not consume the user's daily AI quota).
  String _extractLetter(String raw, CoverLetterInput input) {
    final matches = _letterTag.allMatches(raw).toList();
    if (matches.isEmpty) throw const FormatException('No <letter> block');

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
    final looksBad = text.length < 500 ||
        !lower.contains(input.applicantName.toLowerCase()) ||
        leakMarkers.any(lower.contains);
    if (looksBad) throw const FormatException('Invalid AI letter');

    return text;
  }
}