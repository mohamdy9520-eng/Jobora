import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/application_model.dart';
import '../../core/models/interview_model.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../applications/providers/application_provider.dart';
import 'providers/interview_provider.dart';

class AddInterviewScreen extends StatefulWidget {
  const AddInterviewScreen({super.key, this.preselectedApplicationId});

  /// When launched from an Application's own flow (e.g. "Mark as
  /// Interview"), the application is already known and the picker step
  /// is skipped. When launched from the Interviews tab FAB, this is
  /// null and the user picks from their existing applications below.
  final String? preselectedApplicationId;

  @override
  State<AddInterviewScreen> createState() => _AddInterviewScreenState();
}

class _AddInterviewScreenState extends State<AddInterviewScreen> {
  final _formKey = GlobalKey<FormState>();

  ApplicationModel? _selectedApplication;
  DateTime? _date;
  TimeOfDay? _time;
  InterviewFormat _format = InterviewFormat.online;
  InterviewStage _stage = InterviewStage.hrScreening;
  bool _reminderEnabled = true;
  bool _updateApplicationStatus = true;
  bool _isSaving = false;

  final _locationController = TextEditingController();
  final _meetingUrlController = TextEditingController();
  final _interviewerController = TextEditingController();
  final _notesController = TextEditingController();
  final _preparationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.preselectedApplicationId != null) {
      // Resolve against the provider once the first frame is up, since
      // context.read is safe post-frame and we don't want to depend on
      // build-time provider lookups inside initState.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final app = context
            .read<ApplicationProvider>()
            .byId(widget.preselectedApplicationId!);
        if (app != null) {
          setState(() => _selectedApplication = app);
        }
      });
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _meetingUrlController.dispose();
    _interviewerController.dispose();
    _notesController.dispose();
    _preparationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    if (_selectedApplication == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('interviews_validation_select_application'))),
      );
      return;
    }
    if (_date == null || _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('interviews_validation_select_date_time'))),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final app = _selectedApplication!;
    final dateTime = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );

    setState(() => _isSaving = true);

    final interview = InterviewModel(
      id: '', // ignored by the repository — it always assigns the real id
      applicationId: app.id,
      companyName: app.companyName,
      position: app.position,
      dateTime: dateTime,
      location: _format == InterviewFormat.onsite && _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : null,
      meetingUrl: _format == InterviewFormat.online && _meetingUrlController.text.trim().isNotEmpty
          ? _meetingUrlController.text.trim()
          : null,
      interviewerName:
      _interviewerController.text.trim().isNotEmpty ? _interviewerController.text.trim() : null,
      format: _format,
      stage: _stage,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      preparationNotes:
      _preparationController.text.trim().isNotEmpty ? _preparationController.text.trim() : null,
      reminderEnabled: _reminderEnabled,
    );

    try {
      await context.read<InterviewProvider>().create(interview);

      // Only push the application forward to "interview" — never pull it
      // backward from a later stage like offer/rejected/withdrawn.
      const earlyStatuses = {
        ApplicationStatus.saved,
        ApplicationStatus.applied,
        ApplicationStatus.screening,
      };
      if (_updateApplicationStatus && earlyStatuses.contains(app.status)) {
        await context.read<ApplicationProvider>().update(
          app.copyWith(status: ApplicationStatus.interview),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('interviews_created_success'))),
      );
      context.pop();
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.tr('interviews_create_error')}: $err')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final applications = context.watch<ApplicationProvider>().applications;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('interviews_add_title'))),
      body: SafeArea(
        child: Center(
          child: ResponsiveContentWidth(
            maxWidth: 700,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  if (widget.preselectedApplicationId == null) ...[
                    Text(context.tr('interviews_select_application'),
                        style: AppTextStyles.h3(Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: AppSpacing.md),
                    if (applications.isEmpty)
                      EmptyState(
                        icon: Icons.description_outlined,
                        title: context.tr('interviews_no_applications_title'),
                        subtitle: context.tr('interviews_no_applications_subtitle'),
                      )
                    else
                      DropdownButtonFormField<ApplicationModel>(
                        initialValue: _selectedApplication,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: context.tr('interviews_select_application_hint'),
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          for (final app in applications)
                            DropdownMenuItem(
                              value: app,
                              child: Text('${app.companyName} — ${app.position}',
                                  overflow: TextOverflow.ellipsis),
                            ),
                        ],
                        onChanged: (value) => setState(() => _selectedApplication = value),
                      ),
                    const SizedBox(height: AppSpacing.xl),
                  ] else if (_selectedApplication != null)
                    AppCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(_selectedApplication!.companyName,
                            style: AppTextStyles.h3(Theme.of(context).colorScheme.onSurface)),
                        subtitle: Text(_selectedApplication!.position),
                      ),
                    ),
                  if (_selectedApplication != null || widget.preselectedApplicationId == null) ...[
                    Text(context.tr('interview_field_date'),
                        style: AppTextStyles.labelMedium(Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _pickDate,
                            child: Text(_date == null
                                ? context.tr('interview_field_date')
                                : '${_date!.day}/${_date!.month}/${_date!.year}'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _pickTime,
                            child: Text(_time == null
                                ? context.tr('interview_field_time')
                                : _time!.format(context)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(context.tr('interview_field_format'),
                        style: AppTextStyles.labelMedium(Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: AppSpacing.xs),
                    SegmentedButton<InterviewFormat>(
                      segments: [
                        for (final f in InterviewFormat.values)
                          ButtonSegment(value: f, label: Text(context.tr(f.localizationKey))),
                      ],
                      selected: {_format},
                      onSelectionChanged: (s) => setState(() => _format = s.first),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (_format == InterviewFormat.onsite)
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: context.tr('interview_field_location'),
                          border: const OutlineInputBorder(),
                        ),
                      )
                    else if (_format == InterviewFormat.online)
                      TextFormField(
                        controller: _meetingUrlController,
                        decoration: InputDecoration(
                          labelText: context.tr('interview_field_meeting_url'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _interviewerController,
                      decoration: InputDecoration(
                        labelText: context.tr('interview_field_interviewer'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    DropdownButtonFormField<InterviewStage>(
                      initialValue: _stage,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: context.tr('interview_field_stage'),
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        for (final s in InterviewStage.values)
                          DropdownMenuItem(value: s, child: Text(context.tr(s.localizationKey))),
                      ],
                      onChanged: (value) => setState(() => _stage = value ?? _stage),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: context.tr('interview_field_notes'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _preparationController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: context.tr('interview_field_preparation_notes'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _reminderEnabled,
                      onChanged: (v) => setState(() => _reminderEnabled = v),
                      title: Text(context.tr('interview_field_reminder')),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _updateApplicationStatus,
                      onChanged: (v) => setState(() => _updateApplicationStatus = v),
                      title: Text(context.tr('interview_update_application_status')),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSaving ? null : _submit,
                        child: _isSaving
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : Text(context.tr('interview_save')),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}