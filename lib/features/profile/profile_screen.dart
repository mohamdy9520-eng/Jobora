import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../../core/services/app_settings_controller.dart';
import '../../core/services/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showLanguagePicker(BuildContext context, AppSettingsController settings) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  sheetContext.tr('language_select_title'),
                  style: AppTextStyles.h3(Theme.of(sheetContext).colorScheme.onSurface),
                ),
              ),
              // Renders directly from AppSettingsController.supportedLanguages —
              // adding a 3rd language later means adding one entry there,
              // nothing to change in this UI.
              ...AppSettingsController.supportedLanguages.map((lang) {
                return RadioListTile<String>(
                  value: lang.code,
                  groupValue: settings.locale.languageCode,
                  title: Text(lang.nativeName),
                  onChanged: (code) {
                    if (code != null) settings.setLocale(Locale(code));
                    Navigator.of(sheetContext).pop();
                  },
                );
              }),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  void _showThemePicker(BuildContext context, AppSettingsController settings) {
    final options = <ThemeMode, String>{
      ThemeMode.system: context.tr('theme_system'),
      ThemeMode.light: context.tr('theme_light'),
      ThemeMode.dark: context.tr('theme_dark'),
    };
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  sheetContext.tr('theme_select_title'),
                  style: AppTextStyles.h3(Theme.of(sheetContext).colorScheme.onSurface),
                ),
              ),
              ...options.entries.map((entry) {
                return RadioListTile<ThemeMode>(
                  value: entry.key,
                  groupValue: settings.themeMode,
                  title: Text(entry.value),
                  onChanged: (mode) {
                    if (mode != null) settings.setThemeMode(mode);
                    Navigator.of(sheetContext).pop();
                  },
                );
              }),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsController>();
    final auth = context.watch<AuthController>();
    final textColor = Theme.of(context).colorScheme.onSurface;

    final displayName = (auth.displayName?.trim().isNotEmpty ?? false)
        ? auth.displayName!.trim()
        : context.tr('profile_default_name');
    final email = auth.email ?? '';
    final currentLanguageName = AppSettingsController.supportedLanguages
        .firstWhere((l) => l.code == settings.locale.languageCode,
        orElse: () => AppSettingsController.supportedLanguages.first)
        .nativeName;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('profile_title'))),
      body: SafeArea(
        child: Center(
          child: ResponsiveContentWidth(
            maxWidth: 640,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.person, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayName, style: AppTextStyles.h3(textColor)),
                          if (email.isNotEmpty)
                            Text(email, style: AppTextStyles.bodySmall(textColor)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(context.tr('profile_settings'), style: AppTextStyles.h3(textColor)),
                const SizedBox(height: AppSpacing.md),
                _SettingsTile(
                  icon: Icons.language,
                  title: context.tr('profile_language'),
                  trailing: currentLanguageName,
                  onTap: () => _showLanguagePicker(context, settings),
                ),
                _SettingsTile(
                  icon: Icons.attach_money,
                  title: context.tr('profile_currency'),
                  trailing: settings.currency,
                  onTap: () => context.push(AppRoutes.currencySettings),
                ),
                _SettingsTile(
                  icon: Icons.dark_mode_outlined,
                  title: context.tr('profile_theme'),
                  trailing: switch (settings.themeMode) {
                    ThemeMode.dark => context.tr('theme_dark'),
                    ThemeMode.light => context.tr('theme_light'),
                    ThemeMode.system => context.tr('theme_system'),
                  },
                  onTap: () => _showThemePicker(context, settings),
                ),
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  title: context.tr('profile_notifications'),
                  onTap: () => context.push(AppRoutes.notifications),
                ),
                _SettingsTile(
                  icon: Icons.workspace_premium_outlined,
                  title: context.tr('profile_subscription'),
                  onTap: () => context.push(AppRoutes.subscriptions),
                ),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: context.tr('profile_privacy'),
                  onTap: () => context.push(AppRoutes.privacy),
                ),
                _SettingsTile(
                  icon: Icons.description_outlined,
                  title: context.tr('profile_terms'),
                  onTap: () => context.push(AppRoutes.terms),
                ),
                const SizedBox(height: AppSpacing.xl),
                OutlinedButton.icon(
                  onPressed: () => context.read<AuthController>().signOut(),
                  icon: const Icon(Icons.logout, color: AppColors.danger),
                  label: Text(context.tr('profile_logout'), style: const TextStyle(color: AppColors.danger)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.title, this.trailing, required this.onTap});
  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: AppTextStyles.bodyMedium(textColor)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) Text(trailing!, style: AppTextStyles.bodySmall(textColor)),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }
}