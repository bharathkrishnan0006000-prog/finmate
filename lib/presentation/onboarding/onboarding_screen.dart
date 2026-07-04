import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routes/route_names.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/di/providers.dart';

class _Slide {
  final IconData icon;
  final String title;
  final String description;
  const _Slide(this.icon, this.title, this.description);
}

const _slides = [
  _Slide(
    Icons.insights_rounded,
    'Smart way to\nmanage your money',
    'Track expenses, plan ahead, and achieve\nyour financial goals with ease.',
  ),
  _Slide(
    Icons.upload_file_rounded,
    'Import bank\nstatements instantly',
    'Upload PDF, CSV, or Excel statements and let\nFinMate organize everything automatically.',
  ),
  _Slide(
    Icons.savings_rounded,
    'Plan, save, and\nstay in control',
    'Set budgets, track subscriptions, and grow\nyour savings goals — all completely offline.',
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  final _balanceController = TextEditingController();
  int _page = 0;
  final int _totalPages = _slides.length + 1; // + quick setup page

  void _next() {
    if (_page < _totalPages - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(AppConstants.prefsOnboardingDone, true);
    await prefs.setString(AppConstants.prefsCurrency, 'INR');

    final startingBalance = double.tryParse(_balanceController.text.trim());
    if (startingBalance != null && startingBalance > 0) {
      await ref.read(transactionRepositoryProvider).addTransaction(
            title: 'Starting Balance',
            amount: startingBalance,
            type: TransactionType.income,
            category: 'Others',
            notes: 'Added during onboarding',
          );
    }

    if (!mounted) return;
    context.go(RouteNames.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final isLastSlide = _page == _totalPages - 1;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  ..._slides.map(_buildSlide),
                  _buildQuickSetup(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.xxl, vertical: AppSizes.lg),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalPages, (i) {
                      final selected = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: selected ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSizes.xl),
                  AppButton(
                    label: isLastSlide ? 'Get Started' : 'Continue',
                    onPressed: _next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(_Slide slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: const BoxDecoration(
              color: AppColors.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(slide.icon, size: 84, color: AppColors.primary),
          ),
          const SizedBox(height: AppSizes.xxxl),
          Text(slide.title, style: AppTextStyles.headingLg, textAlign: TextAlign.center),
          const SizedBox(height: AppSizes.md),
          Text(slide.description, style: AppTextStyles.bodyMd, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildQuickSetup() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick setup', style: AppTextStyles.headingMd),
          const SizedBox(height: AppSizes.xs),
          Text(
            'Currency is set to Indian Rupee (₹). You can change this later in Settings.',
            style: AppTextStyles.bodyMd,
          ),
          const SizedBox(height: AppSizes.xxl),
          AppTextField(
            label: 'Starting balance (optional)',
            hint: 'e.g. 25000',
            controller: _balanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: const Padding(
              padding: EdgeInsets.all(14),
              child: Text('₹', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'PIN lock and biometric lock can be enabled anytime from Settings > Security.',
            style: AppTextStyles.bodySm,
          ),
        ],
      ),
    );
  }
}
