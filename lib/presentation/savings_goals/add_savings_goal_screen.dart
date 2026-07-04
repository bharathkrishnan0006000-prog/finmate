import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/di/providers.dart';
import '../../data/database/app_database.dart';

class AddSavingsGoalScreen extends ConsumerStatefulWidget {
  final SavingsGoal? existing;
  const AddSavingsGoalScreen({super.key, this.existing});

  @override
  ConsumerState<AddSavingsGoalScreen> createState() => _AddSavingsGoalScreenState();
}

class _AddSavingsGoalScreenState extends ConsumerState<AddSavingsGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();
  final _contributionController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleController.text = e.title;
      _targetController.text = e.targetAmount.toStringAsFixed(0);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    await ref.read(savingsGoalRepositoryProvider).addOrUpdate(
          id: widget.existing?.id,
          title: _titleController.text.trim(),
          targetAmount: double.parse(_targetController.text),
          savedAmount: widget.existing?.savedAmount ?? 0,
        );
    if (!mounted) return;
    context.pop();
  }

  Future<void> _addContribution() async {
    final amount = double.tryParse(_contributionController.text);
    if (amount == null || amount <= 0 || widget.existing == null) return;
    await ref.read(savingsGoalRepositoryProvider).contribute(widget.existing!.id, amount);
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Add Savings Goal' : 'Edit Savings Goal')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.lg),
          children: [
            AppTextField(
              label: 'Goal Title',
              hint: 'e.g. Laptop',
              controller: _titleController,
              validator: (v) => Validators.required(v, fieldName: 'Title'),
            ),
            const SizedBox(height: AppSizes.lg),
            AppTextField(
              label: 'Target Amount',
              hint: '0.00',
              controller: _targetController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.amount,
            ),
            const SizedBox(height: AppSizes.xxxl),
            AppButton(label: 'Save Goal', isLoading: _isSaving, onPressed: _save),
            if (widget.existing != null) ...[
              const SizedBox(height: AppSizes.xxl),
              const Divider(),
              const SizedBox(height: AppSizes.lg),
              AppTextField(
                label: 'Add Contribution',
                hint: '0.00',
                controller: _contributionController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: AppSizes.md),
              AppOutlinedButton(label: 'Add to Savings', onPressed: _addContribution),
            ],
          ],
        ),
      ),
    );
  }
}
