import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/domain/app_categories.dart';
import '../../../core/offline/models/cached_transaction.dart';
import '../../../core/offline/providers/connectivity_provider.dart';
import '../../../core/offline/providers/offline_queue_provider.dart';
import '../../../core/offline/services/connectivity_service.dart';
import '../../../core/offline/services/hive_cache_service.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../accounts/data/accounts_repository.dart';
import '../domain/account_model.dart';
import '../../transactions/domain/transaction_model.dart';

class DashboardRepository {
  final SupabaseClient _client;
  final ConnectivityService _connectivityService;
  final HiveCacheService _cacheService;

  DashboardRepository(
    this._client,
    this._connectivityService,
    this._cacheService,
  );

  Future<double> getAvailableBalance(String tenantId) async {
    if (!_connectivityService.isOnline) {
      return _cacheService
          .getAccounts(tenantId: tenantId)
          .fold<double>(0.0, (sum, item) => sum + item.balance);
    }

    final response = await _client
        .from('accounts')
        .select()
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: true);

    final accounts = List<Map<String, dynamic>>.from(response as List);
    await _cacheService.cacheAccounts(accounts);

    return accounts.fold<double>(
      0.0,
      (sum, item) => sum + (item['balance'] as num).toDouble(),
    );
  }

  Future<List<Transaction>> getRecentTransactions(String tenantId) async {
    if (!_connectivityService.isOnline) {
      return _cacheService
          .getTransactions(tenantId: tenantId)
          .take(10)
          .map(_transactionFromCache)
          .toList();
    }

    final response = await _client
        .from('transactions')
        .select()
        .eq('tenant_id', tenantId)
        .order('date', ascending: false)
        .limit(10);

    final transactions = List<Map<String, dynamic>>.from(response as List);
    await _cacheService.cacheTransactions(transactions);

    return transactions.map(Transaction.fromJson).toList();
  }

  Future<List<Transaction>> getAllTransactions(String tenantId) async {
    if (!_connectivityService.isOnline) {
      final transactions = _cacheService
          .getTransactions(tenantId: tenantId)
          .map(_transactionFromCache)
          .toList();
      transactions.sort((a, b) => b.date.compareTo(a.date));
      return transactions;
    }

    final response = await _client
        .from('transactions')
        .select()
        .eq('tenant_id', tenantId)
        .order('date', ascending: false);

    final transactions = List<Map<String, dynamic>>.from(response as List);
    await _cacheService.cacheTransactions(transactions);

    return transactions.map(Transaction.fromJson).toList();
  }

  Future<Map<String, double>> getWeeklySpend(String tenantId) async {
    final lastWeek = DateTime.now().subtract(const Duration(days: 7));

    if (!_connectivityService.isOnline) {
      final totalSpent = _cacheService
          .getTransactions(tenantId: tenantId)
          .where(
            (transaction) =>
                transaction.type == 'expense' &&
                !transaction.date.isBefore(lastWeek),
          )
          .fold<double>(0.0, (sum, item) => sum + item.amount);

      return {
        'spent': totalSpent,
        'limit': 5000.0,
      };
    }

    final response = await _client
        .from('transactions')
        .select('amount')
        .eq('tenant_id', tenantId)
        .eq('type', 'expense')
        .gte('date', lastWeek.toIso8601String());

    final data = response as List<dynamic>;
    final totalSpent = data.fold<double>(
      0.0,
      (sum, item) => sum + (item['amount'] as num).toDouble(),
    );

    return {
      'spent': totalSpent,
      'limit': 5000.0,
    };
  }

  Future<List<double>> getWeeklySpendByDay(String tenantId) async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));

    final buckets = List<double>.filled(7, 0.0);

    if (!_connectivityService.isOnline) {
      final transactions = _cacheService.getTransactions(tenantId: tenantId);
      for (final transaction in transactions) {
        if (transaction.type != 'expense') continue;

        final txDay = DateTime(
          transaction.date.year,
          transaction.date.month,
          transaction.date.day,
        );
        if (txDay.isBefore(startDate)) continue;

        final index = txDay.difference(startDate).inDays;
        if (index >= 0 && index < buckets.length) {
          buckets[index] += transaction.amount;
        }
      }
      return buckets;
    }

    final response = await _client
        .from('transactions')
        .select('date, amount')
        .eq('tenant_id', tenantId)
        .eq('type', 'expense')
        .gte('date', startDate.toIso8601String())
        .order('date', ascending: true);

    final transactions = List<Map<String, dynamic>>.from(response as List);
    for (final item in transactions) {
      final date = DateTime.parse(item['date'] as String).toLocal();
      final txDay = DateTime(date.year, date.month, date.day);
      final index = txDay.difference(startDate).inDays;
      if (index >= 0 && index < buckets.length) {
        buckets[index] += (item['amount'] as num).toDouble();
      }
    }

    return buckets;
  }

  Future<String> getUserName() async {
    final user = supabase.auth.currentUser;
    if (user == null) return '';

    final response = await _client
        .from('profiles')
        .select('name')
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return 'Usuario';
    return response['name'] as String? ?? 'Usuario';
  }

  Future<List<Budget>> getBudgets(String tenantId) async {
    final response =
        await _client.from('budgets').select().eq('tenant_id', tenantId);

    final data = response as List<dynamic>;
    return data
        .map((json) => Budget.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Actualiza una transacción y ajusta el balance de su cuenta.
  Future<void> updateTransaction({
    required String id,
    required String? notes,
    required String category,
    required double amount,
    required DateTime date,
  }) async {
    final original = await _client
        .from('transactions')
        .select('amount, type, account_id')
        .eq('id', id)
        .single();

    final originalAmount = (original['amount'] as num).toDouble();
    final type = original['type'] as String? ?? '';
    final accountId = original['account_id'] as String;

    await _client.from('transactions').update({
      'notes': notes,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
    }).eq('id', id);

    final balanceDelta = _balanceDeltaForUpdate(
      type: type,
      oldAmount: originalAmount,
      newAmount: amount,
    );
    if (balanceDelta == 0) return;

    await _applyBalanceDelta(accountId, balanceDelta);
  }

  /// Elimina una transacción y revierte su efecto en la cuenta.
  Future<void> deleteTransaction(String id) async {
    final transaction = await _client
        .from('transactions')
        .select('type, amount, account_id')
        .eq('id', id)
        .single();

    final type = transaction['type'] as String? ?? '';
    final amount = (transaction['amount'] as num).toDouble();
    final accountId = transaction['account_id'] as String;

    final balanceDelta = _balanceDeltaForDelete(type: type, amount: amount);
    if (balanceDelta != 0) {
      await _applyBalanceDelta(accountId, balanceDelta);
    }

    await _client.from('transactions').delete().eq('id', id);
  }

  Future<void> _applyBalanceDelta(String accountId, double delta) async {
    final account = await _client
        .from('accounts')
        .select('balance')
        .eq('id', accountId)
        .single();
    final currentBalance = (account['balance'] as num).toDouble();

    await _client
        .from('accounts')
        .update({'balance': currentBalance + delta}).eq('id', accountId);
  }

  double _balanceDeltaForUpdate({
    required String type,
    required double oldAmount,
    required double newAmount,
  }) {
    if (type == 'expense') {
      return oldAmount - newAmount;
    }
    if (type == 'income') {
      return newAmount - oldAmount;
    }
    return 0;
  }

  double _balanceDeltaForDelete({
    required String type,
    required double amount,
  }) {
    if (type == 'expense') {
      return amount;
    }
    if (type == 'income') {
      return -amount;
    }
    return 0;
  }
}

Transaction _transactionFromCache(CachedTransaction transaction) {
  return Transaction(
    id: transaction.id,
    accountId: transaction.accountId,
    tenantId: transaction.tenantId,
    amount: transaction.amount,
    type: transaction.type,
    category: transaction.category,
    notes: transaction.notes,
    date: transaction.date,
    transferId: transaction.transferId,
    isPendingSync: transaction.isPendingSync,
  );
}

class Budget {
  final String id;
  final String category;
  final double amount;
  final String period;

  Budget({
    required this.id,
    required this.category,
    required this.amount,
    required this.period,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      period: json['period'] as String,
    );
  }

  String get emoji => AppCategories.emojiForId(category);
}

final dashboardRepositoryProvider = Provider((ref) {
  return DashboardRepository(
    supabase,
    ref.read(connectivityServiceProvider),
    ref.read(hiveCacheServiceProvider),
  );
});

typedef UpdateTransactionCallback = Future<void> Function({
  required String id,
  required String? notes,
  required String category,
  required double amount,
  required DateTime date,
});

typedef DeleteTransactionCallback = Future<void> Function(String id);

final availableBalanceProvider =
    FutureProvider.family<double, String>((ref, tenantId) async {
  return ref.watch(dashboardRepositoryProvider).getAvailableBalance(tenantId);
});

final recentTransactionsProvider =
    FutureProvider.family<List<Transaction>, String>((ref, tenantId) async {
  return ref.watch(dashboardRepositoryProvider).getRecentTransactions(tenantId);
});

final allTransactionsProvider =
    FutureProvider.family<List<Transaction>, String>((ref, tenantId) async {
  return ref.watch(dashboardRepositoryProvider).getAllTransactions(tenantId);
});

final weeklySpendProvider =
    FutureProvider.family<Map<String, double>, String>((ref, tenantId) async {
  return ref.watch(dashboardRepositoryProvider).getWeeklySpend(tenantId);
});

final weeklySpendByDayProvider =
    FutureProvider.family<List<double>, String>((ref, tenantId) async {
  return ref.watch(dashboardRepositoryProvider).getWeeklySpendByDay(tenantId);
});

final budgetsProvider =
    FutureProvider.family<List<Budget>, String>((ref, tenantId) async {
  return ref.watch(dashboardRepositoryProvider).getBudgets(tenantId);
});

final userNameProvider = FutureProvider<String>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getUserName();
});

final updateTransactionProvider = Provider<UpdateTransactionCallback>((ref) {
  return ref.watch(dashboardRepositoryProvider).updateTransaction;
});

final deleteTransactionProvider = Provider<DeleteTransactionCallback>((ref) {
  return ref.watch(dashboardRepositoryProvider).deleteTransaction;
});

final creditCardAccountsProvider = FutureProvider.autoDispose
    .family<List<Account>, String>((ref, tenantId) async {
  final accounts = await ref.watch(allAccountsProvider(tenantId).future);
  return accounts.where((account) => account.isCreditCard).toList();
});
