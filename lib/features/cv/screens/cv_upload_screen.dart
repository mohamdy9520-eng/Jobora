import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/cv_model.dart';
import '../providers/cv_provider.dart';

class CvUploadScreen extends StatelessWidget {
  const CvUploadScreen({super.key});

  Future<void> _pickAndUpload(BuildContext context) async {
    final provider = context.read<CvProvider>();
    if (provider.isUploading) return;

    final result = await FilePicker.pickFiles(
      type: FileType.any,
    );
    if (result.isEmpty) return;

    final picked = result.single;
    final path = picked.path;
    if (path == null) return;

    try {
      await provider.upload(File(path), picked.name);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('cv_upload_success'))),
        );
      }
    } catch (e) {
      debugPrint('CV upload error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              kDebugMode
                  ? '${context.tr('cv_upload_error')}\n$e'
                  : context.tr('cv_upload_error'),
            ),
          ),
        );
      }
    }
  }

  /// Opens the CV file in an external app (browser / PDF viewer).
  Future<void> _openCv(BuildContext context, CvModel cv) async {
    final uri = Uri.tryParse(cv.downloadUrl);
    var opened = false;

    if (uri != null && uri.hasScheme) {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('CV open error: $e');
      }
    }

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('cv_upload_error'))),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, CvModel cv) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr('cv_upload_delete_confirm_title')),
        content: Text(
          dialogContext.tr('cv_upload_delete_confirm_body', {'name': cv.fileName}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.tr('common_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              dialogContext.tr('common_delete'),
              style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<CvProvider>().delete(cv);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('cv_upload_error'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('cv_upload_title'))),
      body: Consumer<CvProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              if (provider.isUploading) _UploadProgressBar(provider: provider),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.cvs.isEmpty
                    ? _EmptyState(onTap: () => _pickAndUpload(context))
                    : ListView.separated(
                  padding: EdgeInsets.all(16.w),
                  itemCount: provider.cvs.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    final cv = provider.cvs[index];
                    return _CvCard(
                      cv: cv,
                      onOpen: () => _openCv(context, cv),
                      onDelete: () => _confirmDelete(context, cv),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<CvProvider>(
        builder: (context, provider, _) => FloatingActionButton.extended(
          onPressed: provider.isUploading ? null : () => _pickAndUpload(context),
          icon: const Icon(Icons.upload_file),
          label: Text(context.tr('cv_upload_add_button')),
        ),
      ),
    );
  }
}

class _UploadProgressBar extends StatelessWidget {
  const _UploadProgressBar({required this.provider});

  final CvProvider provider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('cv_upload_uploading'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(height: 6.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: LinearProgressIndicator(
              value: provider.uploadProgress > 0 ? provider.uploadProgress : null,
              minHeight: 6.h,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64.sp,
              color: Theme.of(context).colorScheme.outline,
            ),
            SizedBox(height: 16.h),
            Text(
              context.tr('cv_upload_empty_title'),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              context.tr('cv_upload_empty_subtitle'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.upload_file),
              label: Text(context.tr('cv_upload_add_button')),
            ),
          ],
        ),
      ),
    );
  }
}

class _CvCard extends StatelessWidget {
  const _CvCard({
    required this.cv,
    required this.onOpen,
    required this.onDelete,
  });

  final CvModel cv;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  IconData get _icon {
    switch (cv.fileType) {
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

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onOpen,
        leading: Icon(_icon, size: 28.sp),
        title: Text(cv.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${cv.formattedSize} · ${DateFormat.yMMMd(locale).format(cv.uploadedAt)}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}