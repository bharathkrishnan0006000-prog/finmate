import 'package:drift/drift.dart';

/// Monthly budget goal per category (spec: Budget Goals — Food, Fuel,
/// Travel, Shopping, Medical, Entertainment, Bills, Custom).
class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get category => text()();
  RealColumn get monthlyLimit => real()();

  /// Month this budget applies to, normalized to the 1st of the month.
  DateTimeColumn get month => dateTime()();

  BoolColumn get notifyOnExceed => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
