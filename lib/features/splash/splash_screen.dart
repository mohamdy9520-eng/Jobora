import 'dart:math' as math;

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

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // الحد الأدنى لظهور الـ Splash عشان الانتقال ميبقاش مفاجئ
  static const _minDisplay = Duration(milliseconds: 900);

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.9, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) => _decideNextRoute());
  }

  Future<void> _waitForInit(
      AppSettingsController settings,
      AuthController auth,
      ) async {
    // Settings load from SharedPreferences; auth state comes from
    // FirebaseAuth.authStateChanges() wired in main.dart.
    while (!settings.isLoaded || auth.isInitializing) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _decideNextRoute() async {
    final settings = context.read<AppSettingsController>();
    final auth = context.read<AuthController>();

    await Future.wait([
      Future.delayed(_minDisplay),
      _waitForInit(settings, auth),
    ]);

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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // responsive: عرض اللوجو نسبة من الشاشة مع حد أقصى للتابلت/الديسكتوب
    final logoWidth = math.min(size.width * 0.62, 360.0);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_SplashColors.top, _SplashColors.bottom],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: _WavesPainter()),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _scale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // اللوجو (الشنطة + الجرس + كلمة Jobora) كـ PNG شفاف
                          Image.asset(
                            'assets/splash/logo.png',
                            width: logoWidth,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.work_outline,
                              size: logoWidth * 0.4,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              context.tr('tagline'),
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium(
                                _SplashColors.accent,
                              ),
                            ),
                          ),
                          SizedBox(height: size.height * 0.08),
                          const SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 4,
                              color: _SplashColors.accent,
                              backgroundColor: Color(0x3300E5B0),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            context.tr('loading'),
                            style: AppTextStyles.bodyMedium(
                              _SplashColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ألوان خاصة بالـ Splash بس (لازم تتطابق مع لون الـ Native Splash)
class _SplashColors {
  static const top = Color(0xFF0B5A57);
  static const bottom = Color(0xFF053B3D);
  static const accent = Color(0xFF3DF2C8);
  static const wave = Color(0xFF14C9A2);
}

/// موجة أعلى الشمال + موجة أسفل اليمين
class _WavesPainter extends CustomPainter {
  const _WavesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final topPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          _SplashColors.wave.withValues(alpha: 0.85),
          _SplashColors.wave.withValues(alpha: 0.0),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w * 0.5, h * 0.18));

    final top = Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.3, 0)
      ..quadraticBezierTo(w * 0.22, h * 0.08, 0, h * 0.14)
      ..close();
    canvas.drawPath(top, topPaint);

    final bottomPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          _SplashColors.wave.withValues(alpha: 0.0),
          _SplashColors.wave.withValues(alpha: 0.85),
        ],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(w * 0.5, h * 0.82, w * 0.5, h * 0.18));

    final bottom = Path()
      ..moveTo(w, h)
      ..lineTo(w * 0.62, h)
      ..quadraticBezierTo(w * 0.85, h * 0.93, w, h * 0.84)
      ..close();
    canvas.drawPath(bottom, bottomPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}