import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../../core/constants/app_constants.dart';
import '../../core/error/failures.dart';

/// Backs up each table to its own JSON file (spec: "multiple files") in a
/// folder the user picks via the system file/folder browser — never a
/// fixed app-internal-only location, and never a network destination.
class BackupService {
  final AppDatabase _db;
  BackupService(this._db);

  static const _fileNames = {
    'transactions': 'finmate_transactions.json',
    'categories': 'finmate_categories.json',
    'budgets': 'finmate_budgets.json',
    'subscriptions': 'finmate_subscriptions.json',
    'savings_goals': 'finmate_savings_goals.json',
    'future_expenses': 'finmate_future_expenses.json',
    'debts': 'finmate_debts.json',
    'settings': 'finmate_settings.json',
  };

  Future<Result<String>> backup(SharedPreferences prefs) async {
    final dirPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose a folder to save your FinMate backup',
    );
    if (dirPath == null) return Result.error(const FileFailure('Backup cancelled'));

    try {
      final txns = await _db.transactionsDao.watchAll().first;
      final categories = await _db.categoriesDao.allActive();
      final budgets = await _db.budgetsDao.forMonth(DateTime.now());
      final subs = await _db.subscriptionsDao.watchAll().first;
      final goals = await _db.savingsGoalsDao.watchAll().first;
      final future = await _db.futureExpensesDao.watchAll().first;
      final debts = await _db.debtsDao.watchAll().first;

      final settings = {
        AppConstants.prefsCurrency: prefs.getString(AppConstants.prefsCurrency),
        AppConstants.prefsDarkMode: prefs.getBool(AppConstants.prefsDarkMode),
        AppConstants.prefsAiEnabled: prefs.getBool(AppConstants.prefsAiEnabled),
        AppConstants.prefsLanguage: prefs.getString(AppConstants.prefsLanguage),
        // Deliberately excluded: PIN hash / biometric secrets — those never
        // leave the device's secure storage, even in a backup.
      };

      await _writeJson(dirPath, _fileNames['transactions']!, txns.map((e) => e.toJson()).toList());
      await _writeJson(dirPath, _fileNames['categories']!, categories.map((e) => e.toJson()).toList());
      await _writeJson(dirPath, _fileNames['budgets']!, budgets.map((e) => e.toJson()).toList());
      await _writeJson(dirPath, _fileNames['subscriptions']!, subs.map((e) => e.toJson()).toList());
      await _writeJson(dirPath, _fileNames['savings_goals']!, goals.map((e) => e.toJson()).toList());
      await _writeJson(dirPath, _fileNames['future_expenses']!, future.map((e) => e.toJson()).toList());
      await _writeJson(dirPath, _fileNames['debts']!, debts.map((e) => e.toJson()).toList());
      await _writeJson(dirPath, _fileNames['settings']!, settings);

      return Result.success(dirPath);
    } catch (e) {
      return Result.error(FileFailure('Backup failed: $e'));
    }
  }

  Future<void> _writeJson(String dirPath, String fileName, Object data) async {
    final file = File('$dirPath/$fileName');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
  }

  Future<Result<int>> restore(SharedPreferences prefs) async {
    final dirPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose the folder containing your FinMate backup',
    );
    if (dirPath == null) return Result.error(const FileFailure('Restore cancelled'));

    var restoredCount = 0;
    try {
      restoredCount += await _restoreTransactions(dirPath);
      await _restoreCategories(dirPath);
      await _restoreBudgets(dirPath);
      await _restoreSubscriptions(dirPath);
      await _restoreSavingsGoals(dirPath);
      await _restoreFutureExpenses(dirPath);
      await _restoreDebts(dirPath);
      await _restoreSettings(dirPath, prefs);
      return Result.success(restoredCount);
    } catch (e) {
      return Result.error(FileFailure('Restore failed: $e'));
    }
  }

  Future<List<dynamic>?> _readJsonList(String dirPath, String fileName) async {
    final file = File('$dirPath/$fileName');
    if (!await file.exists()) return null;
    final content = await file.readAsString();
    return jsonDecode(content) as List<dynamic>;
  }

  Future<int> _restoreTransactions(String dirPath) async {
    final list = await _readJsonList(dirPath, _fileNames['transactions']!);
    if (list == null) return 0;
    final entries = list
        .map((e) => Transaction.fromJson(e as Map<String, dynamic>).toCompanion(true))
        .toList();
    await _db.transactionsDao.insertBatch(entries);
    return entries.length;
  }

  Future<void> _restoreCategories(String dirPath) async {
    final list = await _readJsonList(dirPath, _fileNames['categories']!);
    if (list == null) return;
    final entries =
        list.map((e) => Category.fromJson(e as Map<String, dynamic>).toCompanion(true)).toList();
    await _db.categoriesDao.insertBatch(entries);
  }

  Future<void> _restoreBudgets(String dirPath) async {
    final list = await _readJsonList(dirPath, _fileNames['budgets']!);
    if (list == null) return;
    for (final e in list) {
      final b = Budget.fromJson(e as Map<String, dynamic>);
      await _db.budgetsDao.upsert(b.toCompanion(true));
    }
  }

  Future<void> _restoreSubscriptions(String dirPath) async {
    final list = await _readJsonList(dirPath, _fileNames['subscriptions']!);
    if (list == null) return;
    for (final e in list) {
      final s = Subscription.fromJson(e as Map<String, dynamic>);
      await _db.subscriptionsDao.upsert(s.toCompanion(true));
    }
  }

  Future<void> _restoreSavingsGoals(String dirPath) async {
    final list = await _readJsonList(dirPath, _fileNames['savings_goals']!);
    if (list == null) return;
    for (final e in list) {
      final g = SavingsGoal.fromJson(e as Map<String, dynamic>);
      await _db.savingsGoalsDao.upsert(g.toCompanion(true));
    }
  }

  Future<void> _restoreFutureExpenses(String dirPath) async {
    final list = await _readJsonList(dirPath, _fileNames['future_expenses']!);
    if (list == null) return;
    for (final e in list) {
      final f = FutureExpense.fromJson(e as Map<String, dynamic>);
      await _db.futureExpensesDao.upsert(f.toCompanion(true));
    }
  }

  Future<void> _restoreDebts(String dirPath) async {
    final list = await _readJsonList(dirPath, _fileNames['debts']!);
    if (list == null) return;
    for (final e in list) {
      final d = Debt.fromJson(e as Map<String, dynamic>);
      await _db.debtsDao.upsert(d.toCompanion(true));
    }
  }

  Future<void> _restoreSettings(String dirPath, SharedPreferences prefs) async {
    final file = File('$dirPath/${_fileNames['settings']}');
    if (!await file.exists()) return;
    final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    if (map[AppConstants.prefsCurrency] != null) {
      await prefs.setString(AppConstants.prefsCurrency, map[AppConstants.prefsCurrency]);
    }
    if (map[AppConstants.prefsDarkMode] != null) {
      await prefs.setBool(AppConstants.prefsDarkMode, map[AppConstants.prefsDarkMode]);
    }
    if (map[AppConstants.prefsAiEnabled] != null) {
      await prefs.setBool(AppConstants.prefsAiEnabled, map[AppConstants.prefsAiEnabled]);
    }
    if (map[AppConstants.prefsLanguage] != null) {
      await prefs.setString(AppConstants.prefsLanguage, map[AppConstants.prefsLanguage]);
    }
  }
}
