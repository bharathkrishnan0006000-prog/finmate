import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/subscriptions_table.dart';

part 'subscriptions_dao.g.dart';

@DriftAccessor(tables: [Subscriptions])
class SubscriptionsDao extends DatabaseAccessor<AppDatabase>
    with _$SubscriptionsDaoMixin {
  SubscriptionsDao(super.db);

  Future<void> upsert(SubscriptionsCompanion entry) =>
      into(subscriptions).insertOnConflictUpdate(entry);

  Future<void> deleteSubscription(String id) => (update(subscriptions)
        ..where((s) => s.id.equals(id)))
      .write(const SubscriptionsCompanion(isDeleted: Value(true)));

  Stream<List<Subscription>> watchAll() {
    return (select(subscriptions)
          ..where((s) => s.isDeleted.equals(false))
          ..orderBy([(s) => OrderingTerm.asc(s.renewalDate)]))
        .watch();
  }

  Future<List<Subscription>> renewingWithin(int days) async {
    final now = DateTime.now();
    final cutoff = now.add(Duration(days: days));
    final all = await (select(subscriptions)
          ..where((s) =>
              s.isDeleted.equals(false) & s.status.equals('active')))
        .get();
    return all
        .where((s) => s.renewalDate.isBefore(cutoff) &&
            s.renewalDate.isAfter(now.subtract(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => a.renewalDate.compareTo(b.renewalDate));
  }

  Future<double> totalMonthlyCost() async {
    final all = await (select(subscriptions)
          ..where((s) =>
              s.isDeleted.equals(false) & s.status.equals('active')))
        .get();
    double total = 0;
    for (final s in all) {
      switch (s.cycle) {
        case 'Weekly':
          total += s.price * 4.33;
          break;
        case 'Monthly':
          total += s.price;
          break;
        case 'Quarterly':
          total += s.price / 3;
          break;
        case 'Yearly':
          total += s.price / 12;
          break;
      }
    }
    return total;
  }
}
