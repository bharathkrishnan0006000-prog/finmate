import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../database/daos/budgets_dao.dart';

class BudgetRepository {
  final BudgetsDao _dao;
  final _uuid = const Uuid();

  BudgetRepository(this._dao);

  Stream<List<Budget>> watchForMonth(DateTime month) => _dao.watchForMonth(month);
  Future<List<Budget>> forMonth(DateTime month) => _dao.forMonth(month);

  Future<void> setBudget({
    String? id,
    required String category,
    required double monthlyLimit,
    required DateTime month,
    bool notifyOnExceed = true,
  }) {
    final normalized = DateTime(month.year, month.month, 1);
    return _dao.upsert(BudgetsCompanion.insert(
      id: id ?? _uuid.v4(),
      category: category,
      monthlyLimit: monthlyLimit,
      month: normalized,
      notifyOnExceed: Value(notifyOnExceed),
    ));
  }

  Future<void> deleteBudget(String id) => _dao.deleteBudget(id);
}
