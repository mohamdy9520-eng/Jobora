import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../controller/practice_interview_controller.dart';
import '../models/practice_models.dart';
import '../widgets/practice_result_view.dart';

class PracticeChatScreen extends StatefulWidget {
  const PracticeChatScreen({super.key, required this.setup});

  final PracticeSetup setup;

  @override
  State<PracticeChatScreen> createState() => _PracticeChatScreenState();
}

class _PracticeChatScreenState extends State<PracticeChatScreen> {
  late final PracticeInterviewController _controller;
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthController>().uid;
    _controller = PracticeInterviewController(setup: widget.setup, uid: uid);
    _controller.addListener(_scrollToEnd);
    _controller.start();
  }

  @override
  void dispose() {
    _controller.removeListener(_scrollToEnd);
    _controller.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String confirmLabel,
    required String cancelLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _onBackAttempt() async {
    final leave = await _confirm(
      title: context.tr('practice_leave_title'),
      body: context.tr('practice_leave_body'),
      confirmLabel: context.tr('practice_leave_confirm'),
      cancelLabel: context.tr('practice_stay'),
    );
    if (leave && mounted) Navigator.of(context).pop();
  }

  Future<void> _finishEarly() async {
    final finish = await _confirm(
      title: context.tr('practice_finish_early_title'),
      body: context.tr('practice_finish_early_body',
          {'count': _controller.answersGiven.toString()}),
      confirmLabel: context.tr('practice_finish_early'),
      cancelLabel: context.tr('common_cancel'),
    );
    if (finish && mounted) _controller.finishEarly();
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty || !_controller.canAnswer) return;
    _input.clear();
    _controller.submitAnswer(text);
  }

  String _errorText(BuildContext context, PracticeError error) {
    return error == PracticeError.network
        ? context.tr('practice_error_network')
        : context.tr('practice_error_ai');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final c = _controller;
        final done = c.phase == PracticePhase.done;
        final textColor = Theme.of(context).colorScheme.onSurface;

        return PopScope(
          // Nothing to lose before the first answer or once feedback is shown.
          canPop: done || c.answersGiven == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _onBackAttempt();
          },
          child: Scaffold(
            appBar: AppBar(
              title: done
                  ? Text(context.tr('practice_result_title'))
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.setup.jobTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelMedium(textColor),
                  ),
                  Text(
                    context.tr('practice_question_progress', {
                      'current': math
                          .max(1, math.min(c.questionsAsked,
                          PracticeInterviewController.totalQuestions))
                          .toString(),
                      'total': PracticeInterviewController.totalQuestions
                          .toString(),
                    }),
                    style: AppTextStyles.bodySmall(
                        textColor.withValues(alpha: 0.65)),
                  ),
                ],
              ),
              actions: [
                if (c.canFinishEarly)
                  TextButton(
                    onPressed: _finishEarly,
                    child: Text(context.tr('practice_finish_early')),
                  ),
              ],
              bottom: done
                  ? null
                  : PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: c.progress,
                  minHeight: 3,
                ),
              ),
            ),
            body: SafeArea(child: _body(context, c)),
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, PracticeInterviewController c) {
    switch (c.phase) {
      case PracticePhase.interviewing:
        return _chat(context, c);
      case PracticePhase.evaluating:
        return _evaluating(context, c);
      case PracticePhase.done:
        return _result(context, c);
    }
  }

  // ───────────────────────── Chat ─────────────────────────

  Widget _chat(BuildContext context, PracticeInterviewController c) {
    final error = c.error;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: ResponsiveContentWidth(
              maxWidth: 760,
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  for (final m in c.messages)
                    _Bubble(message: m, isArabic: widget.setup.isArabic),
                  if (c.isThinking) const _TypingBubble(),
                  if (error != null && !c.isThinking)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _errorText(context, error),
                            style: AppTextStyles.bodyMedium(AppColors.danger),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                            ),
                            onPressed: c.retry,
                            icon: const Icon(Icons.refresh),
                            label: Text(context.tr('retry')),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Center(
            child: ResponsiveContentWidth(
              maxWidth: 760,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: 5,
                        maxLength: 1500,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: context.tr('practice_input_hint'),
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton.filled(
                      tooltip: context.tr('practice_send'),
                      onPressed: c.canAnswer && _input.text.trim().isNotEmpty
                          ? _send
                          : null,
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────── Evaluating ─────────────────────────

  Widget _evaluating(BuildContext context, PracticeInterviewController c) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final error = c.error;

    return Center(
      child: ResponsiveContentWidth(
        maxWidth: 480,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (error == null) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  context.tr('practice_evaluating_title'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h3(textColor),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.tr('practice_evaluating_subtitle'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium(
                      textColor.withValues(alpha: 0.65)),
                ),
              ] else ...[
                const Icon(Icons.error_outline,
                    size: 40, color: AppColors.warning),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _errorText(context, error),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium(textColor),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: c.retry,
                  icon: const Icon(Icons.refresh),
                  label: Text(context.tr('retry')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Result ─────────────────────────

  Widget _result(BuildContext context, PracticeInterviewController c) {
    final session = c.session;
    if (session == null) return const SizedBox.shrink();

    return Center(
      child: ResponsiveContentWidth(
        maxWidth: 820,
        child: PracticeResultView(
          session: session,
          saveFailed: c.saveFailed,
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.tr('practice_practice_again')),
            ),
            OutlinedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: Text(context.tr('practice_done')),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.isArabic});

  final PracticeMessage message;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final mine = message.role == PracticeRole.candidate;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final maxWidth = math.min(MediaQuery.sizeOf(context).width * 0.82, 520.0);

    return Align(
      alignment:
      mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: mine ? AppColors.primary : Theme.of(context).cardColor,
            border: mine
                ? null
                : Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!mine) ...[
                Text(
                  context.tr('practice_interviewer_label'),
                  style: AppTextStyles.labelMedium(AppColors.primary),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                message.text,
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                style: AppTextStyles.bodyMedium(mine ? Colors.white : textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              context.tr('practice_interviewer_typing'),
              style: AppTextStyles.bodySmall(textColor.withValues(alpha: 0.65)),
            ),
          ],
        ),
      ),
    );
  }
}