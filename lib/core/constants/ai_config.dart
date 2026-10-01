import 'package:firebase_auth/firebase_auth.dart';

/// Thrown when we can't get a Firebase ID token for the current user
/// (nobody signed in, or the token refresh failed).
class AiAuthException implements Exception {
  const AiAuthException({this.isNetwork = false});

  /// True when the failure was a network problem (so the UI can say "no
  /// connection" instead of "AI unavailable").
  final bool isNetwork;

  @override
  String toString() => 'AiAuthException(isNetwork: $isNetwork)';
}

/// Where the AI requests go. The OpenRouter key lives ONLY on the Cloudflare
/// Worker (as a secret); the app authenticates with the user's Firebase ID
/// token. The Worker URL is public, not a secret.
class AiConfig {
  AiConfig._();

  static const String workerUrl =
      'https://jobora-ai.mo-hamdy9520-917.workers.dev';

  /// AI is available only for a signed-in user (the Worker requires a token).
  static bool get isConfigured =>
      workerUrl.isNotEmpty && FirebaseAuth.instance.currentUser != null;

  /// A valid Firebase ID token. The SDK returns the cached one and refreshes
  /// it automatically when it is about to expire.
  static Future<String> idToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw const AiAuthException();
    try {
      final token = await user.getIdToken();
      if (token == null || token.isEmpty) throw const AiAuthException();
      return token;
    } on FirebaseAuthException catch (e) {
      throw AiAuthException(isNetwork: e.code == 'network-request-failed');
    }
  }
}