import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/applications/add_application_screen.dart';
import '../../features/applications/edit/edit_application_screen.dart';
import '../../features/cover_letter/screen/cover_letter_screen.dart';
import '../../features/interviews/add_interview_screen.dart';
import '../../features/interviews/edit_interview_screen.dart';
import '../../features/legal/legal_webview_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/practice_interview/models/practice_models.dart';
import '../../features/practice_interview/screens/practice_chat_screen.dart';
import '../../features/practice_interview/screens/practice_result_screen.dart';
import '../../features/practice_interview/screens/practice_setup_screen.dart';
import '../../features/subscriptions/screens/paywall_screen.dart';
import '../../features/cv/screens/cv_upload_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
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
  static const coverLetter = '/cover-letter';
  static const editProfile = '/settings/edit-profile';

  // Practice interview (Premium). Chat and result receive their data
  // through `extra` (PracticeSetup / PracticeSession), so they redirect
  // back to the setup screen when opened without it.
  static const practiceInterview = '/practice-interview';
  static const practiceChat = '/practice-interview/chat';
  static const practiceResult = '/practice-interview/result';

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
      // Terms/Privacy must be readable from the Signup screen before the
      // user is authenticated (e.g. tapping "Terms & Conditions" while
      // filling the signup form). Without this, the !isAuthenticated
      // check below bounces straight back to /login mid-signup.
      final isPubliclyAccessible = loc == AppRoutes.terms || loc == AppRoutes.privacy;

      if (loc == AppRoutes.splash) return null;

      if (!settings.onboardingCompleted && !isOnboardingFlow) {
        return AppRoutes.language;
      }

      if (settings.onboardingCompleted &&
          !auth.isAuthenticated &&
          !isAuthRoute &&
          !isPubliclyAccessible) {
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
      GoRoute(
        path: AppRoutes.coverLetter,
        builder: (context, state) => const CoverLetterScreen(),
      ),
      GoRoute(
        path: AppRoutes.practiceInterview,
        builder: (c, s) => const PracticeSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.practiceChat,
        redirect: (c, s) =>
        s.extra is PracticeSetup ? null : AppRoutes.practiceInterview,
        builder: (c, s) => PracticeChatScreen(setup: s.extra! as PracticeSetup),
      ),
      GoRoute(
        path: AppRoutes.practiceResult,
        redirect: (c, s) =>
        s.extra is PracticeSession ? null : AppRoutes.practiceInterview,
        builder: (c, s) =>
            PracticeResultScreen(session: s.extra! as PracticeSession),
      ),
      GoRoute(path: AppRoutes.privacy, builder: (c, s) => const PrivacyScreen()),
      GoRoute(path: AppRoutes.notifications, builder: (c, s) => const NotificationsScreen()),
      GoRoute(path: AppRoutes.subscriptions, builder: (c, s) => const PaywallScreen()),
      GoRoute(
        path: AppRoutes.terms,
        builder: (c, s) => const LegalWebViewScreen(
          baseUrl: 'https://mohamdy9520-eng.github.io/jobora-legal/terms.html',
          titleKey: 'terms_title',
        ),
      ),
      GoRoute(path: AppRoutes.editProfile, builder: (c, s) => const EditProfileScreen()),
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