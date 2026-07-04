import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/category_icons.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/di/providers.dart';
import '../../data/database/app_database.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends ConsumerState<CategoryManagementScreen>
    with SingleTickerProviderStateMixin {
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

  Future<void> _addCategory(TransactionType type) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Category name')),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: const Text('Add')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await ref.read(categoryRepositoryProvider).addCategory(name: name, type: type);
    }
  }

  Future<void> _confirmDelete(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text('"${category.name}" will no longer appear as a template. Existing transactions keep this category name.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(categoryRepositoryProvider).deleteCategory(category.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldGrey,
      appBar: AppBar(
        title: const Text('Manage Categories'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'Expense'), Tab(text: 'Income')],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _addCategory(
            _tabController.index == 0 ? TransactionType.expense : TransactionType.income),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CategoryList(type: TransactionType.expense, onDelete: _confirmDelete),
          _CategoryList(type: TransactionType.income, onDelete: _confirmDelete),
        ],
      ),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  final TransactionType type;
  final ValueChanged<Category> onDelete;
  const _CategoryList({required this.type, required this.onDelete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<Category>>(
      stream: ref.watch(categoryRepositoryProvider).watchByType(type),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.category_outlined,
            title: 'No categories yet',
            message: 'Tap the + button to add one.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSizes.lg),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
          itemBuilder: (context, i) {
            final c = items[i];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: ListTile(
                leading: CategoryIconBadge(
                  icon: CategoryIcons.iconFor(c.name),
                  color: CategoryIcons.colorFromValue(c.colorValue),
                  size: 40,
                ),
                title: Text(c.name, style: AppTextStyles.titleMd),
                subtitle: c.isDefault ? const Text('Default') : const Text('Custom'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  onPressed: () => onDelete(c),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
