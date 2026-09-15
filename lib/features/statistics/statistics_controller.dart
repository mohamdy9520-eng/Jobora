import 'package:flutter/material.dart';
import '../../core/models/application_model.dart';

/// Derives all statistics directly from ApplicationProvider's live list.
/// No separate repository is needed for these numbers — every value here
/// is a pure computation over ApplicationModel.status, which already
/// comes from real data (see updateFromApplications, wired via a
/// ChangeNotifierProxyProvider<ApplicationProvider, StatisticsController>
/// in main.dart).
class StatisticsController extends ChangeNotifier {
  List<ApplicationModel> _applications = [];

  int get totalApplications => _applications.length;

  int get interviews =>
      _applications.where((a) => a.status == ApplicationStatus.interview).length;

  int get offers =>
      _applications.where((a) => a.status == ApplicationStatus.offer).length;

  int get rejected =>
      _applications.where((a) => a.status == ApplicationStatus.rejected).length;

  /// Share of applications that moved past the initial "applied" state
  /// (screening, interview, offer, or rejected all count as "a response").
  double get responseRate {
    if (_applications.isEmpty) return 0;
    final responded = _applications
        .where((a) =>
    a.status != ApplicationStatus.saved &&
        a.status != ApplicationStatus.applied)
        .length;
    return responded / _applications.length;
  }

  double get interviewRate =>
      totalApplications == 0 ? 0 : interviews / totalApplications;

  double get offerRate =>
      totalApplications == 0 ? 0 : offers / totalApplications;

  /// Kept for statistics_screen.dart compatibility — there is no separate
  /// loading state anymore since this reads synchronously from the
  /// already-loaded ApplicationProvider list.
  bool get isLoading => false;

  void updateFromApplications(List<ApplicationModel> applications) {
    _applications = applications;
    notifyListeners();
  }
}