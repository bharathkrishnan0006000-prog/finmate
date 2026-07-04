import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart' show sha1;
import 'dart:convert';

import '../database/app_database.dart';
import '../database/daos/transactions_dao.dart';
import '../../core/constants/app_constants.dart';
import '../../core/error/failures.dart';

/// Repository sits between the DAO (raw SQL/Drift) and the presentation
/// layer. It owns validation and derived values (dedupe hash) so no UI
/// widget ever talks to the database directly — that's the Repository
/// Pattern requirement from the spec.
class TransactionRepository {
  final TransactionsDao _dao;
  final _uuid = const Uuid();

  TransactionRepository(this._dao);

  String _dedupeHash({
    required DateTime date,
    required double amount,
    required String description,
    required TransactionType type,
  }) {
    final raw =
        '${date.year}-${date.month}-${date.day}|${amount.toStringAsFixed(2)}|${description.trim().toLowerCase()}|${type.name}';
    return sha1.convert(utf8.encode(raw)).toString();
  }

  Future<Result<String>> addTransaction({
    required String title,
    String description = '',
    required double amount,
    required TransactionType type,
    required String category,
    String paymentMethod = 'Cash',
    required DateTime date,
    String time = '',
    TransactionSource source = TransactionSource.manual,
    String merchant = '',
    String bank = '',
    String referenceNumber = '',
    String tags = '',
    String notes = '',
  }) async {
    if (amount <= 0) {
      return Result.error(
          const ValidationFailure('Negative or zero amounts are not allowed'));
    }
    if (category.trim().isEmpty) {
      return Result.error(const ValidationFailure('Category is required'));
    }

    final id = _uuid.v4();
    final hash = _dedupeHash(
        date: date, amount: amount, description: description.isNotEmpty ? description : title, type: type);

    try {
      await _dao.insertTransaction(TransactionsCompanion.insert(
        id: id,
        title: title,
        description: Value(description),
        amount: amount,
        type: type.name,
        category: category,
        paymentMethod: Value(paymentMethod),
        date: date,
        time: Value(time),
        source: Value(source.name),
        merchant: Value(merchant),
        bank: Value(bank),
        referenceNumber: Value(referenceNumber),
        tags: Value(tags),
        notes: Value(notes),
        dedupeHash: Value(hash),
      ));
      return Result.success(id);
    } catch (e) {
      return Result.error(DatabaseFailure('Failed to save transaction: $e'));
    }
  }

  Future<Result<void>> updateTransaction(Transaction txn) async {
    if (txn.amount <= 0) {
      return Result.error(
          const ValidationFailure('Negative or zero amounts are not allowed'));
    }
    try {
      await _dao.updateTransaction(txn.toCompanion(true));
      return Result.success(null);
    } catch (e) {
      return Result.error(DatabaseFailure('Failed to update transaction: $e'));
    }
  }

  Future<Result<String>> duplicateTransaction(Transaction txn) async {
    return addTransaction(
      title: '${txn.title} (Copy)',
      description: txn.description,
      amount: txn.amount,
      type: TransactionType.values.byName(txn.type),
      category: txn.category,
      paymentMethod: txn.paymentMethod,
      date: txn.date,
      time: txn.time,
      merchant: txn.merchant,
      bank: txn.bank,
      tags: txn.tags,
      notes: txn.notes,
    );
  }

  Future<void> deleteTransaction(String id) => _dao.softDelete(id);
  Future<void> undoDelete(String id) => _dao.restore(id);

  Future<int> bulkDelete(List<String> ids) => _dao.bulkSoftDelete(ids);
  Future<int> deleteByDateRange(DateTime start, DateTime end) =>
      _dao.deleteByDateRange(start, end);
  Future<int> deleteByCategory(String category) =>
      _dao.deleteByCategory(category);
  Future<int> deleteImportedOnly() => _dao.deleteBySource('imported');
  Future<int> deleteManualOnly() => _dao.deleteBySource('manual');
  Future<int> deleteIncomeOnly() =>
      _dao.deleteByType(TransactionType.income.name);
  Future<int> deleteExpenseOnly() =>
      _dao.deleteByType(TransactionType.expense.name);
  Future<int> deleteEverything() => _dao.deleteEverything();

