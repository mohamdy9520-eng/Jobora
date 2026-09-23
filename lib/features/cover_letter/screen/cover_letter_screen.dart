import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../../core/models/application_model.dart';
import '../../../core/services/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_card.dart';
import '../../applications/providers/application_provider.dart';
import '../../subscriptions/providers/subscription_provider.dart';
import '../cover_letter_generator.dart';
import '../cover_letter_pdf.dart';
import '../service/cover_letter_ai_service.dart';
import '../service/cover_letter_usage_service.dart';

class CoverLetterScreen extends StatefulWidget {
  const CoverLetterScreen({super.key});

  @override
  State<CoverLetterScreen> createState() => _CoverLetterScreenState();
}

class _CoverLetterScreenState extends State<CoverLetterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _jobTitle = TextEditingController();
  final _company = TextEditingController();
  final _manager = TextEditingController();
  final _jobDesc = TextEditingController();
  final _skills = TextEditingController();
  final _experience = TextEditingController();
  final _achievements = TextEditingController();
  final _result = TextEditingController();

  final _ai = CoverLetterAiService();
  final _usage = CoverLetterUsageService();

  CoverLetterTone _tone = CoverLetterTone.formal;
  bool _letterArabic = false;
  bool _initialized = false;
  bool _loading = false;
  String? _notice;
  CoverLetterAnalysis? _analysis;
  int? _remaining; // AI letters left today (null = unknown)

  // Last known plan. Used to reload the remaining count when the user
  // subscribes (or the subscription state finishes loading) while this
  // screen is open.
  bool _isPro = false;

  bool get _uiArabic => Localizations.localeOf(context).languageCode == 'ar';
  String _t(String en, String ar) => _uiArabic ? ar : en;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _name.text = context.read<AuthController>().displayName?.trim() ?? '';
    _letterArabic = _uiArabic;
    _isPro = context.read<SubscriptionProvider>().isPro;
    _loadRemaining();
  }

  @override
  void dispose() {
    for (final c in [
      _name, _jobTitle, _company, _manager, _jobDesc,
      _skills, _experience, _achievements, _result,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadRemaining() async {
    final String? uid = context.read<AuthController>().uid;
    if (uid == null || uid.isEmpty || !_ai.isConfigured) return;
    try {
      final left = await _usage.remaining(uid, isPro: _isPro);
      if (mounted) setState(() => _remaining = left);
    } catch (e) {
      debugPrint('[CoverLetterUsage] read failed: $e');
    }
  }

  List<String> get _skillList => _skills.text
      .split(RegExp(r'[,،\n]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  Future<void> _pickApplication() async {
    final apps = context.read<ApplicationProvider>().applications;
    final picked = await showModalBottomSheet<ApplicationModel>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: apps.isEmpty
            ? Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(_t('You have no applications yet.',
              'لسه مفيش طلبات متسجلة.')),
        )
            : ListView.builder(
          shrinkWrap: true,
          itemCount: apps.length,
          itemBuilder: (_, i) => ListTile(
            title: Text(apps[i].position),
            subtitle: Text(apps[i].companyName),
            onTap: () => Navigator.pop(ctx, apps[i]),
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _jobTitle.text = picked.position;
      _company.text = picked.companyName;
      _jobDesc.text = picked.jobDescription ?? '';
      _manager.text = picked.recruiterName ?? '';
    });
  }

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final String? uid = context.read<AuthController>().uid;

    // Read the plan fresh at the moment of generating, so a subscription
    // that just went through is respected immediately.
    final isPro = context.read<SubscriptionProvider>().isPro;
    final limit = CoverLetterUsageService.limitFor(isPro: isPro);

    final input = CoverLetterInput(
      applicantName: _name.text.trim(),
      jobTitle: _jobTitle.text.trim(),
      company: _company.text.trim(),
      hiringManager: _manager.text.trim(),
      jobDescription: _jobDesc.text.trim(),
      skills: _skillList,
      experience: _experience.text.trim(),
      achievements: _achievements.text.trim(),
      tone: _tone,
      isArabic: _letterArabic,
    );

    setState(() {
      _loading = true;
      _notice = null;
    });

    String text;
    String notice;
    var aiUsed = false;
    int? left;

    if (!_ai.isConfigured) {
      text = CoverLetterGenerator.generate(input);
      notice = _t('Generated from your details — edit freely.',
          'اتولّد من بياناتك — تقدر تعدّل عليه براحتك.');
    } else {
      // Check today's AI quota first.
      if (uid != null && uid.isNotEmpty) {
        try {
          left = await _usage.remaining(uid, isPro: isPro);
        } catch (e) {
          debugPrint('[CoverLetterUsage] read failed: $e');
        }
      }

      if (left == null) {
        text = CoverLetterGenerator.generate(input);
        notice = _t(
            'Could not check your daily AI limit, so a template version was used.',
            'مقدرناش نتأكد من حدك اليومي للـ AI، فاستخدمنا النسخة الجاهزة.');
      } else if (left <= 0) {
        text = CoverLetterGenerator.generate(input);
        notice = isPro
            ? _t(
            'You have used all $limit AI letters for today, so a template version was used.',
            'خلّصت $limit خطابات AI النهارده، فاستخدمنا النسخة الجاهزة.')
            : _t(
            'You have used all $limit AI letters for today, so a template version was used. Upgrade to Pro for ${CoverLetterUsageService.proDailyLimit} a day.',
            'خلّصت $limit خطابات AI النهارده، فاستخدمنا النسخة الجاهزة. اشترك في Pro عشان تاخد ${CoverLetterUsageService.proDailyLimit} يوميًا.');
      } else {
        try {
          text = await _ai.generate(input);
          aiUsed = true;
          notice = _t('Written with AI — review and edit before sending.',
              'اتكتب بالذكاء الاصطناعي — راجعه وعدّل عليه قبل الإرسال.');
        } catch (_) {
          text = CoverLetterGenerator.generate(input);
          notice = _t('AI is busy right now, so a template version was used.',
              'الـ AI مشغول دلوقتي، فاستخدمنا النسخة الجاهزة.');
        }
      }
    }

    // Consume one AI letter only after the AI really succeeded.
    if (aiUsed && uid != null && uid.isNotEmpty) {
      try {
        left = await _usage.consume(uid, isPro: isPro);
      } catch (e) {
        debugPrint('[CoverLetterUsage] consume failed: $e');
        left = ((left ?? 1) - 1).clamp(0, limit);
      }
    }

    if (!mounted) return;
    setState(() {
      _result.text = text;
      _notice = notice;
      _analysis = CoverLetterGenerator.analyze(input.jobDescription, input.skills);
      if (left != null) _remaining = left;
      _loading = false;
    });
  }

  String get _fileName {
    final c = _company.text.trim().replaceAll(RegExp(r'[^\w\-]+'), '_');
    return 'cover_letter_${c.isEmpty ? 'jobmate' : c}.pdf';
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _result.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(_t('Copied', 'اتنسخ'))));
  }

  Future<void> _sharePdf() async {
    final bytes = await CoverLetterPdf.build(_result.text, rtl: _letterArabic);
    await Printing.sharePdf(bytes: bytes, filename: _fileName);
  }

  Future<void> _print() async {
    await Printing.layoutPdf(
      name: _fileName,
      onLayout: (_) => CoverLetterPdf.build(_result.text, rtl: _letterArabic),
    );
  }

  Widget _field(
      TextEditingController c,
      String label, {
        int maxLines = 1,
        bool required = false,
        String? hint,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        // minLines must never exceed maxLines.
        minLines: maxLines > 3 ? 3 : maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          alignLabelWithHint: maxLines > 1,
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty)
            ? _t('Required', 'مطلوب')
            : null
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hasResult = _result.text.isNotEmpty;

    // Watch the plan: when it changes (e.g. the user just subscribed, or
    // RevenueCat finished loading), reload the remaining count so the
    // "X of N" line shows the right limit.
    final isPro = context.watch<SubscriptionProvider>().isPro;
    if (isPro != _isPro) {
      _isPro = isPro;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadRemaining();
      });
    }
    final limit = CoverLetterUsageService.limitFor(isPro: isPro);

    return Scaffold(
      appBar: AppBar(title: Text(_t('Cover Letter', 'خطاب التقديم'))),
      body: SafeArea(
        child: Center(
          child: ResponsiveContentWidth(
            maxWidth: 720,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  Text(_t('The job', 'الوظيفة'),
                      style: AppTextStyles.h3(textColor)),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: _pickApplication,
                    icon: const Icon(Icons.description_outlined),
                    label: Text(_t('Pick from my applications',
                        'اختار من طلباتي')),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _field(_jobTitle, _t('Job title', 'المسمى الوظيفي'),
                      required: true),
                  _field(_company, _t('Company', 'الشركة'), required: true),
                  _field(_manager,
                      _t('Hiring manager (optional)', 'اسم مسؤول التوظيف (اختياري)')),
                  _field(
                    _jobDesc,
                    _t('Job description (optional)', 'وصف الوظيفة (اختياري)'),
                    maxLines: 6,
                    hint: _t('Paste it for a better-tailored letter',
                        'الصقه عشان الخطاب يطلع مخصص أكتر'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(_t('About you', 'عنك'),
                      style: AppTextStyles.h3(textColor)),
                  const SizedBox(height: AppSpacing.md),
                  _field(_name, _t('Full name', 'الاسم بالكامل'), required: true),
                  _field(
                    _skills,
                    _t('Key skills', 'أهم المهارات'),
                    maxLines: 2,
                    hint: _t('Flutter, Firebase, REST APIs',
                        'Flutter, Firebase, REST APIs'),
                  ),
                  _field(
                    _experience,
                    _t('Experience summary', 'ملخص خبراتك'),
                    maxLines: 4,
                  ),
                  _field(
                    _achievements,
                    _t('Key achievements (optional)', 'أهم إنجازاتك (اختياري)'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(_t('Letter language', 'لغة الخطاب'),
                      style: AppTextStyles.bodyMedium(textColor)),
                  const SizedBox(height: AppSpacing.sm),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('English')),
                      ButtonSegment(value: true, label: Text('العربية')),
                    ],
                    selected: {_letterArabic},
                    onSelectionChanged: (s) =>
                        setState(() => _letterArabic = s.first),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(_t('Tone', 'الأسلوب'),
                      style: AppTextStyles.bodyMedium(textColor)),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      for (final entry in {
                        CoverLetterTone.formal: _t('Formal', 'رسمي'),
                        CoverLetterTone.friendly: _t('Friendly', 'ودود'),
                        CoverLetterTone.confident: _t('Confident', 'واثق'),
                      }.entries)
                        ChoiceChip(
                          label: Text(entry.value),
                          selected: _tone == entry.key,
                          onSelected: (_) => setState(() => _tone = entry.key),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (_ai.isConfigured && _remaining != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(
                        _t(
                          'AI letters left today: $_remaining of $limit',
                          'خطابات الـ AI المتبقية النهارده: $_remaining من $limit',
                        ),
                        style: AppTextStyles.bodySmall(textColor),
                      ),
                    ),
                  FilledButton.icon(
                    onPressed: _loading ? null : _generate,
                    icon: _loading
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.auto_awesome),
                    label: Text(hasResult
                        ? _t('Regenerate', 'اعمل نسخة جديدة')
                        : _t('Generate cover letter', 'اكتب الخطاب')),
                  ),

                  if (hasResult) ...[
                    const SizedBox(height: AppSpacing.xxl),
                    if (_analysis != null &&
                        (_analysis!.matched.isNotEmpty ||
                            _analysis!.suggested.isNotEmpty))
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_analysis!.matched.isNotEmpty) ...[
                                Text(
                                    _t('Your skills that match this job',
                                        'مهاراتك الي بتطابق الوظيفة'),
                                    style: AppTextStyles.bodyMedium(textColor)),
                                const SizedBox(height: AppSpacing.sm),
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.sm,
                                  children: [
                                    for (final s in _analysis!.matched)
                                      Chip(
                                        label: Text(s),
                                        backgroundColor: AppColors.primary
                                            .withValues(alpha: 0.12),
                                      ),
                                  ],
                                ),
                              ],
                              if (_analysis!.suggested.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                    _t('Keywords in the job you didn\'t mention',
                                        'كلمات مهمة في الوظيفة ومذكرتهاش'),
                                    style: AppTextStyles.bodyMedium(textColor)),
                                const SizedBox(height: AppSpacing.sm),
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.sm,
                                  children: [
                                    for (final s in _analysis!.suggested)
                                      Chip(label: Text(s)),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    if (_notice != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Text(_notice!,
                            style: AppTextStyles.bodySmall(textColor)),
                      ),
                    TextField(
                      controller: _result,
                      maxLines: null,
                      minLines: 12,
                      textDirection:
                      _letterArabic ? TextDirection.rtl : TextDirection.ltr,
                      decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _copy,
                          icon: const Icon(Icons.copy),
                          label: Text(_t('Copy', 'نسخ')),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _sharePdf,
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: Text(_t('Export PDF', 'تصدير PDF')),
                        ),
                        OutlinedButton.icon(
                          onPressed: _print,
                          icon: const Icon(Icons.print_outlined),
                          label: Text(_t('Print', 'طباعة')),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}