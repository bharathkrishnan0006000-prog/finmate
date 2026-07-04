import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../database/daos/categories_dao.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

class CategoryRepository {
  final CategoriesDao _dao;
  final _uuid = const Uuid();

  CategoryRepository(this._dao);

  Stream<List<Category>> watchByType(TransactionType type) =>
      _dao.watchByType(type.name);

  Future<void> addCategory({
    required String name,
    required TransactionType type,
    String iconKey = 'category',
    int? colorValue,
  }) {
    return _dao.insertCategory(CategoriesCompanion.insert(
      id: _uuid.v4(),
      name: name,
      type: type.name,
      iconKey: Value(iconKey),
      colorValue: colorValue ??
          AppColors
              .categoryPalette[name.hashCode % AppColors.categoryPalette.length]
              .value,
    ));
  }

  Future<void> deleteCategory(String id) => _dao.deleteCategory(id);

  /// Seeds the default category list on first launch (spec: default
  /// expense/income categories).
  Future<void> seedDefaultsIfEmpty() async {
    final existing = await _dao.count();
    if (existing > 0) return;

    final entries = <CategoriesCompanion>[];
    for (final name in AppConstants.defaultExpenseCategories) {
      entries.add(CategoriesCompanion.insert(
        id: _uuid.v4(),
        name: name,
        type: TransactionType.expense.name,
        isDefault: const Value(true),
        colorValue:
            AppColors.categoryPalette[entries.length % AppColors.categoryPalette.length]
                .value,
      ));
    }
    for (final name in AppConstants.defaultIncomeCategories) {
      entries.add(CategoriesCompanion.insert(
        id: _uuid.v4(),
        name: name,
        type: TransactionType.income.name,
        isDefault: const Value(true),
        colorValue:
            AppColors.categoryPalette[entries.length % AppColors.categoryPalette.length]
                .value,
      ));
    }
    await _dao.insertBatch(entries);
  }
}
