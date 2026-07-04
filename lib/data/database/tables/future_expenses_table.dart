import 'package:drift/drift.dart';

/// Planned future purchases (spec: Future Expense Planner — e.g. "PS5
/// Controller, ₹6,500, 15 Jun 2024" with a Safe-to-Buy calculation).
class FutureExpenses extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  RealColumn get amount => real()();
  DateTimeColumn get plannedDate => dateTime()();
  TextColumn get notes => text().withDefault(const Constant(''))();

  /// 'planned' | 'purchased' | 'cancelled'
  TextColumn get status => text().withDefault(const Constant('planned'))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
