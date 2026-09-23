// lib/features/legal/privacy/privacy_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/auth_controller.dart';
import '../legal_webview_screen.dart';
import 'privacy_provider.dart';

const _privacyBaseUrl = 'https://mohamdy9520-eng.github.io/jobora-legal/privacy.html';

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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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

    return LegalWebViewScreen(
      baseUrl: _privacyBaseUrl,
      titleKey: 'privacy_title',
      actions: [
        provider.isSubmitting
            ? const Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
        )
            : PopupMenuButton<String>(
          onSelected: (v) =>
          v == 'export' ? _handleExport(context) : _handleDelete(context),
          itemBuilder: (_) => [
            PopupMenuItem(value: 'export', child: Text(context.tr('privacy_export_data'))),
            PopupMenuItem(
              value: 'delete',
              child: Text(
                context.tr('privacy_delete_account'),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ],
    );
  }
}