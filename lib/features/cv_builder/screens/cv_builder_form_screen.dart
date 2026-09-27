import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  bool get _uiArabic => Localizations.localeOf(context).languageCode == 'ar';
  String _t(String en, String ar) => _uiArabic ? ar : en;

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
          _showError(_t('Please fill in your name, job title, email and phone.',
              'من فضلك املأ الاسم والمسمى الوظيفي والإيميل والتليفون.'));
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
      _showError(_t('Could not save your CV. Please try again.',
          'معرفناش نحفظ الـ CV. حاول تاني.'));
    }
  }

  int get _stepIndex => _CvStep.values.indexOf(_step);

  String _stepTitle(_CvStep step) {
    switch (step) {
      case _CvStep.personal:
        return _t('Personal info', 'البيانات الشخصية');
      case _CvStep.summary:
        return _t('Professional summary', 'الملخص الاحترافي');
      case _CvStep.experience:
        return _t('Work experience', 'الخبرة العملية');
      case _CvStep.education:
        return _t('Education', 'التعليم');
      case _CvStep.extras:
        return _t('Skills & more', 'المهارات وأكتر');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(title: Text(_t('Create CV', 'إنشاء سيرة ذاتية'))),
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
                      Text(_stepTitle(_step), style: AppTextStyles.h3(textColor)),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildStepBody(textColor),
                  ),
                ),
                _buildNavBar(),
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
          t: _t,
        );
      case _CvStep.summary:
        return _SummaryStep(
          summarySkills: _summarySkills,
          achievement: _achievement,
          summaryText: _summaryText,
          onGenerate: _generateSummary,
          t: _t,
          textColor: textColor,
        );
      case _CvStep.experience:
        return _ExperienceStep(
          experiences: _experiences,
          isArabic: _uiArabic,
          t: _t,
          onChanged: (list) => setState(() => _experiences = list),
        );
      case _CvStep.education:
        return _EducationStep(
          education: _education,
          isArabic: _uiArabic,
          t: _t,
          onChanged: (list) => setState(() => _education = list),
        );
      case _CvStep.extras:
        return _ExtrasStep(
          skillsText: _skillsText,
          languages: _languages,
          certifications: _certifications,
          projects: _projects,
          t: _t,
          onLanguagesChanged: (l) => setState(() => _languages = l),
          onCertificationsChanged: (c) => setState(() => _certifications = c),
          onProjectsChanged: (p) => setState(() => _projects = p),
        );
    }
  }

  Widget _buildNavBar() {
    final isLast = _step == _CvStep.extras;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _saving ? null : _back,
              child: Text(_t('Back', 'رجوع')),
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
                  : Text(isLast ? _t('Continue to templates', 'كمل لاختيار التصميم') : _t('Next', 'التالي')),
            ),
          ),
        ],
      ),
    );
  }
}

typedef _T = String Function(String en, String ar);

class _PersonalInfoStep extends StatelessWidget {
  const _PersonalInfoStep({
    required this.fullName,
    required this.jobTitle,
    required this.email,
    required this.phone,
    required this.location,
    required this.linkedin,
    required this.website,
    required this.t,
  });

  final TextEditingController fullName;
  final TextEditingController jobTitle;
  final TextEditingController email;
  final TextEditingController phone;
  final TextEditingController location;
  final TextEditingController linkedin;
  final TextEditingController website;
  final _T t;

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
        _field(fullName, '${t('Full name', 'الاسم بالكامل')} *'),
        _field(jobTitle, '${t('Job title', 'المسمى الوظيفي')} *'),
        _field(email, '${t('Email', 'البريد الإلكتروني')} *'),
        _field(phone, '${t('Phone', 'رقم الهاتف')} *'),
        _field(location, t('Location', 'الموقع')),
        _field(linkedin, t('LinkedIn URL (optional)', 'رابط لينكدإن (اختياري)')),
        _field(website, t('Website / Portfolio (optional)', 'موقعك الشخصي (اختياري)')),
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
    required this.t,
    required this.textColor,
  });

  final TextEditingController summarySkills;
  final TextEditingController achievement;
  final TextEditingController summaryText;
  final VoidCallback onGenerate;
  final _T t;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t(
            'We\'ll write a professional summary for you based on your top skills and (optionally) a key achievement. You can edit it afterwards.',
            'هنكتبلك ملخص احترافي على أساس أهم مهاراتك و(اختياريًا) أبرز إنجاز ليك. تقدر تعدّل عليه بعد كده.',
          ),
          style: AppTextStyles.bodySmall(textColor),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: summarySkills,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: t('Top skills', 'أهم مهاراتك'),
            hintText: t('Flutter, Firebase, UI design', 'Flutter, Firebase, UI design'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: achievement,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: t('Key achievement (optional)', 'أبرز إنجاز (اختياري)'),
            hintText: t('Led a redesign that increased activation by 18%',
                'قدت إعادة تصميم زوّدت نسبة التفعيل 18%'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onGenerate,
          icon: const Icon(Icons.auto_awesome),
          label: Text(summaryText.text.isEmpty
              ? t('Generate summary', 'اكتب الملخص')
              : t('Regenerate', 'اعمل نسخة جديدة')),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: summaryText,
          maxLines: 6,
          minLines: 4,
          decoration: InputDecoration(
            labelText: t('Professional summary', 'الملخص الاحترافي'),
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
    required this.isArabic,
    required this.t,
    required this.onChanged,
  });

  final List<ExperienceEntry> experiences;
  final bool isArabic;
  final _T t;
  final ValueChanged<List<ExperienceEntry>> onChanged;

  Future<void> _addOrEdit(BuildContext context, {int? index}) async {
    final result = await showModalBottomSheet<ExperienceEntry>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ExperienceEditor(
        initial: index != null ? experiences[index] : null,
        t: t,
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
          Text(t('No experience added yet.', 'لسه مفيش خبرات متضافة.'),
              style: AppTextStyles.bodyMedium(Theme.of(context).colorScheme.onSurface)),
        for (var i = 0; i < experiences.length; i++)
          AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${experiences[i].jobTitle} — ${experiences[i].company}'),
              subtitle: Text(experiences[i].isCurrent
                  ? t('Present', 'حتى الآن')
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
          label: Text(t('Add experience', 'إضافة خبرة')),
        ),
      ],
    );
  }
}

