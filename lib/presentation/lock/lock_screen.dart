import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/di/providers.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _entered = '';
  String? _error;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometricFirst());
  }

  Future<void> _tryBiometricFirst() async {
    final biometricEnabled = ref.read(biometricEnabledProvider);
    if (!biometricEnabled) return;
    final auth = ref.read(authServiceProvider);
    if (!await auth.isBiometricAvailable()) return;
    final success = await auth.authenticateWithBiometrics();
    if (success) _unlock();
  }

  void _unlock() {
    ref.read(isLockedProvider.notifier).state = false;
  }

  Future<void> _onDigit(String digit) async {
    if (_entered.length >= 6 || _checking) return;
    setState(() {
      _entered += digit;
      _error = null;
    });
    if (_entered.length >= 4) {
      // Auto-submit once a plausible PIN length is reached.
      await _submit();
    }
  }

  Future<void> _submit() async {
    setState(() => _checking = true);
    final auth = ref.read(authServiceProvider);
    final valid = await auth.verifyPin(_entered);
    if (!mounted) return;
    if (valid) {
      _unlock();
    } else {
      setState(() {
        _error = 'Incorrect PIN';
        _entered = '';
        _checking = false;
      });
    }
  }

  void _backspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final biometricEnabled = ref.watch(biometricEnabledProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSizes.huge),
            const Icon(Icons.lock_rounded, color: Colors.white, size: 40),
            const SizedBox(height: AppSizes.lg),
            const Text('Enter PIN',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSizes.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                final filled = i < _entered.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? Colors.white : Colors.white24,
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSizes.md),
            SizedBox(
              height: 20,
              child: _error != null
                  ? Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13))
                  : null,
            ),
            const Spacer(),
            _Keypad(onDigit: _onDigit, onBackspace: _backspace),
            if (biometricEnabled)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.xl),
                child: TextButton.icon(
                  onPressed: _tryBiometricFirst,
                  icon: const Icon(Icons.fingerprint_rounded, color: Colors.white),
                  label: const Text('Use biometric unlock', style: TextStyle(color: Colors.white)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  const _Keypad({required this.onDigit, required this.onBackspace});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows
          .map((row) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: row.map((key) {
                  if (key.isEmpty) return const SizedBox(width: 72, height: 72);
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: Material(
                        color: Colors.white12,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => key == '⌫' ? onBackspace() : onDigit(key),
                          child: Center(
                            child: Text(
                              key,
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ))
          .toList(),
    );
  }
}
