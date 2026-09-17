import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../providers/subscription_provider.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  Future<void> _purchase(BuildContext context, Package package) async {
    final provider = context.read<SubscriptionProvider>();
    final ok = await provider.purchase(package);
    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr('subscriptions_purchase_success'))));
    } else if (provider.error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr('subscriptions_error'))));
    }
  }

  Future<void> _restore(BuildContext context) async {
    final ok = await context.read<SubscriptionProvider>().restore();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? context.tr('subscriptions_restore_success') : context.tr('subscriptions_error'))));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SubscriptionProvider>();
    final textColor = Theme.of(context).colorScheme.onSurface;
    final status = provider.status;
    final packages = provider.currentOffering?.availablePackages ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('subscriptions_title'))),
      body: SafeArea(
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
          child: ResponsiveContentWidth(
            maxWidth: 640,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('subscriptions_current_plan'), style: AppTextStyles.bodySmall(textColor)),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          status.isActive
                              ? (status.productIdentifier ?? '')
                              : context.tr('subscriptions_free_plan'),
                          style: AppTextStyles.h3(textColor),
                        ),
                        if (status.isActive && status.expirationDate != null)
                          Text(
                            status.willRenew
                                ? '${context.tr('subscriptions_renews_on')} ${status.expirationDate!.toLocal()}'
                                : '${context.tr('subscriptions_expires_on')} ${status.expirationDate!.toLocal()}',
                            style: AppTextStyles.bodySmall(textColor),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                ...packages.map((package) {
                  final product = package.storeProduct;
                  return Card(
                    child: ListTile(
                      title: Text(product.title),
                      subtitle: Text(product.description),
                      trailing: provider.isPurchasing
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : FilledButton(
                        onPressed: () => _purchase(context, package),
                        child: Text(product.priceString),
                      ),
                    ),
                  );
                }),
                if (packages.isEmpty && !status.isActive)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(context.tr('subscriptions_no_offers'), textAlign: TextAlign.center),
                  ),
                const SizedBox(height: AppSpacing.xl),
                OutlinedButton(
                  onPressed: () => _restore(context),
                  child: Text(context.tr('subscriptions_restore')),
                ),
                if (status.isActive && status.managementUrl != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: () => launchUrl(Uri.parse(status.managementUrl!)),
                    child: Text(context.tr('subscriptions_manage')),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}