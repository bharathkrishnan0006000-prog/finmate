import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routes/route_names.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/category_icons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/di/providers.dart';
import '../../data/database/app_database.dart';
import '../../data/services/financial_health_service.dart';
import '../common/root_shell.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnRepo = ref.watch(transactionRepositoryProvider);
    final subRepo = ref.watch(subscriptionRepositoryProvider);
    final budgetRepo = ref.watch(budgetRepositoryProvider);

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return Scaffold(
      backgroundColor: AppColors.scaffoldGrey,
      body: SafeArea(
        child: StreamBuilder<List<Transaction>>(
          stream: txnRepo.watchAll(),
          builder: (context, snapshot) {
            final all = snapshot.data ?? [];
            final thisMonth = all
                .where((t) => !t.date.isBefore(monthStart) && !t.date.isAfter(monthEnd))
                .toList();
            final income = thisMonth
                .where((t) => t.type == 'income')
                .fold<double>(0, (s, t) => s + t.amount);
            final expense = thisMonth
                .where((t) => t.type == 'expense')
                .fold<double>(0, (s, t) => s + t.amount);
            final balance = all.fold<double>(
                0, (s, t) => s + (t.type == 'income' ? t.amount : -t.amount));
            final recent = (all..sort((a, b) => b.date.compareTo(a.date))).take(5).toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSizes.lg, 0, AppSizes.lg, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _BalanceCard(balance: balance, income: income, expense: expense, monthTransactions: thisMonth),
                      const SizedBox(height: AppSizes.xl),
                      const SectionHeader(title: 'Quick Actions'),
                      const SizedBox(height: AppSizes.md),
                      _QuickActions(),
                      const SizedBox(height: AppSizes.xl),
                      _FinancialHealthCard(income: income, expense: expense),
                      const SizedBox(height: AppSizes.xl),
                      FutureBuilder(
                        future: budgetRepo.forMonth(now),
                        builder: (context, budgetSnap) {
                          final budgets = budgetSnap.data ?? [];
                          if (budgets.isEmpty) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SectionHeader(title: 'Budget Progress'),
                              const SizedBox(height: AppSizes.md),
                              _BudgetProgressCard(budgets: budgets, monthTransactions: thisMonth),
                              const SizedBox(height: AppSizes.xl),
                            ],
                          );
                        },
                      ),
                      FutureBuilder(
                        future: subRepo.renewingWithin(7),
                        builder: (context, subSnap) {
                          final upcoming = subSnap.data ?? [];
                          if (upcoming.isEmpty) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionHeader(
                                title: 'Upcoming Bills & Subscriptions',
                                actionLabel: 'View all',
                                onAction: () => context.push(RouteNames.subscriptions),
                              ),
                              const SizedBox(height: AppSizes.md),
                              ...upcoming.take(3).map((s) => _UpcomingTile(subscription: s)),
                              const SizedBox(height: AppSizes.xl),
                            ],
                          );
                        },
                      ),
                      SectionHeader(
                        title: 'Recent Transactions',
                        actionLabel: 'View all',
                        onAction: () => context.push(RouteNames.transactions),
                      ),
                      const SizedBox(height: AppSizes.md),
                      if (recent.isEmpty)
                        const EmptyState(
                          icon: Icons.receipt_long_rounded,
                          title: 'No transactions yet',
                          message: 'Add your first expense or import a bank statement to get started.',
                        )
                      else
                        AppCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              for (var i = 0; i < recent.length; i++) ...[
                                _TransactionTile(transaction: recent[i]),
                                if (i != recent.length - 1)
                                  const Divider(height: 1, indent: 64),
                              ],
                            ],
                          ),
                        ),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.lg, AppSizes.lg, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Builder(builder: (context) {
            return GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_greeting(), style: AppTextStyles.bodyMd),
                  Row(
                    children: [
                      const Text('Bharath', style: AppTextStyles.headingMd),
                      const SizedBox(width: 6),
                      const Text('👋', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                ],
              ),
            );
          }),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expense;
  final List<Transaction> monthTransactions;

  const _BalanceCard({
    required this.balance,
    required this.income,
    required this.expense,
    required this.monthTransactions,
  });

  List<FlSpot> _buildSpots() {
    // Group net daily change across the current month for a lightweight
    // "This Month Overview" trend line.
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dailyNet = List<double>.filled(daysInMonth, 0);
    for (final t in monthTransactions) {
      final idx = t.date.day - 1;
      if (idx < 0 || idx >= daysInMonth) continue;
      dailyNet[idx] += (t.type == 'income' ? t.amount : -t.amount);
    }
    double running = 0;
    final spots = <FlSpot>[];
    for (var i = 0; i < daysInMonth; i++) {
      running += dailyNet[i];
      spots.add(FlSpot(i.toDouble(), running));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final spots = _buildSpots();
    return Container(
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Current Balance',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
              const Icon(Icons.expand_more_rounded, color: Colors.white70, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          Text(AppFormatters.amount(balance), style: AppTextStyles.amountLg),
          const SizedBox(height: AppSizes.lg),
          Row(
            children: [
              _MiniStat(label: 'Income', value: income, icon: Icons.arrow_downward_rounded, color: AppColors.accent),
              const SizedBox(width: AppSizes.xl),
              _MiniStat(label: 'Expenses', value: expense, icon: Icons.arrow_upward_rounded, color: Colors.white70),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          const Text('This Month Overview',
              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: AppSizes.sm),
          SizedBox(
            height: 70,
            child: spots.length < 2
                ? const SizedBox.shrink()
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineTouchData: const LineTouchData(enabled: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: AppColors.accent,
                          barWidth: 2.5,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.accent.withOpacity(0.18),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;

  const _MiniStat({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                Text(AppFormatters.compactAmount(value),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.add_circle_outline_rounded, 'Add Expense', RouteNames.addExpense),
      (Icons.upload_file_rounded, 'Upload Statement', RouteNames.uploadStatement),
      (Icons.flag_outlined, 'Future Expense', RouteNames.addFutureExpense),
      (Icons.subscriptions_outlined, 'Subscriptions', RouteNames.subscriptions),
      (Icons.handshake_outlined, 'Borrow & Lend', RouteNames.borrowLend),
    ];
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSizes.md),
        itemBuilder: (context, i) {
          final a = actions[i];
          return SizedBox(
            width: 76,
            child: InkWell(
              onTap: () => context.push(a.$3),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: Icon(a.$1, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(height: 6),
                  Text(a.$2,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: AppTextStyles.bodySm.copyWith(fontSize: 11)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FinancialHealthCard extends ConsumerWidget {
  final double income;
  final double expense;
  const _FinancialHealthCard({required this.income, required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(financialHealthServiceProvider);
    final breakdown = service.calculate(
      monthlyIncome: income,
      monthlyExpense: expense,
      budgetLimitTotal: 0,
      budgetSpentTotal: 0,
      subscriptionMonthlyCost: 0,
      monthlyIncomes: [income],
      previousMonthExpense: 0,
    );
    final score = breakdown.total;
    return AppCard(
      onTap: () => context.push(RouteNames.insights),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 5,
                  backgroundColor: AppColors.scaffoldGrey,
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                ),
                Text('$score', style: AppTextStyles.titleMd),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Financial Health Score', style: AppTextStyles.titleMd),
                const SizedBox(height: 2),
                Text('${service.label(score)} · Tap for full insights', style: AppTextStyles.bodySm),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
        ],
      ),
    );
  }
}

class _BudgetProgressCard extends StatelessWidget {
  final List<Budget> budgets;
  final List<Transaction> monthTransactions;
  const _BudgetProgressCard({required this.budgets, required this.monthTransactions});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: budgets.take(3).map((b) {
          final spent = monthTransactions
              .where((t) => t.type == 'expense' && t.category == b.category)
              .fold<double>(0, (s, t) => s + t.amount);
          final progress = b.monthlyLimit == 0 ? 0.0 : spent / b.monthlyLimit;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(b.category, style: AppTextStyles.bodyLg),
                    Text('${AppFormatters.compactAmount(spent)} / ${AppFormatters.compactAmount(b.monthlyLimit)}',
                        style: AppTextStyles.bodySm),
                  ],
                ),
                const SizedBox(height: 6),
                AppProgressBar(progress: progress),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  final Subscription subscription;
  const _UpcomingTile({required this.subscription});

  @override
  Widget build(BuildContext context) {
    final daysLeft = subscription.renewalDate.difference(DateTime.now()).inDays;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(
          children: [
            CategoryIconBadge(
              icon: CategoryIcons.iconFor(subscription.name),
              color: CategoryIcons.colorFromValue(subscription.colorValue),
              size: 40,
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subscription.name, style: AppTextStyles.titleMd),
                  Text(
                    daysLeft <= 0 ? 'Renewing today' : 'Renewing in $daysLeft day${daysLeft == 1 ? '' : 's'}',
                    style: AppTextStyles.bodySm,
                  ),
                ],
              ),
            ),
            Text(AppFormatters.amount(subscription.price), style: AppTextStyles.titleMd),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: 4),
      onTap: () => context.push(RouteNames.transactionDetail, extra: transaction),
      leading: CategoryIconBadge(
        icon: CategoryIcons.iconFor(transaction.category),
        color: isIncome ? AppColors.income : AppColors.expense,
        size: 42,
      ),
      title: Text(transaction.title, style: AppTextStyles.titleMd),
      subtitle: Text('${transaction.category} · ${AppFormatters.relativeDay(transaction.date)}',
          style: AppTextStyles.bodySm),
      trailing: Text(
        AppFormatters.amountSigned(transaction.amount, isIncome: isIncome),
        style: AppTextStyles.titleMd.copyWith(color: isIncome ? AppColors.income : AppColors.expense),
      ),
    );
  }
}
