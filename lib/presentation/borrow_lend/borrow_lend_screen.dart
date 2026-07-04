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
import '../../data/repositories/debt_repository.dart';

class BorrowLendScreen extends ConsumerStatefulWidget {
  const BorrowLendScreen({super.key});

  @override
  ConsumerState<BorrowLendScreen> createState() => _BorrowLendScreenState();
}

class _BorrowLendScreenState extends ConsumerState<BorrowLendScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(debtRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldGrey,
      appBar: AppBar(
        title: const Text('Borrow & Lend'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'I Borrowed'),
            Tab(text: 'I Lent'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.addDebt, extra: _tabController.index == 0 ? DebtType.borrowed : DebtType.lent),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Entry', style: TextStyle(color: Colors.white)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DebtList(type: DebtType.borrowed, repo: repo),
          _DebtList(type: DebtType.lent, repo: repo),
        ],
      ),
    );
  }
}

class _DebtList extends StatelessWidget {
  final DebtType type;
  final DebtRepository repo;
  const _DebtList({required this.type, required this.repo});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Debt>>(
      stream: repo.watchByType(type),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        final pending = items.where((d) => d.status == 'pending').toList();
        final settled = items.where((d) => d.status == 'settled').toList();
        final totalPending = pending.fold<double>(0, (s, d) => s + d.amount);

        if (items.isEmpty) {
          return EmptyState(
            icon: Icons.handshake_outlined,
            title: type == DebtType.borrowed ? 'Nothing borrowed' : 'Nothing lent',
            message: type == DebtType.borrowed
                ? 'Track money you owe to friends or family.'
                : 'Track money others owe back to you.',
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.lg, AppSizes.lg, 100),
          children: [
            AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    type == DebtType.borrowed ? 'Total You Owe' : 'Total Owed to You',
                    style: AppTextStyles.bodyMd,
                  ),
                  Text(
                    AppFormatters.amount(totalPending),
                    style: AppTextStyles.headingMd.copyWith(
                      color: type == DebtType.borrowed ? AppColors.error : AppColors.income,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            if (pending.isNotEmpty) ...[
              Text('Pending', style: AppTextStyles.headingSm),
              const SizedBox(height: AppSizes.sm),
              ...pending.map((d) => _DebtTile(debt: d, repo: repo)),
            ],
            if (settled.isNotEmpty) ...[
              const SizedBox(height: AppSizes.lg),
              Text('Settled', style: AppTextStyles.headingSm),
              const SizedBox(height: AppSizes.sm),
              ...settled.map((d) => _DebtTile(debt: d, repo: repo)),
            ],
          ],
        );
      },
    );
  }
}

class _DebtTile extends StatelessWidget {
  final Debt debt;
  final DebtRepository repo;
  const _DebtTile({required this.debt, required this.repo});

  @override
  Widget build(BuildContext context) {
    final isSettled = debt.status == 'settled';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: AppCard(
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.accentSoft,
              child: Text(debt.personName.isNotEmpty ? debt.personName[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(debt.personName, style: AppTextStyles.titleMd),
                  Text(
                    isSettled
                        ? 'Settled ${AppFormatters.date(debt.settledDate!)}'
                        : (debt.dueDate != null ? 'Due ${AppFormatters.date(debt.dueDate!)}' : AppFormatters.date(debt.date)),
                    style: AppTextStyles.bodySm,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(AppFormatters.amount(debt.amount), style: AppTextStyles.titleMd),
                if (!isSettled)
                  TextButton(
                    onPressed: () => _showSettleDialog(context, repo, debt),
                    child: const Text('Settle'),
                  )
                else
                  const StatusPill(label: 'Settled', color: AppColors.income),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSettleDialog(BuildContext context, DebtRepository repo, Debt debt) async {
    bool recordTransaction = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Mark as settled?'),
          content: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: recordTransaction,
            onChanged: (v) => setState(() => recordTransaction = v ?? true),
            title: Text(debt.type == 'borrowed'
                ? 'Also record as an expense (repayment)'
                : 'Also record as income (received)'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirm')),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      await repo.settleDebt(debt, recordAsTransaction: recordTransaction);
    }
  }
}
