import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/routes/route_names.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/di/providers.dart';
import '../../data/database/app_database.dart';

class SavingsGoalsScreen extends ConsumerWidget {
  const SavingsGoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(savingsGoalRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldGrey,
      appBar: AppBar(title: const Text('Savings Goals')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.addSavingsGoal),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Savings Goal', style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<List<SavingsGoal>>(
        stream: repo.watchAll(),
        builder: (context, snapshot) {
          final goals = snapshot.data ?? [];
          if (goals.isEmpty) {
            return const EmptyState(
              icon: Icons.savings_outlined,
              title: 'No savings goals yet',
              message: 'Set a target — a laptop, a trip, an emergency fund — and track your progress.',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.lg, AppSizes.lg, 100),
            children: goals.map((g) {
              final progress = g.targetAmount == 0 ? 0.0 : g.savedAmount / g.targetAmount;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.md),
                child: AppCard(
                  onTap: () => context.push(RouteNames.addSavingsGoal, extra: g),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(g.title, style: AppTextStyles.titleMd),
                            const SizedBox(height: 4),
                            Text('Target: ${AppFormatters.amount(g.targetAmount)}', style: AppTextStyles.bodySm),
                            const SizedBox(height: 4),
                            Text('Saved: ${AppFormatters.amount(g.savedAmount)}', style: AppTextStyles.bodySm),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: progress.clamp(0, 1),
                              strokeWidth: 5,
                              backgroundColor: AppColors.scaffoldGrey,
                              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                            ),
                            Text('${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                                style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
