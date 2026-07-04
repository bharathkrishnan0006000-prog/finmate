import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import 'lock_screen.dart';

/// Wraps the whole app. On resume, if PIN or biometric lock is enabled and
/// the configured timeout has elapsed since the app was backgrounded, it
/// overlays the LockScreen until the user authenticates. With no PIN set
/// (fresh install / lock disabled), this is a no-op passthrough.
class AppLockGate extends ConsumerStatefulWidget {
  final Widget child;
  const AppLockGate({super.key, required this.child});

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> with WidgetsBindingObserver {
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Lock immediately on cold start if a PIN has been set.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final pinEnabled = ref.read(pinEnabledProvider);
      final biometricEnabled = ref.read(biometricEnabledProvider);
      final hasPin = await ref.read(authServiceProvider).hasPin();
      if ((pinEnabled || biometricEnabled) && hasPin) {
        ref.read(isLockedProvider.notifier).state = true;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final pinEnabled = ref.read(pinEnabledProvider);
    final biometricEnabled = ref.read(biometricEnabledProvider);
    if (!pinEnabled && !biometricEnabled) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _backgroundedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final bgAt = _backgroundedAt;
      _backgroundedAt = null;
      if (bgAt == null) return;

      final timeoutMinutes = ref.read(lockTimeoutMinutesProvider);
      if (timeoutMinutes < 0) return; // "Never" — don't re-lock on resume.

      final elapsed = DateTime.now().difference(bgAt);
      if (elapsed.inMinutes >= timeoutMinutes) {
        ref.read(isLockedProvider.notifier).state = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = ref.watch(isLockedProvider);
    return Stack(
      children: [
        widget.child,
        if (locked) const LockScreen(),
      ],
    );
  }
}
