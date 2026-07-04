import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/category_icons.dart';
import '../../core/routes/route_names.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/di/providers.dart';
import '../../data/database/app_database.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  TransactionType? _typeFilter;
  SortOption _sort = SortOption.newest;

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(transactionRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldGrey,
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _showSortFilterSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search by merchant, amount, category, notes...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
            child: Row(
              children: [
                _FilterChip(label: 'All', selected: _typeFilter == null, onTap: () => setState(() => _typeFilter = null)),
                const SizedBox(width: AppSizes.sm),
                _FilterChip(
                  label: 'Expense',
                  selected: _typeFilter == TransactionType.expense,
                  onTap: () => setState(() => _typeFilter = TransactionType.expense),
                ),
                const SizedBox(width: AppSizes.sm),
                _FilterChip(
                  label: 'Income',
                  selected: _typeFilter == TransactionType.income,
                  onTap: () => setState(() => _typeFilter = TransactionType.income),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Expanded(
            child: StreamBuilder<List<Transaction>>(
              stream: repo.watchAll(),
              builder: (context, snapshot) {
                var items = snapshot.data ?? [];
                if (_typeFilter != null) {
                  items = items.where((t) => t.type == _typeFilter!.name).toList();
                }
                if (_query.isNotEmpty) {
                  final q = _query.toLowerCase();
                  items = items
                      .where((t) =>
                          t.title.toLowerCase().contains(q) ||
                          t.category.toLowerCase().contains(q) ||
                          t.notes.toLowerCase().contains(q) ||
                          t.merchant.toLowerCase().contains(q) ||
                          t.amount.toString().contains(q))
                      .toList();
                }
                switch (_sort) {
                  case SortOption.newest:
                    items.sort((a, b) => b.date.compareTo(a.date));
                    break;
                  case SortOption.oldest:
                    items.sort((a, b) => a.date.compareTo(b.date));
                    break;
                  case SortOption.highestAmount:
                    items.sort((a, b) => b.amount.compareTo(a.amount));
                    break;
                  case SortOption.lowestAmount:
                    items.sort((a, b) => a.amount.compareTo(b.amount));
                    break;
                }

                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'No transactions found',
                    message: 'Try changing your search or filters.',
                  );
                }

                // Group by date for section headers.
                final grouped = <String, List<Transaction>>{};
                for (final t in items) {
                  final key = AppFormatters.relativeDay(t.date);
                  grouped.putIfAbsent(key, () => []).add(t);
                }

                return ListView(
                  padding: const EdgeInsets.only(bottom: 100),
                  children: grouped.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.md, AppSizes.lg, AppSizes.xs),
                          child: Text(entry.key, style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600)),
                        ),
                        ...entry.value.map((t) => _TxnRow(transaction: t, repo: repo)),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showSortFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sort by', style: AppTextStyles.headingSm),
            const SizedBox(height: AppSizes.sm),
            ...SortOption.values.map((s) => RadioListTile<SortOption>(
                  value: s,
                  groupValue: _sort,
                  title: Text(_sortLabel(s)),
                  onChanged: (v) {
                    setState(() => _sort = v!);
                    Navigator.of(context).pop();
                  },
                )),
          ],
        ),
      ),
    );
  }

  String _sortLabel(SortOption s) {
    switch (s) {
      case SortOption.newest:
        return 'Newest first';
      case SortOption.oldest:
        return 'Oldest first';
      case SortOption.highestAmount:
        return 'Highest amount';
      case SortOption.lowestAmount:
        return 'Lowest amount';
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textPrimary),
      showCheckmark: false,
    );
  }
}

class _TxnRow extends StatelessWidget {
  final Transaction transaction;
  final dynamic repo;
  const _TxnRow({required this.transaction, required this.repo});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete transaction?'),
            content: const Text('This can be undone from the snackbar.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
            ],
          ),
        );
      },
      onDismissed: (_) {
        repo.deleteTransaction(transaction.id);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Transaction deleted'),
          action: SnackBarAction(label: 'Undo', onPressed: () => repo.undoDelete(transaction.id)),
        ));
      },
      child: ListTile(
        onTap: () => context.push(RouteNames.transactionDetail, extra: transaction),
        leading: CategoryIconBadge(
          icon: CategoryIcons.iconFor(transaction.category),
          color: isIncome ? AppColors.income : AppColors.expense,
        ),
        title: Text(transaction.title, style: AppTextStyles.titleMd),
        subtitle: Text(
          '${transaction.category} · ${transaction.paymentMethod}${transaction.source == 'imported' ? ' · Imported' : ''}',
          style: AppTextStyles.bodySm,
        ),
        trailing: Text(
          AppFormatters.amountSigned(transaction.amount, isIncome: isIncome),
          style: AppTextStyles.titleMd.copyWith(color: isIncome ? AppColors.income : AppColors.expense),
        ),
      ),
    );
  }
}
