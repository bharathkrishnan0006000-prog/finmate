import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/future_expenses_table.dart';

part 'future_expenses_dao.g.dart';

@DriftAccessor(tables: [FutureExpenses])
class FutureExpensesDao extends DatabaseAccessor<AppDatabase>
    with _$FutureExpensesDaoMixin {
  FutureExpensesDao(super.db);

  Future<void> upsert(FutureExpensesCompanion entry) =>
      into(futureExpenses).insertOnConflictUpdate(entry);

  Future<void> deletePlan(String id) => (update(futureExpenses)
        ..where((f) => f.id.equals(id)))
      .write(const FutureExpensesCompanion(isDeleted: Value(true)));

  Stream<List<FutureExpense>> watchAll() {
    return (select(futureExpenses)
          ..where((f) =>
              f.isDeleted.equals(false) & f.status.equals('planned'))
          ..orderBy([(f) => OrderingTerm.asc(f.plannedDate)]))
        .watch();
  }
}
