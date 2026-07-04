import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/debts_table.dart';

part 'debts_dao.g.dart';

@DriftAccessor(tables: [Debts])
class DebtsDao extends DatabaseAccessor<AppDatabase> with _$DebtsDaoMixin {
  DebtsDao(super.db);

  Future<void> upsert(DebtsCompanion entry) =>
      into(debts).insertOnConflictUpdate(entry);

  Future<void> deleteDebt(String id) =>
      (update(debts)..where((d) => d.id.equals(id)))
          .write(const DebtsCompanion(isDeleted: Value(true)));

  Future<void> markSettled(String id, DateTime settledDate, {String? transactionId}) {
    return (update(debts)..where((d) => d.id.equals(id))).write(
      DebtsCompanion(
        status: const Value('settled'),
        settledDate: Value(settledDate),
        settledTransactionId: Value(transactionId),
      ),
    );
  }

  Stream<List<Debt>> watchAll() {
    return (select(debts)
          ..where((d) => d.isDeleted.equals(false))
          ..orderBy([(d) => OrderingTerm.desc(d.date)]))
        .watch();
  }

  Stream<List<Debt>> watchByType(String type) {
    return (select(debts)
          ..where((d) => d.isDeleted.equals(false) & d.type.equals(type))
          ..orderBy([(d) => OrderingTerm.desc(d.date)]))
        .watch();
  }

  Future<double> totalPendingByType(String type) async {
    final rows = await (select(debts)
          ..where((d) =>
              d.isDeleted.equals(false) &
              d.type.equals(type) &
              d.status.equals('pending')))
        .get();
    return rows.fold<double>(0, (s, d) => s + d.amount);
  }
}
