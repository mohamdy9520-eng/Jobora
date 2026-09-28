import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_card.dart';
import '../models/cv_builder_model.dart';
import '../providers/cv_builder_provider.dart';
import '../services/summary_generator.dart';
import 'cv_builder_review_screen.dart';

enum _CvStep { personal, summary, experience, education, extras }

class CvBuilderFormScreen extends StatefulWidget {
  const CvBuilderFormScreen({super.key, required this.initialModel});

  final CvBuilderModel initialModel;

  @override
  State<CvBuilderFormScreen> createState() => _CvBuilderFormScreenState();
}

class _CvBuilderFormScreenState extends State<CvBuilderFormScreen> {
  late CvBuilderModel _model;
  _CvStep _step = _CvStep.personal;
  int _summaryVariant = 0;
  bool _saving = false;

  // Personal info controllers
  final _fullName = TextEditingController();
  final _jobTitle = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _location = TextEditingController();
  final _linkedin = TextEditingController();
  final _website = TextEditingController();

  // Summary controllers
  final _summarySkills = TextEditingController();
  final _achievement = TextEditingController();
  final _summaryText = TextEditingController();

  // Extras controllers
  final _skillsText = TextEditingController();

  late List<ExperienceEntry> _experiences;
  late List<EducationEntry> _education;
  late List<LanguageEntry> _languages;
  late List<CertificationEntry> _certifications;
  late List<ProjectEntry> _projects;

