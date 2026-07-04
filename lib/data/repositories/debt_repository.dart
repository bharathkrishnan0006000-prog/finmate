import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../database/daos/debts_dao.dart';
import 'transaction_repository.dart';
import '../../core/constants/app_constants.dart';
import '../../core/error/failures.dart';

enum DebtType { borrowed, lent }

class DebtRepository {
  final DebtsDao _dao;
  final TransactionRepository _transactionRepository;
  final _uuid = const Uuid();

  DebtRepository(this._dao, this._transactionRepository);

  Stream<List<Debt>> watchAll() => _dao.watchAll();
  Stream<List<Debt>> watchByType(DebtType type) => _dao.watchByType(type.name);
  Future<double> totalPending(DebtType type) => _dao.totalPendingByType(type.name);

  Future<Result<void>> addDebt({
    required String personName,
    required double amount,
    required DebtType type,
    required DateTime date,
    DateTime? dueDate,
    String notes = '',
  }) async {
    if (amount <= 0) {
      return Result.error(
          const ValidationFailure('Negative or zero amounts are not allowed'));
    }
    if (personName.trim().isEmpty) {
      return Result.error(const ValidationFailure('Person name is required'));
    }
    await _dao.upsert(DebtsCompanion.insert(
      id: _uuid.v4(),
      personName: personName.trim(),
      amount: amount,
      type: type.name,
      date: date,
      dueDate: Value(dueDate),
      notes: Value(notes),
    ));
    return Result.success(null);
  }

  Future<void> deleteDebt(String id) => _dao.deleteDebt(id);

  /// Marks a debt settled. If [recordAsTransaction] is true, also creates
  /// a matching Transaction:
  /// - Settling a "borrowed" debt (you paid it back) -> Expense.
  /// - Settling a "lent" debt (you got repaid) -> Income.
  Future<void> settleDebt(Debt debt, {bool recordAsTransaction = false}) async {
    String? txnId;
    if (recordAsTransaction) {
      final isBorrowed = debt.type == DebtType.borrowed.name;
      final result = await _transactionRepository.addTransaction(
        title: isBorrowed
            ? 'Repaid ${debt.personName}'
            : 'Received from ${debt.personName}',
        amount: debt.amount,
        type: isBorrowed ? TransactionType.expense : TransactionType.income,
        category: 'Others',
        date: DateTime.now(),
        notes: 'Settled debt: ${debt.notes}',
      );
      if (result.isSuccess) txnId = result.data;
    }
    await _dao.markSettled(debt.id, DateTime.now(), transactionId: txnId);
  }
}
