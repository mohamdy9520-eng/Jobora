import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/applications/add_application_screen.dart';
import '../../features/applications/edit/edit_application_screen.dart';
import '../../features/interviews/add_interview_screen.dart';
import '../../features/interviews/edit_interview_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/subscriptions/screens/subscriptions_screen.dart';
import '../../features/cv/screens/cv_upload_screen.dart';
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
import '../../features/legal/privacy/privacy_screen.dart';
import '../../features/legal/terms/terms_screen.dart';


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
  static const editApplication = '/application';
  static const interviews = '/interviews';
  static const editInterview = '/interview';
  static const statistics = '/statistics';
  static const profile = '/profile';
  static const currencySettings = '/settings/currency';
  static const addInterview = '/add-interview';
  static const cvUpload = '/cv-upload';


  // New settings screens — same pattern as currencySettings: top-level
  // routes pushed from Profile, deliberately outside isOnboardingFlow
  // so the redirect logic never bounces an authenticated user away.
  static const privacy = '/settings/privacy';
  static const notifications = '/settings/notifications';
  static const subscriptions = '/settings/subscriptions';
  static const terms = '/settings/terms';
}

GoRouter buildAppRouter({
  required AppSettingsController settings,
  required AuthController auth,
}) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: Listenable.merge([auth, settings]),
    redirect: (context, state) {
      final loc = state.matchedLocation;

      if (auth.isInitializing) return null;

      final isAuthRoute = loc == AppRoutes.login || loc == AppRoutes.signup;
      final isOnboardingFlow = loc == AppRoutes.language ||
          loc == AppRoutes.currency ||
          loc == AppRoutes.onboarding;

      if (loc == AppRoutes.splash) return null;

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
      GoRoute(path: AppRoutes.language, builder: (c, s) => const LanguageSelectionScreen()),
      GoRoute(path: AppRoutes.currency, builder: (c, s) => const CurrencySelectionScreen()),
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
      GoRoute(
        path: '${AppRoutes.editApplication}/:id/edit',
        builder: (c, s) =>
            EditApplicationScreen(applicationId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '${AppRoutes.editInterview}/:id/edit',
        builder: (c, s) =>
            EditInterviewScreen(interviewId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.currencySettings,
        builder: (c, s) => const CurrencySelectionScreen(fromSettings: true),
      ),
      GoRoute(
        path: AppRoutes.addInterview,
        builder: (c, s) => AddInterviewScreen(
          preselectedApplicationId: s.uri.queryParameters['applicationId'],
        ),
      ),
      GoRoute(
        path: AppRoutes.cvUpload,
        builder: (c, s) => const CvUploadScreen(),
      ),
      GoRoute(path: AppRoutes.privacy, builder: (c, s) => const PrivacyScreen()),
      GoRoute(path: AppRoutes.terms, builder: (c, s) => const TermsScreen()),
      GoRoute(path: AppRoutes.notifications, builder: (c, s) => const NotificationsScreen()),
      GoRoute(path: AppRoutes.subscriptions, builder: (c, s) => const SubscriptionsScreen()),
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
              builder: (c, s) => ApplicationsScreen(
                // TODO: ApplicationsScreen doesn't accept this parameter
                // yet — add an `initialFilter` (or similar) constructor
                // param there and apply it to the list query, e.g.
                // filtering by status in ('interview', 'offer', ...).
                // Values pushed from Home: active | interview | waiting | offer
                initialFilter: s.uri.queryParameters['filter'],
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.interviews, builder: (c, s) => const InterviewsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.statistics, builder: (c, s) => const StatisticsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.profile, builder: (c, s) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
  );
}