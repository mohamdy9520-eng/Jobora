import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/models/application_model.dart';
import '../../core/models/cv_model.dart';
import '../../core/models/interview_model.dart';

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
class CvTipData {
  final IconData icon;
  final String title;
  final String message;

  const CvTipData({
    required this.icon,
    required this.title,
    required this.message,
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
  List<InsightData> buildInsights(List<ApplicationModel> apps) {
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
        message: 'قدّمت على $thisWeek وظايف الأسبوع ده',
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
        message: '$stale طلبات من أكتر من أسبوعين من غير رد',
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
        final better = remoteRate > onsiteRate ? 'الـRemote' : 'الـOnsite';
        insights.add(InsightData(
          icon: Icons.insights_outlined,
          message: 'نسبة ردك على وظايف $better أعلى',
        ));
      }
    }

    return insights.take(3).toList();
  }

  /// Pure logic — surfaces applications that need the user's attention:
  /// applications stuck without a status update for too long. Plug in
  /// the real list from ApplicationProvider.
  List<AttentionItemData> buildAttentionItems(List<ApplicationModel> apps) {
    final items = <AttentionItemData>[];

    final stale = apps
        .where((a) =>
    a.status == ApplicationStatus.applied && a.daysSinceApplied > 14)
        .toList();
    if (stale.isNotEmpty) {
      items.add(AttentionItemData(
        icon: Icons.hourglass_bottom_outlined,
        title: '${stale.length} طلبات محتاجة متابعة',
        subtitle: 'من غير رد من أكتر من أسبوعين — يمكن تبعت follow-up',
      ));
    }

    return items;
  }

  /// CV tips based on FILE PRESENCE ONLY. CvModel currently stores just
  /// file metadata (name, url, size, type) — no extracted text — so
  /// content checks (email present, skills section, quantified
  /// achievements, keyword match, etc.) can't run yet. Once a
  /// text-extraction step exists and CvModel exposes the parsed text,
  /// this can grow into real content analysis.
  List<CvTipData> buildCvTips(List<CvModel> cvs) {
    if (cvs.isEmpty) {
      return const [
        CvTipData(
          icon: Icons.upload_file_outlined,
          title: 'ارفع الـCV بتاعك',
          message:
          'أول ما ترفعه هنقدر نراجعه ونقترحلك تعديلات تزوّد فرصك في القبول.',
        ),
      ];
    }

    // watchAll() in CvRepository already orders by uploadedAt descending,
    // so cvs.first is the latest one.
    final latest = cvs.first;
    final tips = <CvTipData>[];

    // File freshness — a CV untouched for ~4 months is worth revisiting.
    final ageInDays = DateTime.now().difference(latest.uploadedAt).inDays;
    if (ageInDays > 120) {
      tips.add(const CvTipData(
        icon: Icons.update,
        title: 'حدّث الـCV بتاعك',
        message: 'آخر تحديث كان بقاله فترة — راجعه وضيف أي خبرة أو مشروع جديد.',
      ));
    }

    // Multiple uploads sitting around — nudge toward cleanup.
    if (cvs.length > 1) {
      tips.add(CvTipData(
        icon: Icons.delete_sweep_outlined,
        title: 'شيل النسخ القديمة',
        message:
        'عندك ${cvs.length} نسخ من الـCV — سيب أحدث نسخة بس عشان متتلخبطش.',
      ));
    }

    // Unusually small file — likely a scan/photo with little real content,
    // or a broken upload. Flag rather than silently trust it.
    if (latest.fileSizeBytes > 0 && latest.fileSizeBytes < 15 * 1024) {
      tips.add(const CvTipData(
        icon: Icons.warning_amber_outlined,
        title: 'تأكد إن الملف سليم',
        message:
        'حجم الملف صغير بشكل غير متوقع — افتحه وتأكد إن المحتوى ظاهر كامل.',
      ));
    }

    if (tips.isEmpty) {
      return const [
        CvTipData(
          icon: Icons.check_circle_outline,
          title: 'الـCV بتاعك مرفوع وحديث',
          message: 'لسه مفيش تحليل تفصيلي للمحتوى — قريبًا هنضيفه.',
        ),
      ];
    }

    return tips.take(4).toList();
  }

  /// Pure logic — the next few interviews that haven't happened yet,
  /// soonest first. Plug in the live list from InterviewProvider.
  /// `now` is injectable so this stays easy to unit-test.
  List<UpcomingInterviewData> buildUpcomingInterviews(
      List<InterviewModel> interviews, {
        DateTime? now,
        int limit = 3,
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
      timeLabel: _formatTimeLabel(i.dateTime, current),
    ))
        .toList();
  }

  /// "النهارده 3:00 م" / "بكرة 10:30 ص" / "الخميس 1:00 م" / "12/10 4:00 م"
  String _formatTimeLabel(DateTime dt, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diffDays = day.difference(today).inDays;

    final String dayLabel;
    if (diffDays == 0) {
      dayLabel = 'النهارده';
    } else if (diffDays == 1) {
      dayLabel = 'بكرة';
    } else if (diffDays < 7) {
      dayLabel = _weekdayName(dt.weekday);
    } else {
      dayLabel = '${dt.day}/${dt.month}';
    }

    return '$dayLabel ${_formatClock(dt)}';
  }

  String _formatClock(DateTime dt) {
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour < 12 ? 'ص' : 'م';
    return '$hour12:$minute $suffix';
  }

  String _weekdayName(int weekday) {
    // DateTime.weekday: 1 = Monday ... 7 = Sunday
    const names = [
      'الاتنين',
      'التلات',
      'الأربع',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    return names[weekday - 1];
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}