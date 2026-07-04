import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../database/daos/subscriptions_dao.dart';

class SubscriptionRepository {
  final SubscriptionsDao _dao;
  final _uuid = const Uuid();

  SubscriptionRepository(this._dao);

  Stream<List<Subscription>> watchAll() => _dao.watchAll();
  Future<List<Subscription>> renewingWithin(int days) => _dao.renewingWithin(days);
  Future<double> totalMonthlyCost() => _dao.totalMonthlyCost();

  Future<void> addOrUpdate({
    String? id,
    required String name,
    required double price,
    required DateTime renewalDate,
    String cycle = 'Monthly',
    bool reminderEnabled = true,
    String status = 'active',
    String iconKey = 'subscriptions',
    int? colorValue,
  }) {
    return _dao.upsert(SubscriptionsCompanion.insert(
      id: id ?? _uuid.v4(),
      name: name,
      price: price,
      renewalDate: renewalDate,
      cycle: Value(cycle),
      reminderEnabled: Value(reminderEnabled),
      status: Value(status),
      iconKey: Value(iconKey),
      colorValue: Value(colorValue ?? 0xFF1B4D3E),
    ));
  }

  Future<void> deleteSubscription(String id) => _dao.deleteSubscription(id);
}
