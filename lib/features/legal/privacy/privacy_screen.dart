import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/app_settings_controller.dart';
import '../../../core/services/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import 'privacy_provider.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PrivacyProvider(),
      child: const _PrivacyView(),
    );
  }
}

class _PrivacyView extends StatelessWidget {
  const _PrivacyView();

  Future<void> _handleExport(BuildContext context) async {
    final uid = context.read<AuthController>().uid;
    if (uid == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(c.tr('privacy_export_data')),
        content: Text(c.tr('privacy_export_data_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(c.tr('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(c.tr('confirm'))),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await context.read<PrivacyProvider>().requestDataExport(uid);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? context.tr('privacy_export_requested') : context.tr('legal_error_loading'))),
    );
  }

  Future<String?> _promptPassword(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(c.tr('privacy_reauth_title')),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(hintText: c.tr('privacy_reauth_password_hint')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(c.tr('cancel'))),
          FilledButton(
            onPressed: () => Navigator.pop(c, controller.text),
            child: Text(c.tr('confirm')),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context) async {
    final auth = context.read<AuthController>();
    final uid = auth.uid;
    if (uid == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(c.tr('privacy_delete_account')),
        content: Text(c.tr('privacy_delete_account_warning')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(c.tr('cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(c, true),
            child: Text(c.tr('privacy_delete_account_confirm')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final provider = context.read<PrivacyProvider>();
    try {
      await provider.deleteAccount(uid);
      // Auth stream + router redirect handles navigation to /login once
      // FirebaseAuth reports the user as signed out.
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        if (!context.mounted) return;
        final password = await _promptPassword(context);
        if (password == null || password.isEmpty || !context.mounted) return;
        try {
          await provider.reauthenticate(password);
          await provider.deleteAccount(uid);
        } catch (_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(context.tr('legal_error_loading'))));
        }
      } else if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.tr('legal_error_loading'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrivacyProvider>();
    final languageCode = context.watch<AppSettingsController>().locale.languageCode;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('privacy_title'))),
      body: SafeArea(
        child: Builder(builder: (context) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && provider.content == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(context.tr('legal_error_loading'), textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton(
                      onPressed: () => context.read<PrivacyProvider>().load(),
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
                  if (provider.content != null)
                    Text(provider.content!.localized(languageCode), style: AppTextStyles.bodyMedium(textColor)),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(context.tr('privacy_your_data'), style: AppTextStyles.h3(textColor)),
                  const SizedBox(height: AppSpacing.md),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.download_outlined, color: AppColors.primary),
                    title: Text(context.tr('privacy_export_data')),
                    trailing: provider.isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.chevron_right),
                    onTap: provider.isSubmitting ? null : () => _handleExport(context),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                    title: Text(context.tr('privacy_delete_account'), style: const TextStyle(color: AppColors.danger)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _handleDelete(context),
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