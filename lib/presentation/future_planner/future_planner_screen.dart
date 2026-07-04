import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/routes/route_names.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/di/providers.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/future_expense_repository.dart';

class FuturePlannerScreen extends ConsumerWidget {
  const FuturePlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnRepo = ref.watch(transactionRepositoryProvider);
    final futureRepo = ref.watch(futureExpenseRepositoryProvider);
    final subRepo = ref.watch(subscriptionRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldGrey,
      appBar: AppBar(title: const Text('Future Planner')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.addFutureExpense),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Plan Purchase', style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<List<FutureExpense>>(
        stream: futureRepo.watchAll(),
        builder: (context, plannedSnap) {
          final planned = plannedSnap.data ?? [];
          return FutureBuilder(
            future: Future.wait([
              txnRepo.currentBalance(),
              txnRepo.futureDatedTransactions(),
              subRepo.renewingWithin(60),
            ]),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final currentBalance = snap.data![0] as double;
              final futureTxns = snap.data![1] as List<Transaction>;
              final upcomingSubs = snap.data![2] as List<Subscription>;

              final projection = computeBalanceProjection(
                currentBalance: currentBalance,
                futureTransactions: futureTxns
                    .map((t) => (date: t.date, amount: t.amount, isIncome: t.type == 'income'))
                    .toList(),
                plannedPurchases: planned
                    .map((p) => (date: p.plannedDate, amount: p.amount))
                    .toList(),
                subscriptionRenewals: upcomingSubs
                    .map((s) => (date: s.renewalDate, amount: s.price))
                    .toList(),
              );

              return ListView(
                padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.lg, AppSizes.lg, 100),
                children: [
                  Text('Projected Balance (60 days)', style: AppTextStyles.headingSm),
                  const SizedBox(height: AppSizes.md),
                  AppCard(
                    child: SizedBox(
                      height: 180,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: [
                                for (var i = 0; i < projection.length; i++)
                                  FlSpot(i.toDouble(), projection[i].balance),
                              ],
                              isCurved: true,
                              color: AppColors.primary,
                              barWidth: 2.5,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(show: true, color: AppColors.accentSoft),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Planned Purchases', style: AppTextStyles.headingSm),
                    ],
                  ),
                  const SizedBox(height: AppSizes.md),
                  if (planned.isEmpty)
                    const EmptyState(
                      icon: Icons.flag_outlined,
                      title: 'No planned purchases',
                      message: 'Add something you want to buy and see if it fits your budget.',
                    )
                  else
                    ...planned.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSizes.md),
                          child: _PlannedExpenseTile(
                            plan: p,
                            currentBalance: currentBalance,
                            futureTxns: futureTxns,
                            upcomingSubs: upcomingSubs,
                          ),
                        )),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _PlannedExpenseTile extends StatelessWidget {
  final FutureExpense plan;
  final double currentBalance;
  final List<Transaction> futureTxns;
  final List<Subscription> upcomingSubs;

  const _PlannedExpenseTile({
    required this.plan,
    required this.currentBalance,
    required this.futureTxns,
    required this.upcomingSubs,
  });

  @override
  Widget build(BuildContext context) {
    final expectedIncome = futureTxns
        .where((t) => t.type == 'income' && !t.date.isAfter(plan.plannedDate))
        .fold<double>(0, (s, t) => s + t.amount);
    final upcomingBills = futureTxns
        .where((t) => t.type == 'expense' && !t.date.isAfter(plan.plannedDate))
        .fold<double>(0, (s, t) => s + t.amount);
    final subsCost = upcomingSubs
        .where((s) => !s.renewalDate.isAfter(plan.plannedDate))
        .fold<double>(0, (s, sub) => s + sub.price);

    final result = calculateAffordability(
      currentBalance: currentBalance,
      expectedIncome: expectedIncome,
      upcomingBills: upcomingBills,
      upcomingSubscriptions: subsCost,
      plannedAmount: plan.amount,
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.title, style: AppTextStyles.titleMd),
                    Text('Planned for ${AppFormatters.date(plan.plannedDate)}', style: AppTextStyles.bodySm),
                  ],
                ),
              ),
              Text(AppFormatters.amount(plan.amount), style: AppTextStyles.headingMd),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          StatusPill(
            label: result.isSafe ? 'Safe to Buy' : 'Not Recommended',
            color: result.isSafe ? AppColors.income : AppColors.error,
            icon: result.isSafe ? Icons.check_circle_rounded : Icons.warning_rounded,
          ),
          const SizedBox(height: AppSizes.sm),
          Text(result.reason, style: AppTextStyles.bodySm),
          const SizedBox(height: 4),
          Text(
            'You will have ${AppFormatters.amount(result.remainingAfterPurchase)} left after this purchase.',
            style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
