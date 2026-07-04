import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/di/providers.dart';

class BulkDeleteScreen extends ConsumerStatefulWidget {
  const BulkDeleteScreen({super.key});

  @override
  ConsumerState<BulkDeleteScreen> createState() => _BulkDeleteScreenState();
}

class _BulkDeleteScreenState extends ConsumerState<BulkDeleteScreen> {
  bool _isDeleting = false;

  Future<void> _confirmAndRun(String label, Future<int> Function() action, {bool destructive = true}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $label?'),
        content: const Text('This can\'t be undone in bulk (individual transactions can still be restored one at a time from Transactions).'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: destructive ? AppColors.error : AppColors.primary)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    final count = await action();
    if (!mounted) return;
    setState(() => _isDeleting = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted $count transaction${count == 1 ? '' : 's'}')));
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(transactionRepositoryProvider);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.scaffoldGrey,
      appBar: AppBar(title: const Text('Bulk Delete')),
      body: AbsorbPointer(
        absorbing: _isDeleting,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.lg),
          children: [
            _SectionLabel('By Date'),
            _Tile('Today', () => _confirmAndRun('today\'s transactions', () {
                  final start = DateTime(now.year, now.month, now.day);
                  final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
                  return repo.deleteByDateRange(start, end);
                })),
            _Tile('Yesterday', () => _confirmAndRun('yesterday\'s transactions', () {
                  final y = now.subtract(const Duration(days: 1));
                  final start = DateTime(y.year, y.month, y.day);
                  final end = DateTime(y.year, y.month, y.day, 23, 59, 59);
                  return repo.deleteByDateRange(start, end);
                })),
            _Tile('Last 7 Days', () => _confirmAndRun('the last 7 days', () {
                  return repo.deleteByDateRange(now.subtract(const Duration(days: 7)), now);
                })),
            _Tile('Last 30 Days', () => _confirmAndRun('the last 30 days', () {
                  return repo.deleteByDateRange(now.subtract(const Duration(days: 30)), now);
                })),
            _Tile('This Month', () => _confirmAndRun('this month\'s transactions', () {
                  return repo.deleteByDateRange(DateTime(now.year, now.month, 1), now);
                })),
            _Tile('Last Month', () => _confirmAndRun('last month\'s transactions', () {
                  final start = DateTime(now.year, now.month - 1, 1);
                  final end = DateTime(now.year, now.month, 0, 23, 59, 59);
                  return repo.deleteByDateRange(start, end);
                })),
            _Tile('Custom Date Range', () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2015),
                lastDate: DateTime(2100),
              );
              if (range == null) return;
              await _confirmAndRun('the selected range',
                  () => repo.deleteByDateRange(range.start, range.end));
            }),
            const SizedBox(height: AppSizes.xl),
            _SectionLabel('By Category'),
            _Tile('Pick a Category…', () async {
              final category = await showModalBottomSheet<String>(
                context: context,
                builder: (context) => ListView(
                  shrinkWrap: true,
                  children: [
                    ...AppConstants.defaultExpenseCategories,
                    ...AppConstants.defaultIncomeCategories,
                  ]
                      .map((c) => ListTile(title: Text(c), onTap: () => Navigator.of(context).pop(c)))
                      .toList(),
                ),
              );
              if (category == null) return;
              await _confirmAndRun('all "$category" transactions', () => repo.deleteByCategory(category));
            }),
            const SizedBox(height: AppSizes.xl),
            _SectionLabel('By Source / Type'),
            _Tile('Imported Transactions Only',
                () => _confirmAndRun('imported transactions', repo.deleteImportedOnly)),
            _Tile('Manual Transactions Only',
                () => _confirmAndRun('manual transactions', repo.deleteManualOnly)),
            _Tile('Income Only', () => _confirmAndRun('all income', repo.deleteIncomeOnly)),
            _Tile('Expense Only', () => _confirmAndRun('all expenses', repo.deleteExpenseOnly)),
            const SizedBox(height: AppSizes.xl),
            _SectionLabel('Danger Zone'),
            _Tile('Delete Everything', () => _confirmAndRun('ALL transactions', repo.deleteEverything),
                danger: true),
            if (_isDeleting) ...[
              const SizedBox(height: AppSizes.xl),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.sm),
        child: Text(label, style: AppTextStyles.headingSm),
      );
}

class _Tile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const _Tile(this.label, this.onTap, {this.danger = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      child: ListTile(
        title: Text(label, style: TextStyle(color: danger ? AppColors.error : AppColors.textPrimary)),
        trailing: Icon(Icons.chevron_right_rounded, color: danger ? AppColors.error : AppColors.textHint),
        onTap: onTap,
      ),
    );
  }
}
