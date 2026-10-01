import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../../core/services/auth_controller.dart';
import '../../core/services/tab_refresh_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/app_card.dart';
import '../applications/providers/application_provider.dart';
import '../cv/providers/cv_provider.dart';
import '../cv_builder/models/cv_builder_model.dart';
import '../cv_builder/providers/cv_builder_provider.dart';
import '../interviews/providers/interview_provider.dart';
import 'cv_completeness_analyzer.dart';
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
    // Rebuild whenever the user returns to this tab (or resumes the app
    // while on it) so time-based values (greeting, upcoming interviews,
    // stale applications) are never out of date.
    watchTabRefresh(context, 0);

    // Changes whenever MainShell sends this tab back to the top (the user
    // left the tab). Used as the ListView key below so it starts at offset 0.
    final scrollEpoch = watchTabScrollReset(context, 0);

    final textColor = Theme.of(context).colorScheme.onSurface;
    final auth = context.watch<AuthController>();
    final home = context.watch<HomeController>();

    // Real, live data — these providers are Firestore streams, so
    // everything below updates the moment something changes anywhere in
    // the app, no manual refresh needed.
    final applicationProvider = context.watch<ApplicationProvider>();
    final interviewProvider = context.watch<InterviewProvider>();
    final cvProvider = context.watch<CvProvider>();
    final cvBuilderProvider = context.watch<CvBuilderProvider>();

    // Real display name from the account the user signed up with —
    // falls back to a generic localized label only if they never set one.
    final displayName = (auth.displayName?.trim().isNotEmpty ?? false)
        ? auth.displayName!.trim()
        : context.tr('home_default_name');

    // NOTE: AuthController must expose these two as nullable Strings.
    // If your fields are named differently, change only these two lines.
    final String? username = auth.username;
    final String? jobTitle = auth.jobTitle;

    final summary = HomeSummary(
      applications: applicationProvider.applications.length,
      interviews: interviewProvider.interviews.length,
      cvs: cvProvider.cvs.length,
    );

    // The CV the user built with the CV Builder, described as plain values
    // so CvCompletenessAnalyzer can tell what's missing. Blank drafts
    // (created the moment the user opens the Builder) are ignored, so an
    // empty draft doesn't produce a wall of "you're missing everything".
    final CvCompletenessInput? builderCv =
    _builderInput(cvBuilderProvider.cvs);

    // Local analysis of the latest uploaded file (PDF text extraction runs
    // on-device, no API). null while it's still being analyzed.
    final latestUpload =
    cvProvider.cvs.isEmpty ? null : cvProvider.cvs.first;
    final fileAnalysis =
    latestUpload == null ? null : cvProvider.analysisFor(latestUpload.id);

    // HomeController's builders are pure — feed them the live lists from
    // their own providers instead of relying on HomeController to fetch
    // application/interview/cv data itself. `tr: context.tr` is passed
    // through so their (template-based) strings come out localized
    // instead of hardcoded.
    final insights =
    home.buildInsights(applicationProvider.applications, tr: context.tr);
    final attentionItems = home.buildAttentionItems(
        applicationProvider.applications,
        tr: context.tr);
    final cvTips = home.buildCvTips(
      cvProvider.cvs,
      builderCv: builderCv,
      fileAnalysis: fileAnalysis,
      tr: context.tr,
    );
    final upcomingInterviews = home.buildUpcomingInterviews(
        interviewProvider.interviews,
        tr: context.tr);

    // home.isLoading/hasError only cover whatever HomeController fetches
    // on its own — applications/interviews/cv have their own isLoading
    // via their providers and keep working independently of this.
    final showError = home.hasError && !home.isLoading;

    return Scaffold(
      // Account details live in the app bar: name, @username, job title.
      appBar: _ProfileAppBar(
        greeting: context.tr(_greetingKey()),
        name: displayName,
        username: username,
        jobTitle: jobTitle,
      ),
      // No floatingActionButton here on purpose — "add application"
      // already lives on the Applications screen.
      body: home.isLoading
          ? const Center(child: CircularProgressIndicator())
          : showError
          ? _HomeErrorState(onRetry: () => home.load())
          : SafeArea(
        top: false, // the app bar already handles the top inset
        child: Center(
          child: ResponsiveContentWidth(
            maxWidth: 960,
            child: ListView(
              key: ValueKey('home-scroll-$scrollEpoch'),
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                // ── Counters (display only, not tappable) ──
                Text(context.tr('home_your_job_search'),
                    style: AppTextStyles.h3(textColor)),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 156,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _CounterCard(
                          value: summary.applications.toString(),
                          label:
                          context.tr('home_total_applications'),
                          color: AppColors.statusApplied,
                          icon: Icons.description_outlined,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _CounterCard(
                          value: summary.interviews.toString(),
                          label: context.tr('home_total_interviews'),
                          color: AppColors.statusInterview,
                          icon: Icons.event_outlined,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _CounterCard(
                          value: summary.cvs.toString(),
                          label: context.tr('home_total_cvs'),
                          color: AppColors.primary,
                          icon: Icons.badge_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Practice interview ─────────────
                // Everyone opens the practice setup screen: free users
                // get ONE lifetime session, Pro users are unlimited.
                // The setup screen itself shows "sessions left" and swaps
                // the start button for an upgrade card (→ paywall, with
                // ?next= to continue back here after purchase) once the
                // free session has been used.
                _PracticeInterviewCard(
                  title: context.tr('home_practice_title'),
                  subtitle: context.tr('home_practice_subtitle'),
                  onTap: () => context.push(AppRoutes.practiceInterview),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Insights: short observations derived from the
                // user's own data. Skipped entirely when
                // there's nothing to say.
                if (insights.isNotEmpty) ...[
                  _SectionHeader(
                      title: context.tr('home_insights_title')),
                  const SizedBox(height: AppSpacing.md),
                  for (final insight in insights) ...[
                    AppCard(
                      child: Row(
                        children: [
                          Icon(insight.icon,
                              size: 20, color: AppColors.primary),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(insight.message,
                                style: AppTextStyles.bodyMedium(
                                    textColor)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                ],

                // Only shows when there's real data to attend to.
                if (attentionItems.isNotEmpty) ...[
                  _SectionHeader(
                      title: context.tr('home_needs_attention')),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                                Icons.notifications_active_outlined,
                                color: AppColors.warning),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                context.tr(
                                    'home_actions_need_attention', {
                                  'count': attentionItems.length
                                      .toString()
                                }),
                                style: AppTextStyles.bodyMedium(
                                    textColor),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: AppSpacing.xxl),
                        for (var i = 0;
                        i < attentionItems.length;
                        i++) ...[
                          if (i > 0)
                            const SizedBox(height: AppSpacing.md),
                          _AttentionItem(
                            icon: attentionItems[i].icon,
                            title: attentionItems[i].title,
                            subtitle: attentionItems[i].subtitle,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],

                // ── Upcoming interviews (live from InterviewProvider) ──
                if (upcomingInterviews.isNotEmpty) ...[
                  _SectionHeader(title: context.tr('home_upcoming')),
                  const SizedBox(height: AppSpacing.md),
                  for (final interview in upcomingInterviews) ...[
                    AppCard(
                      onTap: () => context.push(
                          '${AppRoutes.applicationDetails}/${interview.applicationId}'),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.statusInterview
                                  .withValues(alpha: 0.12),
                              borderRadius:
                              BorderRadius.circular(AppRadius.md),
                            ),
                            child: const Icon(Icons.event,
                                color: AppColors.statusInterview),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(interview.jobTitle,
                                    style: AppTextStyles.bodyMedium(
                                        textColor)),
                                Text(
                                    '${interview.company} · ${interview.timeLabel}',
                                    style: AppTextStyles.bodySmall(
                                        textColor)),
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

                // ── Quick actions ────────────────────────────
                // Responsive grid that always fills the available
                // width (the same 960px-max column as everything
                // else on this screen):
                //   • wide screens (tablet): row(s) of up to 4 cards
                //   • phones: 2 columns, no horizontal scrolling
                // 5 actions total now — on phones that's a 2×2 grid
                // plus one card alone on a third row; on tablets it's
                // 4 + 1. LayoutBuilder/Wrap below handles both without
                // any special-casing.
                Text(context.tr('home_quick_actions'),
                    style: AppTextStyles.h3(textColor)),
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = AppSpacing.md;
                    final columns =
                    constraints.maxWidth >= 560 ? 4 : 2;
                    final itemWidth = (constraints.maxWidth -
                        spacing * (columns - 1)) /
                        columns;

                    final actions = [
                      _QuickAction(
                        icon: Icons.add_circle_outline,
                        label: context.tr('home_add_application'),
                        onTap: () =>
                            context.push(AppRoutes.addApplication),
                      ),
                      _QuickAction(
                        icon: Icons.event_available_outlined,
                        label: context.tr('home_add_interview'),
                        onTap: () =>
                            context.push(AppRoutes.addInterview),
                      ),
                      // ── Build a CV from scratch (middle card) ──
                      // Distinct from "home_add_cv" below, which
                      // uploads an existing file. This one starts the
                      // CvBuilderEntryScreen → CvBuilderFormScreen flow.
                      _QuickAction(
                        icon: Icons.auto_awesome_outlined,
                        label: context.tr('home_build_cv'),
                        onTap: () =>
                            context.push(AppRoutes.cvBuilder),
                      ),
                      _QuickAction(
                        icon: Icons.upload_file_outlined,
                        label: context.tr('home_add_cv'),
                        onTap: () =>
                            context.push(AppRoutes.cvUpload),
                      ),
                      _QuickAction(
                        icon: Icons.mail_outline,
                        label:
                        context.tr('home_create_cover_letter'),
                        onTap: () =>
                            context.push(AppRoutes.coverLetter),
                      ),
                    ];

                    // To center smaller fixed-size cards instead of
                    // stretching them, add
                    //   alignment: WrapAlignment.center,
                    // below and clamp itemWidth (e.g. min(itemWidth, 160)).
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        for (final action in actions)
                          SizedBox(width: itemWidth, child: action),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xxl),

                // ── CV tips (bottom of the page) ────────────
                // Local tips only (no AI): personal/missing-content
                // tips first, then a daily-rotating general tip.
                // Tips with opensBuilder are tappable → CV Builder.
                _SectionHeader(
                    title: context.tr('home_cv_tips_title')),
                const SizedBox(height: AppSpacing.md),
                for (final tip in cvTips) ...[
                  AppCard(
                    onTap: tip.opensBuilder
                        ? () => context.push(AppRoutes.cvBuilder)
                        : null,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(tip.icon,
                            size: 20, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(tip.title,
                                  style: AppTextStyles.bodyMedium(
                                      textColor)),
                              Text(tip.message,
                                  style: AppTextStyles.bodySmall(
                                      textColor)),
                            ],
                          ),
                        ),
                        if (tip.opensBuilder) ...[
                          const SizedBox(width: AppSpacing.sm),
                          const Icon(Icons.chevron_right),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CV Builder → CvCompletenessInput mapping
// ─────────────────────────────────────────────────────────────

final RegExp _digit = RegExp(r'[0-9٠-٩]');

/// A draft is created the moment the user opens the CV Builder, so an
/// untouched draft must not count as "a CV with everything missing".
bool _isBlankDraft(CvBuilderModel m) =>
    m.personalInfo.fullName.trim().isEmpty &&
        m.personalInfo.email.trim().isEmpty &&
        m.summary.trim().isEmpty &&
        m.experiences.isEmpty &&
        m.education.isEmpty &&
        m.skills.isEmpty;

/// Describes the most recently updated non-blank Builder CV as plain
/// values for CvCompletenessAnalyzer, or null if there isn't one.
CvCompletenessInput? _builderInput(List<CvBuilderModel> all) {
  CvBuilderModel? latest;
  for (final m in all) {
    if (_isBlankDraft(m)) continue;
    if (latest == null || m.updatedAt.isAfter(latest.updatedAt)) latest = m;
  }
  if (latest == null) return null;
  final b = latest;

  bool filled(String? s) => s != null && s.trim().isNotEmpty;

  return CvCompletenessInput(
    hasEmail: filled(b.personalInfo.email),
    hasPhone: filled(b.personalInfo.phone),
    hasLink: filled(b.personalInfo.linkedinUrl) ||
        filled(b.personalInfo.websiteUrl),
    summaryLength: b.summary.trim().length,
    experienceCount: b.experiences.length,
    experienceHasNumbers:
    b.experiences.any((e) => e.bullets.any(_digit.hasMatch)),
    educationCount: b.education.length,
    skillsCount: b.skills.length,
    projectsCount: b.projects.length,
    certificationsCount: b.certifications.length,
    languagesCount: b.languages.length,
  );
}

/// Shown when HomeController's own load() fails. Applications/interviews/
/// CV keep working regardless (they're independent live providers) — this
/// only covers whatever HomeController itself is responsible for.
class _HomeErrorState extends StatelessWidget {
  const _HomeErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppColors.warning),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.tr('home_error_loading'),
              style: AppTextStyles.bodyMedium(textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(context.tr('home_retry')),
            ),
          ],
        ),
      ),
    );
  }
}

/// App bar that carries the account details: avatar, greeting + name,
/// then "@username · job title" underneath.
class _ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ProfileAppBar({
    required this.greeting,
    required this.name,
    this.username,
    this.jobTitle,
  });

  final String greeting;
  final String name;
  final String? username;
  final String? jobTitle;

  @override
  Size get preferredSize => const Size.fromHeight(88);

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';

    final u = username?.trim() ?? '';
    final j = jobTitle?.trim() ?? '';
    final details = [
      if (u.isNotEmpty) '@$u',
      if (j.isNotEmpty) j,
    ].join(' · ');

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ResponsiveContentWidth(
            maxWidth: 960,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(initial,
                        style: AppTextStyles.h3(AppColors.primary)),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(greeting,
                            style: AppTextStyles.bodySmall(textColor)),
                        Text(name,
                            style: AppTextStyles.h3(textColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        if (details.isNotEmpty)
                          Text(details,
                              style: AppTextStyles.bodySmall(textColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Big, display-only counter (deliberately no onTap).
class _CounterCard extends StatelessWidget {
  const _CounterCard({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return AppCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: AppTextStyles.h1(textColor)),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: AppTextStyles.bodySmall(textColor),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeInterviewCard extends StatelessWidget {
  const _PracticeInterviewCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.locked = false,
  });
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Shows a lock instead of the chevron. Not used for now: free users
  /// have one lifetime session, so the card is open for everyone.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.record_voice_over_outlined,
                color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMedium(textColor)),
                Text(subtitle, style: AppTextStyles.bodySmall(textColor)),
              ],
            ),
          ),
          Icon(locked ? Icons.lock_outline : Icons.chevron_right),
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
    return Text(title,
        style: AppTextStyles.h3(Theme.of(context).colorScheme.onSurface));
  }
}

class _AttentionItem extends StatelessWidget {
  const _AttentionItem(
      {required this.icon, required this.title, required this.subtitle});
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

/// A single quick-action tile. It has no fixed width: the parent decides
/// (see the LayoutBuilder/Wrap in HomeScreen), so it stretches to fill its
/// grid cell. Labels share one font size and wrap to two lines if needed.
class _QuickAction extends StatelessWidget {
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final radius = BorderRadius.circular(AppRadius.md);

    return Material(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          height: 104,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 28),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                style: AppTextStyles.bodySmall(textColor),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}