  // ده بيتحكم في لغة الملخص المتولّد (محتوى الـ CV)، مش نصوص الواجهة.
  bool get _uiArabic => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _model = widget.initialModel;
    final info = _model.personalInfo;
    _fullName.text = info.fullName;
    _jobTitle.text = info.jobTitle;
    _email.text = info.email;
    _phone.text = info.phone;
    _location.text = info.location ?? '';
    _linkedin.text = info.linkedinUrl ?? '';
    _website.text = info.websiteUrl ?? '';
    _summaryText.text = _model.summary;
    _skillsText.text = _model.skills.join(', ');
    _experiences = List.of(_model.experiences);
    _education = List.of(_model.education);
    _languages = List.of(_model.languages);
    _certifications = List.of(_model.certifications);
    _projects = List.of(_model.projects);
  }

  @override
  void dispose() {
    for (final c in [
      _fullName, _jobTitle, _email, _phone, _location, _linkedin, _website,
      _summarySkills, _achievement, _summaryText, _skillsText,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _skillList => _skillsText.text
      .split(RegExp(r'[,،\n]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  List<String> get _summarySkillList => _summarySkills.text
      .split(RegExp(r'[,،\n]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  PersonalInfoData get _currentPersonalInfo => PersonalInfoData(
    fullName: _fullName.text.trim(),
    jobTitle: _jobTitle.text.trim(),
    email: _email.text.trim(),
    phone: _phone.text.trim(),
    location: _location.text.trim().isEmpty ? null : _location.text.trim(),
    linkedinUrl: _linkedin.text.trim().isEmpty ? null : _linkedin.text.trim(),
    websiteUrl: _website.text.trim().isEmpty ? null : _website.text.trim(),
    photoUrl: _model.personalInfo.photoUrl,
  );

  CvBuilderModel _buildCurrentModel() {
    return _model.copyWith(
      personalInfo: _currentPersonalInfo,
      summary: _summaryText.text.trim(),
      experiences: _experiences,
      education: _education,
      skills: _skillList,
      languages: _languages,
      certifications: _certifications,
      projects: _projects,
    );
  }

  void _generateSummary() {
    final years = _experiences.isEmpty
        ? 0
        : _buildCurrentModel().totalYearsOfExperience;
    final skills = _summarySkillList.isNotEmpty ? _summarySkillList : _skillList;

    setState(() {
      _summaryVariant++;
      _summaryText.text = SummaryGenerator.generate(
        jobTitle: _jobTitle.text.trim(),
        yearsOfExperience: years,
        topSkills: skills,
        topAchievement: _achievement.text.trim().isEmpty ? null : _achievement.text.trim(),
        isArabic: _uiArabic,
        variantSeed: _summaryVariant,
      );
    });
  }

  bool _validatePersonal() {
    return _fullName.text.trim().isNotEmpty &&
        _jobTitle.text.trim().isNotEmpty &&
        _email.text.trim().isNotEmpty &&
        _phone.text.trim().isNotEmpty;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _next() async {
    switch (_step) {
      case _CvStep.personal:
        if (!_validatePersonal()) {
          _showError(context.tr('cv_builder_error_personal_required'));
          return;
        }
        setState(() => _step = _CvStep.summary);
        break;
      case _CvStep.summary:
        setState(() => _step = _CvStep.experience);
        break;
      case _CvStep.experience:
        setState(() => _step = _CvStep.education);
        break;
      case _CvStep.education:
        setState(() => _step = _CvStep.extras);
        break;
      case _CvStep.extras:
        await _saveAndContinue();
        break;
    }
  }

  void _back() {
    switch (_step) {
      case _CvStep.personal:
        Navigator.of(context).maybePop();
        break;
      case _CvStep.summary:
        setState(() => _step = _CvStep.personal);
        break;
      case _CvStep.experience:
        setState(() => _step = _CvStep.summary);
        break;
      case _CvStep.education:
        setState(() => _step = _CvStep.experience);
        break;
      case _CvStep.extras:
        setState(() => _step = _CvStep.education);
        break;
    }
  }

  Future<void> _saveAndContinue() async {
    setState(() => _saving = true);
    final model = _buildCurrentModel();
    try {
      await context.read<CvBuilderProvider>().save(model);
      if (!mounted) return;
      setState(() {
        _model = model;
        _saving = false;
      });
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => CvBuilderReviewScreen(model: model)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError(context.tr('cv_builder_error_save'));
    }
  }

  int get _stepIndex => _CvStep.values.indexOf(_step);

  String _stepTitle(BuildContext context, _CvStep step) {
    switch (step) {
      case _CvStep.personal:
        return context.tr('cv_builder_step_personal');
      case _CvStep.summary:
        return context.tr('cv_builder_step_summary');
      case _CvStep.experience:
        return context.tr('cv_builder_step_experience');
      case _CvStep.education:
        return context.tr('cv_builder_step_education');
      case _CvStep.extras:
        return context.tr('cv_builder_step_extras');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('cv_builder_title'))),
      body: SafeArea(
        child: Center(
          child: ResponsiveContentWidth(
            maxWidth: 720,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value: (_stepIndex + 1) / _CvStep.values.length,
                        minHeight: 4,
                      ),
                      const SizedBox(height: 10),
                      Text(_stepTitle(context, _step), style: AppTextStyles.h3(textColor)),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildStepBody(textColor),
                  ),
                ),
                _buildNavBar(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepBody(Color textColor) {
    switch (_step) {
      case _CvStep.personal:
        return _PersonalInfoStep(
          fullName: _fullName,
          jobTitle: _jobTitle,
          email: _email,
          phone: _phone,
          location: _location,
          linkedin: _linkedin,
          website: _website,
        );
      case _CvStep.summary:
        return _SummaryStep(
          summarySkills: _summarySkills,
          achievement: _achievement,
          summaryText: _summaryText,
          onGenerate: _generateSummary,
          textColor: textColor,
        );
      case _CvStep.experience:
        return _ExperienceStep(
          experiences: _experiences,
          onChanged: (list) => setState(() => _experiences = list),
        );
      case _CvStep.education:
        return _EducationStep(
          education: _education,
          onChanged: (list) => setState(() => _education = list),
        );
      case _CvStep.extras:
        return _ExtrasStep(
          skillsText: _skillsText,
          languages: _languages,
          certifications: _certifications,
          projects: _projects,
          onLanguagesChanged: (l) => setState(() => _languages = l),
          onCertificationsChanged: (c) => setState(() => _certifications = c),
          onProjectsChanged: (p) => setState(() => _projects = p),
        );
    }
  }

  Widget _buildNavBar(BuildContext context) {
    final isLast = _step == _CvStep.extras;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _saving ? null : _back,
              child: Text(context.tr('cv_builder_back')),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: _saving ? null : _next,
              child: _saving
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Text(isLast
                  ? context.tr('cv_builder_continue_templates')
                  : context.tr('cv_builder_next')),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalInfoStep extends StatelessWidget {
  const _PersonalInfoStep({
    required this.fullName,
    required this.jobTitle,
    required this.email,
    required this.phone,
    required this.location,
    required this.linkedin,
    required this.website,
  });

  final TextEditingController fullName;
  final TextEditingController jobTitle;
  final TextEditingController email;
  final TextEditingController phone;
  final TextEditingController location;
  final TextEditingController linkedin;
  final TextEditingController website;

  Widget _field(TextEditingController c, String label, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(fullName, '${context.tr('cv_builder_field_full_name')} *'),
        _field(jobTitle, '${context.tr('cv_builder_field_job_title')} *'),
        _field(email, '${context.tr('auth_email')} *'),
        _field(phone, '${context.tr('cv_builder_field_phone')} *'),
        _field(location, context.tr('field_location')),
        _field(linkedin, context.tr('cv_builder_field_linkedin')),
        _field(website, context.tr('cv_builder_field_website')),
      ],
    );
  }
}

class _SummaryStep extends StatelessWidget {
  const _SummaryStep({
    required this.summarySkills,
    required this.achievement,
    required this.summaryText,
    required this.onGenerate,
    required this.textColor,
  });

  final TextEditingController summarySkills;
  final TextEditingController achievement;
  final TextEditingController summaryText;
  final VoidCallback onGenerate;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('cv_builder_summary_intro'),
          style: AppTextStyles.bodySmall(textColor),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: summarySkills,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: context.tr('cv_builder_top_skills'),
            hintText: context.tr('cv_builder_skills_hint_example'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: achievement,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: context.tr('cv_builder_key_achievement'),
            hintText: context.tr('cv_builder_achievement_hint'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onGenerate,
          icon: const Icon(Icons.auto_awesome),
          label: Text(summaryText.text.isEmpty
              ? context.tr('cv_builder_generate_summary')
              : context.tr('cv_builder_regenerate_summary')),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: summaryText,
          maxLines: 6,
          minLines: 4,
          decoration: InputDecoration(
            labelText: context.tr('cv_builder_step_summary'),
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}

class _ExperienceStep extends StatelessWidget {
  const _ExperienceStep({
    required this.experiences,
    required this.onChanged,
  });

  final List<ExperienceEntry> experiences;
  final ValueChanged<List<ExperienceEntry>> onChanged;

  Future<void> _addOrEdit(BuildContext context, {int? index}) async {
    final result = await showModalBottomSheet<ExperienceEntry>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ExperienceEditor(
        initial: index != null ? experiences[index] : null,
      ),
    );
    if (result == null) return;
    final updated = List<ExperienceEntry>.of(experiences);
    if (index != null) {
      updated[index] = result;
    } else {
      updated.add(result);
    }
    onChanged(updated);
  }

  void _remove(int index) {
    final updated = List<ExperienceEntry>.of(experiences)..removeAt(index);
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (experiences.isEmpty)
          Text(context.tr('cv_builder_no_experience'),
              style: AppTextStyles.bodyMedium(Theme.of(context).colorScheme.onSurface)),
        for (var i = 0; i < experiences.length; i++)
          AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${experiences[i].jobTitle} — ${experiences[i].company}'),
              subtitle: Text(experiences[i].isCurrent
                  ? context.tr('cv_builder_present')
                  : (experiences[i].endDate != null
                  ? '${experiences[i].startDate.year} - ${experiences[i].endDate!.year}'
                  : '${experiences[i].startDate.year}')),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _addOrEdit(context, index: i),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.warning),
                    onPressed: () => _remove(i),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _addOrEdit(context),
          icon: const Icon(Icons.add),
          label: Text(context.tr('cv_builder_add_experience')),
        ),
      ],
    );
  }
}

class _ExperienceEditor extends StatefulWidget {
  const _ExperienceEditor({this.initial});
  final ExperienceEntry? initial;

  @override
  State<_ExperienceEditor> createState() => _ExperienceEditorState();
}

class _ExperienceEditorState extends State<_ExperienceEditor> {
  final _company = TextEditingController();
  final _jobTitle = TextEditingController();
  final _location = TextEditingController();
  final _bullets = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCurrent = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _company.text = initial.company;
      _jobTitle.text = initial.jobTitle;
      _location.text = initial.location ?? '';
      _bullets.text = initial.bullets.join('\n');
      _startDate = initial.startDate;
      _endDate = initial.endDate;
      _isCurrent = initial.isCurrent;
    }
  }

  @override
  void dispose() {
    _company.dispose();
    _jobTitle.dispose();
    _location.dispose();
    _bullets.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  void _save() {
    if (_company.text.trim().isEmpty || _jobTitle.text.trim().isEmpty || _startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('cv_builder_error_experience_required'))),
      );
      return;
    }
    final entry = ExperienceEntry(
      company: _company.text.trim(),
      jobTitle: _jobTitle.text.trim(),
      location: _location.text.trim().isEmpty ? null : _location.text.trim(),
      startDate: _startDate!,
      endDate: _isCurrent ? null : _endDate,
      isCurrent: _isCurrent,
      bullets: _bullets.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
    );
    Navigator.of(context).pop(entry);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.tr('cv_builder_step_experience'),
                style: AppTextStyles.h3(Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 16),
            TextField(
              controller: _jobTitle,
              decoration: InputDecoration(
                  labelText: '${context.tr('cv_builder_field_job_title')} *',
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _company,
              decoration: InputDecoration(
                  labelText: '${context.tr('cv_builder_field_company')} *',
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _location,
              decoration: InputDecoration(
                  labelText: context.tr('cv_builder_field_location_optional'),
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(isStart: true),
                    child: Text(_startDate == null
                        ? '${context.tr('cv_builder_start_date')} *'
                        : '${_startDate!.year}/${_startDate!.month}'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isCurrent ? null : () => _pickDate(isStart: false),
                    child: Text(_isCurrent
                        ? context.tr('cv_builder_present')
                        : (_endDate == null
                        ? context.tr('cv_builder_end_date')
                        : '${_endDate!.year}/${_endDate!.month}')),
                  ),
                ),
              ],
            ),
            CheckboxListTile(
              value: _isCurrent,
              onChanged: (v) => setState(() => _isCurrent = v ?? false),
              title: Text(context.tr('cv_builder_currently_work_here')),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bullets,
              maxLines: 4,
              minLines: 3,
              decoration: InputDecoration(
                labelText: context.tr('cv_builder_bullets_label'),
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                  onPressed: _save, child: Text(context.tr('save'))),
            ),
          ],
        ),
      ),
    );
  }
}

