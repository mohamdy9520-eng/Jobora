import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_router.dart';
import '../../core/services/app_settings_controller.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsController>();
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ResponsiveContentWidth(
            maxWidth: 480,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xxxl),
                  Text('Choose your language\nاختر لغتك',
                      style: AppTextStyles.h2(textColor), textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.xxxl),
                  _LanguageOption(
                    label: 'English',
                    selected: settings.locale.languageCode == 'en',
                    onTap: () => settings.setLocale(const Locale('en')),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _LanguageOption(
                    label: 'العربية',
                    selected: settings.locale.languageCode == 'ar',
                    onTap: () => settings.setLocale(const Locale('ar')),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => context.go(AppRoutes.currency),
                    child: const Text('Continue / متابعة'),
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

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? scheme.primary : Theme.of(context).dividerColor, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppTextStyles.bodyLarge(scheme.onSurface))),
            if (selected) Icon(Icons.check_circle, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}