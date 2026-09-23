import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/models/application_model.dart';
import '../../../core/models/cv_model.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_card.dart';
import '../../applications/providers/application_provider.dart';
import '../../cv/providers/cv_provider.dart';
import '../../subscriptions/providers/subscription_provider.dart';
import '../models/practice_models.dart';
import '../repository/practice_session_repository.dart';
import '../services/cv_text_extractor.dart';
import '../services/practice_interview_ai_service.dart';
import '../widgets/practice_result_view.dart';

class _CvChoice {
  const _CvChoice(this.cv);
  final CvModel? cv; // null = "no CV"
}

class PracticeSetupScreen extends StatefulWidget {
  const PracticeSetupScreen({super.key});

  @override
  State<PracticeSetupScreen> createState() => _PracticeSetupScreenState();
}

class _PracticeSetupScreenState extends State<PracticeSetupScreen> {
  final _notes = TextEditingController();
  final _ai = PracticeInterviewAiService();
  final _extractor = CvTextExtractor();
  final _repository = PracticeSessionRepository();

  String? _uid;
  String? _applicationId;
  String? _cvChoiceId; // explicit CV pick (null = automatic)
  bool _cvNone = false; // user explicitly chose "no CV"
  bool _isArabic = false;
  bool _initialized = false;
  bool _starting = false;
  String? _errorKey;

  List<PracticeSession> _sessions = const [];
  StreamSubscription<List<PracticeSession>>? _historySub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    _isArabic = Localizations.localeOf(context).languageCode == 'ar';
    _uid = context.read<AuthController>().uid;

