import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../database/daos/future_expenses_dao.dart';

class FutureExpenseRepository {
  final FutureExpensesDao _dao;
  final _uuid = const Uuid();

  FutureExpenseRepository(this._dao);

  Stream<List<FutureExpense>> watchAll() => _dao.watchAll();

  Future<void> addPlan({
    String? id,
    required String title,
    required double amount,
    required DateTime plannedDate,
    String notes = '',
  }) {
    return _dao.upsert(FutureExpensesCompanion.insert(
      id: id ?? _uuid.v4(),
      title: title,
      amount: amount,
      plannedDate: plannedDate,
      notes: Value(notes),
    ));
  }

  Future<void> deletePlan(String id) => _dao.deletePlan(id);
}

/// Result of the "Is it possible?" affordability check shown on the
/// Future Expense Planner screen.
class AffordabilityResult {
  final bool isSafe;
  final double projectedBalance;
  final double remainingAfterPurchase;
  final String reason;

  const AffordabilityResult({
    required this.isSafe,
    required this.projectedBalance,
    required this.remainingAfterPurchase,
    required this.reason,
  });
}

/// A single point on the Future Balance Projection chart.
class ProjectedBalancePoint {
  final DateTime date;
  final double balance;
  const ProjectedBalancePoint(this.date, this.balance);
}

/// Builds a day-by-day projected balance series for the next [horizonDays]
/// days, starting from today's actual balance and rolling forward through:
/// - any future-dated transactions the user already added (scheduled
///   expenses like "milk every weekday", or planned income like salary),
/// - planned future purchases from the Future Expense Planner,
/// - upcoming subscription renewals.
/// Used by the Future Planner screen's balance chart.
List<ProjectedBalancePoint> computeBalanceProjection({
  required double currentBalance,
  required List<({DateTime date, double amount, bool isIncome})> futureTransactions,
  required List<({DateTime date, double amount})> plannedPurchases,
  required List<({DateTime date, double amount})> subscriptionRenewals,
  int horizonDays = 60,
}) {
  final today = DateTime.now();
  final start = DateTime(today.year, today.month, today.day);

  // Net delta per future day.
  final deltas = <DateTime, double>{};
  void addDelta(DateTime date, double amount) {
    final key = DateTime(date.year, date.month, date.day);
    deltas[key] = (deltas[key] ?? 0) + amount;
  }

  for (final t in futureTransactions) {
    addDelta(t.date, t.isIncome ? t.amount : -t.amount);
  }
  for (final p in plannedPurchases) {
    addDelta(p.date, -p.amount);
  }
  for (final s in subscriptionRenewals) {
    addDelta(s.date, -s.amount);
  }

  final series = <ProjectedBalancePoint>[];
  double running = currentBalance;
  series.add(ProjectedBalancePoint(start, running));
  for (var i = 1; i <= horizonDays; i++) {
    final day = start.add(Duration(days: i));
    running += deltas[day] ?? 0;
    series.add(ProjectedBalancePoint(day, running));
  }
  return series;
}

/// Rule-based affordability calculator:
/// projectedBalance = currentBalance + expectedIncome - upcomingBills - subscriptions
/// remainingAfterPurchase = projectedBalance - plannedAmount
/// Safe when remainingAfterPurchase keeps at least a small buffer (>= 0
/// and doesn't wipe out more than 80% of the projected balance).
AffordabilityResult calculateAffordability({
  required double currentBalance,
  required double expectedIncome,
  required double upcomingBills,
  required double upcomingSubscriptions,
  required double plannedAmount,
}) {
  final projectedBalance =
      currentBalance + expectedIncome - upcomingBills - upcomingSubscriptions;
  final remaining = projectedBalance - plannedAmount;

  if (remaining < 0) {
    return AffordabilityResult(
      isSafe: false,
      projectedBalance: projectedBalance,
      remainingAfterPurchase: remaining,
      reason:
          'This purchase would put you below zero after upcoming bills and subscriptions.',
    );
  }

  final bufferRatio = projectedBalance == 0 ? 0 : remaining / projectedBalance;
  if (bufferRatio < 0.15) {
    return AffordabilityResult(
      isSafe: false,
      projectedBalance: projectedBalance,
      remainingAfterPurchase: remaining,
      reason:
          'This would use most of your projected balance, leaving very little safety buffer.',
    );
  }

  return AffordabilityResult(
    isSafe: true,
    projectedBalance: projectedBalance,
    remainingAfterPurchase: remaining,
    reason: 'You will have a healthy buffer left after all planned expenses.',
  );
}
