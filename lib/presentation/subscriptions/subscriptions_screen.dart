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

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(subscriptionRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldGrey,
      appBar: AppBar(title: const Text('Subscriptions')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.addSubscription),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Subscription', style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<List<Subscription>>(
        stream: repo.watchAll(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.subscriptions_outlined,
              title: 'No subscriptions yet',
              message: 'Add Netflix, rent, gym, or any recurring bill to track renewals.',
            );
          }
          final monthlyTotal = items
              .where((s) => s.status == 'active')
              .fold<double>(0, (s, sub) => s + (sub.cycle == 'Monthly' ? sub.price : sub.price));

          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.lg, AppSizes.lg, 100),
            children: [
              AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Active Subscriptions', style: AppTextStyles.bodyMd),
                        Text('${items.where((s) => s.status == 'active').length}', style: AppTextStyles.headingLg),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Est. Monthly Cost', style: AppTextStyles.bodyMd),
                        Text(AppFormatters.amount(monthlyTotal), style: AppTextStyles.headingMd),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              ...items.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.md),
                    child: AppCard(
                      onTap: () => context.push(RouteNames.addSubscription, extra: s),
                      child: Row(
                        children: [
                          CategoryIconBadge(
                            icon: CategoryIcons.iconFor(s.name),
                            color: CategoryIcons.colorFromValue(s.colorValue),
                          ),
                          const SizedBox(width: AppSizes.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.name, style: AppTextStyles.titleMd),
                                Text('${AppFormatters.amount(s.price)} / ${s.cycle.toLowerCase()}',
                                    style: AppTextStyles.bodySm),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(_renewalLabel(s.renewalDate), style: AppTextStyles.bodySm),
                              const SizedBox(height: 2),
                              Text(AppFormatters.dateShort(s.renewalDate), style: AppTextStyles.bodySm),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }

  String _renewalLabel(DateTime date) {
    final days = date.difference(DateTime.now()).inDays;
    if (days <= 0) return 'Renews today';
    if (days == 1) return 'Renews tomorrow';
    return 'Renews in $days days';
  }
}
