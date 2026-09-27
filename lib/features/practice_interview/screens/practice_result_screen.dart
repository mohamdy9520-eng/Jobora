import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/responsive.dart';
import '../models/practice_models.dart';
import '../widgets/practice_result_view.dart';

/// Shows the saved feedback of a finished session (opened from history).
class PracticeResultScreen extends StatelessWidget {
  const PracticeResultScreen({super.key, required this.session});

  final PracticeSession session;

  @override
  Widget build(BuildContext context) {
    final muted =
    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('practice_result_title')),
            // When this session happened, so old reports are easy to tell apart.
            Text(
              session.dateLabel,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: muted),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ResponsiveContentWidth(
            maxWidth: 820,
            child: PracticeResultView(
              session: session,
              actions: [
                FilledButton(
                  onPressed: () => context.pop(),
                  child: Text(context.tr('practice_done')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}