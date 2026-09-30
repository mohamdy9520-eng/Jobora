import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AdConfig {
  AdConfig._();

  /// Set to true temporarily to test the GDPR form on a debug build
  /// (simulates a user in the EEA). Remember to set it back to false.
  static const bool debugForceEeaConsent = false;

  /// Your real device's hashed ID (printed in logcat by the UMP SDK).
  /// Emulators are test devices automatically.
  static const List<String> consentTestDeviceIds = <String>[];

  static const _testBannerAndroid = 'ca-app-pub-3940256099942544/9214589741';
  static const _testBannerIos = 'ca-app-pub-3940256099942544/2435281174';

  static bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;
  static bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;

  static bool get isSupported => !kIsWeb && (_isAndroid || _isIos);

  /// Debug/profile ALWAYS use Google's test units (clicking your own real
  /// ads can get the account banned). Only release builds use real IDs,
  /// read from the `env` file. If the ID is missing, ads are simply off.
  static String? get bannerUnitId {
    if (!isSupported) return null;
    if (!kReleaseMode) return _isAndroid ? _testBannerAndroid : _testBannerIos;

    final key = _isAndroid ? 'ADMOB_BANNER_ANDROID_ID' : 'ADMOB_BANNER_IOS_ID';
    final value = dotenv.env[key]?.trim();
    return (value == null || value.isEmpty) ? null : value;
  }
}