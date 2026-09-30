import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// Keeps two counters per bottom-nav branch:
///
/// * a "revision" — bumping it rebuilds only the page that watches it
///   (see [watchTabRefresh]). Used to refresh data / time-based values.
/// * a "scroll reset" — bumping it makes the page recreate its scroll
///   view so it starts again from the top (see [watchTabScrollReset]).
///
/// They are separate on purpose: a data refresh (e.g. app resumed) must
/// not throw the user back to the top of the page, while leaving a tab
/// should.
class TabRefreshController extends ChangeNotifier {
  final Map<int, int> _revisions = {};
  final Map<int, int> _scrollResets = {};

  int revisionOf(int branch) => _revisions[branch] ?? 0;

  int scrollResetOf(int branch) => _scrollResets[branch] ?? 0;

  void refresh(int branch) {
    _revisions[branch] = revisionOf(branch) + 1;
    notifyListeners();
  }

  /// Sends the page of [branch] back to its initial scroll position
  /// (top). Called by MainShell for the tab the user just left.
  void resetScroll(int branch) {
    _scrollResets[branch] = scrollResetOf(branch) + 1;
    notifyListeners();
  }
}

/// Call at the top of a tab page's build(). The page rebuilds every time
/// its tab is re-entered (or the app returns to the foreground on it).
/// This alone does NOT touch the scroll position — see
/// [watchTabScrollReset] for that.
int watchTabRefresh(BuildContext context, int branch) =>
    context.select<TabRefreshController, int>((c) => c.revisionOf(branch));

/// Call at the top of a tab page's build() and use the returned value in
/// a `ValueKey` on the page's main scroll view, e.g.
/// `ListView(key: ValueKey('home-scroll-$epoch'), ...)`.
/// Whenever the value changes, the scroll view is recreated and starts
/// from the top.
int watchTabScrollReset(BuildContext context, int branch) =>
    context.select<TabRefreshController, int>((c) => c.scrollResetOf(branch));