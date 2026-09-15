import 'package:flutter/material.dart';

/// Real home-dashboard data — starts empty (not mock), so the screen
/// correctly falls back to its own EmptyState until real data exists.
class HomeSummary {
  final int activeApplications;
  final int interviews;
  final int waitingResponse;
  final int offers;

  const HomeSummary({
    this.activeApplications = 0,
    this.interviews = 0,
    this.waitingResponse = 0,
    this.offers = 0,
  });
}

class AttentionItemData {
  final IconData icon;
  final String title;
  final String subtitle;

  const AttentionItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class UpcomingInterviewData {
  final String applicationId;
  final String jobTitle;
  final String company;
  final String timeLabel;

  const UpcomingInterviewData({
    required this.applicationId,
    required this.jobTitle,
    required this.company,
    required this.timeLabel,
  });
}

/// Feeds HomeScreen with real data. Empty for now because
/// ApplicationRepository / InterviewRepository don't exist yet (Core
/// Data — step 2). Once they do, replace the body of `load()` with real
/// reads — HomeScreen itself won't need any further changes, since it
/// only ever reads from this controller, never hardcodes anything.
class HomeController extends ChangeNotifier {
  HomeSummary _summary = const HomeSummary();
  List<AttentionItemData> _attentionItems = const [];
  List<UpcomingInterviewData> _upcomingInterviews = const [];
  bool _isLoading = false;

  HomeSummary get summary => _summary;
  List<AttentionItemData> get attentionItems => _attentionItems;
  List<UpcomingInterviewData> get upcomingInterviews => _upcomingInterviews;
  bool get isLoading => _isLoading;
  bool get hasApplications => _summary.activeApplications > 0;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    // TODO(step-2 Core Data): replace with real reads once
    // ApplicationRepository / InterviewRepository exist, e.g.:
    //   final apps = await applicationRepository.watchAll(uid);
    //   _summary = HomeSummary(activeApplications: apps.length, ...);
    //   _attentionItems = buildAttentionItems(apps);
    //   _upcomingInterviews = interviewRepository.upcoming(uid);

    _isLoading = false;
    notifyListeners();
  }
}