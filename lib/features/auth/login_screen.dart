import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscure = true;
  String? _errorMessage;

  Future<void> _submit() async {
    if (_isSubmitting) return; // guard against double submission
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
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

  // دالة تسجيل الدخول باستخدام جوجل
  Future<void> _signInWithGoogle() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // 1. بدء عملية اختيار حساب جوجل
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isSubmitting = false);
        return;
      }

      // 2. الحصول على تفاصيل المصادقة
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. إنشاء بيانات الاعتماد الخاصة بـ Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. تسجيل الدخول في فايربيس
      await FirebaseAuth.instance.signInWithCredential(credential);
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
      case 'invalid-email':
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return context.tr('error_invalid_credentials');
      case 'user-disabled':
        return context.tr('error_user_disabled');
      case 'too-many-requests':
        return context.tr('error_too_many_requests');
      case 'network-request-failed':
        return context.tr('error_network');
      default:
        return context.tr('error_generic');
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = context.tr('auth_email'));
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('auth_reset_email_sent'))),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _mapAuthError(e));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final horizontalPadding = context.isMobile ? AppSpacing.xl : AppSpacing.xxxl;

    return Scaffold(
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
                    const SizedBox(height: AppSpacing.xxxl),
                    Text(context.tr('auth_login'), style: AppTextStyles.h1(textColor)),
                    const SizedBox(height: AppSpacing.xxxl),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(labelText: context.tr('auth_email')),
                      validator: (v) =>
                      (v == null || !v.contains('@')) ? context.tr('auth_email') : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: context.tr('auth_password'),
                        suffixIcon: IconButton(
                          // تصحيح منطق الأيقونة: عين مشطوبة عندما يكون الباسورد مخفياً، وعين مفتوحة عندما يكون ظاهراً
                          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6) ? context.tr('auth_password') : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isSubmitting ? null : _resetPassword,
                        child: Text(context.tr('auth_forgot_password')),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : Text(context.tr('auth_login')),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Text(context.tr('auth_or')),
                      ),
                      const Expanded(child: Divider()),
                    ]),
                    const SizedBox(height: AppSpacing.lg),
                    OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _signInWithGoogle, // تفعيل زر جوجل
                      icon: const Icon(Icons.g_mobiledata, size: 28),
                      label: Text(context.tr('auth_continue_google')),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(context.tr('auth_no_account')),
                        TextButton(
                          onPressed: () => context.go(AppRoutes.signup),
                          child: Text(context.tr('auth_signup')),
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