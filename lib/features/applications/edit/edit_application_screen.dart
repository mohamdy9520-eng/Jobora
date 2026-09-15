import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/application_model.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../providers/application_provider.dart';

/// Edit screen for an existing application. Loads the current model from
/// [ApplicationProvider] by id, prefills every field (main + additional),
/// and saves via provider.update() with copyWith so untouched fields are
/// preserved.
class EditApplicationScreen extends StatefulWidget {
  const EditApplicationScreen({super.key, required this.applicationId});

  final String applicationId;

  @override
  State<EditApplicationScreen> createState() => _EditApplicationScreenState();
}

class _EditApplicationScreenState extends State<EditApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _companyController;
  late final TextEditingController _positionController;
  late final TextEditingController _jobUrlController;
  late final TextEditingController _salaryMinController;
  late final TextEditingController _salaryMaxController;
  late final TextEditingController _locationController;
  late final TextEditingController _notesController;

  ApplicationModel? _original;
  ApplicationStatus _status = ApplicationStatus.applied;
  WorkType? _workType;
  ApplicationSource? _source;
  bool _showAdditionalDetails = false;
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _companyController = TextEditingController();
    _positionController = TextEditingController();
    _jobUrlController = TextEditingController();
    _salaryMinController = TextEditingController();
    _salaryMaxController = TextEditingController();
    _locationController = TextEditingController();
    _notesController = TextEditingController();
  }

  void _hydrateFromModel(ApplicationModel model) {
    if (_initialized) return;
    _initialized = true;
    _original = model;
    _companyController.text = model.companyName;
    _positionController.text = model.position;
    _jobUrlController.text = model.jobUrl ?? '';
    _salaryMinController.text = model.salaryMin?.toString() ?? '';
    _salaryMaxController.text = model.salaryMax?.toString() ?? '';
    _locationController.text = model.location ?? '';
    _notesController.text = model.notes ?? '';
    _status = model.status;
    _workType = model.workType;
    _source = model.source;
    // Auto-expand "Additional Details" if any of those fields already
    // have data, so the user doesn't think their data disappeared.
    _showAdditionalDetails = (model.jobUrl?.isNotEmpty ?? false) ||
        model.salaryMin != null ||
        model.salaryMax != null ||
        (model.location?.isNotEmpty ?? false) ||
        model.workType != null ||
        model.source != null ||
        (model.notes?.isNotEmpty ?? false);
  }

  Future<void> _save() async {
    if (_isSaving || _original == null) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final updated = _original!.copyWith(
        companyName: _companyController.text.trim(),
        position: _positionController.text.trim(),
        status: _status,
        jobUrl: _jobUrlController.text.trim().isEmpty ? null : _jobUrlController.text.trim(),
        salaryMin: double.tryParse(_salaryMinController.text.trim()),
        salaryMax: double.tryParse(_salaryMaxController.text.trim()),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        workType: _workType,
        source: _source,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await context.read<ApplicationProvider>().update(updated);
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
    _companyController.dispose();
    _positionController.dispose();
    _jobUrlController.dispose();
    _salaryMinController.dispose();
    _salaryMaxController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApplicationProvider>();
    final model = provider.byId(widget.applicationId);

    if (model == null) {
      // Still loading, or the app was deleted elsewhere (e.g. another
      // device) while this screen was open.
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('edit_application_title'))),
        body: Center(
          child: provider.isLoading
              ? const CircularProgressIndicator()
              : Text(context.tr('error_application_not_found')),
        ),
      );
    }

    _hydrateFromModel(model);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('edit_application_title'))),
      body: SafeArea(
        child: Center(
          child: ResponsiveContentWidth(
            maxWidth: 600,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  TextFormField(
                    controller: _companyController,
                    decoration: InputDecoration(labelText: context.tr('field_company_name')),
                    validator: (v) => (v == null || v.trim().isEmpty) ? '' : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _positionController,
                    decoration: InputDecoration(labelText: context.tr('field_position')),
                    validator: (v) => (v == null || v.trim().isEmpty) ? '' : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  DropdownButtonFormField<ApplicationStatus>(
                    value: _status,
                    decoration: InputDecoration(labelText: context.tr('field_status')),
                    items: ApplicationStatus.values.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(right: AppSpacing.sm),
                              decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                            ),
                            Text(context.tr('status_${s.name}')),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _status = v ?? _status),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  InkWell(
                    onTap: () => setState(() => _showAdditionalDetails = !_showAdditionalDetails),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(context.tr('additional_details'),
                              style: AppTextStyles.h3(Theme.of(context).colorScheme.onSurface)),
                        ),
                        Icon(_showAdditionalDetails ? Icons.expand_less : Icons.expand_more),
                      ],
                    ),
                  ),
                  if (_showAdditionalDetails) ...[
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _jobUrlController,
                      decoration: InputDecoration(labelText: context.tr('field_job_url')),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _salaryMinController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: context.tr('field_salary_min')),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: TextFormField(
                            controller: _salaryMaxController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: context.tr('field_salary_max')),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(labelText: context.tr('field_location')),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    DropdownButtonFormField<WorkType>(
                      value: _workType,
                      decoration: InputDecoration(labelText: context.tr('field_work_type')),
                      items: [
                        DropdownMenuItem(value: WorkType.onsite, child: Text(context.tr('work_type_onsite'))),
                        DropdownMenuItem(value: WorkType.hybrid, child: Text(context.tr('work_type_hybrid'))),
                        DropdownMenuItem(value: WorkType.remote, child: Text(context.tr('work_type_remote'))),
                      ],
                      onChanged: (v) => setState(() => _workType = v),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    DropdownButtonFormField<ApplicationSource>(
                      value: _source,
                      decoration: InputDecoration(labelText: context.tr('field_source')),
                      items: ApplicationSource.values
                          .map((s) => DropdownMenuItem(
                          value: s, child: Text(context.tr(s.localizationKey))))
                          .toList(),
                      onChanged: (v) => setState(() => _source = v),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(labelText: context.tr('field_notes')),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxxl),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(context.tr('save')),
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