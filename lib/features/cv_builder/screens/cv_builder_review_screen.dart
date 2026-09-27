import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../models/cv_builder_model.dart';
import '../providers/cv_builder_provider.dart';
import '../templates/cv_template.dart';
import '../templates/cv_template_registry.dart';
import 'cv_builder_form_screen.dart';

/// آخر خطوة في الـ flow: اختيار تصميم من CvTemplateRegistry، معاينة
/// الـ PDF بشكل حي (PdfPreview من باكدج printing)، وتصدير/طباعة
/// الملف. مفيش تعديل مباشر على البيانات هنا — أي تعديل بيرجّع
/// المستخدم لـ CvBuilderFormScreen.
class CvBuilderReviewScreen extends StatefulWidget {
  const CvBuilderReviewScreen({super.key, required this.model});

  final CvBuilderModel model;

  @override
  State<CvBuilderReviewScreen> createState() => _CvBuilderReviewScreenState();
}

class _CvBuilderReviewScreenState extends State<CvBuilderReviewScreen> {
  late CvTemplate _selectedTemplate;
  bool _savingTemplate = false;

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';
  String _t(String en, String ar) => _isArabic ? ar : en;

  @override
  void initState() {
    super.initState();
    _selectedTemplate = CvTemplateRegistry.byId(widget.model.templateId);
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) {
    return _selectedTemplate.build(widget.model, isArabic: _isArabic);
  }

  Future<void> _selectTemplate(CvTemplate template) async {
    if (template.id == _selectedTemplate.id) return;
    setState(() => _selectedTemplate = template);

    // نحفظ اختيار التصميم فورًا عشان لو المستخدم قفل ورجع، يلاقي
    // آخر تصميم اختاره محفوظ على الـ CV.
    setState(() => _savingTemplate = true);
    try {
      final updated = widget.model.copyWith(templateId: template.id);
      await context.read<CvBuilderProvider>().save(updated);
    } catch (_) {
      // فشل حفظ اختيار التصميم مش لازم يوقف المعاينة، هنسيبه يحاول
      // تاني في المرة الجاية أو وقت الحفظ النهائي.
    } finally {
      if (mounted) setState(() => _savingTemplate = false);
    }
  }

  void _editCv() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CvBuilderFormScreen(initialModel: widget.model),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Preview & export', 'المعاينة والتصدير')),
        actions: [
          TextButton(
            onPressed: _editCv,
            child: Text(_t('Edit', 'تعديل')),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ResponsiveContentWidth(
            maxWidth: 900,
            child: Column(
              children: [
                _buildTemplatePicker(textColor),
                Expanded(
                  child: PdfPreview(
                    key: ValueKey(_selectedTemplate.id),
                    build: _generatePdf,
                    allowSharing: true,
                    allowPrinting: true,
                    canChangePageFormat: false,
                    canChangeOrientation: false,
                    canDebug: false,
                    pdfFileName:
                    '${widget.model.personalInfo.fullName.trim().isEmpty ? 'CV' : widget.model.personalInfo.fullName.trim()}.pdf',
                    loadingWidget: const Center(child: CircularProgressIndicator()),
                    onError: (context, error) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _t(
                            'Could not generate the preview. Please try again.',
                            'معرفناش نجهز المعاينة. حاول تاني.',
                          ),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium(textColor),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplatePicker(Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_t('Template', 'التصميم'), style: AppTextStyles.h3(textColor)),
              if (_savingTemplate) ...[
                const SizedBox(width: 10),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: CvTemplateRegistry.all.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final template = CvTemplateRegistry.all[index];
                final isSelected = template.id == _selectedTemplate.id;
                return _TemplateCard(
                  name: template.nameFor(isArabic: _isArabic),
                  description: template.descriptionFor(isArabic: _isArabic),
                  isSelected: isSelected,
                  onTap: () => _selectTemplate(template),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.name,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  final String name;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? scheme.primary : scheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? scheme.primary.withValues(alpha: 0.06) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: AppTextStyles.bodyMedium(scheme.onSurface)
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: scheme.primary, size: 18),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: AppTextStyles.bodySmall(scheme.onSurface.withValues(alpha: 0.7)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}