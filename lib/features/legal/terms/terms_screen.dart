import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/app_settings_controller.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../legal_content_provider.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LegalContentProvider('terms_of_service'),
      child: const _TermsView(),
    );
  }
}

class _TermsView extends StatelessWidget {
  const _TermsView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LegalContentProvider>();
    final languageCode = context.watch<AppSettingsController>().locale.languageCode;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('terms_title'))),
      body: SafeArea(
        child: Builder(builder: (context) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null || provider.content == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(context.tr('legal_error_loading'), textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton(
                      onPressed: () => context.read<LegalContentProvider>().load(),
                      child: Text(context.tr('retry')),
                    ),
                  ],
                ),
              ),
            );
          }
          return Center(
            child: ResponsiveContentWidth(
              maxWidth: 720,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  Text(
                    provider.content!.localized(languageCode),
                    style: AppTextStyles.bodyMedium(textColor),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}