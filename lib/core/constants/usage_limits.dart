/// Single source of truth for plan limits, shared by the paywall (what we
/// promise) and the usage services (what we enforce).
class UsageLimits {
  UsageLimits._();

  /// AI cover letters per day on the free plan.
  static const int freeCoverLettersPerDay = 3;

  /// AI cover letters per day with Jobora Pro.
  static const int proCoverLettersPerDay = 10;

  /// Practice interview sessions on the free plan.
  /// LIFETIME limit (trial), NOT per day.
  /// If you change this, also change the `freeUsed <= 2` ceiling in
  /// firestore.rules (usage/practiceSessions).
  static const int freePracticeSessionsLifetime = 2;

// Pro users have UNLIMITED practice sessions: there is deliberately no
// constant for it, and nothing is ever counted or written for them.
}