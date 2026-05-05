import 'package:hive_flutter/hive_flutter.dart';

import '../hive_boxes.dart';
import '../models/cached_account.dart';
import '../models/cached_transaction.dart';

class HiveCacheService {
  late Box<CachedTransaction> _transactions;
  late Box<CachedAccount> _accounts;

  Future<void> initialize() async {
    _transactions = await Hive.openBox<CachedTransaction>(
      HiveBoxes.cachedTransactions,
    );
    _accounts = await Hive.openBox<CachedAccount>(HiveBoxes.cachedAccounts);
  }

  Future<void> cacheTransactions(
      List<Map<String, dynamic>> transactions) async {
    await _transactions.clear();
    for (final t in transactions) {
      final cached = CachedTransaction()
        ..id = t['id'] as String
        ..accountId = t['account_id'] as String
        ..tenantId = t['tenant_id'] as String
        ..amount = (t['amount'] as num).toDouble()
        ..type = t['type'] as String
        ..category = (t['category'] as String?) ?? 'other'
        ..date = DateTime.parse(t['date'] as String)
        ..notes = t['notes'] as String?
        ..cachedAt = DateTime.now()
        ..isPendingSync = false
        ..transferId = t['transfer_id'] as String?;
      await _transactions.put(cached.id, cached);
    }
  }

  Future<void> saveOfflineTransaction(CachedTransaction transaction) async {
    await _transactions.put(transaction.id, transaction);
  }

  List<CachedTransaction> getTransactions({String? tenantId}) {
    return _transactions.values
        .where((t) => tenantId == null || t.tenantId == tenantId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> cacheAccounts(List<Map<String, dynamic>> accounts) async {
    await _accounts.clear();
    for (final a in accounts) {
      final cached = CachedAccount()
        ..id = a['id'] as String
        ..tenantId = a['tenant_id'] as String
        ..name = a['name'] as String
        ..type = a['type'] as String
        ..balance = (a['balance'] as num).toDouble()
        ..creditLimit = (a['credit_limit'] as num?)?.toDouble()
        ..billingCloseDay = a['billing_close_day'] as int?
        ..paymentDueDay = a['payment_due_day'] as int?
        ..cachedAt = DateTime.now();
      await _accounts.put(cached.id, cached);
    }
  }

  List<CachedAccount> getAccounts({String? tenantId}) {
    return _accounts.values
        .where((a) => tenantId == null || a.tenantId == tenantId)
        .toList();
  }

  Future<void> updateAccountBalance(String accountId, double delta) async {
    final account = _accounts.get(accountId);
    if (account != null) {
      account.balance += delta;
      await account.save();
    }
  }

  Future<void> setLastSync(DateTime dt) async {
    final box = await Hive.openBox(HiveBoxes.syncMetadata);
    await box.put('last_sync', dt.toIso8601String());
  }

  Future<DateTime?> getLastSync() async {
    final box = await Hive.openBox(HiveBoxes.syncMetadata);
    final raw = box.get('last_sync');
    return raw != null ? DateTime.parse(raw as String) : null;
  }
}