    final uid = _uid;
    if (uid != null && uid.isNotEmpty) {
      _historySub = _repository.watchAll(uid).listen(
            (sessions) {
          if (mounted) setState(() => _sessions = sessions);
        },
        onError: (Object e) => debugPrint('[PracticeSetup] history error: $e'),
      );
    }
  }

  @override
  void dispose() {
    _historySub?.cancel();
    _notes.dispose();
    super.dispose();
  }

  // ───────────────────────── Selection helpers ─────────────────────────

  ApplicationModel? _application(ApplicationProvider p) =>
      _applicationId == null ? null : p.byId(_applicationId!);

  /// Explicit pick > CV linked to the application > most recent CV.
  CvModel? _resolveCv(CvProvider p, ApplicationModel? app) {
    if (_cvNone) return null;
    if (_cvChoiceId != null) return p.byId(_cvChoiceId!);
    final linked = app?.cvId;
    if (linked != null) {
      final cv = p.byId(linked);
      if (cv != null) return cv;
    }
    return p.cvs.isNotEmpty ? p.cvs.first : null;
  }

  IconData _cvIcon(CvFileType type) {
    switch (type) {
      case CvFileType.pdf:
        return Icons.picture_as_pdf_outlined;
      case CvFileType.word:
        return Icons.description_outlined;
      case CvFileType.image:
        return Icons.image_outlined;
      case CvFileType.other:
        return Icons.insert_drive_file_outlined;
    }
  }

  Future<void> _pickApplication(List<ApplicationModel> apps) async {
    final id = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.7,
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: apps.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(apps[i].position),
              subtitle: Text(apps[i].companyName),
              selected: apps[i].id == _applicationId,
              onTap: () => Navigator.pop(ctx, apps[i].id),
            ),
          ),
        ),
      ),
    );
    if (id == null || !mounted) return;
    setState(() {
      _applicationId = id;
      _cvChoiceId = null;
      _cvNone = false;
      _errorKey = null;
    });
  }

  Future<void> _pickCv(List<CvModel> cvs) async {
    final choice = await showModalBottomSheet<_CvChoice>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.7,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.block),
                title: Text(context.tr('practice_cv_none')),
                onTap: () => Navigator.pop(ctx, const _CvChoice(null)),
              ),
              for (final cv in cvs)
                ListTile(
                  leading: Icon(_cvIcon(cv.fileType)),
                  title: Text(cv.fileName,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle:
                  cv.formattedSize.isEmpty ? null : Text(cv.formattedSize),
                  selected: cv.id == _cvChoiceId,
                  onTap: () => Navigator.pop(ctx, _CvChoice(cv)),
                ),
            ],
          ),
        ),
      ),
    );
    if (choice == null || !mounted) return;
    setState(() {
      if (choice.cv == null) {
        _cvNone = true;
        _cvChoiceId = null;
      } else {
        _cvNone = false;
        _cvChoiceId = choice.cv!.id;
      }
      _errorKey = null;
    });
  }

  // ───────────────────────── Start ─────────────────────────

  Future<void> _start() async {
    final apps = context.read<ApplicationProvider>();
    final cvs = context.read<CvProvider>();
    final app = _application(apps);

    if (app == null) {
      setState(() => _errorKey = 'practice_error_pick_application');
      return;
    }

    final cv = _resolveCv(cvs, app);
    final notes = _notes.text.trim();

    setState(() {
      _starting = true;
      _errorKey = null;
    });

    var cvText = '';
    if (cv != null) {
      try {
        cvText = await _extractor.extract(cv);
      } on CvTextUnavailable {
        // Falls back to the notes below.
      } catch (_) {
        // Same fallback.
      }
    }
    if (!mounted) return;

    if (cvText.isEmpty && notes.isEmpty) {
      setState(() {
        _starting = false;
        _errorKey = cv == null
            ? 'practice_error_need_cv_or_notes'
            : 'practice_error_cv_unreadable';
      });
      return;
    }

    setState(() => _starting = false);

    context.push(
      AppRoutes.practiceChat,
      extra: PracticeSetup(
        applicationId: app.id,
        jobTitle: app.position,
        company: app.companyName,
        isArabic: _isArabic,
        jobDescription: app.jobDescription ?? '',
        cvText: cvText,
        notes: notes,
      ),
    );
  }

  Future<void> _confirmDelete(PracticeSession session) async {
    final uid = _uid;
    if (uid == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('practice_history_delete_title')),
        content: Text(context.tr('practice_history_delete_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('common_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('common_delete')),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _repository.delete(uid, session.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('error_delete_failed'))),
      );
    }
  }

  // ───────────────────────── Build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final isPro = context.watch<SubscriptionProvider>().isPro;
    final apps = context.watch<ApplicationProvider>();
    final cvs = context.watch<CvProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('practice_title'))),
      body: SafeArea(
        child: !isPro
            ? const _LockedView()
            : LayoutBuilder(
          builder: (context, constraints) {
            final form = _buildForm(context, apps, cvs);
            final history = _buildHistory(context);

            // Tablet / desktop: form on one side, history on the other.
            if (constraints.maxWidth >= 900) {
              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: ListView(children: form)),
                        const SizedBox(width: AppSpacing.xxl),
                        Expanded(flex: 2, child: ListView(children: history)),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Center(
              child: ResponsiveContentWidth(
                maxWidth: 720,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  children: [
                    ...form,
                    const SizedBox(height: AppSpacing.xxl),
                    ...history,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildForm(
      BuildContext context,
      ApplicationProvider apps,
      CvProvider cvs,
      ) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final muted = textColor.withValues(alpha: 0.65);
    final app = _application(apps);
    final cv = _resolveCv(cvs, app);

    return [
      Text(context.tr('practice_intro'),
          style: AppTextStyles.bodyMedium(muted)),
      const SizedBox(height: AppSpacing.xl),

      // ── The job ──
      Text(context.tr('practice_section_job'),
          style: AppTextStyles.h3(textColor)),
      const SizedBox(height: AppSpacing.md),
      if (apps.applications.isEmpty)
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.tr('practice_no_applications_title'),
                  style: AppTextStyles.bodyMedium(textColor)),
              const SizedBox(height: AppSpacing.xs),
              Text(context.tr('practice_no_applications_subtitle'),
                  style: AppTextStyles.bodySmall(muted)),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => context.push(AppRoutes.addApplication),
                child: Text(context.tr('practice_no_applications_action')),
              ),
            ],
          ),
        )
      else
        _SelectorTile(
          icon: Icons.work_outline,
          label: context.tr('practice_pick_application'),
          value: app == null ? null : '${app.position} · ${app.companyName}',
          placeholder: context.tr('practice_pick_application_hint'),
          onTap: () => _pickApplication(apps.applications),
        ),
      if (app != null && (app.jobDescription ?? '').trim().isEmpty) ...[
        const SizedBox(height: AppSpacing.sm),
        Text(context.tr('practice_no_job_description_hint'),
            style: AppTextStyles.bodySmall(AppColors.warning)),
      ],
      const SizedBox(height: AppSpacing.xl),

      // ── The CV ──
      Text(context.tr('practice_section_cv'),
          style: AppTextStyles.h3(textColor)),
      const SizedBox(height: AppSpacing.md),
      if (cvs.cvs.isEmpty)
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.tr('cv_empty_hint'),
                  style: AppTextStyles.bodySmall(muted)),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: () => context.push(AppRoutes.cvUpload),
                child: Text(context.tr('cv_upload_add_button')),
              ),
            ],
          ),
        )
      else
        _SelectorTile(
          icon: cv == null ? Icons.block : _cvIcon(cv.fileType),
          label: context.tr('practice_pick_cv'),
          value: cv?.fileName ?? context.tr('practice_cv_none'),
          placeholder: context.tr('practice_cv_none'),
          onTap: () => _pickCv(cvs.cvs),
        ),
      if (cv != null && cv.fileType != CvFileType.pdf) ...[
        const SizedBox(height: AppSpacing.sm),
        Text(context.tr('practice_cv_only_pdf_hint'),
            style: AppTextStyles.bodySmall(AppColors.warning)),
      ],
      const SizedBox(height: AppSpacing.md),
      TextField(
        controller: _notes,
        minLines: 3,
        maxLines: 8,
        maxLength: 3000,
        keyboardType: TextInputType.multiline,
        decoration: InputDecoration(
          labelText: context.tr('practice_notes_label'),
          hintText: context.tr('practice_notes_hint'),
          alignLabelWithHint: true,
        ),
      ),
      const SizedBox(height: AppSpacing.md),

      // ── Language ──
      Text(context.tr('practice_interview_language'),
          style: AppTextStyles.bodyMedium(textColor)),
      const SizedBox(height: AppSpacing.sm),
      SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: false, label: Text('English')),
          ButtonSegment(value: true, label: Text('العربية')),
        ],
        selected: {_isArabic},
        onSelectionChanged: (s) => setState(() => _isArabic = s.first),
      ),
      const SizedBox(height: AppSpacing.xl),

      if (_errorKey != null) ...[
        Text(context.tr(_errorKey!),
            style: AppTextStyles.bodyMedium(AppColors.danger)),
        const SizedBox(height: AppSpacing.md),
      ],
      if (!_ai.isConfigured) ...[
        Text(context.tr('practice_ai_not_configured'),
            style: AppTextStyles.bodyMedium(AppColors.danger)),
        const SizedBox(height: AppSpacing.md),
      ],
      FilledButton.icon(
        onPressed: (_starting || !_ai.isConfigured) ? null : _start,
        icon: _starting
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : const Icon(Icons.play_arrow_rounded),
        label: Text(_starting
            ? context.tr('practice_reading_cv')
            : context.tr('practice_start')),
      ),
    ];
  }

  List<Widget> _buildHistory(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return [
      Text(context.tr('practice_history_title'),
          style: AppTextStyles.h3(textColor)),
      const SizedBox(height: AppSpacing.md),
      if (_sessions.isEmpty)
        Text(context.tr('practice_history_empty'),
            style: AppTextStyles.bodyMedium(textColor.withValues(alpha: 0.65)))
      else
        for (final s in _sessions)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _HistoryTile(
              session: s,
              onTap: () => context.push(AppRoutes.practiceResult, extra: s),
              onDelete: () => _confirmDelete(s),
            ),
          ),
      const SizedBox(height: AppSpacing.xxxl),
    ];
  }
}

