import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../../core/services/app_settings_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _icons = [Icons.fact_check_outlined, Icons.event_available_outlined, Icons.rocket_launch_outlined];

  Future<void> _finish() async {
    await context.read<AppSettingsController>().completeOnboarding();
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final titles = ['onboarding_title_1', 'onboarding_title_2', 'onboarding_title_3'];
    final subtitles = [
      'onboarding_subtitle_1',
      'onboarding_subtitle_2',
      'onboarding_subtitle_3'
    ];

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ResponsiveContentWidth(
            maxWidth: 560,
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(onPressed: _finish, child: Text(context.tr('skip'))),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemCount: 3,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxxl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_icons[index], size: 56, color: AppColors.primary),
                          ),
                          const SizedBox(height: AppSpacing.xxxl),
                          Text(context.tr(titles[index]),
                              style: AppTextStyles.h2(textColor), textAlign: TextAlign.center),
                          const SizedBox(height: AppSpacing.md),
                          Text(context.tr(subtitles[index]),
                              style: AppTextStyles.bodyLarge(textColor.withValues(alpha: 0.7)),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                        (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _page == i ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _page == i ? AppColors.primary : Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_page < 2) {
                          _controller.nextPage(
                              duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
                        } else {
                          _finish();
                        }
                      },
                      child: Text(_page < 2 ? context.tr('continue') : context.tr('get_started')),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}