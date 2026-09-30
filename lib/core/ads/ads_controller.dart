import 'dart:async';

import 'package:flutter/cupertino.dart' as PrivacyOptionsRequirementStatus;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

/// Owns everything about ads that is not UI:
///  1. GDPR/UMP consent (must finish BEFORE any ad request),
///  2. Mobile Ads SDK initialization,
///  3. the user's "hide banner" choice.
class AdsController extends ChangeNotifier {
  /// How long the banner stays hidden after the user taps close.
  static const Duration hideDuration = Duration(minutes: 30);

  bool _initStarted = false;
  bool _sdkStarted = false;
  bool _canRequestAds = false;
  bool _privacyOptionsRequired = false;
  DateTime? _hiddenUntil;
  Timer? _reshowTimer;

  bool get canRequestAds => _canRequestAds;

  /// True when the user is in a region where a "change my consent" entry
  /// point is legally required (EEA/UK). Show it in Profile.
  bool get privacyOptionsRequired => _privacyOptionsRequired;

  bool get _isHidden =>
      _hiddenUntil != null && DateTime.now().isBefore(_hiddenUntil!);

  bool get shouldShowBanner =>
      AdConfig.isSupported && _canRequestAds && !_isHidden;

  /// Safe to call many times; only the first call does work.
  Future<void> initialize() async {
    if (_initStarted || !AdConfig.isSupported) return;
    _initStarted = true;
    try {
      await _gatherConsent();
      await _refreshConsentState();
      if (_canRequestAds) await _startSdk();
    } catch (e, st) {
      debugPrint('Ads init failed: $e\n$st');
    }
  }

  Future<void> _gatherConsent() {
    final completer = Completer<void>();

    final params = ConsentRequestParameters(
      tagForUnderAgeOfConsent: false,
      consentDebugSettings: (kDebugMode && AdConfig.debugForceEeaConsent)
          ? ConsentDebugSettings(
        debugGeography: DebugGeography.debugGeographyEea,
        testIdentifiers: AdConfig.consentTestDeviceIds,
      )
          : null,
    );

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
          () {
        // Shows the form only if the user's region requires it.
        ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
          if (error != null) debugPrint('UMP form error: ${error.message}');
          if (!completer.isCompleted) completer.complete();
        });
      },
          (FormError error) {
        debugPrint('UMP info update error: ${error.message}');
        if (!completer.isCompleted) completer.complete();
      },
    );

    return completer.future;
  }

  Future<void> _refreshConsentState() async {
    _canRequestAds = await ConsentInformation.instance.canRequestAds();
    final status =
    await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
    _privacyOptionsRequired = status == PrivacyOptionsRequirementStatus.required;
    notifyListeners();
  }

  Future<void> _startSdk() async {
    if (_sdkStarted) return;
    _sdkStarted = true;
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.no,
        maxAdContentRating: MaxAdContentRating.pg,
      ),
    );
    await MobileAds.instance.initialize();
  }

  /// Opens the "Privacy options" form so the user can change/withdraw
  /// consent at any time (required by GDPR).
  Future<void> showPrivacyOptions() async {
    final completer = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((FormError? error) {
      if (error != null) debugPrint('Privacy options error: ${error.message}');
      if (!completer.isCompleted) completer.complete();
    });
    await completer.future;
    await _refreshConsentState();
    if (_canRequestAds) await _startSdk();
  }

  /// Called by the close button (which lives OUTSIDE the ad area).
  void dismissBanner({Duration duration = hideDuration}) {
    _hiddenUntil = DateTime.now().add(duration);
    _reshowTimer?.cancel();
    _reshowTimer = Timer(duration, () {
      _hiddenUntil = null;
      notifyListeners();
    });
    notifyListeners();
  }

  @override
  void dispose() {
    _reshowTimer?.cancel();
    super.dispose();
  }
}