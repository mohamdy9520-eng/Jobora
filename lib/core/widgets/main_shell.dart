import 'dart:io' show Platform, exit;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/applications/providers/application_provider.dart';
import '../../features/cv/providers/cv_provider.dart';
import '../../features/cv_builder/providers/cv_builder_provider.dart';
import '../../features/interviews/providers/interview_provider.dart';
import '../ads/ads_controller.dart';
import '../ads/app_banner_ad.dart';
import '../localization/app_localizations.dart';
import '../router/app_router.dart';
import '../services/tab_refresh_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  StatefulNavigationShell get _shell => widget.navigationShell;

  /// The tab that was visible the last time we looked. Tracked here (instead
  /// of relying on oldWidget in didUpdateWidget) so we always know which tab
  /// was just left, whatever caused the switch (nav bar tap, back button,
  /// goBranch from anywhere else).
  late int _lastIndex;

  @override
  void initState() {
    super.initState();
    _lastIndex = widget.navigationShell.currentIndex;
    WidgetsBinding.instance.addObserver(this);
    // Consent form + Mobile Ads init need a running UI, so wait for frame 1.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdsController>().initialize();
    });
  }

  @override
  void didUpdateWidget(covariant MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newIndex = widget.navigationShell.currentIndex;
    if (newIndex != _lastIndex) {
      final leftIndex = _lastIndex;
      _lastIndex = newIndex;
      // Post-frame: notifying providers during build is not allowed.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // The tab we just left is off-screen now: send it back to the top
        // so it is already at its initial state when the user returns.
        context.read<TabRefreshController>().resetScroll(leftIndex);
        _refreshTab(newIndex);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Data refresh only — scroll position is intentionally not reset when
    // the app comes back from the background.
    if (state == AppLifecycleState.resumed) {
      _refreshTab(_shell.currentIndex);
    }
  }

  /// Refreshes a tab: first makes sure every live Firestore provider is
  /// still subscribed (a stream that hit an error never restarts by
  /// itself), then bumps the tab's revision so its page rebuilds.
  void _refreshTab(int index) {
    context.read<ApplicationProvider>().ensureSubscribed();
    context.read<InterviewProvider>().ensureSubscribed();
    context.read<CvProvider>().ensureSubscribed();
    context.read<CvBuilderProvider>().ensureSubscribed();
    context.read<TabRefreshController>().refresh(index);
  }

  List<_NavItem> _items(BuildContext context) => [
    _NavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: context.tr('nav_home'),
    ),
    _NavItem(
      icon: Icons.description_outlined,
      selectedIcon: Icons.description,
      label: context.tr('nav_applications'),
    ),
    _NavItem(
      icon: Icons.event_outlined,
      selectedIcon: Icons.event,
      label: context.tr('nav_interviews'),
    ),
    _NavItem(
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
      label: context.tr('nav_statistics'),
    ),
    _NavItem(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: context.tr('nav_profile'),
    ),
  ];

  void _onDestinationSelected(int index) {
    final isSame = index == _shell.currentIndex;
    _shell.goBranch(index, initialLocation: isSame);
    // Tapping the current tab again also refreshes it and sends it back
    // to the top.
    if (isSame) {
      context.read<TabRefreshController>().resetScroll(index);
      _refreshTab(index);
    }
  }

  /// FAB is shown on Applications (1) and Interviews (2) only.
  /// Home (0) has its own "Add Application"/"Add Interview" quick actions,
  /// so no FAB there. Statistics (3) and Profile (4) have no FAB either.
  bool _showFab(int index) => index == 1 || index == 2;

  Widget? _buildFab(BuildContext context, {bool extended = false}) {
    final index = _shell.currentIndex;
    if (!_showFab(index)) return null;

    final isInterviews = index == 2;
    final route =
    isInterviews ? AppRoutes.addInterview : AppRoutes.addApplication;
    final labelKey =
    isInterviews ? 'interviews_add_title' : 'home_add_application';

    if (extended) {
      return SizedBox(
        width: double.infinity,
        child: FloatingActionButton.extended(
          heroTag: 'main_shell_fab',
          onPressed: () => context.push(route),
          icon: const Icon(Icons.add),
          label: Text(context.tr(labelKey)),
        ),
      );
    }

    return FloatingActionButton(
      heroTag: 'main_shell_fab',
      onPressed: () => context.push(route),
      tooltip: context.tr(labelKey),
      child: const Icon(Icons.add),
    );
  }

  /// The default Material 3 label size (12sp) doesn't fit "Applications"
  /// in the space each of the 5 equally-sized destinations gets on a
  /// phone-width screen, so it wraps to a second line and leaves a
  /// stray "s". Shrinking just the label style (locally, via a Theme
  /// override) fixes that without touching the rest of the app's
  /// typography.
  Widget _buildNavigationBar(BuildContext context, List<_NavItem> items) {
    final baseTheme = Theme.of(context);
    return Theme(
      data: baseTheme.copyWith(
        navigationBarTheme: baseTheme.navigationBarTheme.copyWith(
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 10.5,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected
                  ? baseTheme.colorScheme.onSurface
                  : baseTheme.colorScheme.onSurfaceVariant,
            );
          }),
        ),
      ),
      child: NavigationBar(
        selectedIndex: _shell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: [
          for (final item in items)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label,
            ),
        ],
      ),
    );
  }

  /// Banner sits right above the NavigationBar, shared by all 5 tabs
  /// (one ad instance for the whole shell — no reload on tab switch).
  Widget _buildBottomBar(BuildContext context, List<_NavItem> items) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppBannerAd(),
        _buildNavigationBar(context, items),
      ],
    );
  }

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('home_exit_title')),
        content: Text(context.tr('home_exit_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.tr('home_exit_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              context.tr('home_exit_confirm'),
              style: const TextStyle(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _handlePopInvoked(BuildContext context, bool didPop) async {
    if (didPop) return;

    if (_shell.currentIndex != 0) {
      _shell.goBranch(0);
      return;
    }

    final shouldExit = await _showExitConfirmationDialog(context);
    if (shouldExit) {
      debugPrint('🚪 Exit confirmed — closing app now');
      if (Platform.isAndroid) {
        SystemNavigator.pop();
      } else {
        exit(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final useRail = context.isTablet || context.isDesktop;
    final items = _items(context);

    if (!useRail) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) =>
            _handlePopInvoked(context, didPop),
        child: Scaffold(
          body: _shell,
          floatingActionButton: _buildFab(context),
          bottomNavigationBar: _buildBottomBar(context, items),
        ),
      );
    }

    final extended = context.isDesktop;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) =>
          _handlePopInvoked(context, didPop),
      child: Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _shell.currentIndex,
              onDestinationSelected: _onDestinationSelected,
              extended: extended,
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              leading: _showFab(_shell.currentIndex)
                  ? Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _buildFab(context, extended: extended),
              )
                  : null,
              destinations: [
                for (final item in items)
                  NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: Text(item.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: _shell),
                  const AppBannerAd(handleBottomSafeArea: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}