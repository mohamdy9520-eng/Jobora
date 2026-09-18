import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/application_model.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../core/router/app_router.dart';
import 'providers/application_provider.dart';

/// Lists all of the signed-in user's job applications, sorted by most
/// recently updated first. Tapping a card opens ApplicationDetailsScreen;
/// the FAB opens AddApplicationScreen.
///
/// Each card also supports swipe gestures:
/// - Swipe right (start-to-end) opens EditApplicationScreen. The card is
///   never actually dismissed for this direction — confirmDismiss always
///   returns false after navigating, so it snaps back into place.
/// - Swipe left (end-to-start) asks for confirmation, then deletes the
///   application via ApplicationProvider.delete.
///
/// [initialFilter] arrives as a query param when pushed from Home's
/// summary cards — one of: active | interview | waiting | offer.
/// It only sets the *initial* selection; the user can still change or
/// clear it from the filter bar. Null/unrecognized values show everything.
class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key, this.initialFilter});

  final String? initialFilter;

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  String? _activeFilter;

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.initialFilter;
  }

  bool _matchesFilter(ApplicationModel app) {
    switch (_activeFilter) {
      case 'interview':
        return app.status == ApplicationStatus.interview;
      case 'waiting':
        return app.status == ApplicationStatus.screening;
      case 'offer':
        return app.status == ApplicationStatus.offer;
      case 'active':
      // "Active" excludes both terminal states — rejected and
      // withdrawn — everything else (saved, applied, screening,
      // interview, offer) still counts as in progress.
        return app.status != ApplicationStatus.rejected &&
            app.status != ApplicationStatus.withdrawn;
      default:
        return true;
    }
  }

  String _filterLabel(BuildContext context, String filter) {
    switch (filter) {
      case 'interview':
        return context.tr('home_interviews');
      case 'waiting':
        return context.tr('home_waiting_response');
      case 'offer':
        return context.tr('home_offers');
      case 'active':
        return context.tr('home_active_applications');
      default:
        return filter;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApplicationProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('applications_title'))),
      body: SafeArea(
        child: Center(
          child: ResponsiveContentWidth(
            maxWidth: 700,
            child: Column(
              children: [
                if (_activeFilter != null) _buildFilterBanner(context),
                Expanded(child: _buildBody(context, provider)),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.addApplication),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterBanner(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Chip(
          label: Text(_filterLabel(context, _activeFilter!)),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: () => setState(() => _activeFilter = null),
          backgroundColor: theme.colorScheme.primaryContainer,
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ApplicationProvider provider) {
    if (provider.isLoading && provider.applications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.applications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            context.tr('error_load_failed'),
            style: AppTextStyles.bodyMedium(Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final applications = List.of(provider.applications)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final filtered = _activeFilter == null
        ? applications
        : applications.where(_matchesFilter).toList();

    if (applications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.work_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: AppSpacing.lg),
              Text(
                context.tr('applications_empty_title'),
                style: AppTextStyles.h3(Theme.of(context).colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.tr('applications_empty_subtitle'),
                style: AppTextStyles.bodyMedium(Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (filtered.isEmpty) {
      // Real applications exist, just none match the active filter —
      // different message from the true empty state above, plus a
      // way back to the full list.
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_alt_off_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: AppSpacing.lg),
              Text(
                context.tr('applications_filter_empty_title'),
                style: AppTextStyles.h3(Theme.of(context).colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => setState(() => _activeFilter = null),
                child: Text(context.tr('applications_show_all')),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final app = filtered[index];
        return _ApplicationCard(application: app);
      },
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.application});

  final ApplicationModel application;

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('confirm_delete_title')),
        content: Text(context.tr('confirm_delete_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              context.tr('delete'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<bool> _handleDismiss(BuildContext context, DismissDirection direction) async {
    if (direction == DismissDirection.startToEnd) {
      // Swipe right -> edit. Never actually remove the card: navigate,
      // then tell Dismissible to snap back regardless of what happens
      // on the edit screen.
      await context.push('${AppRoutes.editApplication}/${application.id}/edit');
      return false;
    }

    // Swipe left -> delete, after confirmation.
    final confirmed = await _confirmDelete(context);
    if (!confirmed) return false;

    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<ApplicationProvider>();
    try {
      await provider.delete(application.id);
      return true;
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.tr('error_delete_failed'))),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(application.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) => _handleDismiss(context, direction),
      background: _SwipeBackground(
        alignment: Alignment.centerLeft,
        color: theme.colorScheme.primaryContainer,
        icon: Icons.edit_outlined,
        iconColor: theme.colorScheme.onPrimaryContainer,
      ),
      secondaryBackground: _SwipeBackground(
        alignment: Alignment.centerRight,
        color: theme.colorScheme.errorContainer,
        icon: Icons.delete_outline,
        iconColor: theme.colorScheme.onErrorContainer,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('${AppRoutes.applicationDetails}/${application.id}'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 44,
                  decoration: BoxDecoration(
                    color: application.status.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.position,
                        style: AppTextStyles.h3(theme.colorScheme.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        application.companyName,
                        style: AppTextStyles.bodyMedium(theme.colorScheme.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: application.status.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    context.tr('status_${application.status.name}'),
                    style: AppTextStyles.bodySmall(application.status.color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.iconColor,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Icon(icon, color: iconColor),
    );
  }
}