import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../../features/subscriptions/providers/subscription_provider.dart';
import '../localization/app_localizations.dart';
import 'ad_config.dart';
import 'ads_controller.dart';

/// Adaptive anchored banner with a close button.
///
/// AdMob-policy notes (why it's built this way):
///  * The close button is in a separate strip ABOVE the ad, never
///    overlapping it, so it can't be mistaken for part of the ad or
///    cause accidental ad clicks.
///  * The strip is labelled "Ad" and the ad has spacing around it,
///    away from the navigation controls.
///  * Hidden while the keyboard is open, and for Pro subscribers.
///  * The banner is NOT covered, resized or altered in any way.
class AppBannerAd extends StatefulWidget {
  const AppBannerAd({super.key, this.handleBottomSafeArea = false});

  /// Only needed when the banner is the bottom-most element (tablet/rail
  /// layout). On phones the NavigationBar below it handles the inset.
  final bool handleBottomSafeArea;

  @override
  State<AppBannerAd> createState() => _AppBannerAdState();
}

class _AppBannerAdState extends State<AppBannerAd>
    with WidgetsBindingObserver {
  static const int _maxRetries = 3;
  static const double _maxAdWidth = 728;

  BannerAd? _ad;
  bool _loaded = false;
  bool _eligible = false;
  int? _requestedWidth;
  int _retries = 0;
  int _generation = 0; // invalidates callbacks of superseded loads
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _retryTimer?.cancel();
    _generation++;
    _ad?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _eligible &&
        _ad == null &&
        _requestedWidth != null) {
      _retries = 0;
      _load(_requestedWidth!);
    }
  }

  void _post(VoidCallback fn) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) fn();
    });
  }

  /// Called from build(): only records intent, real work is post-frame.
  void _sync({required bool eligible, required int width}) {
    _eligible = eligible;
    if (!eligible) {
      if (_ad != null || _requestedWidth != null) {
        _post(() {
          if (!_eligible) _teardown();
        });
      }
      return;
    }
    if (_requestedWidth != width) {
      _requestedWidth = width;
      _post(() {
        if (_eligible) _load(width);
      });
    }
  }

  void _teardown() {
    _generation++;
    _retryTimer?.cancel();
    _ad?.dispose();
    setState(() {
      _ad = null;
      _loaded = false;
      _requestedWidth = null;
      _retries = 0;
    });
  }

  Future<void> _load(int width) async {
    final unitId = AdConfig.bannerUnitId;
    if (unitId == null) return;

    _retryTimer?.cancel();
    if (mounted) setState(() => _loaded = false);
    _ad?.dispose();
    _ad = null;
    final gen = ++_generation;

    final size =
    await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || gen != _generation) return;
    if (size == null) {
      _scheduleRetry(width, gen);
      return;
    }

    final ad = BannerAd(
      adUnitId: unitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted || gen != _generation) return;
          setState(() {
            _loaded = true;
            _retries = 0;
          });
        },
        onAdFailedToLoad: (failed, error) {
          failed.dispose();
          debugPrint('Banner failed: ${error.code} ${error.message}');
          if (!mounted || gen != _generation) return;
          setState(() {
            _ad = null;
            _loaded = false;
          });
          _scheduleRetry(width, gen);
        },
      ),
    );
    _ad = ad;
    try {
      await ad.load();
    } catch (e) {
      debugPrint('Banner load threw: $e');
    }
  }

  void _scheduleRetry(int width, int gen) {
    if (_retries >= _maxRetries) return;
    final delay = Duration(seconds: 15 * (1 << _retries)); // 15s, 30s, 60s
    _retries++;
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      if (mounted && _eligible && gen == _generation) _load(width);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ads = context.watch<AdsController>();
    final isPro = context.select<SubscriptionProvider, bool>((s) => s.isPro);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final eligible = ads.shouldShowBanner && !isPro;
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(constraints.maxWidth, _maxAdWidth).floor();
        _sync(eligible: eligible, width: width);

        final ad = _ad;
        if (!eligible || keyboardOpen || !_loaded || ad == null) {
          return const SizedBox.shrink();
        }

        return Material(
          color: theme.navigationBarTheme.backgroundColor ??
              theme.colorScheme.surfaceContainer,
          child: SafeArea(
            top: false,
            bottom: widget.handleBottomSafeArea,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(height: 1),
                // Close strip — completely separate from the ad.
                SizedBox(
                  height: 32,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 12),
                        child: Text(
                          context.tr('ad_label'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: context.tr('ad_close'),
                        onPressed: ads.dismissBanner,
                        iconSize: 18,
                        padding: EdgeInsets.zero,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(48, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8), // gap between close button and ad
                SizedBox(
                  width: ad.size.width.toDouble(),
                  height: ad.size.height.toDouble(),
                  child: AdWidget(ad: ad),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
  }
}