class _ExperienceEditor extends StatefulWidget {
  const _ExperienceEditor({this.initial, required this.t});
  final ExperienceEntry? initial;
  final _T t;

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
        SnackBar(content: Text(widget.t(
            'Please fill in company, job title and start date.',
            'من فضلك املأ اسم الشركة والمسمى الوظيفي وتاريخ البداية.'))),
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
    final t = widget.t;
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
            Text(t('Work experience', 'الخبرة العملية'), style: AppTextStyles.h3(Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 16),
            TextField(
              controller: _jobTitle,
              decoration: InputDecoration(labelText: '${t('Job title', 'المسمى الوظيفي')} *', border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _company,
              decoration: InputDecoration(labelText: '${t('Company', 'الشركة')} *', border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _location,
              decoration: InputDecoration(labelText: t('Location (optional)', 'الموقع (اختياري)'), border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(isStart: true),
                    child: Text(_startDate == null
                        ? '${t('Start date', 'تاريخ البداية')} *'
                        : '${_startDate!.year}/${_startDate!.month}'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isCurrent ? null : () => _pickDate(isStart: false),
                    child: Text(_isCurrent
                        ? t('Present', 'حتى الآن')
                        : (_endDate == null
                        ? t('End date', 'تاريخ النهاية')
                        : '${_endDate!.year}/${_endDate!.month}')),
                  ),
                ),
              ],
            ),
            CheckboxListTile(
              value: _isCurrent,
              onChanged: (v) => setState(() => _isCurrent = v ?? false),
              title: Text(t('I currently work here', 'لسه شغال هنا')),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bullets,
              maxLines: 4,
              minLines: 3,
              decoration: InputDecoration(
                labelText: t('Key responsibilities / achievements (one per line)', 'أهم المهام/الإنجازات (سطر لكل نقطة)'),
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _save, child: Text(t('Save', 'حفظ'))),
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
    required this.isArabic,
    required this.t,
    required this.onChanged,
  });

  final List<EducationEntry> education;
  final bool isArabic;
  final _T t;
  final ValueChanged<List<EducationEntry>> onChanged;

  Future<void> _addOrEdit(BuildContext context, {int? index}) async {
    final result = await showModalBottomSheet<EducationEntry>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _EducationEditor(
        initial: index != null ? education[index] : null,
        t: t,
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
          Text(t('No education added yet.', 'لسه مفيش بيانات تعليمية.'),
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
          label: Text(t('Add education', 'إضافة مؤهل دراسي')),
        ),
      ],
    );
  }
}

