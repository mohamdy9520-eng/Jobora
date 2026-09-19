import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/cv_model.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/cv_picker_field.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/status_badge.dart';
import '../cv/providers/cv_provider.dart';
import 'providers/application_provider.dart';

class ApplicationDetailsScreen extends StatelessWidget {
  const ApplicationDetailsScreen({super.key, required this.applicationId});

  final String applicationId;

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  Future<void> _openCv(BuildContext context, CvModel cv) async {
    var opened = false;
    final uri = Uri.tryParse(cv.downloadUrl);
    if (uri != null) {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        opened = false;
      }
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('error_open_cv'))),
      );
    }
  }

  Widget _buildCvCard(BuildContext context, String cvId, Color textColor) {
    final cvProvider = context.watch<CvProvider>();
    final cv = cvProvider.byId(cvId);

    Widget content;
    if (cv != null) {
      content = InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _openCv(context, cv),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Icon(CvPickerField.iconFor(cv.fileType), color: textColor),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cv.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium(textColor),
                    ),
                    if (cv.formattedSize.isNotEmpty)
                      Text(cv.formattedSize, style: AppTextStyles.bodySmall(textColor)),
                  ],
                ),
              ),
              Icon(Icons.open_in_new, size: 18, color: textColor),
            ],
          ),
        ),
      );
    } else if (cvProvider.isLoading) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else {
      // The CV was linked, then deleted afterwards.
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(Icons.link_off, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                context.tr('cv_unavailable'),
                style: AppTextStyles.bodyMedium(Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('section_cv'), style: AppTextStyles.h3(textColor)),
          const SizedBox(height: AppSpacing.xs),
          content,
        ],
      ),
    );
  }

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
                if (app.cvId != null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _buildCvCard(context, app.cvId!, textColor),
                ],
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