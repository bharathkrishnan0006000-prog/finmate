import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/savings_goals_table.dart';

part 'savings_goals_dao.g.dart';

@DriftAccessor(tables: [SavingsGoals])
class SavingsGoalsDao extends DatabaseAccessor<AppDatabase>
    with _$SavingsGoalsDaoMixin {
  SavingsGoalsDao(super.db);

  Future<void> upsert(SavingsGoalsCompanion entry) =>
      into(savingsGoals).insertOnConflictUpdate(entry);

  Future<void> deleteGoal(String id) => (update(savingsGoals)
        ..where((g) => g.id.equals(id)))
      .write(const SavingsGoalsCompanion(isDeleted: Value(true)));

  Stream<List<SavingsGoal>> watchAll() {
    return (select(savingsGoals)
          ..where((g) => g.isDeleted.equals(false))
          ..orderBy([(g) => OrderingTerm.desc(g.createdAt)]))
        .watch();
  }

  Future<void> addContribution(String id, double amount) async {
    final goal = await (select(savingsGoals)..where((g) => g.id.equals(id)))
        .getSingle();
    await (update(savingsGoals)..where((g) => g.id.equals(id))).write(
      SavingsGoalsCompanion(savedAmount: Value(goal.savedAmount + amount)),
    );
  }
}
