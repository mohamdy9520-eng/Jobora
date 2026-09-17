import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'core/localization/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/services/app_settings_controller.dart';
import 'core/services/auth_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/applications/providers/application_provider.dart';
import 'features/home/home_controller.dart';
import 'features/interviews/providers/interview_provider.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'features/statistics/statistics_controller.dart';
import 'features/subscriptions/providers/subscription_provider.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // TODO: replace with your real RevenueCat public SDK keys (from the
  // RevenueCat dashboard → Project settings → API keys).
  if (!kIsWeb) {
    await Purchases.setLogLevel(LogLevel.warn);
    final configuration = Platform.isIOS
        ? PurchasesConfiguration('appl_XXXXXXXXXXXXXXXXXXXXXXXX')
        : PurchasesConfiguration('goog_XXXXXXXXXXXXXXXXXXXXXXXX');
    await Purchases.configure(configuration);
  }

  final settingsController = AppSettingsController();
  await settingsController.load();

  final authController = AuthController();
  FirebaseAuth.instance.authStateChanges().listen(authController.setUser);

  runApp(JobMateApp(
    settingsController: settingsController,
    authController: authController,
  ));
}

class JobMateApp extends StatefulWidget {
  const JobMateApp({
    super.key,
    required this.settingsController,
    required this.authController,
  });

  final AppSettingsController settingsController;
  final AuthController authController;

  @override
  State<JobMateApp> createState() => _JobMateAppState();
}

class _JobMateAppState extends State<JobMateApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = buildAppRouter(
      settings: widget.settingsController,
      auth: widget.authController,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.settingsController),
        ChangeNotifierProvider.value(value: widget.authController),
        ChangeNotifierProvider(create: (_) => HomeController()..load()),
        ChangeNotifierProxyProvider<AuthController, ApplicationProvider>(
          create: (_) => ApplicationProvider(),
          update: (_, auth, provider) => provider!..updateAuth(auth.uid),
        ),
        ChangeNotifierProxyProvider<AuthController, InterviewProvider>(
          create: (_) => InterviewProvider(),
          update: (_, auth, provider) => provider!..updateAuth(auth.uid),
        ),
        ChangeNotifierProxyProvider<AuthController, NotificationProvider>(
          create: (_) => NotificationProvider(),
          update: (_, auth, provider) => provider!..updateAuth(auth.uid),
        ),
        // RevenueCat's App User ID is kept in sync with the Firebase uid
        // via updateAuth — same proxy pattern as the providers above.
        ChangeNotifierProxyProvider<AuthController, SubscriptionProvider>(
          create: (_) => SubscriptionProvider(),
          update: (_, auth, provider) => provider!..updateAuth(auth.uid),
        ),
        ChangeNotifierProxyProvider<ApplicationProvider, StatisticsController>(
          create: (_) => StatisticsController(),
          update: (_, applicationProvider, stats) =>
          stats!..updateFromApplications(applicationProvider.applications),
        ),
      ],
      child: Consumer<AppSettingsController>(
        builder: (context, settings, _) {
          return ScreenUtilInit(
            designSize: const Size(390, 844),
            minTextAdapt: true,
            builder: (context, child) => MaterialApp.router(
              title: 'JobMate',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: settings.themeMode,
              locale: settings.locale,
              supportedLocales: kSupportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, child) => Directionality(
                textDirection: settings.locale.languageCode == 'ar'
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: child!,
              ),
              routerConfig: _router,
            ),
          );
        },
      ),
    );
  }
}