  Stream<List<Transaction>> watchRecent(int count) => _dao.watchRecent(count);
  Stream<List<Transaction>> watchAll() => _dao.watchAll();
  Stream<List<Transaction>> watchByDateRange(DateTime start, DateTime end) =>
      _dao.watchByDateRange(start, end);

  Future<List<Transaction>> fetchPaged({
    required int page,
    int pageSize = 30,
    TransactionType? type,
    String? category,
    String? paymentMethod,
    bool? importedOnly,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    SortOption sort = SortOption.newest,
  }) =>
      _dao.fetchPaged(
        page: page,
        pageSize: pageSize,
        type: type,
        category: category,
        paymentMethod: paymentMethod,
        importedOnly: importedOnly,
        startDate: startDate,
        endDate: endDate,
        minAmount: minAmount,
        maxAmount: maxAmount,
        sort: sort,
      );

  Future<List<Transaction>> search(String query) => _dao.search(query);

  Future<double> totalIncome(DateTime start, DateTime end) =>
      _dao.sumByTypeAndRange(TransactionType.income, start, end);
  Future<double> totalExpense(DateTime start, DateTime end) =>
      _dao.sumByTypeAndRange(TransactionType.expense, start, end);
  /// Balance as of today — deliberately excludes any transaction dated
  /// in the future (e.g. scheduled/repeated expenses, planned salary),
  /// so those don't distort "what I have right now".
  Future<double> currentBalance() async {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final income = await _dao.sumByTypeAndRange(
        TransactionType.income, DateTime(2000), endOfToday);
    final expense = await _dao.sumByTypeAndRange(
        TransactionType.expense, DateTime(2000), endOfToday);
    return income - expense;
  }

  Future<Map<String, double>> categoryTotals(
          TransactionType type, DateTime start, DateTime end) =>
      _dao.categoryTotals(type, start, end);

  /// All transactions dated after today — scheduled/repeated future
  /// expenses and planned future income (e.g. salary added ahead of
  /// time) feed the Future Balance projection chart.
  Future<List<Transaction>> futureDatedTransactions() async {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final all = await _dao.watchAll().first;
    return all.where((t) => t.date.isAfter(endOfToday)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Bulk-adds the same expense/income across many dates in one go —
  /// powers the "repeat this entry" calendar/weekday picker on Add
  /// Expense (e.g. ₹10 for milk on every weekday for the next month).
  Future<Result<int>> addRepeatingTransaction({
    required String title,
    String description = '',
    required double amount,
    required TransactionType type,
    required String category,
    String paymentMethod = 'Cash',
    required List<DateTime> dates,
    String notes = '',
  }) async {
    if (amount <= 0) {
      return Result.error(
          const ValidationFailure('Negative or zero amounts are not allowed'));
    }
    if (dates.isEmpty) {
      return Result.error(const ValidationFailure('Select at least one date'));
    }
    final entries = dates
        .map((date) => TransactionsCompanion.insert(
              id: _uuid.v4(),
              title: title,
              description: Value(description),
              amount: amount,
              type: type.name,
              category: category,
              paymentMethod: Value(paymentMethod),
              date: date,
              source: const Value('manual'),
              notes: Value(notes),
              dedupeHash: Value(_dedupeHash(
                  date: date, amount: amount, description: description.isNotEmpty ? description : title, type: type)),
            ))
        .toList();
    try {
      await _dao.insertBatch(entries);
      return Result.success(entries.length);
    } catch (e) {
      return Result.error(DatabaseFailure('Failed to save repeating entries: $e'));
    }
  }

  /// Used by the statement importer to separate genuine duplicates from
  /// new transactions before insert (spec: "Skip Duplicates / Import
  /// Anyway" prompt).
  Future<Set<String>> existingHashes(List<String> hashes) async {
    final rows = await _dao.findByDedupeHashes(hashes);
    return rows.map((r) => r.dedupeHash).toSet();
  }

  String computeHash({
    required DateTime date,
    required double amount,
    required String description,
    required TransactionType type,
  }) =>
      _dedupeHash(date: date, amount: amount, description: description, type: type);

  Future<void> insertImportedBatch(List<TransactionsCompanion> entries) =>
      _dao.insertBatch(entries);
}
