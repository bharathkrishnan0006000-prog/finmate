import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/category_icons.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/di/providers.dart';
import '../../data/database/app_database.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final Transaction? existing;
  const AddExpenseScreen({super.key, this.existing});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  String? _selectedCategory;
  String _paymentMethod = AppConstants.paymentMethods.first;
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  bool _isSaving = false;

  bool _repeatEnabled = false;
  final List<DateTime> _repeatDates = [];

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _amountController.text = e.amount.toStringAsFixed(0);
      _noteController.text = e.notes;
      _type = TransactionType.values.byName(e.type);
      _selectedCategory = e.category;
      _paymentMethod = e.paymentMethod;
      _date = e.date;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _addRepeatDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final alreadyAdded = _repeatDates.any((d) =>
          d.year == picked.year && d.month == picked.month && d.day == picked.day);
      if (!alreadyAdded) setState(() => _repeatDates.add(picked));
    }
  }

  Future<void> _addWeekdayRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: DateTime.now(),
        end: DateTime.now().add(const Duration(days: 7)),
      ),
      helpText: 'Select date range — weekdays only will be added',
    );
    if (range == null) return;
    setState(() {
      for (var d = range.start;
          !d.isAfter(range.end);
          d = d.add(const Duration(days: 1))) {
        if (d.weekday >= DateTime.monday && d.weekday <= DateTime.friday) {
          final exists = _repeatDates.any(
              (x) => x.year == d.year && x.month == d.month && x.day == d.day);
          if (!exists) _repeatDates.add(d);
        }
      }
      _repeatDates.sort();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }
    if (_repeatEnabled && _repeatDates.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Add at least one date to repeat on')));
      return;
    }

    setState(() => _isSaving = true);
    final amount = double.parse(_amountController.text.replaceAll(',', ''));
    final repo = ref.read(transactionRepositoryProvider);
    final timeStr = _time.format(context);

    if (_isEditing) {
      final updated = widget.existing!.copyWith(
        amount: amount,
        type: _type.name,
        category: _selectedCategory!,
        paymentMethod: _paymentMethod,
        date: _date,
        time: timeStr,
        notes: _noteController.text.trim(),
        title: _selectedCategory!,
      );
      final result = await repo.updateTransaction(updated);
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (result.isSuccess) {
        context.pop();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result.failure!.message)));
      }
      return;
    }

    if (_repeatEnabled) {
      final result = await repo.addRepeatingTransaction(
        title: _selectedCategory!,
        description: _noteController.text.trim(),
        amount: amount,
        type: _type,
        category: _selectedCategory!,
        paymentMethod: _paymentMethod,
        dates: _repeatDates,
        notes: _noteController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added ${result.data} scheduled entries')));
        context.pop();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result.failure!.message)));
      }
      return;
    }

    final result = await repo.addTransaction(
      title: _selectedCategory!,
      description: _noteController.text.trim(),
      amount: amount,
      type: _type,
      category: _selectedCategory!,
      paymentMethod: _paymentMethod,
      date: _date,
      time: timeStr,
      notes: _noteController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (result.isSuccess) {
      context.pop();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.failure!.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(_isEditing ? 'Edit Transaction' : 'Add Expense')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.md, AppSizes.lg, AppSizes.xxxl),
          children: [
            _TypeToggle(
              type: _type,
              onChanged: (t) => setState(() {
                _type = t;
                _selectedCategory = null;
              }),
            ),
            const SizedBox(height: AppSizes.xl),
            AppTextField(
              label: 'Amount',
              hint: '0.00',
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: Validators.amount,
              prefixIcon: const Padding(
                padding: EdgeInsets.all(14),
                child: Text('₹', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
              ),
            ),
            const SizedBox(height: AppSizes.xl),
            _CategoryTemplates(
              type: _type,
              selected: _selectedCategory,
              onSelected: (c) => setState(() => _selectedCategory = c),
            ),
            const SizedBox(height: AppSizes.xl),
            AppTextField(
              label: _selectedCategory == null
                  ? 'Note (optional)'
                  : 'What did you spend on for $_selectedCategory?',
              hint: _selectedCategory == null
                  ? 'Add a note'
                  : 'e.g. Pizza and a coke',
              controller: _noteController,
              maxLines: 2,
            ),
            const SizedBox(height: AppSizes.xl),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: AbsorbPointer(
                      child: AppTextField(
                        label: 'Date',
                        controller: TextEditingController(text: AppFormatters.date(_date)),
                        suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickTime,
                    child: AbsorbPointer(
                      child: AppTextField(
                        label: 'Time',
                        controller: TextEditingController(text: _time.format(context)),
                        suffixIcon: const Icon(Icons.access_time_rounded, size: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.xl),
            Text('Payment Method', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSizes.sm),
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              items: AppConstants.paymentMethods
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => setState(() => _paymentMethod = v!),
            ),
            if (!_isEditing) ...[
              const SizedBox(height: AppSizes.xl),
              _RepeatSection(
                enabled: _repeatEnabled,
                dates: _repeatDates,
                onToggle: (v) => setState(() => _repeatEnabled = v),
                onAddDate: _addRepeatDate,
                onAddWeekdayRange: _addWeekdayRange,
                onRemoveDate: (d) => setState(() => _repeatDates.remove(d)),
              ),
            ],
            const SizedBox(height: AppSizes.xxxl),
            AppButton(
              label: _isEditing
                  ? 'Save Changes'
                  : (_repeatEnabled ? 'Save Scheduled Expenses' : 'Save Expense'),
              isLoading: _isSaving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final TransactionType type;
  final ValueChanged<TransactionType> onChanged;
  const _TypeToggle({required this.type, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.scaffoldGrey,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        children: [
          _ToggleButton(
            label: 'Expense',
            selected: type == TransactionType.expense,
            onTap: () => onChanged(TransactionType.expense),
          ),
          _ToggleButton(
            label: 'Income',
            selected: type == TransactionType.income,
            onTap: () => onChanged(TransactionType.income),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
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
            style: AppTextStyles.titleMd.copyWith(
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryTemplates extends ConsumerWidget {
  final TransactionType type;
  final String? selected;
  final ValueChanged<String> onSelected;

  const _CategoryTemplates({required this.type, required this.selected, required this.onSelected});

  Future<void> _addCustomCategory(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Pet Care'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await ref.read(categoryRepositoryProvider).addCategory(name: name, type: type);
      onSelected(name);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSizes.sm),
        StreamBuilder<List<Category>>(
          stream: ref.watch(categoryRepositoryProvider).watchByType(type),
          builder: (context, snapshot) {
            final categories = snapshot.data ?? [];
            return Wrap(
              spacing: AppSizes.sm,
              runSpacing: AppSizes.sm,
              children: [
                ...categories.map((c) => _TemplateChip(
                      label: c.name,
                      icon: CategoryIcons.iconFor(c.name),
                      selected: selected == c.name,
                      onTap: () => onSelected(c.name),
                    )),
                ActionChip(
                  avatar: const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                  label: const Text('Add custom'),
                  onPressed: () => _addCustomCategory(context, ref),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _TemplateChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TemplateChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: Icon(icon, size: 16, color: selected ? Colors.white : AppColors.primary),
      label: Text(label),
      labelStyle: AppTextStyles.bodySm.copyWith(
        color: selected ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.scaffoldGrey,
      showCheckmark: false,
    );
  }
}

class _RepeatSection extends StatelessWidget {
  final bool enabled;
  final List<DateTime> dates;
  final ValueChanged<bool> onToggle;
  final VoidCallback onAddDate;
  final VoidCallback onAddWeekdayRange;
  final ValueChanged<DateTime> onRemoveDate;

  const _RepeatSection({
    required this.enabled,
    required this.dates,
    required this.onToggle,
    required this.onAddDate,
    required this.onAddWeekdayRange,
    required this.onRemoveDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.scaffoldGrey,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Repeat on multiple dates', style: AppTextStyles.titleMd),
                    Text('e.g. ₹10 for milk on every weekday',
                        style: AppTextStyles.bodySm),
                  ],
                ),
              ),
              Switch(value: enabled, onChanged: onToggle, activeThumbColor: AppColors.primary),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: AppSizes.md),
            Wrap(
              spacing: AppSizes.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: onAddDate,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add date'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                ),
                OutlinedButton.icon(
                  onPressed: onAddWeekdayRange,
                  icon: const Icon(Icons.date_range_rounded, size: 16),
                  label: const Text('Weekdays in range'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                ),
              ],
            ),
            if (dates.isNotEmpty) ...[
              const SizedBox(height: AppSizes.md),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: dates
                    .map((d) => Chip(
                          label: Text(AppFormatters.dateShort(d)),
                          onDeleted: () => onRemoveDate(d),
                          deleteIconColor: AppColors.textSecondary,
                        ))
                    .toList(),
              ),
              const SizedBox(height: AppSizes.xs),
              Text('${dates.length} date${dates.length == 1 ? '' : 's'} selected',
                  style: AppTextStyles.bodySm),
            ],
          ],
        ],
      ),
    );
  }
}
