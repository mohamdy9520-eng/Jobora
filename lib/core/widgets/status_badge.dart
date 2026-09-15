import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../models/application_model.dart';
import '../theme/app_text_styles.dart';

/// A pill-shaped status badge with a colored dot + text.
/// Never relies on color alone — always shows the localized label too.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final ApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            context.tr(status.localizationKey),
            style: AppTextStyles.labelMedium(color),
          ),
        ],
      ),
    );
  }
}
