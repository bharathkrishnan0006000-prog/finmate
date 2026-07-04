import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:sqlite3/sqlite3.dart';

import 'tables/transactions_table.dart';
import 'tables/categories_table.dart';
import 'tables/budgets_table.dart';
import 'tables/subscriptions_table.dart';
import 'tables/savings_goals_table.dart';
import 'tables/future_expenses_table.dart';
import 'tables/debts_table.dart';
import 'daos/transactions_dao.dart';
import 'daos/categories_dao.dart';
import 'daos/budgets_dao.dart';
import 'daos/subscriptions_dao.dart';
import 'daos/savings_goals_dao.dart';
import 'daos/future_expenses_dao.dart';
import 'daos/debts_dao.dart';
import '../../core/constants/app_constants.dart';

part 'app_database.g.dart';

/// Single source of truth for local persistence. 100% offline, backed by
/// SQLite via Drift. Designed to comfortably hold 100k+ transactions:
/// indexes on `date` and `category`, and every list query is paginated
/// at the DAO layer (see TransactionsDao.watchPaged).
@DriftDatabase(
  tables: [
    Transactions,
    Categories,
    Budgets,
    Subscriptions,
    SavingsGoals,
    FutureExpenses,
    Debts,
  ],
  daos: [
    TransactionsDao,
    CategoriesDao,
    BudgetsDao,
    SubscriptionsDao,
    SavingsGoalsDao,
    FutureExpensesDao,
    DebtsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement(
              'CREATE INDEX idx_txn_date ON transactions(date);');
          await customStatement(
              'CREATE INDEX idx_txn_category ON transactions(category);');
          await customStatement(
              'CREATE INDEX idx_txn_type ON transactions(type);');
          await customStatement(
              'CREATE INDEX idx_txn_dedupe ON transactions(dedupe_hash);');
        },
        onUpgrade: (m, from, to) async {
          // Add versioned migrations here as the schema evolves.
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, AppConstants.dbFileName));
    return NativeDatabase.createInBackground(
      file,
      setup: (rawDb) {
        rawDb.execute('PRAGMA foreign_keys = ON;');
        rawDb.execute('PRAGMA journal_mode = WAL;');
      },
    );
  });
}
