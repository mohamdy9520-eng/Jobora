import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../../core/services/app_settings_controller.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';

class CurrencySelectionScreen extends StatelessWidget {
  const CurrencySelectionScreen({super.key, this.fromSettings = false});

  /// When true, this screen was pushed from Profile/Settings rather than
  /// the onboarding flow: it pops back to the caller instead of advancing
  /// go_router to the onboarding step, and shows a "Save" label instead
  /// of "Continue".
  final bool fromSettings;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsController>();
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('onboarding_choose_currency'))),
      body: SafeArea(
        child: Center(
          child: ResponsiveContentWidth(
            maxWidth: 560,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView.separated(
                      itemCount: AppSettingsController.supportedCurrencies.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final currency = AppSettingsController.supportedCurrencies[index];
                        final selected = settings.currency == currency;
                        return InkWell(
                          onTap: () => settings.setCurrency(currency),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: selected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).dividerColor,
                                width: selected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                    child: Text(currency, style: AppTextStyles.bodyLarge(textColor))),
                                if (selected)
                                  Icon(Icons.check_circle,
                                      color: Theme.of(context).colorScheme.primary),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (fromSettings) {
                        Navigator.of(context).pop();
                      } else {
                        context.go(AppRoutes.onboarding);
                      }
                    },
                    child: Text(context.tr(fromSettings ? 'save' : 'continue')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}