import 'package:drift/drift.dart';

/// Recurring subscriptions/bills (Netflix, Rent, Insurance, etc.)
class Subscriptions extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get price => real()();
  DateTimeColumn get renewalDate => dateTime()();

  /// 'Weekly' | 'Monthly' | 'Quarterly' | 'Yearly'
  TextColumn get cycle => text().withDefault(const Constant('Monthly'))();

  BoolColumn get reminderEnabled => boolean().withDefault(const Constant(true))();

  /// 'active' | 'paused' | 'cancelled'
  TextColumn get status => text().withDefault(const Constant('active'))();

  TextColumn get iconKey => text().withDefault(const Constant('subscriptions'))();
  IntColumn get colorValue => integer().withDefault(const Constant(0xFF1B4D3E))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
