import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/di/providers.dart';
import '../../data/database/app_database.dart';

class AddSubscriptionScreen extends ConsumerStatefulWidget {
  final Subscription? existing;
  const AddSubscriptionScreen({super.key, this.existing});

  @override
  ConsumerState<AddSubscriptionScreen> createState() => _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState extends ConsumerState<AddSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  String _cycle = AppConstants.subscriptionCycles[1]; // Monthly
  DateTime _renewalDate = DateTime.now().add(const Duration(days: 7));
  bool _reminderEnabled = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameController.text = e.name;
      _priceController.text = e.price.toStringAsFixed(0);
      _cycle = e.cycle;
      _renewalDate = e.renewalDate;
      _reminderEnabled = e.reminderEnabled;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    await ref.read(subscriptionRepositoryProvider).addOrUpdate(
          id: widget.existing?.id,
          name: _nameController.text.trim(),
          price: double.parse(_priceController.text),
          renewalDate: _renewalDate,
          cycle: _cycle,
          reminderEnabled: _reminderEnabled,
        );
    if (!mounted) return;
    context.pop();
  }

  Future<void> _delete() async {
    await ref.read(subscriptionRepositoryProvider).deleteSubscription(widget.existing!.id);
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Add Subscription' : 'Edit Subscription'),
        actions: [
          if (widget.existing != null)
            IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: _delete),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.lg),
          children: [
            AppTextField(label: 'Name', hint: 'e.g. Netflix', controller: _nameController, validator: (v) => Validators.required(v, fieldName: 'Name')),
            const SizedBox(height: AppSizes.lg),
            AppTextField(
              label: 'Price',
              hint: '0.00',
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.amount,
            ),
            const SizedBox(height: AppSizes.lg),
            Text('Billing Cycle', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSizes.sm),
            Wrap(
              spacing: 8,
              children: AppConstants.subscriptionCycles
                  .map((c) => ChoiceChip(
                        label: Text(c),
                        selected: _cycle == c,
                        onSelected: (_) => setState(() => _cycle = c),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(color: _cycle == c ? Colors.white : AppColors.textPrimary),
                        showCheckmark: false,
                      ))
                  .toList(),
            ),
            const SizedBox(height: AppSizes.lg),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _renewalDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _renewalDate = picked);
              },
              child: AbsorbPointer(
                child: AppTextField(
                  label: 'Next Renewal Date',
                  controller: TextEditingController(text: AppFormatters.date(_renewalDate)),
                  suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _reminderEnabled,
              onChanged: (v) => setState(() => _reminderEnabled = v),
              title: const Text('Renewal reminder'),
              subtitle: const Text('Notify me before this renews'),
              activeThumbColor: AppColors.primary,
            ),
            const SizedBox(height: AppSizes.xxxl),
            AppButton(label: 'Save Subscription', isLoading: _isSaving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
