import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import 'statistics_controller.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Theme.of(context).colorScheme.onSurface;
    final stats = context.watch<StatisticsController>();

    if (stats.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final gridCrossAxisCount = context.isDesktop ? 4 : (context.isTablet ? 3 : 2);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('statistics_title'))),
      body: SafeArea(
        child: Center(
          child: ResponsiveContentWidth(
            maxWidth: 960,
            child: stats.totalApplications == 0
                ? EmptyState(
              icon: Icons.bar_chart_outlined,
              title: context.tr('statistics_empty_title'),
              subtitle: context.tr('statistics_empty_subtitle'),
            )
                : ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                GridView.count(
                  crossAxisCount: gridCrossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.6,
                  children: [
                    _StatCard(
                      label: context.tr('statistics_total_applications'),
                      value: stats.totalApplications.toString(),
                      color: AppColors.statusApplied,
                    ),
                    _StatCard(
                      label: context.tr('home_interviews'),
                      value: stats.interviews.toString(),
                      color: AppColors.statusInterview,
                    ),
                    _StatCard(
                      label: context.tr('home_offers'),
                      value: stats.offers.toString(),
                      color: AppColors.statusOffer,
                    ),
                    _StatCard(
                      label: context.tr('status_rejected'),
                      value: stats.rejected.toString(),
                      color: AppColors.statusRejected,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                AppCard(
                  child: Column(
                    children: [
                      _RateRow(
                        label: context.tr('statistics_response_rate'),
                        value: stats.responseRate,
                        color: AppColors.statusApplied,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _RateRow(
                        label: context.tr('statistics_interview_rate'),
                        value: stats.interviewRate,
                        color: AppColors.statusInterview,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _RateRow(
                        label: context.tr('statistics_offer_rate'),
                        value: stats.offerRate,
                        color: AppColors.statusOffer,
                      ),
                    ],
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

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const Spacer(),
          Text(value, style: AppTextStyles.h1(textColor)),
          Text(label, style: AppTextStyles.bodySmall(textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _RateRow extends StatelessWidget {
  const _RateRow({required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: AppTextStyles.bodyMedium(textColor))),
            Text('${(value * 100).toStringAsFixed(0)}%', style: AppTextStyles.h3(textColor)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}