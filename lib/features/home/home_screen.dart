import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../../core/services/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import 'home_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greetingKey() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'home_greeting_morning';
    if (hour < 18) return 'home_greeting_afternoon';
    return 'home_greeting_evening';
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final auth = context.watch<AuthController>();
    final home = context.watch<HomeController>();

    // Real display name from the account the user signed up with —
    // falls back to a generic localized label only if they never set one.
    final displayName = (auth.displayName?.trim().isNotEmpty ?? false)
        ? auth.displayName!.trim()
        : context.tr('home_default_name');

    if (home.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!home.hasApplications) {
      return Scaffold(
        body: SafeArea(
          child: EmptyState(
            icon: Icons.rocket_launch_outlined,
            title: context.tr('home_empty_title'),
            subtitle: context.tr('home_empty_subtitle'),
            actionLabel: context.tr('home_add_application'),
            onAction: () => context.push(AppRoutes.addApplication),
          ),
        ),
      );
    }

    final gridCrossAxisCount = context.isDesktop ? 4 : (context.isTablet ? 3 : 2);
    final summary = home.summary;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ResponsiveContentWidth(
            maxWidth: 960,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Text('${context.tr(_greetingKey())}, $displayName 👋',
                    style: AppTextStyles.h2(textColor)),
                const SizedBox(height: AppSpacing.xl),

                Text(context.tr('home_your_job_search'), style: AppTextStyles.h3(textColor)),
                const SizedBox(height: AppSpacing.md),
                GridView.count(
                  crossAxisCount: gridCrossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.7,
                  children: [
                    _SummaryCard(
                      value: summary.activeApplications.toString(),
                      label: context.tr('home_active_applications'),
                      color: AppColors.statusApplied,
                      icon: Icons.description_outlined,
                    ),
                    _SummaryCard(
                      value: summary.interviews.toString(),
                      label: context.tr('home_interviews'),
                      color: AppColors.statusInterview,
                      icon: Icons.event_outlined,
                    ),
                    _SummaryCard(
                      value: summary.waitingResponse.toString(),
                      label: context.tr('home_waiting_response'),
                      color: AppColors.statusScreening,
                      icon: Icons.hourglass_empty,
                    ),
                    _SummaryCard(
                      value: summary.offers.toString(),
                      label: context.tr('home_offers'),
                      color: AppColors.statusOffer,
                      icon: Icons.emoji_events_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Whole section only shows when there's real data to attend to —
                // no placeholder items when the list is empty.
                if (home.attentionItems.isNotEmpty) ...[
                  _SectionHeader(title: context.tr('home_needs_attention')),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.notifications_active_outlined, color: AppColors.warning),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                context.tr('home_actions_need_attention',
                                    {'count': home.attentionItems.length.toString()}),
                                style: AppTextStyles.bodyMedium(textColor),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: AppSpacing.xxl),
                        for (var i = 0; i < home.attentionItems.length; i++) ...[
                          if (i > 0) const SizedBox(height: AppSpacing.md),
                          _AttentionItem(
                            icon: home.attentionItems[i].icon,
                            title: home.attentionItems[i].title,
                            subtitle: home.attentionItems[i].subtitle,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],

                if (home.upcomingInterviews.isNotEmpty) ...[
                  _SectionHeader(title: context.tr('home_upcoming')),
                  const SizedBox(height: AppSpacing.md),
                  for (final interview in home.upcomingInterviews) ...[
                    AppCard(
                      onTap: () => context.push(
                          '${AppRoutes.applicationDetails}/${interview.applicationId}'),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.statusInterview.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: const Icon(Icons.event, color: AppColors.statusInterview),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(interview.jobTitle, style: AppTextStyles.bodyMedium(textColor)),
                                Text('${interview.company} · ${interview.timeLabel}',
                                    style: AppTextStyles.bodySmall(textColor)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                ],

                Text(context.tr('home_quick_actions'), style: AppTextStyles.h3(textColor)),
                const SizedBox(height: AppSpacing.md),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _QuickAction(
                        icon: Icons.add_circle_outline,
                        label: context.tr('home_add_application'),
                        onTap: () => context.push(AppRoutes.addApplication),
                      ),
                      _QuickAction(
                        icon: Icons.event_available_outlined,
                        label: context.tr('home_add_interview'),
                        // TODO: wire once the "add interview" screen/route exists.
                        onTap: () {},
                      ),
                      _QuickAction(
                        icon: Icons.upload_file_outlined,
                        label: context.tr('home_add_cv'),
                        // TODO: wire once the CV upload screen/route exists.
                        onTap: () {},
                      ),
                      _QuickAction(
                        icon: Icons.mail_outline,
                        label: context.tr('home_create_cover_letter'),
                        // TODO: wire once the cover letter screen/route exists.
                        onTap: () {},
                      ),
                      _QuickAction(
                        icon: Icons.mic_none_outlined,
                        label: context.tr('home_practice_interview'),
                        // TODO: wire once the interview practice screen/route exists.
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.value, required this.label, required this.color, required this.icon});
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Text(value, style: AppTextStyles.h1(textColor)),
          Text(label, style: AppTextStyles.bodySmall(textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.h3(Theme.of(context).colorScheme.onSurface));
  }
}

class _AttentionItem extends StatelessWidget {
  const _AttentionItem({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.bodyMedium(textColor)),
              Text(subtitle, style: AppTextStyles.bodySmall(textColor)),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: 96,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: AppSpacing.sm),
              Text(label, style: AppTextStyles.bodySmall(textColor), textAlign: TextAlign.center, maxLines: 2),
            ],
          ),
        ),
      ),
    );
  }
}