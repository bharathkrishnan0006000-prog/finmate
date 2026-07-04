import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/di/providers.dart';
import '../../data/database/app_database.dart';
import '../../core/constants/app_constants.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  List<String>? _tips;
  bool _analyzing = false;

  Future<void> _analyzeSpending() async {
    setState(() => _analyzing = true);
    final txnRepo = ref.read(transactionRepositoryProvider);
    final ai = ref.read(aiInsightServiceProvider);
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final thisMonthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

    final thisMonth = await txnRepo.categoryTotals(
        TransactionType.expense, thisMonthStart, thisMonthEnd);
    final lastMonth = await txnRepo.categoryTotals(
        TransactionType.expense, lastMonthStart, lastMonthEnd);

    final tips = ai.generateSpendingTips(
        thisMonthByCategory: thisMonth, lastMonthByCategory: lastMonth);

    if (!mounted) return;
    setState(() {
      _tips = tips;
      _analyzing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final aiEnabled = ref.watch(aiEnabledProvider);
    final txnRepo = ref.watch(transactionRepositoryProvider);
    final healthService = ref.watch(financialHealthServiceProvider);

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return Scaffold(
      backgroundColor: AppColors.scaffoldGrey,
      appBar: AppBar(title: const Text('Insights')),
      body: FutureBuilder(
        future: Future.wait([
          txnRepo.totalIncome(monthStart, monthEnd),
          txnRepo.totalExpense(monthStart, monthEnd),
        ]),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final income = snap.data![0];
          final expense = snap.data![1];
          final breakdown = healthService.calculate(
            monthlyIncome: income,
            monthlyExpense: expense,
            budgetLimitTotal: 0,
            budgetSpentTotal: 0,
            subscriptionMonthlyCost: 0,
            monthlyIncomes: [income],
            previousMonthExpense: 0,
          );
          final score = breakdown.total;

          return ListView(
            padding: const EdgeInsets.all(AppSizes.lg),
            children: [
              AppCard(
                child: Column(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: score / 100,
                            strokeWidth: 8,
                            backgroundColor: AppColors.scaffoldGrey,
                            valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                          ),
                          Text('$score', style: AppTextStyles.headingLg),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    Text('Financial Health Score', style: AppTextStyles.titleMd),
                    Text(healthService.label(score), style: AppTextStyles.bodyMd),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.xl),
              Text('Score Breakdown', style: AppTextStyles.headingSm),
              const SizedBox(height: AppSizes.md),
              AppCard(
                child: Column(
                  children: [
                    _ScoreRow('Savings Rate', breakdown.savingsRateScore, 30),
                    _ScoreRow('Budget Usage', breakdown.budgetUsageScore, 25),
                    _ScoreRow('Subscription Load', breakdown.subscriptionLoadScore, 20),
                    _ScoreRow('Income Stability', breakdown.incomeStabilityScore, 15),
                    _ScoreRow('Spending Control', breakdown.spendingControlScore, 10),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('AI Insights', style: AppTextStyles.headingSm),
                  if (!aiEnabled)
                    Text('Disabled in Settings', style: AppTextStyles.bodySm.copyWith(color: AppColors.textHint)),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              if (!aiEnabled)
                AppCard(
                  child: Text(
                    'Turn on "Enable AI Features" in Settings to generate spending tips. Everything runs on your device — no data leaves your phone.',
                    style: AppTextStyles.bodyMd,
                  ),
                )
              else ...[
                AppButton(
                  label: 'Analyze Spending',
                  icon: Icons.auto_awesome_rounded,
                  isLoading: _analyzing,
                  onPressed: _analyzeSpending,
                ),
                if (_tips != null) ...[
                  const SizedBox(height: AppSizes.md),
                  ..._tips!.map((tip) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.sm),
                        child: AppCard(
                          child: Row(
                            children: [
                              const Icon(Icons.lightbulb_rounded, color: AppColors.warning, size: 20),
                              const SizedBox(width: AppSizes.sm),
                              Expanded(child: Text(tip, style: AppTextStyles.bodyMd)),
                            ],
                          ),
                        ),
                      )),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final int score;
  final int max;
  const _ScoreRow(this.label, this.score, this.max);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: AppTextStyles.bodyMd)),
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / max,
                minHeight: 6,
                backgroundColor: AppColors.scaffoldGrey,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Text('$score/$max', style: AppTextStyles.bodySm),
        ],
      ),
    );
  }
}
