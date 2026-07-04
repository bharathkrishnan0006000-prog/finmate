import 'package:drift/drift.dart';

/// Every transaction — manual or imported, income or expense.
/// Field set matches the spec exactly: uuid, title, description, amount,
/// type, category, payment method, date, time, createdAt, source,
/// merchant, bank, tags, notes.
class Transactions extends Table {
  TextColumn get id => text()(); // UUID, primary key
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  RealColumn get amount => real()();

  /// 'income' | 'expense'
  TextColumn get type => text()();

  TextColumn get category => text()();
  TextColumn get paymentMethod => text().withDefault(const Constant('Cash'))();

  /// Date the transaction actually occurred (statement date when imported —
  /// NEVER the upload date).
  DateTimeColumn get date => dateTime()();

  TextColumn get time => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 'manual' | 'imported'
  TextColumn get source => text().withDefault(const Constant('manual'))();

  TextColumn get merchant => text().withDefault(const Constant(''))();
  TextColumn get bank => text().withDefault(const Constant(''))();
  TextColumn get referenceNumber => text().withDefault(const Constant(''))();

  /// Comma-separated tags, e.g. "work,reimbursable"
  TextColumn get tags => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();

  /// Fingerprint used for duplicate detection during statement import
  /// (hash of date + amount + description + type).
  TextColumn get dedupeHash => text().withDefault(const Constant(''))();

  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
