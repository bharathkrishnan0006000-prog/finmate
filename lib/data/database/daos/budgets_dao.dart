import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/budgets_table.dart';

part 'budgets_dao.g.dart';

@DriftAccessor(tables: [Budgets])
class BudgetsDao extends DatabaseAccessor<AppDatabase> with _$BudgetsDaoMixin {
  BudgetsDao(super.db);

  Future<void> upsert(BudgetsCompanion entry) =>
      into(budgets).insertOnConflictUpdate(entry);

  Future<void> deleteBudget(String id) => (update(budgets)
        ..where((b) => b.id.equals(id)))
      .write(const BudgetsCompanion(isDeleted: Value(true)));

  Stream<List<Budget>> watchForMonth(DateTime month) {
    final normalized = DateTime(month.year, month.month, 1);
    return (select(budgets)
          ..where((b) =>
              b.month.equals(normalized) & b.isDeleted.equals(false)))
        .watch();
  }

  Future<List<Budget>> forMonth(DateTime month) {
    final normalized = DateTime(month.year, month.month, 1);
    return (select(budgets)
          ..where((b) =>
              b.month.equals(normalized) & b.isDeleted.equals(false)))
        .get();
  }
}