class _EducationEditor extends StatefulWidget {
  const _EducationEditor({this.initial, required this.t});
  final EducationEntry? initial;
  final _T t;

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
        SnackBar(content: Text(widget.t(
            'Please fill in institution and degree.',
            'من فضلك املأ اسم المؤسسة التعليمية والمؤهل.'))),
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
    final t = widget.t;
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
            Text(t('Education', 'التعليم'), style: AppTextStyles.h3(Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 16),
            TextField(
              controller: _institution,
              decoration: InputDecoration(labelText: '${t('Institution', 'المؤسسة التعليمية')} *', border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _degree,
              decoration: InputDecoration(labelText: '${t('Degree', 'المؤهل')} *', border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _field,
              decoration: InputDecoration(labelText: t('Field of study (optional)', 'التخصص (اختياري)'), border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(isStart: true),
                    child: Text(_startDate == null
                        ? t('Start date', 'تاريخ البداية')
                        : '${_startDate!.year}'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(isStart: false),
                    child: Text(_endDate == null
                        ? t('End date', 'تاريخ النهاية')
                        : '${_endDate!.year}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _grade,
              decoration: InputDecoration(labelText: t('Grade (optional)', 'التقدير (اختياري)'), border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _save, child: Text(t('Save', 'حفظ'))),
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
    required this.t,
    required this.onLanguagesChanged,
    required this.onCertificationsChanged,
    required this.onProjectsChanged,
  });

  final TextEditingController skillsText;
  final List<LanguageEntry> languages;
  final List<CertificationEntry> certifications;
  final List<ProjectEntry> projects;
  final _T t;
  final ValueChanged<List<LanguageEntry>> onLanguagesChanged;
  final ValueChanged<List<CertificationEntry>> onCertificationsChanged;
  final ValueChanged<List<ProjectEntry>> onProjectsChanged;

  Future<void> _addLanguage(BuildContext context) async {
    final nameController = TextEditingController();
    var level = LanguageLevel.conversational;
    final result = await showDialog<LanguageEntry>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(t('Add language', 'إضافة لغة')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: t('Language', 'اللغة')),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<LanguageLevel>(
                initialValue: level,
                items: [
                  for (final l in LanguageLevel.values)
                    DropdownMenuItem(value: l, child: Text(_levelLabel(l))),
                ],
                onChanged: (v) => setState(() => level = v ?? level),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('Cancel', 'إلغاء'))),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                Navigator.pop(ctx, LanguageEntry(name: nameController.text.trim(), level: level));
              },
              child: Text(t('Add', 'إضافة')),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      onLanguagesChanged([...languages, result]);
    }
  }

  String _levelLabel(LanguageLevel level) {
    switch (level) {
      case LanguageLevel.basic:
        return t('Basic', 'أساسي');
      case LanguageLevel.conversational:
        return t('Conversational', 'محادثة');
      case LanguageLevel.fluent:
        return t('Fluent', 'طلاقة');
      case LanguageLevel.native:
        return t('Native', 'اللغة الأم');
    }
  }

  Future<void> _addCertification(BuildContext context) async {
    final nameController = TextEditingController();
    final issuerController = TextEditingController();
    final result = await showDialog<CertificationEntry>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('Add certification', 'إضافة شهادة')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: t('Certification name', 'اسم الشهادة'))),
            const SizedBox(height: 12),
            TextField(controller: issuerController, decoration: InputDecoration(labelText: t('Issuer', 'الجهة المانحة'))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('Cancel', 'إلغاء'))),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(ctx, CertificationEntry(
                name: nameController.text.trim(),
                issuer: issuerController.text.trim(),
              ));
            },
            child: Text(t('Add', 'إضافة')),
          ),
        ],
      ),
    );
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
        title: Text(t('Add project', 'إضافة مشروع')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: t('Project name', 'اسم المشروع'))),
            const SizedBox(height: 12),
            TextField(controller: descController, maxLines: 3, decoration: InputDecoration(labelText: t('Description (optional)', 'الوصف (اختياري)'))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('Cancel', 'إلغاء'))),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(ctx, ProjectEntry(
                name: nameController.text.trim(),
                description: descController.text.trim().isEmpty ? null : descController.text.trim(),
              ));
            },
            child: Text(t('Add', 'إضافة')),
          ),
        ],
      ),
    );
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
        Text(t('Skills', 'المهارات'), style: AppTextStyles.h3(textColor)),
        const SizedBox(height: 8),
        TextField(
          controller: skillsText,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: t('Flutter, Firebase, REST APIs', 'Flutter, Firebase, REST APIs'),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(t('Languages', 'اللغات'), style: AppTextStyles.h3(textColor)),
            TextButton.icon(onPressed: () => _addLanguage(context), icon: const Icon(Icons.add), label: Text(t('Add', 'إضافة'))),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < languages.length; i++)
              Chip(
                label: Text('${languages[i].name} — ${_levelLabel(languages[i].level)}'),
                onDeleted: () => onLanguagesChanged(List.of(languages)..removeAt(i)),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(t('Certifications', 'الشهادات'), style: AppTextStyles.h3(textColor)),
            TextButton.icon(onPressed: () => _addCertification(context), icon: const Icon(Icons.add), label: Text(t('Add', 'إضافة'))),
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
            Text(t('Projects', 'المشاريع'), style: AppTextStyles.h3(textColor)),
            TextButton.icon(onPressed: () => _addProject(context), icon: const Icon(Icons.add), label: Text(t('Add', 'إضافة'))),
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