class _SelectorTile extends StatelessWidget {
  const _SelectorTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final muted = textColor.withValues(alpha: 0.65);
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodySmall(muted)),
                const SizedBox(height: 2),
                Text(
                  value ?? placeholder,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium(
                      value == null ? muted : textColor),
                ),
              ],
            ),
          ),
          const Icon(Icons.unfold_more),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.session,
    required this.onTap,
    required this.onDelete,
  });

  final PracticeSession session;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final score = session.feedback.score;
    final color = practiceScoreColor(score);

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text('$score', style: AppTextStyles.labelMedium(color)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.jobTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium(textColor)),
                Text(
                  '${session.company} · ${session.dateLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall(
                      textColor.withValues(alpha: 0.65)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 20),
          ),
        ],
      ),
    );
  }
}

/// Shown instead of the setup form to users without an active Pro plan.
class _LockedView extends StatelessWidget {
  const _LockedView();

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Center(
      child: ResponsiveContentWidth(
        maxWidth: 480,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.workspace_premium_rounded,
                  size: 56, color: AppColors.primary),
              const SizedBox(height: AppSpacing.lg),
              Text(
                context.tr('practice_locked_title'),
                textAlign: TextAlign.center,
                style: AppTextStyles.h2(textColor),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.tr('practice_locked_subtitle'),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium(
                    textColor.withValues(alpha: 0.65)),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: () => context.push(AppRoutes.subscriptions),
                child: Text(context.tr('premium_upgrade')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}