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
import '../../core/di/providers.dart';
import '../../data/database/app_database.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final Transaction transaction;
  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncome = transaction.type == 'income';
    final repo = ref.read(transactionRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(RouteNames.addExpense, extra: transaction),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'duplicate') {
                await repo.duplicateTransaction(transaction);
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Transaction duplicated')));
                }
              } else if (value == 'delete') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete transaction?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await repo.deleteTransaction(transaction.id);
                  if (context.mounted) context.pop();
                }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.lg),
        children: [
          Center(
            child: Column(
              children: [
                CategoryIconBadge(
                  icon: CategoryIcons.iconFor(transaction.category),
                  color: isIncome ? AppColors.income : AppColors.expense,
                  size: 64,
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  AppFormatters.amountSigned(transaction.amount, isIncome: isIncome),
                  style: AppTextStyles.displayLg.copyWith(
                    color: isIncome ? AppColors.income : AppColors.expense,
                  ),
                ),
                Text(transaction.title, style: AppTextStyles.bodyLg),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.xl),
          AppCard(
            child: Column(
              children: [
                _Row('Category', transaction.category),
                _Row('Payment Method', transaction.paymentMethod),
                _Row('Date', AppFormatters.date(transaction.date)),
                if (transaction.time.isNotEmpty) _Row('Time', transaction.time),
                _Row('Source', transaction.source == 'imported' ? 'Imported' : 'Manual'),
                if (transaction.merchant.isNotEmpty) _Row('Merchant', transaction.merchant),
                if (transaction.bank.isNotEmpty) _Row('Bank', transaction.bank),
                if (transaction.referenceNumber.isNotEmpty)
                  _Row('Reference No.', transaction.referenceNumber),
              ],
            ),
          ),
          if (transaction.notes.isNotEmpty) ...[
            const SizedBox(height: AppSizes.lg),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notes', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Text(transaction.notes, style: AppTextStyles.bodyLg),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMd),
          Text(value, style: AppTextStyles.titleMd),
        ],
      ),
    );
  }
}
