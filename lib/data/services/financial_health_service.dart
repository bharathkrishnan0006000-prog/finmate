/// Rule-based Financial Health Score (spec explicitly asks for this to
/// NOT depend on AI). Produces a 0-100 score plus a breakdown so the
/// Insights screen can explain *why* the score is what it is.
class FinancialHealthBreakdown {
  final int savingsRateScore; // 0-30
  final int budgetUsageScore; // 0-25
  final int subscriptionLoadScore; // 0-20
  final int incomeStabilityScore; // 0-15
  final int spendingControlScore; // 0-10

  const FinancialHealthBreakdown({
    required this.savingsRateScore,
    required this.budgetUsageScore,
    required this.subscriptionLoadScore,
    required this.incomeStabilityScore,
    required this.spendingControlScore,
  });

  int get total =>
      savingsRateScore +
      budgetUsageScore +
      subscriptionLoadScore +
      incomeStabilityScore +
      spendingControlScore;
}

class FinancialHealthService {
  /// [monthlyIncomes] — last few months of income, most recent last.
  /// Used to judge income stability (low variance = more stable).
  FinancialHealthBreakdown calculate({
    required double monthlyIncome,
    required double monthlyExpense,
    required double budgetLimitTotal,
    required double budgetSpentTotal,
    required double subscriptionMonthlyCost,
    required List<double> monthlyIncomes,
    required double previousMonthExpense,
  }) {
    // 1. Savings rate: (income - expense) / income, scaled to 30 pts.
    final savingsRate =
        monthlyIncome <= 0 ? 0.0 : (monthlyIncome - monthlyExpense) / monthlyIncome;
    final savingsScore = (savingsRate.clamp(0, 0.4) / 0.4 * 30).round();

    // 2. Budget usage: staying under budget scores high, exceeding scores low.
    int budgetScore;
    if (budgetLimitTotal <= 0) {
      budgetScore = 15; // No budgets set — neutral score.
    } else {
      final usage = budgetSpentTotal / budgetLimitTotal;
      if (usage <= 0.8) {
        budgetScore = 25;
      } else if (usage <= 1.0) {
        budgetScore = 18;
      } else if (usage <= 1.2) {
        budgetScore = 8;
      } else {
        budgetScore = 0;
      }
    }

    // 3. Subscription load: subscriptions as % of income.
    final subLoad = monthlyIncome <= 0 ? 0.0 : subscriptionMonthlyCost / monthlyIncome;
    int subScore;
    if (subLoad <= 0.05) {
      subScore = 20;
    } else if (subLoad <= 0.10) {
      subScore = 15;
    } else if (subLoad <= 0.20) {
      subScore = 8;
    } else {
      subScore = 2;
    }

    // 4. Income stability: coefficient of variation across recent months.
    int stabilityScore = 15;
    if (monthlyIncomes.length >= 2) {
      final mean = monthlyIncomes.reduce((a, b) => a + b) / monthlyIncomes.length;
      if (mean > 0) {
        final variance = monthlyIncomes
                .map((v) => (v - mean) * (v - mean))
                .reduce((a, b) => a + b) /
            monthlyIncomes.length;
        final cv = (variance > 0 ? variance : 0).toDouble() / (mean * mean);
        stabilityScore = ((1 - cv.clamp(0, 1)) * 15).round();
      }
    }

    // 5. Spending control: month-over-month expense change.
    int spendingScore = 10;
    if (previousMonthExpense > 0) {
      final change = (monthlyExpense - previousMonthExpense) / previousMonthExpense;
      if (change <= 0) {
        spendingScore = 10;
      } else if (change <= 0.1) {
        spendingScore = 7;
      } else if (change <= 0.25) {
        spendingScore = 4;
      } else {
        spendingScore = 0;
      }
    }

    return FinancialHealthBreakdown(
      savingsRateScore: savingsScore,
      budgetUsageScore: budgetScore,
      subscriptionLoadScore: subScore,
      incomeStabilityScore: stabilityScore,
      spendingControlScore: spendingScore,
    );
  }

  String label(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Needs Attention';
  }
}
