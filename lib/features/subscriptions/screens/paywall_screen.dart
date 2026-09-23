import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/responsive.dart';
import '../providers/subscription_provider.dart';

/// 🔗 غيّر اللينكات دي بلينك الـ GitHub Pages بتاعك بعد الرفع.
/// مثال: https://<username>.github.io/<repo>/terms.html
const String kTermsUrl = 'https://YOUR_GITHUB_USERNAME.github.io/jobora-legal/terms.html';
const String kPrivacyUrl = 'https://YOUR_GITHUB_USERNAME.github.io/jobora-legal/privacy.html';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isPurchasing = false;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SubscriptionProvider>();
      provider.fetchOfferings();
      provider.refreshCustomerInfo();
    });
  }

  /// After a successful purchase/restore: go Home, and if the paywall was
  /// opened from a Premium feature (via ?next=...), continue straight to it.
  /// Only whitelisted destinations are honored, so a crafted link can't
  /// send the user to an arbitrary route.
  void _continueAfterSuccess() {
    final next = GoRouterState.of(context).uri.queryParameters['next'];
    final router = GoRouter.of(context);

    router.go('/home');
    if (next == AppRoutes.practiceInterview) {
      router.push(AppRoutes.practiceInterview);
    }
  }

  Future<void> _handlePurchase(Package package) async {
    setState(() => _isPurchasing = true);
    final provider = context.read<SubscriptionProvider>();
    final success = await provider.purchasePackage(package);
    if (!mounted) return;
    setState(() => _isPurchasing = false);

    if (success) {
      _continueAfterSuccess();
    } else if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!)),
      );
    }
  }

  Future<void> _handleRestore() async {
    setState(() => _isRestoring = true);
    final provider = context.read<SubscriptionProvider>();
    final restored = await provider.restorePurchases();
    if (!mounted) return;
    setState(() => _isRestoring = false);

    if (restored) {
      _continueAfterSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.error ?? context.tr('paywall_restore_no_purchases'),
          ),
        ),
      );
    }
  }

  Future<void> _openLegalUrl(String baseUrl) async {
    // بيبعت ?lang=ar أو ?lang=en حسب لغة التطبيق، والصفحة نفسها بتقرأها وتبدل اللغة تلقائي.
    final langCode = Localizations.localeOf(context).languageCode;
    final uri = Uri.parse(baseUrl).replace(queryParameters: {'lang': langCode});
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('error_generic'))),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('error_generic'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Theme override صريح: يضمن إن النصوص هنا تفضل غامقة وواضحة
    // فوق خلفية بيضا حتى لو الـ ThemeData الرئيسي بتاع التطبيق
    // معمول Brightness.dark في مكان تاني.
    return Theme(
      data: Theme.of(context).copyWith(
        brightness: Brightness.light,
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: Colors.black87,
          displayColor: Colors.black87,
        ),
      ),
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);

          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: ResponsiveContentWidth(
                maxWidth: 600,
                child: Consumer<SubscriptionProvider>(
                  builder: (context, provider, _) {
                    if (provider.isPro) {
                      return _AlreadySubscribed(
                        onBackToHome: () => context.go('/home'),
                      );
                    }

                    if (provider.isLoading && provider.offerings == null) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final packages =
                        provider.offerings?.current?.availablePackages ?? [];

                    if (packages.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            provider.error ??
                                context.tr('paywall_no_packages_available'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ),
                      );
                    }

                    final package = packages.first;
                    final product = package.storeProduct;

                    return Stack(
                      children: [
                        SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 170),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: TextButton(
                                  onPressed: () => context.go('/home'),
                                  child: Text(context.tr('paywall_back_to_home')),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Center(
                                child: Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.workspace_premium_rounded,
                                    size: 36,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                context.tr('paywall_title'),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87, // ✅ لون صريح
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.tr('paywall_hero_subtitle'),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 24),
                              _BenefitsCard(
                                planName: context.tr('paywall_monthly_plan_name'),
                                planDescription:
                                context.tr('paywall_monthly_plan_desc'),
                                features: const [
                                  'paywall_feature_1',
                                  'paywall_feature_2',
                                  'paywall_feature_3',
                                  'paywall_feature_4',
                                ].map((k) => context.tr(k)).toList(),
                              ),
                            ],
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: _StickyCheckout(
                            priceLabel: _priceLabel(context, product),
                            isPurchasing: _isPurchasing,
                            isRestoring: _isRestoring,
                            onSubscribe: () => _handlePurchase(package),
                            onRestore: _handleRestore,
                            onTerms: () => _openLegalUrl(kTermsUrl),
                            onPrivacy: () => _openLegalUrl(kPrivacyUrl),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _priceLabel(BuildContext context, StoreProduct product) {
    final period = product.subscriptionPeriod ?? '';
    final isYearly = period.contains('Y');
    final cycleKey =
    isYearly ? 'paywall_renews_yearly' : 'paywall_renews_monthly';
    return context.tr(cycleKey, {'price': product.priceString});
  }
}

class _BenefitsCard extends StatelessWidget {
  final String planName;
  final String planDescription;
  final List<String> features;

  const _BenefitsCard({
    required this.planName,
    required this.planDescription,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            planName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87, // ✅ لون صريح
            ),
          ),
          const SizedBox(height: 4),
          Text(
            planDescription,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('paywall_features_title'),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black87, // ✅ لون صريح
            ),
          ),
          const SizedBox(height: 8),
          ...features.map(
                (f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle,
                      size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      f,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.black87), // ✅ لون صريح
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyCheckout extends StatelessWidget {
  final String priceLabel;
  final bool isPurchasing;
  final bool isRestoring;
  final VoidCallback onSubscribe;
  final VoidCallback onRestore;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  const _StickyCheckout({
    required this.priceLabel,
    required this.isPurchasing,
    required this.isRestoring,
    required this.onSubscribe,
    required this.onRestore,
    required this.onTerms,
    required this.onPrivacy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            priceLabel,
            textAlign: TextAlign.center,
            style:
            theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isPurchasing ? null : onSubscribe,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isPurchasing
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
                  : Text(
                context.tr('paywall_subscribe_now'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton(
                onPressed: isRestoring ? null : onRestore,
                child: isRestoring
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text(context.tr('paywall_restore_purchases')),
              ),
              const Text('•', style: TextStyle(color: Colors.grey)),
              TextButton(
                onPressed: onTerms,
                child: Text(context.tr('paywall_terms')),
              ),
              const Text('•', style: TextStyle(color: Colors.grey)),
              TextButton(
                onPressed: onPrivacy,
                child: Text(context.tr('paywall_privacy')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlreadySubscribed extends StatelessWidget {
  final VoidCallback onBackToHome;

  const _AlreadySubscribed({required this.onBackToHome});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded, size: 56, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              context.tr('paywall_already_subscribed'),
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.black87),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onBackToHome,
                child: Text(context.tr('paywall_back_to_home')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}