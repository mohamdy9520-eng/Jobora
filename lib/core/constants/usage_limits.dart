/// Single source of truth for plan limits, shared by the paywall (what we
/// promise) and the usage services (what we enforce).
///
/// Put this file at: lib/core/constants/usage_limits.dart
class UsageLimits {
  UsageLimits._();

  /// AI cover letters per day on the free plan.
  static const int freeCoverLettersPerDay = 3;

  /// AI cover letters per day with Jobora Pro.
  static const int proCoverLettersPerDay = 10;
}