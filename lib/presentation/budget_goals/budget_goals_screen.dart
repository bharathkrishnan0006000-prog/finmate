import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/category_icons.dart';
import '../../core/routes/route_names.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/di/providers.dart';
import '../../data/database/app_database.dart';

class BudgetGoalsScreen extends ConsumerWidget {
  const BudgetGoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetRepo = ref.watch(budgetRepositoryProvider);
    final txnRepo = ref.watch(transactionRepositoryProvider);
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return Scaffold(
      backgroundColor: AppColors.scaffoldGrey,
      appBar: AppBar(title: const Text('Budget Goals')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.addBudgetGoal),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Budget Goal', style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<List<Budget>>(
        stream: budgetRepo.watchForMonth(now),
        builder: (context, budgetSnap) {
          final budgets = budgetSnap.data ?? [];
          if (budgets.isEmpty) {
            return const EmptyState(
              icon: Icons.track_changes_rounded,
              title: 'No budgets set',
              message: 'Set a monthly limit for a category to start tracking your spending against it.',
            );
          }
          return StreamBuilder<List<Transaction>>(
            stream: txnRepo.watchByDateRange(monthStart, monthEnd),
            builder: (context, txnSnap) {
              final txns = txnSnap.data ?? [];
              return ListView(
                padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.lg, AppSizes.lg, 100),
                children: budgets.map((b) {
                  final spent = txns
                      .where((t) => t.type == 'expense' && t.category == b.category)
                      .fold<double>(0, (s, t) => s + t.amount);
                  final remaining = b.monthlyLimit - spent;
                  final progress = b.monthlyLimit == 0 ? 0.0 : spent / b.monthlyLimit;
                  final isOver = spent > b.monthlyLimit;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.md),
                    child: AppCard(
                      onTap: () => context.push(RouteNames.addBudgetGoal, extra: b),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CategoryIconBadge(
                                icon: CategoryIcons.iconFor(b.category),
                                color: isOver ? AppColors.error : AppColors.primary,
                              ),
                              const SizedBox(width: AppSizes.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(b.category, style: AppTextStyles.titleMd),
                                    Text(
                                      '${AppFormatters.amount(spent)} / ${AppFormatters.amount(b.monthlyLimit)}',
                                      style: AppTextStyles.bodySm,
                                    ),
                                  ],
                                ),
                              ),
                              Text('${(progress * 100).clamp(0, 999).toStringAsFixed(0)}%',
                                  style: AppTextStyles.titleMd.copyWith(color: isOver ? AppColors.error : AppColors.primary)),
                            ],
                          ),
                          const SizedBox(height: AppSizes.md),
                          AppProgressBar(progress: progress),
                          if (isOver) ...[
                            const SizedBox(height: AppSizes.sm),
                            Text(
                              'Over budget by ${AppFormatters.amount(remaining.abs())}',
                              style: AppTextStyles.bodySm.copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
