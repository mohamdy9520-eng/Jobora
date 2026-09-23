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
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('practice_result_title'))),
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