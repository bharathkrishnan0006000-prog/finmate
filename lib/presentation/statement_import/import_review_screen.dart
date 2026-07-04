import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/routes/route_names.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/di/providers.dart';
import '../../data/models/parsed_transaction.dart';
import '../../data/database/app_database.dart';

class ImportReviewScreen extends ConsumerStatefulWidget {
  final List<ParsedTransaction> parsedTransactions;
  const ImportReviewScreen({super.key, required this.parsedTransactions});

  @override
  ConsumerState<ImportReviewScreen> createState() => _ImportReviewScreenState();
}

class _ImportReviewScreenState extends ConsumerState<ImportReviewScreen> {
  bool _checking = true;
  bool _importing = false;
  bool _skipDuplicates = true;
  Set<String> _duplicateHashes = {};
  final Map<ParsedTransaction, String> _hashes = {};

  @override
  void initState() {
    super.initState();
    _checkDuplicates();
  }

  Future<void> _checkDuplicates() async {
    final repo = ref.read(transactionRepositoryProvider);
    for (final t in widget.parsedTransactions) {
      _hashes[t] = repo.computeHash(
          date: t.date, amount: t.amount, description: t.description, type: t.type);
    }
    final existing = await repo.existingHashes(_hashes.values.toList());
    setState(() {
      _duplicateHashes = existing;
      for (final t in widget.parsedTransactions) {
        t.isDuplicate = _duplicateHashes.contains(_hashes[t]);
      }
      _checking = false;
    });
  }

  Future<void> _confirmImport() async {
    setState(() => _importing = true);
    final repo = ref.read(transactionRepositoryProvider);
    final toImport = widget.parsedTransactions.where((t) {
      if (!t.includeInImport) return false;
      if (t.isDuplicate && _skipDuplicates) return false;
      return true;
    }).toList();

    final entries = toImport
        .map((t) => TransactionsCompanion.insert(
              id: const Uuid().v4(),
              title: t.description.isEmpty ? 'Imported Transaction' : t.description,
              description: Value(t.description),
              amount: t.amount,
              type: t.type.name,
              category: t.category,
              date: t.date,
              source: const Value('imported'),
              referenceNumber: Value(t.referenceNumber),
              bank: Value(t.bankName),
              dedupeHash: Value(_hashes[t] ?? ''),
            ))
        .toList();

    await repo.insertImportedBatch(entries);
    if (!mounted) return;
    setState(() => _importing = false);
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Import Complete'),
        content: Text('${entries.length} transactions were imported successfully.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go(RouteNames.dashboard);
            },
            child: const Text('Go to Dashboard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final duplicates = widget.parsedTransactions.where((t) => t.isDuplicate).length;
    final income = widget.parsedTransactions.where((t) => t.type == TransactionType.income);
    final expense = widget.parsedTransactions.where((t) => t.type == TransactionType.expense);

    return Scaffold(
      backgroundColor: AppColors.scaffoldGrey,
      appBar: AppBar(title: const Text('Review Import')),
      body: _checking
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSizes.lg),
              children: [
                AppCard(
                  child: Column(
                    children: [
                      _SummaryRow('Total Parsed', '${widget.parsedTransactions.length}'),
                      _SummaryRow('Income Transactions', '${income.length}', color: AppColors.income),
                      _SummaryRow('Expense Transactions', '${expense.length}', color: AppColors.expense),
                      _SummaryRow('Duplicates Found', '$duplicates', color: AppColors.warning),
                    ],
                  ),
                ),
                if (duplicates > 0) ...[
                  const SizedBox(height: AppSizes.lg),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$duplicates possible duplicate${duplicates == 1 ? '' : 's'} found',
                            style: AppTextStyles.titleMd),
                        const SizedBox(height: 4),
                        Text('These transactions look similar to ones already in your app.',
                            style: AppTextStyles.bodySm),
                        const SizedBox(height: AppSizes.md),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _skipDuplicates,
                          onChanged: (v) => setState(() => _skipDuplicates = v),
                          title: const Text('Skip duplicates'),
                          subtitle: Text(_skipDuplicates ? 'Duplicates will not be imported' : 'Duplicates will be imported anyway'),
                          activeThumbColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSizes.lg),
                Text('Transactions', style: AppTextStyles.headingSm),
                const SizedBox(height: AppSizes.sm),
                ...widget.parsedTransactions.map((t) => Card(
                      margin: const EdgeInsets.only(bottom: AppSizes.sm),
                      child: CheckboxListTile(
                        value: t.includeInImport,
                        onChanged: (v) => setState(() => t.includeInImport = v ?? true),
                        title: Text(t.description.isEmpty ? 'Transaction' : t.description),
                        subtitle: Text(
                            '${AppFormatters.date(t.date)} · ${t.category}${t.isDuplicate ? ' · Possible duplicate' : ''}'),
                        secondary: Text(
                          AppFormatters.amountSigned(t.amount, isIncome: t.type == TransactionType.income),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: t.type == TransactionType.income ? AppColors.income : AppColors.expense,
                          ),
                        ),
                        activeColor: AppColors.primary,
                      ),
                    )),
                const SizedBox(height: AppSizes.xxxl),
                AppButton(
                  label: _importing ? 'Importing…' : 'Confirm Import',
                  isLoading: _importing,
                  onPressed: _confirmImport,
                ),
              ],
            ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _SummaryRow(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMd),
          Text(value, style: AppTextStyles.titleMd.copyWith(color: color)),
        ],
      ),
    );
  }
}
