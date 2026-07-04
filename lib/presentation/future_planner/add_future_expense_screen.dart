import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/di/providers.dart';

class AddFutureExpenseScreen extends ConsumerStatefulWidget {
  const AddFutureExpenseScreen({super.key});

  @override
  ConsumerState<AddFutureExpenseScreen> createState() => _AddFutureExpenseScreenState();
}

class _AddFutureExpenseScreenState extends ConsumerState<AddFutureExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 14));
  bool _isSaving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    await ref.read(futureExpenseRepositoryProvider).addPlan(
          title: _titleController.text.trim(),
          amount: double.parse(_amountController.text),
          plannedDate: _date,
        );
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Future Expense')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.lg),
          children: [
            AppTextField(
              label: 'Title',
              hint: 'e.g. PS5 Controller',
              controller: _titleController,
              validator: (v) => Validators.required(v, fieldName: 'Title'),
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
                  firstDate: DateTime.now(),
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
            const SizedBox(height: AppSizes.xxxl),
            AppButton(label: 'Add to Planner', isLoading: _isSaving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
