import 'package:drift/drift.dart';

/// Savings goals (Laptop, Bike, Emergency Fund, ...).
class SavingsGoals extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  RealColumn get targetAmount => real()();
  RealColumn get savedAmount => real().withDefault(const Constant(0))();
  DateTimeColumn get targetDate => dateTime().nullable()();
  TextColumn get iconKey => text().withDefault(const Constant('savings'))();
  IntColumn get colorValue => integer().withDefault(const Constant(0xFF6FCF97))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