class _EducationStep extends StatelessWidget {
  const _EducationStep({
    required this.education,
    required this.onChanged,
  });

  final List<EducationEntry> education;
  final ValueChanged<List<EducationEntry>> onChanged;

  Future<void> _addOrEdit(BuildContext context, {int? index}) async {
    final result = await showModalBottomSheet<EducationEntry>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _EducationEditor(
        initial: index != null ? education[index] : null,
      ),
    );
    if (result == null) return;
    final updated = List<EducationEntry>.of(education);
    if (index != null) {
      updated[index] = result;
    } else {
      updated.add(result);
    }
    onChanged(updated);
  }

  void _remove(int index) {
    final updated = List<EducationEntry>.of(education)..removeAt(index);
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (education.isEmpty)
          Text(context.tr('cv_builder_no_education'),
              style: AppTextStyles.bodyMedium(Theme.of(context).colorScheme.onSurface)),
        for (var i = 0; i < education.length; i++)
          AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(education[i].institution),
              subtitle: Text(education[i].degree),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _addOrEdit(context, index: i),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.warning),
                    onPressed: () => _remove(i),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _addOrEdit(context),
          icon: const Icon(Icons.add),
          label: Text(context.tr('cv_builder_add_education')),
        ),
      ],
    );
  }
}

