import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/models/application_model.dart';
import '../../core/models/cv_model.dart';
import '../../core/models/interview_model.dart';
import '../cv_builder/services/cv_text_extractor.dart';
import 'cv_completeness_analyzer.dart';
import 'cv_tips_repository.dart';

/// Signature matching `AppLocalizationsX.tr` — passed in from the screen
/// so this controller stays free of BuildContext, while still producing
/// localized strings instead of hardcoded Arabic.
typedef Translator = String Function(String key, [Map<String, String>? args]);

/// Plain counters shown on Home. Display-only — the cards aren't tappable.
/// Starts at zero (not mock) until the real repositories exist.
class HomeSummary {
  final int applications;
  final int interviews;
  final int cvs;

  const HomeSummary({
    this.applications = 0,
    this.interviews = 0,
    this.cvs = 0,
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

/// A single home-screen insight card — a short, human-readable
/// observation derived from the user's own application data
/// (momentum, stale applications, response-rate comparisons, etc.).
class InsightData {
  final IconData icon;
  final String message;

  const InsightData({required this.icon, required this.message});
}

/// One actionable suggestion related to the user's CV.
/// [opensBuilder] = true means the card is tappable and should open the
/// CV Builder (used for "you're missing X" tips).
class CvTipData {
  final IconData icon;
  final String title;
  final String message;
  final bool opensBuilder;

  const CvTipData({
    required this.icon,
    required this.title,
    required this.message,
    this.opensBuilder = false,
  });
}

/// Feeds HomeScreen with whatever it doesn't get from its own live
/// providers. Applications/Interviews/CVs are read directly from
/// ApplicationProvider / InterviewProvider / CvProvider in HomeScreen —
/// HomeController.load() is only for things that still need their own
/// fetch (e.g. anything not yet backed by a repository/provider).
class HomeController extends ChangeNotifier {
  bool _isLoading = false;
  Object? _error;

  // Reserved for whatever HomeController itself ends up owning a Stream
  // for later. Not used by applications/interviews/cv — those are
  // independent providers watched directly by HomeScreen.
  StreamSubscription? _subscription;

  bool get isLoading => _isLoading;
  bool get hasError => _error != null;
  Object? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: fill in once HomeController owns something of its own to
      // fetch. Nothing to do here right now — applications, interviews
      // and CVs are all read live from their own providers in HomeScreen.
    } catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Pure logic — plug in the real ApplicationModel list from
  /// ApplicationProvider.
  ///
  /// NOTE: these are template-based observations, not real NLP/AI
  /// analysis — [tr] just localizes the current templates.
  List<InsightData> buildInsights(
      List<ApplicationModel> apps, {
        required Translator tr,
      }) {
    final insights = <InsightData>[];
    final now = DateTime.now();

    // 1) Momentum: how many applications went out this week.
    final thisWeek = apps
        .where((a) =>
        a.applicationDate.isAfter(now.subtract(const Duration(days: 7))))
        .length;
    if (thisWeek > 0) {
      insights.add(InsightData(
        icon: Icons.trending_up,
        message: tr('home_insight_applications_this_week',
            {'count': thisWeek.toString()}),
      ));
    }

    // 2) Stale applications: still "applied", no movement in 14+ days.
    final stale = apps
        .where((a) =>
    a.status == ApplicationStatus.applied && a.daysSinceApplied > 14)
        .length;
    if (stale > 0) {
      insights.add(InsightData(
        icon: Icons.schedule_outlined,
        message: tr('home_insight_stale_applications',
            {'count': stale.toString()}),
      ));
    }

    // 3) Response-rate comparison: remote vs onsite (needs a minimum
    // sample size on both sides before drawing a conclusion).
    final remote = apps.where((a) => a.workType == WorkType.remote).toList();
    final onsite = apps.where((a) => a.workType == WorkType.onsite).toList();
    if (remote.length >= 3 && onsite.length >= 3) {
      double rate(List<ApplicationModel> l) =>
          l.where((a) => a.status != ApplicationStatus.applied).length /
              l.length;
      final remoteRate = rate(remote);
      final onsiteRate = rate(onsite);
      if ((remoteRate - onsiteRate).abs() > 0.15) {
        final betterType = remoteRate > onsiteRate
            ? tr('work_type_remote')
            : tr('work_type_onsite');
        insights.add(InsightData(
          icon: Icons.insights_outlined,
          message:
          tr('home_insight_better_response_rate', {'type': betterType}),
        ));
      }
    }

    return insights.take(3).toList();
  }

  /// Pure logic — surfaces applications that need the user's attention:
  /// applications stuck without a status update for too long. Plug in
  /// the real list from ApplicationProvider.
  List<AttentionItemData> buildAttentionItems(
      List<ApplicationModel> apps, {
        required Translator tr,
      }) {
    final items = <AttentionItemData>[];

    final stale = apps
        .where((a) =>
    a.status == ApplicationStatus.applied && a.daysSinceApplied > 14)
        .toList();
    if (stale.isNotEmpty) {
      items.add(AttentionItemData(
        icon: Icons.hourglass_bottom_outlined,
        title: tr('home_attention_stale_title',
            {'count': stale.length.toString()}),
        subtitle: tr('home_attention_stale_subtitle'),
      ));
    }

    return items;
  }

  /// CV tips, all local (no AI, no network). Card order:
  ///   1) file-based tips about the uploaded CVs (presence/age/size),
  ///   2) "you're missing X" tips from [builderCv] via CvCompletenessAnalyzer
  ///      (tappable, they open the CV Builder),
  ///   3) general tips from CvTipsRepository, rotating daily.
  /// At most [maxCards] cards, and at least one general tip always shows.
  List<CvTipData> buildCvTips(
      List<CvModel> cvs, {
        CvCompletenessInput? builderCv,
        CvFileAnalysis? fileAnalysis,
        required Translator tr,
      }) {
    const maxCards = 4;
    const maxPriorityCards = 3;

    final priority = <CvTipData>[];

    // ── 1) File-based tips ──
    if (cvs.isEmpty) {
      priority.add(CvTipData(
        icon: Icons.upload_file_outlined,
        title: tr('home_cv_tip_upload_title'),
        message: tr('home_cv_tip_upload_message'),
      ));
    } else {
      final latest = cvs.first;

      final ageInDays = DateTime.now().difference(latest.uploadedAt).inDays;
      if (ageInDays > 120) {
        priority.add(CvTipData(
          icon: Icons.update,
          title: tr('home_cv_tip_update_title'),
          message: tr('home_cv_tip_update_message'),
        ));
      }

      if (cvs.length > 1) {
        priority.add(CvTipData(
          icon: Icons.delete_sweep_outlined,
          title: tr('home_cv_tip_cleanup_title'),
          message: tr('home_cv_tip_cleanup_message',
              {'count': cvs.length.toString()}),
        ));
      }

      if (fileAnalysis?.status == CvFileAnalysisStatus.unreadable) {
        // النص الفعلي فاضي: سكان/صورة. بنقترح الـ Builder.
        priority.add(CvTipData(
          icon: Icons.image_not_supported_outlined,
          title: tr('home_cv_tip_unreadable_title'),
          message: tr('home_cv_tip_unreadable_message'),
          opensBuilder: true,
        ));
      } else if (fileAnalysis == null &&
          latest.fileSizeBytes > 0 &&
          latest.fileSizeBytes < 15 * 1024) {
        // لسه مفحوصش، فنستخدم تقدير الحجم الصغير مؤقتًا.
        priority.add(CvTipData(
          icon: Icons.warning_amber_outlined,
          title: tr('home_cv_tip_check_file_title'),
          message: tr('home_cv_tip_check_file_message'),
        ));
      }
    }

    // ── 2) Missing-content tips ──
    // الـ Builder أدق فبياخد الأولوية. لو مفيش، نستخدم نتيجة فحص الـ PDF.
    final gapSource = builderCv ??
        (fileAnalysis?.status == CvFileAnalysisStatus.ready
            ? fileAnalysis!.input
            : null);
    if (gapSource != null) {
      final gaps = CvCompletenessAnalyzer.analyze(gapSource);
      for (final gap in gaps.take(2)) {
        priority.add(CvTipData(
          icon: gap.icon,
          title: tr('cv_gap_${gap.key}_title'),
          message: tr('cv_gap_${gap.key}_message'),
          opensBuilder: builderCv != null,
        ));
      }
    }

    final top = priority.take(maxPriorityCards).toList();

    // ── 3) General tips, rotating daily ──
    final generalCount = maxCards - top.length; // always >= 1
    final general = CvTipsRepository.tipsOfTheDay(count: generalCount).map(
          (t) => CvTipData(
        icon: t.icon,
        title: tr('cv_tip_${t.id}_title'),
        message: tr('cv_tip_${t.id}_message'),
      ),
    );

    return [...top, ...general];
  }

  /// Pure logic — the next few interviews that haven't happened yet,
  /// soonest first. Plug in the live list from InterviewProvider.
  /// `now` is injectable so this stays easy to unit-test.
  List<UpcomingInterviewData> buildUpcomingInterviews(
      List<InterviewModel> interviews, {
        DateTime? now,
        int limit = 3,
        required Translator tr,
      }) {
    final current = now ?? DateTime.now();

    final upcoming = interviews
        .where((i) => i.dateTime.isAfter(current))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return upcoming
        .take(limit)
        .map((i) => UpcomingInterviewData(
      applicationId: i.applicationId,
      jobTitle: i.position,
      company: i.companyName,
      timeLabel: _formatTimeLabel(i.dateTime, current, tr),
    ))
        .toList();
  }

  /// "اليوم 3:00 م" / "غدًا 10:30 ص" / "الخميس 1:00 م" / "12/10 4:00 م"
  /// (or the English equivalent, per [tr]).
  String _formatTimeLabel(DateTime dt, DateTime now, Translator tr) {
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diffDays = day.difference(today).inDays;

    final String dayLabel;
    if (diffDays == 0) {
      dayLabel = tr('date_today');
    } else if (diffDays == 1) {
      dayLabel = tr('date_tomorrow');
    } else if (diffDays < 7) {
      dayLabel = _weekdayName(dt.weekday, tr);
    } else {
      dayLabel = '${dt.day}/${dt.month}';
    }

    return '$dayLabel ${_formatClock(dt, tr)}';
  }

  String _formatClock(DateTime dt, Translator tr) {
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour < 12 ? tr('time_am') : tr('time_pm');
    return '$hour12:$minute $suffix';
  }

  String _weekdayName(int weekday, Translator tr) {
    // DateTime.weekday: 1 = Monday ... 7 = Sunday
    const keys = [
      'weekday_monday',
      'weekday_tuesday',
      'weekday_wednesday',
      'weekday_thursday',
      'weekday_friday',
      'weekday_saturday',
      'weekday_sunday',
    ];
    return tr(keys[weekday - 1]);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}