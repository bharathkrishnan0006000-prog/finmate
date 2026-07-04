import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../data/repositories/savings_goal_repository.dart';
import '../../data/repositories/future_expense_repository.dart';
import '../../data/repositories/debt_repository.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/financial_health_service.dart';
import '../../data/services/ai_insight_service.dart';
import '../../data/services/statement_parser_service.dart';
import '../../data/services/export_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/backup_service.dart';
import '../../data/services/ocr_service.dart';

/// Single AppDatabase instance for the whole app lifetime.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// SharedPreferences is loaded once in main() and overridden into the
/// ProviderScope, so every provider can read it synchronously.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main()');
});

// ---------------- Repositories ----------------

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(appDatabaseProvider).transactionsDao);
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(appDatabaseProvider).categoriesDao);
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(ref.watch(appDatabaseProvider).budgetsDao);
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(ref.watch(appDatabaseProvider).subscriptionsDao);
});

final savingsGoalRepositoryProvider = Provider<SavingsGoalRepository>((ref) {
  return SavingsGoalRepository(ref.watch(appDatabaseProvider).savingsGoalsDao);
});

final futureExpenseRepositoryProvider = Provider<FutureExpenseRepository>((ref) {
  return FutureExpenseRepository(ref.watch(appDatabaseProvider).futureExpensesDao);
});

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  return DebtRepository(
    ref.watch(appDatabaseProvider).debtsDao,
    ref.watch(transactionRepositoryProvider),
  );
});

// ---------------- Services ----------------

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final financialHealthServiceProvider = Provider<FinancialHealthService>((ref) {
  return FinancialHealthService();
});

/// AI features are OFF by default and only ever run on explicit user
/// action (spec: "AI should NEVER continuously run").
final aiInsightServiceProvider = Provider<AiInsightService>((ref) {
  return AiInsightService();
});

final statementParserServiceProvider = Provider<StatementParserService>((ref) {
  return StatementParserService();
});

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(appDatabaseProvider));
});

final ocrServiceProvider = Provider<OcrService>((ref) {
  final service = OcrService();
  ref.onDispose(service.dispose);
  return service;
});

final pinEnabledProvider = StateProvider<bool>((ref) {
  return ref.watch(sharedPreferencesProvider).getBool(AppConstants.prefsPinEnabled) ?? false;
});

final biometricEnabledProvider = StateProvider<bool>((ref) {
  return ref.watch(sharedPreferencesProvider).getBool(AppConstants.prefsBiometricEnabled) ?? false;
});

/// Minutes of background time before the app re-locks. 0 = immediately,
/// -1 = never.
final lockTimeoutMinutesProvider = StateProvider<int>((ref) {
  return ref.watch(sharedPreferencesProvider).getInt(AppConstants.prefsLockTimeoutMinutes) ?? 0;
});

/// True while the app should be showing the lock screen.
final isLockedProvider = StateProvider<bool>((ref) => false);

// ---------------- Settings (backed by SharedPreferences) ----------------

final aiEnabledProvider = StateProvider<bool>((ref) {
  return ref.watch(sharedPreferencesProvider).getBool('ai_features_enabled') ?? false;
});

final darkModeProvider = StateProvider<bool>((ref) {
  return ref.watch(sharedPreferencesProvider).getBool('dark_mode') ?? false;
});

final currencyCodeProvider = StateProvider<String>((ref) {
  return ref.watch(sharedPreferencesProvider).getString('currency_code') ?? 'INR';
});
