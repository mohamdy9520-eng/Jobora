import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';

/// One screen, two tabs: change the display name, and (for email/password
/// accounts only) change the password. Reached from ProfileScreen's edit
/// icon.
class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('edit_profile_title')),
          bottom: TabBar(
            tabs: [
              Tab(text: context.tr('edit_profile_tab_name')),
              Tab(text: context.tr('edit_profile_tab_password')),
            ],
          ),
        ),
        body: const SafeArea(
          child: TabBarView(
            children: [
              _EditNameTab(),
              _EditPasswordTab(),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditNameTab extends StatefulWidget {
  const _EditNameTab();

  @override
  State<_EditNameTab> createState() => _EditNameTabState();
}

class _EditNameTabState extends State<_EditNameTab> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // القيمة الحالية بتتعبّى من AuthController.displayName — لو الحساب
    // قديم ومفيهوش اسم أصلاً، الحقل هيبان فاضي واليوزر هيدخل اسمه هنا
    // لأول مرة.
    final auth = context.read<AuthController>();
    _nameController = TextEditingController(text: auth.displayName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await context.read<AuthController>().updateDisplayName(_nameController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('edit_profile_name_success'))),
      );
      // رجوع تلقائي لصفحة الـ Profile بعد النجاح — تأخير بسيط عشان
      // اليوزر يلاحظ رسالة النجاح قبل ما الشاشة تتقفل.
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) context.pop();
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _mapError(e));
    } catch (e) {
      setState(() => _errorMessage = context.tr('error_generic'));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return context.tr('error_network');
      default:
        return context.tr('error_generic');
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = context.isMobile ? AppSpacing.xl : AppSpacing.xxxl;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: AppSpacing.xl),
        child: ResponsiveContentWidth(
          maxWidth: 440,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: context.tr('auth_full_name')),
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? context.tr('auth_full_name') : null,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : Text(context.tr('edit_profile_save')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditPasswordTab extends StatefulWidget {
  const _EditPasswordTab();

  @override
  State<_EditPasswordTab> createState() => _EditPasswordTabState();
}

class _EditPasswordTabState extends State<_EditPasswordTab> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // Firebase بيطلب reauthentication بالباسورد الحالي قبل تغييره —
      // ده بيتم جوه AuthController.changePassword نفسها.
      await context.read<AuthController>().changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('edit_profile_password_success'))),
      );
      // رجوع تلقائي لصفحة الـ Profile بعد النجاح — تأخير بسيط عشان
      // اليوزر يلاحظ رسالة النجاح قبل ما الشاشة تتقفل.
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) context.pop();
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _mapError(e));
    } catch (e) {
      setState(() => _errorMessage = context.tr('error_generic'));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return context.tr('error_invalid_credentials');
      case 'weak-password':
        return context.tr('error_weak_password');
      case 'requires-recent-login':
        return context.tr('error_requires_recent_login');
      case 'network-request-failed':
        return context.tr('error_network');
      default:
        return context.tr('error_generic');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final horizontalPadding = context.isMobile ? AppSpacing.xl : AppSpacing.xxxl;

    // حسابات جوجل من غير باسورد إيميل — مفيش حاجة تتغيّر.
    if (!auth.hasPasswordProvider) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, size: 40, color: AppColors.primary),
              const SizedBox(height: AppSpacing.md),
              Text(
                context.tr('edit_profile_no_password_provider'),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium(Theme.of(context).colorScheme.onSurface),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: AppSpacing.xl),
        child: ResponsiveContentWidth(
          maxWidth: 440,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: _obscureCurrent,
                  decoration: InputDecoration(
                    labelText: context.tr('edit_profile_current_password'),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureCurrent
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? '' : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNew,
                  decoration: InputDecoration(
                    labelText: context.tr('edit_profile_new_password'),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNew
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? '' : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: context.tr('edit_profile_confirm_password'),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) => (v != _newPasswordController.text) ? '' : null,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : Text(context.tr('edit_profile_save')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}