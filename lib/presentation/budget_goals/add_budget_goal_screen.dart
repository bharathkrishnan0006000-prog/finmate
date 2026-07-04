import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/di/providers.dart';
import '../../data/database/app_database.dart';

class AddBudgetGoalScreen extends ConsumerStatefulWidget {
  final Budget? existing;
  const AddBudgetGoalScreen({super.key, this.existing});

  @override
  ConsumerState<AddBudgetGoalScreen> createState() => _AddBudgetGoalScreenState();
}

class _AddBudgetGoalScreenState extends ConsumerState<AddBudgetGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _limitController = TextEditingController();
  String? _category;
  bool _notify = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _category = e.category;
      _limitController.text = e.monthlyLimit.toStringAsFixed(0);
      _notify = e.notifyOnExceed;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _category == null) return;
    setState(() => _isSaving = true);
    await ref.read(budgetRepositoryProvider).setBudget(
          id: widget.existing?.id,
          category: _category!,
          monthlyLimit: double.parse(_limitController.text),
          month: DateTime.now(),
          notifyOnExceed: _notify,
        );
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Add Budget Goal' : 'Edit Budget Goal')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.lg),
          children: [
            Text('Category', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSizes.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.defaultExpenseCategories
                  .map((c) => ChoiceChip(
                        label: Text(c),
                        selected: _category == c,
                        onSelected: (_) => setState(() => _category = c),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(color: _category == c ? Colors.white : AppColors.textPrimary),
                        showCheckmark: false,
                      ))
                  .toList(),
            ),
            const SizedBox(height: AppSizes.xl),
            AppTextField(
              label: 'Monthly Limit',
              hint: '0.00',
              controller: _limitController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.amount,
            ),
            const SizedBox(height: AppSizes.lg),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _notify,
              onChanged: (v) => setState(() => _notify = v),
              title: const Text('Notify when exceeded'),
              activeThumbColor: AppColors.primary,
            ),
            const SizedBox(height: AppSizes.xxxl),
            AppButton(label: 'Save Budget Goal', isLoading: _isSaving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
