import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../localization/app_localizations.dart';
import '../models/cv_model.dart';
import '../theme/app_text_styles.dart';
import '../../features/cv/providers/cv_provider.dart';

/// Form field that lets the user pick one of their uploaded CVs (or none).
/// Tapping it opens a bottom sheet with the user's CVs from [CvProvider].
///
/// [selectedCvId] == null means "no CV". If the id points to a CV that no
/// longer exists (deleted after being linked), the field shows a muted
/// "CV unavailable" text instead of crashing.
class CvPickerField extends StatelessWidget {
  const CvPickerField({
    super.key,
    required this.selectedCvId,
    required this.onChanged,
  });

  final String? selectedCvId;
  final ValueChanged<String?> onChanged;

  static IconData iconFor(CvFileType type) {
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

  void _openPicker(BuildContext context) {
    final cvs = context.read<CvProvider>().cvs;
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    sheetContext.tr('cv_select_title'),
                    style: AppTextStyles.h3(colorScheme.onSurface),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.block),
                  title: Text(sheetContext.tr('cv_no_cv')),
                  trailing: selectedCvId == null
                      ? Icon(Icons.check_circle, color: colorScheme.primary)
                      : null,
                  onTap: () {
                    onChanged(null);
                    Navigator.of(sheetContext).pop();
                  },
                ),
                const Divider(height: 1),
                if (cvs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      sheetContext.tr('cv_empty_hint'),
                      style: AppTextStyles.bodyMedium(
                        colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: cvs.length,
                      itemBuilder: (_, i) {
                        final cv = cvs[i];
                        final isSelected = cv.id == selectedCvId;
                        return ListTile(
                          leading: Icon(iconFor(cv.fileType)),
                          title: Text(
                            cv.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: cv.formattedSize.isEmpty
                              ? null
                              : Text(cv.formattedSize),
                          trailing: isSelected
                              ? Icon(Icons.check_circle,
                              color: colorScheme.primary)
                              : null,
                          onTap: () {
                            onChanged(cv.id);
                            Navigator.of(sheetContext).pop();
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cvProvider = context.watch<CvProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final id = selectedCvId;
    final selected = id == null ? null : cvProvider.byId(id);

    final String text;
    Color textColor = colorScheme.onSurface;
    if (id == null) {
      text = context.tr('cv_none_selected');
      textColor = colorScheme.onSurface.withValues(alpha: 0.6);
    } else if (selected != null) {
      text = selected.fileName;
    } else if (cvProvider.isLoading) {
      text = '...';
      textColor = colorScheme.onSurface.withValues(alpha: 0.6);
    } else {
      text = context.tr('cv_unavailable');
      textColor = colorScheme.error;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openPicker(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: context.tr('field_cv'),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Row(
          children: [
            if (selected != null) ...[
              Icon(iconFor(selected.fileType), size: 20),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}