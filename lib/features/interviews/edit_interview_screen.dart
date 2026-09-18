import 'package:flutter/material.dart';
import 'package:jobora/features/interviews/providers/interview_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/interview_model.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../core/widgets/app_card.dart';

/// Edit screen for an existing interview. Loads the current model from
/// [InterviewProvider] by id, prefills every field, and saves via
/// provider.update() with copyWith so untouched fields are preserved.
class EditInterviewScreen extends StatefulWidget {
  const EditInterviewScreen({super.key, required this.interviewId});

  final String interviewId;

  @override
  State<EditInterviewScreen> createState() => _EditInterviewScreenState();
}

class _EditInterviewScreenState extends State<EditInterviewScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _locationController;
  late final TextEditingController _meetingUrlController;
  late final TextEditingController _interviewerController;
  late final TextEditingController _notesController;
  late final TextEditingController _preparationController;

  InterviewModel? _original;
  DateTime? _date;
  TimeOfDay? _time;
  InterviewFormat _format = InterviewFormat.online;
  InterviewStage _stage = InterviewStage.hrScreening;
  bool _reminderEnabled = true;
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController();
    _meetingUrlController = TextEditingController();
    _interviewerController = TextEditingController();
    _notesController = TextEditingController();
    _preparationController = TextEditingController();
  }

  void _hydrateFromModel(InterviewModel model) {
    if (_initialized) return;
    _initialized = true;
    _original = model;
    _date = DateTime(model.dateTime.year, model.dateTime.month, model.dateTime.day);
    _time = TimeOfDay(hour: model.dateTime.hour, minute: model.dateTime.minute);
    _format = model.format;
    _stage = model.stage;
    _reminderEnabled = model.reminderEnabled;
    _locationController.text = model.location ?? '';
    _meetingUrlController.text = model.meetingUrl ?? '';
    _interviewerController.text = model.interviewerName ?? '';
    _notesController.text = model.notes ?? '';
    _preparationController.text = model.preparationNotes ?? '';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
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

  Future<void> _save() async {
    if (_isSaving || _original == null) return;
    if (_date == null || _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('interviews_validation_select_date_time'))),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      final dateTime = DateTime(
        _date!.year,
        _date!.month,
        _date!.day,
        _time!.hour,
        _time!.minute,
      );

      final updated = _original!.copyWith(
        dateTime: dateTime,
        format: _format,
        stage: _stage,
        location: _format == InterviewFormat.onsite && _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        meetingUrl: _format == InterviewFormat.online && _meetingUrlController.text.trim().isNotEmpty
            ? _meetingUrlController.text.trim()
            : null,
        interviewerName:
        _interviewerController.text.trim().isEmpty ? null : _interviewerController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        preparationNotes:
        _preparationController.text.trim().isEmpty ? null : _preparationController.text.trim(),
        reminderEnabled: _reminderEnabled,
      );

      await context.read<InterviewProvider>().update(updated);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('error_save_failed'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InterviewProvider>();
    final model = provider.byId(widget.interviewId);

    if (model == null) {
      // Still loading, or the interview was deleted elsewhere (e.g.
      // another device) while this screen was open.
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('interviews_edit_title'))),
        body: Center(
          child: provider.isLoading
              ? const CircularProgressIndicator()
              : Text(context.tr('error_interview_not_found')),
        ),
      );
    }

    _hydrateFromModel(model);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('interviews_edit_title'))),
      body: SafeArea(
        child: Center(
          child: ResponsiveContentWidth(
            maxWidth: 700,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
              AppCard(
              child: ListTile(
              contentPadding: EdgeInsets.zero,
                title: Text(model.companyName, style: AppTextStyles.h3(Theme.of(context).colorScheme.onSurface)),
                subtitle: Text(model.position),
              ),
            ),
                  const SizedBox(height: AppSpacing.xl),
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
                  const SizedBox(height: AppSpacing.xxxl),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(context.tr('save')),
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

/// Small read-only header showing which application this interview
/// belongs to. companyName/position never change here — editing which
/// application an interview is linked to isn't supported.
class AppCardHeader extends StatelessWidget {
  const AppCardHeader({super.key, required this.companyName, required this.position});

  final String companyName;
  final String position;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(companyName, style: AppTextStyles.h3(textColor)),
        Text(position, style: AppTextStyles.bodyMedium(textColor)),
      ],
    );
  }
}