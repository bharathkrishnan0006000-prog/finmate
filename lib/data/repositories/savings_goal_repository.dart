import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../database/daos/savings_goals_dao.dart';

class SavingsGoalRepository {
  final SavingsGoalsDao _dao;
  final _uuid = const Uuid();

  SavingsGoalRepository(this._dao);

  Stream<List<SavingsGoal>> watchAll() => _dao.watchAll();

  Future<void> addOrUpdate({
    String? id,
    required String title,
    required double targetAmount,
    double savedAmount = 0,
    DateTime? targetDate,
    String iconKey = 'savings',
    int? colorValue,
  }) {
    return _dao.upsert(SavingsGoalsCompanion.insert(
      id: id ?? _uuid.v4(),
      title: title,
      targetAmount: targetAmount,
      savedAmount: Value(savedAmount),
      targetDate: Value(targetDate),
      iconKey: Value(iconKey),
      colorValue: Value(colorValue ?? 0xFF6FCF97),
    ));
  }

  Future<void> contribute(String id, double amount) => _dao.addContribution(id, amount);
  Future<void> deleteGoal(String id) => _dao.deleteGoal(id);
}
