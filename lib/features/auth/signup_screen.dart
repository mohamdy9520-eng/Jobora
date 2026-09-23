import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart'; // أضفنا حزمة جوجل
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../../core/services/auth_controller.dart';
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

  // متغيرات التحكم في إظهار/إخفاء الكلمة لكل حقل على حدة
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _errorMessage;

  bool get _canSubmit => _agreedToTerms && !_isSubmitting;

  void _openTerms() {
    // فتح شاشة الشروط جوه التطبيق نفسه، مش في متصفح خارجي، عشان اليوزر
    // يرجع لنفس فورم التسجيل بنفس البيانات بعد ما يقرأها.
    context.push(AppRoutes.terms);
  }

  Future<void> _submit() async {
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

        if (mounted) {
          final authController = context.read<AuthController>();

          // مهم: الـ authStateChanges اتطلق قبل ما نعمل updateDisplayName،
          // يعني الـ AuthController لسه شايل نسخة قديمة من اليوزر من غير اسم.
          // من غير السطر ده، هوم سكرين هيعرض الاسم الافتراضي لحد ما اليوزر
          // يقفل التطبيق ويفتحه تاني. بنجبر الكنترولر يتحدث دلوقتي بنفس
          // الـ User المحدّث (اللي دلوقتي فيه الاسم بعد الـ reload).
          await authController.setUser(FirebaseAuth.instance.currentUser);

          // بيعمل الـ 'users' profile document لأول مرة، وياخد username
          // مبدئي من جزء الإيميل قبل الـ @ (طالما مفيش profile قديم أصلاً).
          await authController.ensureProfile();
        }

        await user.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _mapAuthError(e));
    } catch (e) {
      setState(() => _errorMessage = context.tr('error_generic'));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // دالة تسجيل / إنشاء الحساب باستخدام جوجل
  Future<void> _signInWithGoogle() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isSubmitting = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // تسجيل الدخول/الحساب بجوجل بيجيب الاسم جاهز من حساب جوجل نفسه
      // ضمن الـ User object، فـ authStateChanges هيطلق ومعاه الاسم من
      // أول مرة — مفيش داعي لأي setUser يدوي هنا.
      await FirebaseAuth.instance.signInWithCredential(credential);

      // لو ده أول مرة اليوزر يدخل بجوجل، نعمله برضه profile document
      // (ensureProfile بتتأكد إنها متكتبش فوق username موجود بالفعل).
      if (mounted) {
        await context.read<AuthController>().ensureProfile();
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _mapAuthError(e));
    } catch (e) {
      setState(() => _errorMessage = context.tr('error_generic'));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

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
    final primaryColor = Theme.of(context).colorScheme.primary;
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

                    // حقل كلمة المرور مع أيقونة العين المصححة
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: context.tr('auth_password'),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6) ? '' : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // حقل تأكيد كلمة المرور مع أيقونة العين المصححة
                    TextFormField(
                      controller: _confirmController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: context.tr('auth_confirm_password'),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (v) => (v != _passwordController.text) ? '' : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    Row(
                      children: [
                        Checkbox(
                          value: _agreedToTerms,
                          onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: _openTerms,
                            child: RichText(
                              text: TextSpan(
                                text: context.tr('auth_agree_prefix'),
                                style: TextStyle(color: textColor, fontSize: 14),
                                children: [
                                  TextSpan(
                                    text: context.tr('auth_terms_conditions'),
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    ElevatedButton(
                      onPressed: _canSubmit ? _submit : null,
                      child: _isSubmitting
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : Text(context.tr('auth_signup')),
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
                      onPressed: _isSubmitting ? null : _signInWithGoogle,
                      icon: const Icon(Icons.g_mobiledata, size: 28),
                      label: Text(context.tr('auth_continue_google')),
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