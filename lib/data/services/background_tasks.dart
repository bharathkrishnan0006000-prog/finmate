import 'package:workmanager/workmanager.dart';
import '../database/app_database.dart';
import '../../core/constants/app_constants.dart';
import 'notification_service.dart';

const String periodicCheckTaskName = 'finmate_periodic_check';

/// WorkManager runs this in a separate background isolate — it can't
/// share the app's Riverpod container, so it opens its own short-lived
/// database connection, does its checks, fires any notifications, and
/// closes. This only runs on the schedule below; it is never triggered
/// by app usage, keeping it lightweight and battery-friendly.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != periodicCheckTaskName) return true;

    final db = AppDatabase();
    final notifications = NotificationService();
    try {
      await _checkBudgets(db, notifications);
      await _checkSubscriptions(db, notifications);
      await _checkSavingsGoals(db, notifications);
      await _checkFutureExpenses(db, notifications);
    } catch (_) {
      // Swallow errors — a missed background check should never crash
      // or repeatedly retry aggressively.
    } finally {
      await db.close();
    }
    return true;
  });
}

Future<void> _checkBudgets(AppDatabase db, NotificationService notifications) async {
  final now = DateTime.now();
  final budgets = await db.budgetsDao.forMonth(now);
  final monthStart = DateTime(now.year, now.month, 1);
  final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

  for (final budget in budgets) {
    if (!budget.notifyOnExceed) continue;
    final spent = await db.transactionsDao.categoryTotals(
        TransactionType.expense, monthStart, monthEnd);
    final categorySpent = spent[budget.category] ?? 0;
    if (budget.monthlyLimit <= 0) continue;
    final percent = (categorySpent / budget.monthlyLimit) * 100;
    if (percent >= 90) {
      await notifications.budgetWarning(budget.category, percent);
    }
  }
}

Future<void> _checkSubscriptions(AppDatabase db, NotificationService notifications) async {
  final upcoming = await db.subscriptionsDao.renewingWithin(3);
  for (final sub in upcoming) {
    if (!sub.reminderEnabled) continue;
    await notifications.subscriptionReminder(sub.name, sub.renewalDate);
  }
}

Future<void> _checkSavingsGoals(AppDatabase db, NotificationService notifications) async {
  final goals = await db.savingsGoalsDao.watchAll().first;
  // Light-touch weekly nudge — only for goals that are still meaningfully
  // short of target, to avoid notification fatigue.
  for (final goal in goals) {
    if (goal.targetAmount <= 0) continue;
    final progress = goal.savedAmount / goal.targetAmount;
    if (progress < 0.95 && DateTime.now().weekday == DateTime.monday) {
      await notifications.savingsReminder(goal.title);
    }
  }
}

Future<void> _checkFutureExpenses(AppDatabase db, NotificationService notifications) async {
  final plans = await db.futureExpensesDao.watchAll().first;
  final now = DateTime.now();
  for (final plan in plans) {
    final daysUntil = plan.plannedDate.difference(now).inDays;
    if (daysUntil == 2) {
      await notifications.futureExpenseReminder(plan.title, plan.plannedDate);
    }
  }
}

/// Called once from main() to schedule the recurring background check.
/// WorkManager enforces a 15-minute minimum; twice a day is plenty for
/// reminders that are inherently not time-critical to the minute.
Future<void> registerBackgroundTasks() async {
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    periodicCheckTaskName,
    periodicCheckTaskName,
    frequency: const Duration(hours: 12),
    constraints: Constraints(networkType: NetworkType.not_required),
  );
}
