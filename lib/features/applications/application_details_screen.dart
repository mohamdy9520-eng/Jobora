import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/status_badge.dart';
import 'providers/application_provider.dart';

class ApplicationDetailsScreen extends StatelessWidget {
  const ApplicationDetailsScreen({super.key, required this.applicationId});

  final String applicationId;

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final provider = context.watch<ApplicationProvider>();
    final app = provider.byId(applicationId);

    return Scaffold(
      appBar: AppBar(title: Text(app?.companyName ?? '')),
      body: SafeArea(
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : provider.error != null
            ? EmptyState(
          icon: Icons.error_outline,
          title: context.tr('error_loading_title'),
          subtitle: provider.error!,
        )
            : app == null
            ? EmptyState(
          icon: Icons.search_off,
          title: context.tr('application_details_not_found_title'),
          subtitle: context.tr('application_details_not_found_subtitle'),
        )
            : Center(
          child: ResponsiveContentWidth(
            maxWidth: 700,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Text(app.companyName, style: AppTextStyles.h2(textColor)),
                const SizedBox(height: AppSpacing.xs),
                Text(app.position, style: AppTextStyles.bodyLarge(textColor)),
                const SizedBox(height: AppSpacing.md),
                StatusBadge(status: app.status),
                const SizedBox(height: AppSpacing.xl),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr('section_job_details'),
                          style: AppTextStyles.h3(textColor)),
                      const SizedBox(height: AppSpacing.sm),
                      _DetailRow(
                        label: context.tr('field_application_date'),
                        value: _formatDate(app.applicationDate),
                      ),
                      if (app.interviewDate != null)
                        _DetailRow(
                          label: context.tr('field_interview_date'),
                          value: _formatDate(app.interviewDate!),
                        ),
                      if (app.location != null)
                        _DetailRow(
                          label: context.tr('field_location'),
                          value: app.location!,
                        ),
                      if (app.workType != null)
                        _DetailRow(
                          label: context.tr('field_work_type'),
                          value: context.tr('work_type_${app.workType!.name}'),
                        ),
                      if (app.source != null)
                        _DetailRow(
                          label: context.tr('field_source'),
                          value: context.tr(app.source!.localizationKey),
                        ),
                      if (app.salaryMin != null)
                        _DetailRow(
                          label: context.tr('field_salary_min'),
                          value:
                          '${app.currency} ${app.salaryMin!.toStringAsFixed(0)}'
                              '${app.salaryMax != null ? ' – ${app.salaryMax!.toStringAsFixed(0)}' : ''}',
                        ),
                      if (app.jobUrl != null)
                        _DetailRow(
                          label: context.tr('field_job_url'),
                          value: app.jobUrl!,
                        ),
                    ],
                  ),
                ),
                if (app.recruiterName != null ||
                    app.recruiterEmail != null ||
                    app.recruiterPhone != null ||
                    app.recruiterLinkedIn != null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('section_recruiter'),
                            style: AppTextStyles.h3(textColor)),
                        const SizedBox(height: AppSpacing.sm),
                        if (app.recruiterName != null)
                          _DetailRow(
                            label: context.tr('field_recruiter_name'),
                            value: app.recruiterName!,
                          ),
                        if (app.recruiterEmail != null)
                          _DetailRow(
                            label: context.tr('field_recruiter_email'),
                            value: app.recruiterEmail!,
                          ),
                        if (app.recruiterPhone != null)
                          _DetailRow(
                            label: context.tr('field_recruiter_phone'),
                            value: app.recruiterPhone!,
                          ),
                        if (app.recruiterLinkedIn != null)
                          _DetailRow(
                            label: context.tr('field_recruiter_linkedin'),
                            value: app.recruiterLinkedIn!,
                          ),
                      ],
                    ),
                  ),
                ],
                if (app.notes != null && app.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('section_notes'), style: AppTextStyles.h3(textColor)),
                        const SizedBox(height: AppSpacing.sm),
                        Text(app.notes!, style: AppTextStyles.bodyMedium(textColor)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodySmall(textColor))),
          Expanded(
            child: Text(value, style: AppTextStyles.bodyMedium(textColor), textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}