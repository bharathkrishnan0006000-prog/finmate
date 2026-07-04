import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/di/providers.dart';
import '../../data/repositories/debt_repository.dart';

class AddDebtScreen extends ConsumerStatefulWidget {
  final DebtType initialType;
  const AddDebtScreen({super.key, this.initialType = DebtType.borrowed});

  @override
  ConsumerState<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends ConsumerState<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  late DebtType _type;
  DateTime _date = DateTime.now();
  DateTime? _dueDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final result = await ref.read(debtRepositoryProvider).addDebt(
          personName: _nameController.text.trim(),
          amount: double.parse(_amountController.text),
          type: _type,
          date: _date,
          dueDate: _dueDate,
          notes: _notesController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (result.isSuccess) {
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.failure!.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Borrow / Lend')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.lg),
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.scaffoldGrey,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _TypeButton(
                      label: 'I Borrowed',
                      selected: _type == DebtType.borrowed,
                      onTap: () => setState(() => _type = DebtType.borrowed),
                    ),
                  ),
                  Expanded(
                    child: _TypeButton(
                      label: 'I Lent',
                      selected: _type == DebtType.lent,
                      onTap: () => setState(() => _type = DebtType.lent),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.xl),
            AppTextField(
              label: 'Person',
              hint: 'e.g. Rahul',
              controller: _nameController,
              validator: (v) => Validators.required(v, fieldName: 'Person name'),
            ),
            const SizedBox(height: AppSizes.lg),
            AppTextField(
              label: 'Amount',
              hint: '0.00',
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.amount,
            ),
            const SizedBox(height: AppSizes.lg),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2015),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: AbsorbPointer(
                child: AppTextField(
                  label: 'Date',
                  controller: TextEditingController(text: AppFormatters.date(_date)),
                  suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime(2015),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
              child: AbsorbPointer(
                child: AppTextField(
                  label: 'Due Date (optional)',
                  controller: TextEditingController(text: _dueDate == null ? '' : AppFormatters.date(_dueDate!)),
                  hint: 'Not set',
                  suffixIcon: const Icon(Icons.event_rounded, size: 18),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            AppTextField(label: 'Notes (optional)', controller: _notesController, maxLines: 2),
            const SizedBox(height: AppSizes.xxxl),
            AppButton(label: 'Save Entry', isLoading: _isSaving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TypeButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
