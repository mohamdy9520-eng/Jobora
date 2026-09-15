import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/applications/add_application_screen.dart';
import '../../features/applications/edit/edit_application_screen.dart';
import '../services/app_settings_controller.dart';
import '../services/auth_controller.dart';
import '../widgets/main_shell.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/language_selection_screen.dart';
import '../../features/onboarding/currency_selection_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/applications/applications_screen.dart';
import '../../features/applications/application_details_screen.dart';
import '../../features/interviews/interviews_screen.dart';
import '../../features/statistics/statistics_screen.dart';
import '../../features/profile/profile_screen.dart';

class AppRoutes {
  AppRoutes._();
  static const splash = '/splash';
  static const language = '/language';
  static const currency = '/currency';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';
  static const applications = '/applications';
  static const addApplication = '/add-application';
  static const applicationDetails = '/application';

  /// Edit screen for an existing application — deliberately a separate
  /// screen (not AddApplicationScreen reused in an edit mode), reached
  /// via '/application/:id/edit'.
  static const editApplication = '/application';
  static const interviews = '/interviews';
  static const statistics = '/statistics';
  static const profile = '/profile';

  /// Currency screen reused from Profile/Settings. Deliberately a
  /// different path from [currency] (the onboarding step) so the
  /// redirect logic below — which treats [currency] as part of
  /// onboarding and bounces authenticated users to /home — never
  /// touches this one.
  static const currencySettings = '/settings/currency';
}

/// Builds the app's GoRouter, redirecting based on onboarding + auth state.
/// Must be called exactly once (see main.dart) — never rebuild this object.
GoRouter buildAppRouter({
  required AppSettingsController settings,
  required AuthController auth,
}) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    // Listens to BOTH — auth changes (login/logout) and settings changes
    // (e.g. onboarding just got marked complete) each need to re-trigger
    // the redirect below, even with no explicit navigation call anywhere.
    refreshListenable: Listenable.merge([auth, settings]),
    redirect: (context, state) {
      final loc = state.matchedLocation;

      if (auth.isInitializing) return null; // stay on splash while checking

      final isAuthRoute = loc == AppRoutes.login || loc == AppRoutes.signup;
      final isOnboardingFlow = loc == AppRoutes.language ||
          loc == AppRoutes.currency ||
          loc == AppRoutes.onboarding;

      if (loc == AppRoutes.splash) return null; // splash decides its own next step

      if (!settings.onboardingCompleted && !isOnboardingFlow) {
        return AppRoutes.language;
      }

      if (settings.onboardingCompleted && !auth.isAuthenticated && !isAuthRoute) {
        return AppRoutes.login;
      }

      if (auth.isAuthenticated && (isAuthRoute || isOnboardingFlow)) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (c, s) => const SplashScreen()),
      GoRoute(
          path: AppRoutes.language, builder: (c, s) => const LanguageSelectionScreen()),
      GoRoute(
          path: AppRoutes.currency, builder: (c, s) => const CurrencySelectionScreen()),
      GoRoute(path: AppRoutes.onboarding, builder: (c, s) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.login, builder: (c, s) => const LoginScreen()),
      GoRoute(path: AppRoutes.signup, builder: (c, s) => const SignupScreen()),
      GoRoute(
        path: AppRoutes.addApplication,
        builder: (c, s) => const AddApplicationScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.applicationDetails}/:id',
        builder: (c, s) =>
            ApplicationDetailsScreen(applicationId: s.pathParameters['id']!),
      ),
      // Dedicated edit screen (not AddApplicationScreen reused) — see
      // AppRoutes.editApplication doc comment above.
      GoRoute(
        path: '${AppRoutes.editApplication}/:id/edit',
        builder: (c, s) =>
            EditApplicationScreen(applicationId: s.pathParameters['id']!),
      ),
      // Currency screen accessed from Profile/Settings (not onboarding).
      // Not part of isOnboardingFlow above, so authenticated users are
      // never redirected away from it.
      GoRoute(
        path: AppRoutes.currencySettings,
        builder: (c, s) => const CurrencySelectionScreen(fromSettings: true),
      ),
      // Shell route: bottom navigation tabs share persistent chrome.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.home, builder: (c, s) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: AppRoutes.applications,
                builder: (c, s) => const ApplicationsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: AppRoutes.interviews, builder: (c, s) => const InterviewsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: AppRoutes.statistics,
                builder: (c, s) => const StatisticsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.profile, builder: (c, s) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
  );
}