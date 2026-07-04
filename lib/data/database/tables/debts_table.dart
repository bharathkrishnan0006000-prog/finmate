import 'package:drift/drift.dart';

/// Money borrowed from someone or lent to someone. Deliberately separate
/// from Transactions — an IOU isn't income or an expense until it's
/// settled, so it needs its own lifecycle (pending -> settled).
class Debts extends Table {
  TextColumn get id => text()();
  TextColumn get personName => text()();
  RealColumn get amount => real()();

  /// 'borrowed' (money I owe someone) | 'lent' (money owed to me)
  TextColumn get type => text()();

  DateTimeColumn get date => dateTime()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();

  /// 'pending' | 'settled'
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get settledDate => dateTime().nullable()();

  /// Links to the Transaction created when this was settled, if the user
  /// chose to also record it as a transaction (nullable).
  TextColumn get settledTransactionId => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
