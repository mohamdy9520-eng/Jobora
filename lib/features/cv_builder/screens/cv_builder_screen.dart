import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_localizations.dart';
import '../providers/cv_builder_provider.dart';
import '../templates/cv_template_registry.dart';
import 'cv_builder_form_screen.dart';

/// نقطة الدخول لـ /cv-builder. مفيش UI حقيقي هنا — بس بتعمل draft
/// جديد (بأول template متاح كـ default) وبعدين تروح على
/// CvBuilderFormScreen على طول. الوسيط ده موجود بس لأن إنشاء الـ
/// draft عملية async، وGoRoute.builder مش بيقبل async مباشرة.
class CvBuilderEntryScreen extends StatefulWidget {
  const CvBuilderEntryScreen({super.key});

  @override
  State<CvBuilderEntryScreen> createState() => _CvBuilderEntryScreenState();
}

class _CvBuilderEntryScreenState extends State<CvBuilderEntryScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _createDraft());
  }

  Future<void> _createDraft() async {
    setState(() => _error = null);
    try {
      final draft = await context.read<CvBuilderProvider>().createDraft(
        templateId: CvTemplateRegistry.all.first.id,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CvBuilderFormScreen(initialModel: draft),
        ),
      );
    } catch (err) {
      if (!mounted) return;
      setState(() => _error = err.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _error == null
            ? const CircularProgressIndicator()
            : Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40),
              const SizedBox(height: 12),
              Text(
                context.tr('cv_builder_entry_error'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _createDraft,
                child: Text(context.tr('retry')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}