class _EducationEditor extends StatefulWidget {
  const _EducationEditor({this.initial});
  final EducationEntry? initial;

  @override
  State<_EducationEditor> createState() => _EducationEditorState();
}

class _EducationEditorState extends State<_EducationEditor> {
  final _institution = TextEditingController();
  final _degree = TextEditingController();
  final _field = TextEditingController();
  final _grade = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _institution.text = initial.institution;
      _degree.text = initial.degree;
      _field.text = initial.fieldOfStudy ?? '';
      _grade.text = initial.grade ?? '';
      _startDate = initial.startDate;
      _endDate = initial.endDate;
    }
  }

  @override
  void dispose() {
    _institution.dispose();
    _degree.dispose();
    _field.dispose();
    _grade.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  void _save() {
    if (_institution.text.trim().isEmpty || _degree.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('cv_builder_error_education_required'))),
      );
      return;
    }
    final entry = EducationEntry(
      institution: _institution.text.trim(),
      degree: _degree.text.trim(),
      fieldOfStudy: _field.text.trim().isEmpty ? null : _field.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      grade: _grade.text.trim().isEmpty ? null : _grade.text.trim(),
    );
    Navigator.of(context).pop(entry);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.tr('cv_builder_step_education'),
                style: AppTextStyles.h3(Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 16),
            TextField(
              controller: _institution,
              decoration: InputDecoration(
                  labelText: '${context.tr('cv_builder_field_institution')} *',
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _degree,
              decoration: InputDecoration(
                  labelText: '${context.tr('cv_builder_field_degree')} *',
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _field,
              decoration: InputDecoration(
                  labelText: context.tr('cv_builder_field_of_study'),
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(isStart: true),
                    child: Text(_startDate == null
                        ? context.tr('cv_builder_start_date')
                        : '${_startDate!.year}'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(isStart: false),
                    child: Text(_endDate == null
                        ? context.tr('cv_builder_end_date')
                        : '${_endDate!.year}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _grade,
              decoration: InputDecoration(
                  labelText: context.tr('cv_builder_grade'),
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                  onPressed: _save, child: Text(context.tr('save'))),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExtrasStep extends StatelessWidget {
  const _ExtrasStep({
    required this.skillsText,
    required this.languages,
    required this.certifications,
    required this.projects,
    required this.onLanguagesChanged,
    required this.onCertificationsChanged,
    required this.onProjectsChanged,
  });

  final TextEditingController skillsText;
  final List<LanguageEntry> languages;
  final List<CertificationEntry> certifications;
  final List<ProjectEntry> projects;
  final ValueChanged<List<LanguageEntry>> onLanguagesChanged;
  final ValueChanged<List<CertificationEntry>> onCertificationsChanged;
  final ValueChanged<List<ProjectEntry>> onProjectsChanged;

  String _levelLabel(BuildContext context, LanguageLevel level) {
    switch (level) {
      case LanguageLevel.basic:
        return context.tr('cv_builder_level_basic');
      case LanguageLevel.conversational:
        return context.tr('cv_builder_level_conversational');
      case LanguageLevel.fluent:
        return context.tr('cv_builder_level_fluent');
      case LanguageLevel.native:
        return context.tr('cv_builder_level_native');
    }
  }

  Future<void> _addLanguage(BuildContext context) async {
    final nameController = TextEditingController();
    var level = LanguageLevel.conversational;
    final result = await showDialog<LanguageEntry>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(ctx.tr('cv_builder_add_language_title')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: ctx.tr('cv_builder_language_label')),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<LanguageLevel>(
                initialValue: level,
                items: [
                  for (final l in LanguageLevel.values)
                    DropdownMenuItem(value: l, child: Text(_levelLabel(ctx, l))),
                ],
                onChanged: (v) => setState(() => level = v ?? level),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(ctx.tr('cancel'))),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                Navigator.pop(ctx, LanguageEntry(name: nameController.text.trim(), level: level));
              },
              child: Text(ctx.tr('cv_builder_add')),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    if (result != null) {
      onLanguagesChanged([...languages, result]);
    }
  }

  Future<void> _addCertification(BuildContext context) async {
    final nameController = TextEditingController();
    final issuerController = TextEditingController();
    final result = await showDialog<CertificationEntry>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('cv_builder_add_certification_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: ctx.tr('cv_builder_certification_name'))),
            const SizedBox(height: 12),
            TextField(
                controller: issuerController,
                decoration: InputDecoration(labelText: ctx.tr('cv_builder_issuer'))),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.tr('cancel'))),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(ctx, CertificationEntry(
                name: nameController.text.trim(),
                issuer: issuerController.text.trim(),
              ));
            },
            child: Text(ctx.tr('cv_builder_add')),
          ),
        ],
      ),
    );
    nameController.dispose();
    issuerController.dispose();
    if (result != null) {
      onCertificationsChanged([...certifications, result]);
    }
  }

  Future<void> _addProject(BuildContext context) async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final result = await showDialog<ProjectEntry>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('cv_builder_add_project_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: ctx.tr('cv_builder_project_name'))),
            const SizedBox(height: 12),
            TextField(
                controller: descController,
                maxLines: 3,
                decoration: InputDecoration(labelText: ctx.tr('cv_builder_description_optional'))),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.tr('cancel'))),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(ctx, ProjectEntry(
                name: nameController.text.trim(),
                description: descController.text.trim().isEmpty ? null : descController.text.trim(),
              ));
            },
            child: Text(ctx.tr('cv_builder_add')),
          ),
        ],
      ),
    );
    nameController.dispose();
    descController.dispose();
    if (result != null) {
      onProjectsChanged([...projects, result]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('cv_builder_skills_label'), style: AppTextStyles.h3(textColor)),
        const SizedBox(height: 8),
        TextField(
          controller: skillsText,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: context.tr('cv_builder_skills_hint'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.tr('cv_builder_languages_label'), style: AppTextStyles.h3(textColor)),
            TextButton.icon(
                onPressed: () => _addLanguage(context),
                icon: const Icon(Icons.add),
                label: Text(context.tr('cv_builder_add'))),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < languages.length; i++)
              Chip(
                label: Text('${languages[i].name} — ${_levelLabel(context, languages[i].level)}'),
                onDeleted: () => onLanguagesChanged(List.of(languages)..removeAt(i)),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.tr('cv_builder_certifications_label'), style: AppTextStyles.h3(textColor)),
            TextButton.icon(
                onPressed: () => _addCertification(context),
                icon: const Icon(Icons.add),
                label: Text(context.tr('cv_builder_add'))),
          ],
        ),
        for (var i = 0; i < certifications.length; i++)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(certifications[i].name),
            subtitle: Text(certifications[i].issuer),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.warning),
              onPressed: () => onCertificationsChanged(List.of(certifications)..removeAt(i)),
            ),
          ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.tr('cv_builder_projects_label'), style: AppTextStyles.h3(textColor)),
            TextButton.icon(
                onPressed: () => _addProject(context),
                icon: const Icon(Icons.add),
                label: Text(context.tr('cv_builder_add'))),
          ],
        ),
        for (var i = 0; i < projects.length; i++)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(projects[i].name),
            subtitle: projects[i].description != null ? Text(projects[i].description!) : null,
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.warning),
              onPressed: () => onProjectsChanged(List.of(projects)..removeAt(i)),
            ),
          ),
      ],
    );
  }
}