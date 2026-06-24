import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/auth/auth_provider.dart';
import 'core/config/app_config.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/splash/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR');
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  if (AppConfig.sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = AppConfig.sentryDsn;
        options.environment = AppConfig.env;
        options.tracesSampleRate = AppConfig.isProd ? 0.2 : 1.0;
        options.debug = AppConfig.isDev;
      },
      appRunner: () => runApp(const ProviderScope(child: DolunchApp())),
    );
  } else {
    runApp(const ProviderScope(child: DolunchApp()));
  }
}

class DolunchApp extends ConsumerWidget {
  const DolunchApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: Future.wait([
        ref.read(authNotifierProvider).init(),
      ]),
      builder: (_, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            home: SplashScreen(),
            debugShowCheckedModeBanner: false,
          );
        }
        return _AppWithOnboarding();
      },
    );
  }
}

class _AppWithOnboarding extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingAsync = ref.watch(onboardingDoneProvider);

    return onboardingAsync.when(
      loading: () => const MaterialApp(
        home: SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
      error: (_, __) => _RouterApp(),
      data: (done) {
        if (!done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: OnboardingScreen(
              onDone: () => ref.invalidate(onboardingDoneProvider),
            ),
          );
        }
        return _RouterApp();
      },
    );
  }
}

class _RouterApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: '점심어때',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
