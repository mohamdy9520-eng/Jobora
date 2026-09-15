import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _agreedToTerms = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _canSubmit => _agreedToTerms && !_isSubmitting;

  Future<void> _submit() async {
    // Guard: button is disabled unless terms are accepted, and we bail out
    // early to prevent duplicate accounts from a fast double-tap.
    if (!_canSubmit) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName(_nameController.text.trim());
        await user.reload();
        await user.sendEmailVerification();
        // If you use RevenueCat for subscriptions, link it here:
        // await Purchases.logIn(user.uid);
      }
      // No need to call AuthController.setUser here — main.dart listens to
      // FirebaseAuth.instance.authStateChanges() and updates it automatically,
      // which triggers the router redirect.
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _mapAuthError(e));
    } catch (e) {
      setState(() => _errorMessage = context.tr('error_generic'));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // Maps common FirebaseAuth error codes to localized messages.
  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return context.tr('error_email_in_use');
      case 'invalid-email':
        return context.tr('error_invalid_email');
      case 'weak-password':
        return context.tr('error_weak_password');
      case 'network-request-failed':
        return context.tr('error_network');
      default:
        return context.tr('error_generic');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final horizontalPadding = context.isMobile ? AppSpacing.xl : AppSpacing.xxxl;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: ResponsiveContentWidth(
              maxWidth: 440,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(context.tr('auth_signup'), style: AppTextStyles.h1(textColor)),
                    const SizedBox(height: AppSpacing.xxl),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: context.tr('auth_full_name')),
                      validator: (v) => (v == null || v.trim().isEmpty) ? '' : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(labelText: context.tr('auth_email')),
                      validator: (v) => (v == null || !v.contains('@')) ? '' : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(labelText: context.tr('auth_password')),
                      validator: (v) => (v == null || v.length < 6) ? '' : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _confirmController,
                      obscureText: true,
                      decoration: InputDecoration(labelText: context.tr('auth_confirm_password')),
                      validator: (v) =>
                      (v != _passwordController.text) ? '' : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Checkbox(
                          value: _agreedToTerms,
                          onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                        ),
                        Expanded(child: Text(context.tr('auth_agree_terms'))),
                      ],
                    ),
                    if (_errorMessage != null)
                      Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    const SizedBox(height: AppSpacing.sm),
                    ElevatedButton(
                      // Disabled entirely unless Terms & Privacy are accepted.
                      onPressed: _canSubmit ? _submit : null,
                      child: _isSubmitting
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : Text(context.tr('auth_signup')),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(context.tr('auth_have_account')),
                        TextButton(
                          onPressed: () => context.go(AppRoutes.login),
                          child: Text(context.tr('auth_login')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}