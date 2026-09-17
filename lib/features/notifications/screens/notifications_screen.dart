import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';


class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('notifications_title')),
          bottom: TabBar(tabs: [
            Tab(text: context.tr('notifications_tab_preferences')),
            Tab(text: context.tr('notifications_tab_history')),
          ]),
        ),
        body: const TabBarView(
          children: [_PreferencesTab(), _HistoryTab()],
        ),
      ),
    );
  }
}

class _PreferencesTab extends StatelessWidget {
  const _PreferencesTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final s = provider.settings;

    return Center(
      child: ResponsiveContentWidth(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            SwitchListTile(
              title: Text(context.tr('notif_setting_push')),
              value: s.pushEnabled,
              onChanged: (v) => provider.updateSettings(s.copyWith(pushEnabled: v)),
            ),
            SwitchListTile(
              title: Text(context.tr('notif_setting_application_updates')),
              value: s.applicationUpdates,
              onChanged: (v) => provider.updateSettings(s.copyWith(applicationUpdates: v)),
            ),
            SwitchListTile(
              title: Text(context.tr('notif_setting_interview_reminders')),
              value: s.interviewReminders,
              onChanged: (v) => provider.updateSettings(s.copyWith(interviewReminders: v)),
            ),
            SwitchListTile(
              title: Text(context.tr('notif_setting_weekly_summary')),
              value: s.weeklySummary,
              onChanged: (v) => provider.updateSettings(s.copyWith(weeklySummary: v)),
            ),
            SwitchListTile(
              title: Text(context.tr('notif_setting_marketing')),
              value: s.marketingEmails,
              onChanged: (v) => provider.updateSettings(s.copyWith(marketingEmails: v)),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  IconData _iconFor(AppNotificationType type) => switch (type) {
    AppNotificationType.applicationUpdate => Icons.work_outline,
    AppNotificationType.interviewReminder => Icons.event_outlined,
    AppNotificationType.weeklySummary => Icons.bar_chart_outlined,
    AppNotificationType.marketing => Icons.campaign_outlined,
    AppNotificationType.system => Icons.info_outline,
  };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.notifications.isEmpty) {
      return Center(child: Text(context.tr('notifications_empty')));
    }

    return Center(
      child: ResponsiveContentWidth(
        maxWidth: 720,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: provider.unreadCount == 0 ? null : () => provider.markAllAsRead(),
                child: Text(context.tr('notifications_mark_all_read')),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                itemCount: provider.notifications.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final n = provider.notifications[i];
                  return Dismissible(
                    key: ValueKey(n.id),
                    onDismissed: (_) => provider.deleteNotification(n.id),
                    background: Container(color: AppColors.danger),
                    child: ListTile(
                      leading: Icon(_iconFor(n.type), color: AppColors.primary),
                      title: Text(
                        n.title,
                        style: n.isRead
                            ? AppTextStyles.bodyMedium(Theme.of(context).colorScheme.onSurface)
                            : AppTextStyles.bodyMedium(Theme.of(context).colorScheme.onSurface)
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: n.isRead ? null : const Icon(Icons.circle, size: 8, color: AppColors.primary),
                      onTap: () => provider.markAsRead(n.id),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}