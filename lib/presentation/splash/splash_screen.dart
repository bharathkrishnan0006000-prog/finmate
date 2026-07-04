import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/route_names.dart';
import '../../core/di/providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Seed default categories on first-ever launch.
    await ref.read(categoryRepositoryProvider).seedDefaultsIfEmpty();

    final prefs = ref.read(sharedPreferencesProvider);
    final onboardingDone = prefs.getBool(AppConstants.prefsOnboardingDone) ?? false;

    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    context.go(onboardingDone ? RouteNames.dashboard : RouteNames.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.eco_rounded, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              AppConstants.appName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              AppConstants.appTagline,
              style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 1.2),
            ),
            const SizedBox(height: 56),
            const SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation(Colors.white),
                minHeight: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
