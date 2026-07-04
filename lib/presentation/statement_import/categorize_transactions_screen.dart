import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/category_icons.dart';
import '../../core/routes/route_names.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/di/providers.dart';
import '../../data/models/parsed_transaction.dart';
import '../../core/constants/app_constants.dart';

class CategorizeTransactionsScreen extends ConsumerStatefulWidget {
  final List<ParsedTransaction> parsedTransactions;
  const CategorizeTransactionsScreen({super.key, required this.parsedTransactions});

  @override
  ConsumerState<CategorizeTransactionsScreen> createState() => _CategorizeTransactionsScreenState();
}

class _CategorizeTransactionsScreenState extends ConsumerState<CategorizeTransactionsScreen> {
  @override
  void initState() {
    super.initState();
    // Best-effort keyword-based suggestion for each row (rule-based "AI",
    // only runs here on explicit user action — opening this screen after
    // choosing to import a statement).
    final ai = ref.read(aiInsightServiceProvider);
    for (final t in widget.parsedTransactions) {
      t.category = ai.suggestCategory(t.description,
          fallback: t.type == TransactionType.income ? 'Salary' : 'Others');
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.parsedTransactions.first.type == TransactionType.income
        ? AppConstants.defaultIncomeCategories
        : AppConstants.defaultExpenseCategories;

    return Scaffold(
      backgroundColor: AppColors.scaffoldGrey,
      appBar: AppBar(title: const Text('Categorize Transactions')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSizes.lg),
              itemCount: widget.parsedTransactions.length,
              itemBuilder: (context, index) {
                final t = widget.parsedTransactions[index];
                final list = t.type == TransactionType.income
                    ? AppConstants.defaultIncomeCategories
                    : AppConstants.defaultExpenseCategories;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.md),
                  child: AppCard(
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
                                  Text(t.description.isEmpty ? 'Transaction' : t.description,
                                      style: AppTextStyles.titleMd),
                                  Text(AppFormatters.date(t.date), style: AppTextStyles.bodySm),
                                ],
                              ),
                            ),
                            Text(
                              AppFormatters.amountSigned(t.amount, isIncome: t.type == TransactionType.income),
                              style: AppTextStyles.titleMd.copyWith(
                                color: t.type == TransactionType.income ? AppColors.income : AppColors.expense,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.md),
                        DropdownButtonFormField<String>(
                          initialValue: list.contains(t.category) ? t.category : list.last,
                          decoration: const InputDecoration(labelText: 'Category'),
                          items: list
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Row(
                                      children: [
                                        Icon(CategoryIcons.iconFor(c), size: 16, color: AppColors.primary),
                                        const SizedBox(width: 8),
                                        Text(c),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => t.category = v!),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: AppButton(
                label: 'Continue (${widget.parsedTransactions.length})',
                onPressed: () => context.push(RouteNames.importReview, extra: widget.parsedTransactions),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
