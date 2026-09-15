import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/interview_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import 'providers/interview_provider.dart';

class InterviewsScreen extends StatelessWidget {
  const InterviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InterviewProvider>();
    final upcoming = provider.upcoming;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('interviews_title'))),
      body: SafeArea(
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.error != null
            ? EmptyState(
          icon: Icons.error_outline,
          title: context.tr('error_loading_title'),
          subtitle: provider.error!,
        )
            : upcoming.isEmpty
            ? EmptyState(
          icon: Icons.event_outlined,
          title: context.tr('interviews_empty_title'),
          subtitle: context.tr('interviews_empty_subtitle'),
        )
            : Center(
          child: ResponsiveContentWidth(
            maxWidth: 700,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Text(context.tr('interviews_upcoming'),
                    style: AppTextStyles.h3(Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: AppSpacing.md),
                for (int i = 0; i < upcoming.length; i++) ...[
                  _InterviewCard(interview: upcoming[i]),
                  if (i != upcoming.length - 1) const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InterviewCard extends StatelessWidget {
  const _InterviewCard({required this.interview});
  final InterviewModel interview;

  String _relativeDayLabel(BuildContext context) {
    if (interview.isTomorrow) return context.tr('date_tomorrow');
    final now = DateTime.now();
    final isToday = interview.dateTime.year == now.year &&
        interview.dateTime.month == now.month &&
        interview.dateTime.day == now.day;
    if (isToday) return context.tr('date_today');
    return '${interview.dateTime.day}/${interview.dateTime.month}/${interview.dateTime.year}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  IconData get _formatIcon {
    switch (interview.format) {
      case InterviewFormat.online:
        return Icons.videocam_outlined;
      case InterviewFormat.onsite:
        return Icons.location_on_outlined;
      case InterviewFormat.phone:
        return Icons.call_outlined;
    }
  }

  String _formatDetailText(BuildContext context) {
    switch (interview.format) {
      case InterviewFormat.online:
        return interview.meetingUrl != null
            ? context.tr('interview_format_online_with_link')
            : context.tr('interview_format_online');
      case InterviewFormat.onsite:
        return interview.location ?? context.tr('interview_format_onsite');
      case InterviewFormat.phone:
        return context.tr('interview_format_phone');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.statusInterview.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(_relativeDayLabel(context),
                    style: AppTextStyles.labelMedium(AppColors.statusInterview)),
              ),
              const Spacer(),
              Text(_formatTime(interview.dateTime), style: AppTextStyles.bodyMedium(textColor)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(interview.position, style: AppTextStyles.h3(textColor)),
          Text(interview.companyName, style: AppTextStyles.bodyMedium(textColor)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(_formatIcon, size: 16, color: AppColors.lightTextSecondary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(_formatDetailText(context), style: AppTextStyles.bodySmall(textColor)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              // TODO(step-5 Interviews): navigate to an interview-prep
              // screen/flow once it exists; no route is defined for it yet.
              onPressed: null,
              child: Text(context.tr('interviews_prepare')),
            ),
          ),
        ],
      ),
    );
  }
}