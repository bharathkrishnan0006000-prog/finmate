import 'dart:math';

/// "AI" features for v1 are rule-based pattern analysis — no on-device
/// model, no background execution, no battery/memory cost when the
/// Settings > "Enable AI Features" toggle is off. Every method here is
/// only ever invoked from an explicit button press (Analyze Spending,
/// Generate AI Tips, Categorize Imported Transactions, Generate
/// Insights) — never from a timer or app-start hook.
///
/// This is intentionally swappable: a future version can replace the
/// method bodies with an on-device TFLite model without touching any
/// call site, since the public API (inputs/outputs) stays the same.
class AiInsightService {
  /// Suggests a category for an imported transaction based on merchant/
  /// description keyword matching against common patterns.
  String suggestCategory(String description, {String fallback = 'Others'}) {
    final text = description.toLowerCase();
    final rules = <String, List<String>>{
      'Food': ['swiggy', 'zomato', 'restaurant', 'cafe', 'food', 'dominos', 'pizza'],
      'Travel': ['uber', 'ola', 'irctc', 'flight', 'indigo', 'taxi', 'metro'],
      'Fuel': ['petrol', 'fuel', 'diesel', 'hp ', 'iocl', 'bharat petroleum'],
      'Shopping': ['amazon', 'flipkart', 'myntra', 'ajio', 'mall'],
      'Bills': ['electricity', 'water bill', 'broadband', 'wifi', 'gas bill'],
      'Entertainment': ['netflix', 'spotify', 'prime video', 'hotstar', 'bookmyshow'],
      'Medical': ['pharmacy', 'hospital', 'clinic', 'apollo', 'medplus'],
      'Rent': ['rent', 'landlord'],
      'Salary': ['salary', 'payroll'],
    };
    for (final entry in rules.entries) {
      if (entry.value.any((kw) => text.contains(kw))) return entry.key;
    }
    return fallback;
  }

  /// Compares this month's category spend against last month's and
  /// surfaces the most notable change as a short, human-readable tip.
  List<String> generateSpendingTips({
    required Map<String, double> thisMonthByCategory,
    required Map<String, double> lastMonthByCategory,
  }) {
    final tips = <String>[];
    for (final category in thisMonthByCategory.keys) {
      final current = thisMonthByCategory[category] ?? 0;
      final previous = lastMonthByCategory[category] ?? 0;
      if (previous <= 0 || current <= 0) continue;
      final changePercent = ((current - previous) / previous) * 100;
      if (changePercent >= 20) {
        tips.add(
            'You spent ${changePercent.toStringAsFixed(0)}% more on $category this month than last month.');
      }
    }
    if (tips.isEmpty) {
      tips.add('Your spending is steady across categories compared to last month.');
    }
    return tips;
  }

  /// Simple daily-average based projection for "safe to spend" framing.
  double projectMonthEndSpend(double spentSoFar, int dayOfMonth, int daysInMonth) {
    if (dayOfMonth <= 0) return spentSoFar;
    final dailyAvg = spentSoFar / dayOfMonth;
    return dailyAvg * daysInMonth;
  }

  /// Picks the single most actionable insight from a set of candidates —
  /// used on the Insights screen's highlighted "AI Insight" card.
  String topInsight(List<String> candidates) {
    if (candidates.isEmpty) return 'No notable spending patterns this week.';
    // Deterministic pick (longest / most specific tip first) rather than
    // random, so the same data always produces the same headline.
    final sorted = [...candidates]..sort((a, b) => b.length.compareTo(a.length));
    return sorted.first;
  }

  String randomEncouragement() {
    const messages = [
      'Small changes add up — keep tracking every expense.',
      'You are building a great habit by reviewing your spending.',
      'Consistency beats perfection — one entry at a time.',
    ];
    return messages[Random().nextInt(messages.length)];
  }
}
