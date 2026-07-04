import 'package:drift/drift.dart';

/// Expense/income categories. Defaults are seeded on first launch;
/// users can add custom ones (spec: "Custom Category").
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// 'expense' | 'income'
  TextColumn get type => text()();

  /// Material icon codepoint name, resolved via CategoryIcons map.
  TextColumn get iconKey => text().withDefault(const Constant('category'))();

  /// Stored as an ARGB int.
  IntColumn get colorValue => integer()();

  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
