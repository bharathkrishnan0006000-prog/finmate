import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/di/providers.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/utils/formatters.dart';
import 'presentation/lock/app_lock_gate.dart';
import 'data/services/background_tasks.dart';
import 'data/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final prefs = await SharedPreferences.getInstance();
  AppFormatters.currencySymbol =
      prefs.getString(AppConstants.prefsCurrency) == 'INR' || true ? '\u20B9' : '\$';

  // Sets up the notification channel only — does not run any analysis or
  // background work by itself.
  await NotificationService().init();
  // Schedules the twice-daily background check (budgets/subscriptions/
  // savings/future expenses). This is the only background work FinMate
  // ever performs, and it's independent of the optional AI toggle.
  await registerBackgroundTasks();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const FinMateApp(),
    ),
  );
}

class FinMateApp extends ConsumerWidget {
  const FinMateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(darkModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: appRouter,
      builder: (context, child) => AppLockGate(child: child ?? const SizedBox.shrink()),
    );
  }
}
