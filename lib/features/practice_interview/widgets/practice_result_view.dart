import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../models/practice_models.dart';

Color practiceScoreColor(int score) {
  if (score >= 85) return AppColors.success;
  if (score >= 70) return AppColors.primary;
  if (score >= 50) return AppColors.warning;
  return AppColors.danger;
}

String practiceScoreLabelKey(int score) {
  if (score >= 85) return 'practice_score_excellent';
  if (score >= 70) return 'practice_score_good';
  if (score >= 50) return 'practice_score_fair';
  return 'practice_score_poor';
}

Color _ratingColor(AnswerRating rating) {
  switch (rating) {
    case AnswerRating.good:
      return AppColors.success;
    case AnswerRating.okay:
      return AppColors.warning;
    case AnswerRating.weak:
      return AppColors.danger;
  }
}

/// Full feedback report. Scrolls by itself; parents just give it a bounded
/// height (and usually cap its width with ResponsiveContentWidth).
class PracticeResultView extends StatelessWidget {
  const PracticeResultView({
    super.key,
    required this.session,
    this.saveFailed = false,
    this.actions = const [],
  });

  final PracticeSession session;
  final bool saveFailed;

  /// Buttons shown at the bottom (built by the parent screen).
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final fb = session.feedback;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final dir = session.isArabic ? TextDirection.rtl : TextDirection.ltr;
    final pairs = session.pairs;

    final strengths = fb.strengths.isEmpty
        ? null
        : _ListCard(
      title: context.tr('practice_result_strengths'),
      icon: Icons.thumb_up_alt_outlined,
      color: AppColors.success,
      items: fb.strengths,
      dir: dir,
    );
    final weaknesses = fb.weaknesses.isEmpty
        ? null
        : _ListCard(
      title: context.tr('practice_result_weaknesses'),
      icon: Icons.trending_down_rounded,
      color: AppColors.warning,
      items: fb.weaknesses,
      dir: dir,
    );
    final say = fb.say.isEmpty
        ? null
        : _ListCard(
      title: context.tr('practice_result_say'),
      icon: Icons.check_circle_outline,
      color: AppColors.success,
      items: fb.say,
      dir: dir,
    );
    final avoid = fb.avoid.isEmpty
        ? null
        : _ListCard(
      title: context.tr('practice_result_avoid'),
      icon: Icons.block_outlined,
      color: AppColors.danger,
      items: fb.avoid,
      dir: dir,
    );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        _ScoreCard(session: session, dir: dir),
        const SizedBox(height: AppSpacing.lg),
        if (saveFailed) ...[
          Text(
            context.tr('practice_save_failed'),
            style: AppTextStyles.bodySmall(AppColors.warning),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        ..._pair(strengths, weaknesses),
        if (pairs.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Text(context.tr('practice_result_review'),
              style: AppTextStyles.h3(textColor)),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < pairs.length; i++) ...[
            _ReviewCard(
              index: i + 1,
              pair: pairs[i],
              review: fb.reviewFor(i + 1),
              dir: dir,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
        const SizedBox(height: AppSpacing.md),
        ..._pair(say, avoid),
        if (fb.tips.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _ListCard(
            title: context.tr('practice_result_tips'),
            icon: Icons.lightbulb_outline,
            color: AppColors.primary,
            items: fb.tips,
            dir: dir,
          ),
        ],
        for (final a in actions) ...[
          const SizedBox(height: AppSpacing.md),
          a,
        ],
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }

  /// Two cards side by side on wide screens, stacked on phones.
  List<Widget> _pair(Widget? a, Widget? b) {
    if (a == null && b == null) return const [];
    if (a == null || b == null) return [a ?? b!];
    return [_TwoUp(first: a, second: b)];
  }
}

class _TwoUp extends StatelessWidget {
  const _TwoUp({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 640) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: first),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: second),
            ],
          );
        }
        return Column(
          children: [
            first,
            const SizedBox(height: AppSpacing.lg),
            second,
          ],
        );
      },
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.session, required this.dir});

  final PracticeSession session;
  final TextDirection dir;

  @override
  Widget build(BuildContext context) {
    final fb = session.feedback;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final color = practiceScoreColor(fb.score);

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: fb.score / 100,
                    strokeWidth: 8,
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Text('${fb.score}', style: AppTextStyles.h2(textColor)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr(practiceScoreLabelKey(fb.score)),
                    style: AppTextStyles.h3(color)),
                const SizedBox(height: 2),
                Text(
                  '${session.jobTitle} · ${session.company}',
                  style: AppTextStyles.bodySmall(
                      textColor.withValues(alpha: 0.65)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(fb.summary,
                    textDirection: dir,
                    style: AppTextStyles.bodyMedium(textColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    required this.dir,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;
  final TextDirection dir;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(title, style: AppTextStyles.h3(textColor)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Icon(Icons.circle, size: 7, color: color),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(item,
                        textDirection: dir,
                        style: AppTextStyles.bodyMedium(textColor)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.index,
    required this.pair,
    required this.review,
    required this.dir,
  });

  final int index;
  final PracticePair pair;
  final AnswerReview? review;
  final TextDirection dir;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final muted = textColor.withValues(alpha: 0.65);
    final r = review;
    final ratingColor = r == null ? muted : _ratingColor(r.rating);

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: AppSpacing.md),
          shape: const Border(),
          collapsedShape: const Border(),
          initiallyExpanded: r != null && r.rating != AnswerRating.good,
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: ratingColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    context.tr('practice_result_question_n',
                        {'n': index.toString()}),
                    style: AppTextStyles.bodySmall(muted),
                  ),
                  if (r != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      context.tr('practice_rating_${r.rating.name}'),
                      style: AppTextStyles.labelMedium(ratingColor),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                pair.question,
                textDirection: dir,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium(textColor),
              ),
            ],
          ),
          children: [
            _Labeled(
              label: context.tr('practice_result_your_answer'),
              text: pair.answer,
              dir: dir,
              labelColor: muted,
            ),
            if (r != null && r.issue.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _Labeled(
                label: context.tr('practice_result_issue'),
                text: r.issue,
                dir: dir,
                labelColor: AppColors.danger,
              ),
            ],
            if (r != null && r.better.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: _Labeled(
                  label: context.tr('practice_result_better'),
                  text: r.better,
                  dir: dir,
                  labelColor: AppColors.success,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Labeled extends StatelessWidget {
  const _Labeled({
    required this.label,
    required this.text,
    required this.dir,
    required this.labelColor,
  });

  final String label;
  final String text;
  final TextDirection dir;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: AppTextStyles.labelMedium(labelColor)),
        const SizedBox(height: 4),
        Text(text,
            textDirection: dir, style: AppTextStyles.bodyMedium(textColor)),
      ],
    );
  }
}