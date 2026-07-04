import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/category_icons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/di/providers.dart';
import '../../data/database/app_database.dart';
import '../../core/constants/app_constants.dart';

enum _Period { thisMonth, last7Days, thisYear }

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  _Period _period = _Period.thisMonth;

  (DateTime, DateTime) get _range {
    final now = DateTime.now();
    switch (_period) {
      case _Period.thisMonth:
        return (DateTime(now.year, now.month, 1), DateTime(now.year, now.month + 1, 0, 23, 59, 59));
      case _Period.last7Days:
        return (now.subtract(const Duration(days: 6)), now);
      case _Period.thisYear:
        return (DateTime(now.year, 1, 1), DateTime(now.year, 12, 31, 23, 59, 59));
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(transactionRepositoryProvider);
    final (start, end) = _range;

    return Scaffold(
      backgroundColor: AppColors.scaffoldGrey,
      appBar: AppBar(title: const Text('Analytics')),
      body: StreamBuilder<List<Transaction>>(
        stream: repo.watchByDateRange(start, end),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          final expenses = items.where((t) => t.type == 'expense').toList();
          final income = items.where((t) => t.type == 'income').toList();
          final totalExpense = expenses.fold<double>(0, (s, t) => s + t.amount);
          final totalIncome = income.fold<double>(0, (s, t) => s + t.amount);

          final byCategory = <String, double>{};
          for (final t in expenses) {
            byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
          }
          final sortedCategories = byCategory.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          final dailyTotals = <int, double>{};
          for (final t in expenses) {
            dailyTotals[t.date.day] = (dailyTotals[t.date.day] ?? 0) + t.amount;
          }

          return ListView(
            padding: const EdgeInsets.all(AppSizes.lg),
            children: [
              _PeriodSelector(period: _period, onChanged: (p) => setState(() => _period = p)),
              const SizedBox(height: AppSizes.lg),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Expenses', style: AppTextStyles.bodyMd),
                    const SizedBox(height: 4),
                    Text(AppFormatters.amount(totalExpense), style: AppTextStyles.headingLg),
                    const SizedBox(height: 4),
                    Text('Income this period: ${AppFormatters.amount(totalIncome)}',
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.income)),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.xl),
              if (sortedCategories.isNotEmpty) ...[
                Text('Category Breakdown', style: AppTextStyles.headingSm),
                const SizedBox(height: AppSizes.md),
                AppCard(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 180,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: [
                              for (var i = 0; i < sortedCategories.length; i++)
                                PieChartSectionData(
                                  value: sortedCategories[i].value,
                                  color: CategoryIcons.colorFor(i),
                                  title: '',
                                  radius: 46,
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                      ...List.generate(sortedCategories.length, (i) {
                        final entry = sortedCategories[i];
                        final pct = totalExpense == 0 ? 0 : (entry.value / totalExpense * 100);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(width: 10, height: 10, decoration: BoxDecoration(color: CategoryIcons.colorFor(i), shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(entry.key, style: AppTextStyles.bodyMd)),
                              Text('${pct.toStringAsFixed(0)}%', style: AppTextStyles.bodySm),
                              const SizedBox(width: 8),
                              Text(AppFormatters.compactAmount(entry.value), style: AppTextStyles.titleMd),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.xl),
              ],
              Text('Daily Trend', style: AppTextStyles.headingSm),
              const SizedBox(height: AppSizes.md),
              AppCard(
                child: SizedBox(
                  height: 160,
                  child: dailyTotals.isEmpty
                      ? const Center(child: Text('No expenses in this period'))
                      : BarChart(
                          BarChartData(
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            titlesData: const FlTitlesData(
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            barGroups: dailyTotals.entries
                                .map((e) => BarChartGroupData(x: e.key, barRods: [
                                      BarChartRodData(
                                        toY: e.value,
                                        color: AppColors.primary,
                                        width: 10,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ]))
                                .toList(),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSizes.xl),
              if (expenses.isNotEmpty) ...[
                Text('Insights', style: AppTextStyles.headingSm),
                const SizedBox(height: AppSizes.md),
                AppCard(
                  child: Column(
                    children: [
                      _InsightRow(
                        'Largest Expense',
                        expenses.reduce((a, b) => a.amount > b.amount ? a : b).title,
                        AppFormatters.amount(expenses.reduce((a, b) => a.amount > b.amount ? a : b).amount),
                      ),
                      _InsightRow('Most Frequent Category', sortedCategories.first.key, ''),
                      _InsightRow('Average Daily Spending',
                          AppFormatters.amount(totalExpense / (dailyTotals.isEmpty ? 1 : dailyTotals.length)), ''),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final _Period period;
  final ValueChanged<_Period> onChanged;
  const _PeriodSelector({required this.period, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _chip('This Month', _Period.thisMonth),
        const SizedBox(width: 8),
        _chip('Last 7 Days', _Period.last7Days),
        const SizedBox(width: 8),
        _chip('This Year', _Period.thisYear),
      ],
    );
  }

  Widget _chip(String label, _Period p) {
    return ChoiceChip(
      label: Text(label),
      selected: period == p,
      onSelected: (_) => onChanged(p),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(color: period == p ? Colors.white : AppColors.textPrimary),
      showCheckmark: false,
    );
  }
}

class _InsightRow extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  const _InsightRow(this.label, this.value, this.sub);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyMd)),
          Text(sub.isEmpty ? value : '$value · $sub', style: AppTextStyles.titleMd),
        ],
      ),
    );
  }
}
