import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/transactions_table.dart';
import '../../../core/constants/app_constants.dart';

part 'transactions_dao.g.dart';

@DriftAccessor(tables: [Transactions])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  // ---------- Writes ----------

  Future<void> insertTransaction(TransactionsCompanion entry) =>
      into(transactions).insert(entry);

  Future<void> insertBatch(List<TransactionsCompanion> entries) {
    return batch((b) => b.insertAll(transactions, entries));
  }

  Future<bool> updateTransaction(TransactionsCompanion entry) =>
      update(transactions).replace(entry);

  /// Soft delete so "Undo Delete" (spec requirement) is possible.
  Future<void> softDelete(String id) => (update(transactions)
        ..where((t) => t.id.equals(id)))
      .write(const TransactionsCompanion(isDeleted: Value(true)));

  Future<void> restore(String id) => (update(transactions)
        ..where((t) => t.id.equals(id)))
      .write(const TransactionsCompanion(isDeleted: Value(false)));

  Future<void> hardDeletePermanently(String id) =>
      (delete(transactions)..where((t) => t.id.equals(id))).go();

  Future<int> bulkSoftDelete(List<String> ids) {
    return (update(transactions)..where((t) => t.id.isIn(ids)))
        .write(const TransactionsCompanion(isDeleted: Value(true)));
  }

  Future<int> deleteByDateRange(DateTime start, DateTime end) {
    return (update(transactions)
          ..where((t) => t.date.isBetweenValues(start, end)))
        .write(const TransactionsCompanion(isDeleted: Value(true)));
  }

  Future<int> deleteByCategory(String category) {
    return (update(transactions)..where((t) => t.category.equals(category)))
        .write(const TransactionsCompanion(isDeleted: Value(true)));
  }

  Future<int> deleteBySource(String source) {
    return (update(transactions)..where((t) => t.source.equals(source)))
        .write(const TransactionsCompanion(isDeleted: Value(true)));
  }

  Future<int> deleteByType(String type) {
    return (update(transactions)..where((t) => t.type.equals(type)))
        .write(const TransactionsCompanion(isDeleted: Value(true)));
  }

  Future<int> deleteEverything() {
    return (update(transactions)..where((t) => t.isDeleted.equals(false)))
        .write(const TransactionsCompanion(isDeleted: Value(true)));
  }

  // ---------- Duplicate detection (statement import) ----------

  Future<List<Transaction>> findByDedupeHashes(List<String> hashes) {
    return (select(transactions)
          ..where((t) => t.dedupeHash.isIn(hashes) & t.isDeleted.equals(false)))
        .get();
  }

  // ---------- Reads ----------

  Stream<List<Transaction>> watchAll({int? limit, int? offset}) {
    final query = select(transactions)
      ..where((t) => t.isDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);
    if (limit != null) query.limit(limit, offset: offset ?? 0);
    return query.watch();
  }

  /// Paginated fetch — keeps 100k+ datasets smooth (spec requirement).
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
  }) {
    final query = select(transactions)
      ..where((t) => t.isDeleted.equals(false));

    if (type != null) {
      query.where((t) => t.type.equals(type.name));
    }
    if (category != null) {
      query.where((t) => t.category.equals(category));
    }
    if (paymentMethod != null) {
      query.where((t) => t.paymentMethod.equals(paymentMethod));
    }
    if (importedOnly != null) {
      query.where((t) =>
          t.source.equals(importedOnly ? 'imported' : 'manual'));
    }
    if (startDate != null && endDate != null) {
      query.where((t) => t.date.isBetweenValues(startDate, endDate));
    }
    if (minAmount != null) {
      query.where((t) => t.amount.isBiggerOrEqualValue(minAmount));
    }
    if (maxAmount != null) {
      query.where((t) => t.amount.isSmallerOrEqualValue(maxAmount));
    }

    switch (sort) {
      case SortOption.newest:
        query.orderBy([(t) => OrderingTerm.desc(t.date)]);
        break;
      case SortOption.oldest:
        query.orderBy([(t) => OrderingTerm.asc(t.date)]);
        break;
      case SortOption.highestAmount:
        query.orderBy([(t) => OrderingTerm.desc(t.amount)]);
        break;
      case SortOption.lowestAmount:
        query.orderBy([(t) => OrderingTerm.asc(t.amount)]);
        break;
    }

    query.limit(pageSize, offset: page * pageSize);
    return query.get();
  }

  /// Full-text-ish search across merchant, amount, category, description,
  /// notes, tags, payment method (spec: Search section).
  Future<List<Transaction>> search(String query) {
    final likeQuery = '%$query%';
    return (select(transactions)
          ..where((t) =>
              t.isDeleted.equals(false) &
              (t.merchant.like(likeQuery) |
                  t.title.like(likeQuery) |
                  t.description.like(likeQuery) |
                  t.category.like(likeQuery) |
                  t.notes.like(likeQuery) |
                  t.tags.like(likeQuery) |
                  t.paymentMethod.like(likeQuery)))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  Stream<List<Transaction>> watchRecent(int count) {
    return (select(transactions)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(count))
        .watch();
  }

  Stream<List<Transaction>> watchByDateRange(DateTime start, DateTime end) {
    return (select(transactions)
          ..where((t) =>
              t.isDeleted.equals(false) & t.date.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  // ---------- Aggregates (dashboard, analytics, health score) ----------

  Future<double> sumByTypeAndRange(
      TransactionType type, DateTime start, DateTime end) async {
    final sumExp = transactions.amount.sum();
    final query = selectOnly(transactions)
      ..addColumns([sumExp])
      ..where(transactions.isDeleted.equals(false) &
          transactions.type.equals(type.name) &
          transactions.date.isBetweenValues(start, end));
    final result = await query.getSingleOrNull();
    return result?.read(sumExp) ?? 0.0;
  }

  Future<Map<String, double>> categoryTotals(
      TransactionType type, DateTime start, DateTime end) async {
    final sumExp = transactions.amount.sum();
    final query = selectOnly(transactions)
      ..addColumns([transactions.category, sumExp])
      ..where(transactions.isDeleted.equals(false) &
          transactions.type.equals(type.name) &
          transactions.date.isBetweenValues(start, end))
      ..groupBy([transactions.category]);
    final rows = await query.get();
    return {
      for (final row in rows)
        row.read(transactions.category)!: row.read(sumExp) ?? 0.0,
    };
  }

  Future<double> currentBalance() async {
    final income =
        await sumByTypeAndRange(TransactionType.income, DateTime(2000), DateTime(2100));
    final expense =
        await sumByTypeAndRange(TransactionType.expense, DateTime(2000), DateTime(2100));
    return income - expense;
  }
}
