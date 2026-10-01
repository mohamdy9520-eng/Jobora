import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum PracticeVoiceError {
  permissionDenied,
  localeMissing,
  unavailable,
  ttsUnavailable,
}

/// Speech-to-text (answers) + text-to-speech (questions) for the practice
/// interview. Everything is initialised lazily, so the microphone permission
/// prompt only appears when the user actually taps the mic.
class PracticeVoiceService extends ChangeNotifier {
  PracticeVoiceService({required this.isArabic});

  final bool isArabic;

  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _sttReady = false;
  bool _ttsReady = false;
  bool _ttsLanguageOk = false;
  bool _listening = false;
  bool _speaking = false;
  bool _disposed = false;
  String? _localeId;
  PracticeVoiceError? _error;
  void Function(String words)? _onText;

  bool get isListening => _listening;
  bool get isSpeaking => _speaking;

  /// Returns the pending error once and clears it (no notification).
  PracticeVoiceError? takeError() {
    final e = _error;
    _error = null;
    return e;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  // ───────────────────────── Speech to text ─────────────────────────

  Future<bool> _ensureStt() async {
    if (_sttReady) return true;
    try {
      _sttReady = await _stt.initialize(
        onStatus: _onStatus,
        onError: _onError,
      );
    } catch (e) {
      debugPrint('[PracticeVoice] stt init failed: $e');
      _sttReady = false;
    }

    if (!_sttReady) {
      var hasPermission = true;
      try {
        hasPermission = await _stt.hasPermission;
      } catch (_) {}
      _error = hasPermission
          ? PracticeVoiceError.unavailable
          : PracticeVoiceError.permissionDenied;
      return false;
    }

    _localeId = await _pickLocale();
    return true;
  }

  Future<String?> _pickLocale() async {
    String norm(String s) => s.replaceAll('-', '_').toLowerCase();
    final prefer = isArabic ? ['ar_eg', 'ar_sa', 'ar_ae'] : ['en_us', 'en_gb'];
    final lang = isArabic ? 'ar' : 'en';

    try {
      final locales = await _stt.locales();
      // Some devices report an empty list even though recognition works:
      // fall back to a sensible default instead of blocking the user.
      if (locales.isEmpty) return isArabic ? 'ar_EG' : 'en_US';

      for (final p in prefer) {
        for (final l in locales) {
          if (norm(l.localeId) == p) return l.localeId;
        }
      }
      for (final l in locales) {
        final id = norm(l.localeId);
        if (id == lang || id.startsWith('${lang}_')) return l.localeId;
      }
    } catch (e) {
      debugPrint('[PracticeVoice] locales failed: $e');
    }
    return null;
  }

  void _onStatus(String status) {
    if (status == 'notListening' || status == 'done') {
      if (_listening) {
        _listening = false;
        _notify();
      }
    }
  }

  void _onError(SpeechRecognitionError e) {
    final msg = e.errorMsg.toLowerCase();
    debugPrint('[PracticeVoice] stt error: $msg');
    _listening = false;
    if (msg.contains('permission')) {
      _error = PracticeVoiceError.permissionDenied;
    } else if (msg.contains('language')) {
      _error = PracticeVoiceError.localeMissing;
    }
    // "no_match" / "speech_timeout" are normal (user was silent): no error.
    _notify();
  }

  /// Starts dictation. [onText] receives the full recognised text so far
  /// (partial results included). Returns false if listening couldn't start;
  /// the reason is available through [takeError].
  Future<bool> startListening({
    required void Function(String words) onText,
  }) async {
    await stopSpeaking(); // never record our own voice

    if (!await _ensureStt()) {
      _notify();
      return false;
    }
    if (_localeId == null) {
      _error = PracticeVoiceError.localeMissing;
      _notify();
      return false;
    }

    _onText = onText;
    try {
      await _stt.listen(
        onResult: (r) => _onText?.call(r.recognizedWords),
        localeId: _localeId,
        listenFor: const Duration(minutes: 3),
        pauseFor: const Duration(seconds: 8),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
        ),
      );
      _listening = true;
      _notify();
      return true;
    } catch (e) {
      debugPrint('[PracticeVoice] listen failed: $e');
      _error = PracticeVoiceError.unavailable;
      _listening = false;
      _notify();
      return false;
    }
  }

  Future<void> stopListening() async {
    try {
      await _stt.stop();
    } catch (_) {}
    if (_listening) {
      _listening = false;
      _notify();
    }
  }

  // ───────────────────────── Text to speech ─────────────────────────

  Future<void> _ensureTts() async {
    if (_ttsReady) return;
    _ttsReady = true;
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);

      _tts.setStartHandler(() {
        _speaking = true;
        _notify();
      });
      void done() {
        _speaking = false;
        _notify();
      }

      _tts.setCompletionHandler(done);
      _tts.setCancelHandler(done);
      _tts.setErrorHandler((_) => done());

      final candidates =
      isArabic ? ['ar-EG', 'ar-SA', 'ar'] : ['en-US', 'en-GB'];
      for (final c in candidates) {
        final ok = await _tts.isLanguageAvailable(c);
        if (ok == true || ok == 1) {
          await _tts.setLanguage(c);
          _ttsLanguageOk = true;
          break;
        }
      }
    } catch (e) {
      debugPrint('[PracticeVoice] tts init failed: $e');
    }
  }

  /// Reads [text] aloud. Does nothing while the mic is open.
  Future<void> speak(String text) async {
    if (_listening || text.trim().isEmpty) return;
    await _ensureTts();
    if (!_ttsLanguageOk) {
      _error = PracticeVoiceError.ttsUnavailable;
      _notify();
      return;
    }
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      debugPrint('[PracticeVoice] speak failed: $e');
    }
  }

  Future<void> stopSpeaking() async {
    if (!_ttsReady) return;
    try {
      await _tts.stop();
    } catch (_) {}
    if (_speaking) {
      _speaking = false;
      _notify();
    }
  }

  Future<void> stopAll() async {
    await stopListening();
    await stopSpeaking();
  }

  @override
  void dispose() {
    _disposed = true;
    _stt.cancel();
    if (_ttsReady) _tts.stop();
    super.dispose();
  }
}