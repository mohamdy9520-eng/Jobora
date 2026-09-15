import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/router/app_router.dart';
import '../../core/services/app_settings_controller.dart';
import '../../core/services/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/localization/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decideNextRoute());
  }

  Future<void> _decideNextRoute() async {
    final settings = context.read<AppSettingsController>();
    final auth = context.read<AuthController>();

    // Settings load from SharedPreferences; auth state comes from
    // FirebaseAuth.authStateChanges() wired in main.dart.
    while (!settings.isLoaded || auth.isInitializing) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    if (!mounted) return;

    if (!settings.onboardingCompleted) {
      context.go(AppRoutes.language);
    } else if (!auth.isAuthenticated) {
      context.go(AppRoutes.login);
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: const Icon(Icons.work_outline, size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(context.tr('app_name'), style: AppTextStyles.h1(Colors.white)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.tr('tagline'),
              style: AppTextStyles.bodyMedium(Colors.white.withValues(alpha: 0.85)),
            ),
          ],
        ),
      ),
    );
  }
}