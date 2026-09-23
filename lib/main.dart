import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/localization/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/services/app_settings_controller.dart';
import 'core/services/auth_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/applications/providers/application_provider.dart';
import 'features/cv/providers/cv_provider.dart';
import 'features/home/home_controller.dart';
import 'features/interviews/providers/interview_provider.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'features/statistics/statistics_controller.dart';
import 'features/subscriptions/providers/subscription_provider.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تحميل ملف البيئة env (بدون امتداد، اسمه الفعلي "env" على القرص)
  await dotenv.load(fileName: "env");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // إعداد RevenueCat لتطبيق Jobora باستخدام مفتاح الـ Test
  if (!kIsWeb) {
    await _configureRevenueCat();
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

Future<void> _configureRevenueCat() async {
  final apiKey = dotenv.env['REVENUECAT_API_KEY'];

  if (apiKey == null || apiKey.isEmpty) {
    throw StateError('REVENUECAT_API_KEY missing');
  }

  // 🔍 مؤقت للتشخيص فقط - امسحه بعد ما تتأكد
  debugPrint('RC Key length: ${apiKey.length}');
  debugPrint('RC Key prefix: ${apiKey.substring(0, apiKey.length > 6 ? 6 : apiKey.length)}');
  debugPrint('RC Key suffix: ${apiKey.substring(apiKey.length > 6 ? apiKey.length - 6 : 0)}');

  if (kDebugMode) {
    await Purchases.setLogLevel(LogLevel.debug);
  } else {
    await Purchases.setLogLevel(LogLevel.error);
  }

  final configuration = PurchasesConfiguration(apiKey);
  await Purchases.configure(configuration);
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
        ChangeNotifierProxyProvider<AuthController, CvProvider>(
          create: (_) => CvProvider(),
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