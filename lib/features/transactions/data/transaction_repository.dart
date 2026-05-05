import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/offline/models/cached_account.dart';
import '../../../core/offline/models/cached_transaction.dart';
import '../../../core/offline/providers/connectivity_provider.dart';
import '../../../core/offline/providers/offline_queue_provider.dart';
import '../../../core/offline/services/connectivity_service.dart';
import '../../../core/offline/services/hive_cache_service.dart';
import '../../../core/offline/services/offline_queue_service.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../dashboard/domain/account_model.dart';

class TransactionRepository {
  final SupabaseClient _client;
  final ConnectivityService _connectivityService;
  final HiveCacheService _cacheService;
  final OfflineQueueService _queueService;
  final Uuid _uuid;

  TransactionRepository(
    this._client,
    this._connectivityService,
    this._cacheService,
    this._queueService, {
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  Future<List<Account>> getAccounts(String tenantId) async {
    if (!_connectivityService.isOnline) {
      return _cacheService
          .getAccounts(tenantId: tenantId)
          .map(_accountFromCache)
          .toList();
    }

    try {
      final response = await _client
          .from('accounts')
          .select()
          .eq('tenant_id', tenantId)
          .order('created_at', ascending: true);

      final accounts = List<Map<String, dynamic>>.from(response as List);
      await _cacheService.cacheAccounts(accounts);

      return accounts.map(Account.fromJson).toList();
    } catch (_) {
      final cached = _cacheService.getAccounts(tenantId: tenantId);
      if (cached.isNotEmpty) {
        return cached.map(_accountFromCache).toList();
      }
      throw Exception('No se pudieron cargar las cuentas disponibles.');
    }
  }

  Future<String> saveExpense({
    required String tenantId,
    required String accountId,
    required double amount,
    required String category,
    String? notes,
    bool hasSplit = false,
  }) async {
    return _saveTransaction(
      tenantId: tenantId,
      accountId: accountId,
      amount: amount,
      category: category,
      type: 'expense',
      notes: notes,
      hasSplit: hasSplit,
    );
  }

  Future<String> saveIncome({
    required String tenantId,
    required String accountId,
    required double amount,
    required String category,
    String? notes,
  }) async {
    return _saveTransaction(
      tenantId: tenantId,
      accountId: accountId,
      amount: amount,
      category: category,
      type: 'income',
      notes: notes,
    );
  }

  Future<String> _saveTransaction({
    required String tenantId,
    required String accountId,
    required double amount,
    required String category,
    required String type,
    String? notes,
    bool hasSplit = false,
  }) async {
    final transactionId = _uuid.v4();
    final now = DateTime.now();
    final transactionMap = <String, dynamic>{
      'id': transactionId,
      'tenant_id': tenantId,
      'account_id': accountId,
      'amount': amount,
      'type': type,
      'category': category,
      'notes': notes,
      'date': now.toIso8601String(),
      'has_split': hasSplit,
    };

    if (_connectivityService.isOnline) {
      try {
        await _saveOnlineTransaction(
          transactionMap: transactionMap,
          accountId: accountId,
          amount: amount,
          type: type,
        );
        return transactionId;
      } catch (error) {
        if (!_shouldFallbackOffline(error)) {
          throw Exception(
            'No se pudo guardar ${type == 'expense' ? 'el gasto' : 'el ingreso'}.',
          );
        }
      }
    }

    await _saveOfflineTransaction(
      transactionMap: transactionMap,
      accountId: accountId,
      amount: amount,
      type: type,
    );

    return transactionId;
  }

  Future<void> _saveOnlineTransaction({
    required Map<String, dynamic> transactionMap,
    required String accountId,
    required double amount,
    required String type,
  }) async {
    await _client.from('transactions').insert(transactionMap);

    final accountData = await _client
        .from('accounts')
        .select('balance')
        .eq('id', accountId)
        .single();

    final currentBalance = (accountData['balance'] as num).toDouble();
    final newBalance = type == 'expense'
        ? currentBalance - amount
        : currentBalance + amount;

    await _client.from('accounts').update({'balance': newBalance}).eq('id', accountId);

    await _cacheService.saveOfflineTransaction(
      _cachedTransactionFromMap(
        transactionMap,
        isPendingSync: false,
      ),
    );
    await _cacheService.updateAccountBalance(
      accountId,
      type == 'expense' ? -amount : amount,
    );
  }

  Future<void> _saveOfflineTransaction({
    required Map<String, dynamic> transactionMap,
    required String accountId,
    required double amount,
    required String type,
  }) async {
    await _cacheService.saveOfflineTransaction(
      _cachedTransactionFromMap(
        transactionMap,
        isPendingSync: true,
      ),
    );
    await _cacheService.updateAccountBalance(
      accountId,
      type == 'expense' ? -amount : amount,
    );
    await _queueService.enqueue(
      type: 'create_transaction',
      payload: transactionMap,
    );
  }

  bool _shouldFallbackOffline(Object error) {
    return error is SocketException ||
        error is TimeoutException ||
        error is HttpException ||
        error is PostgrestException ||
        error.toString().toLowerCase().contains('network') ||
        error.toString().toLowerCase().contains('socket') ||
        error.toString().toLowerCase().contains('timed out');
  }

  CachedTransaction _cachedTransactionFromMap(
    Map<String, dynamic> map, {
    required bool isPendingSync,
  }) {
    return CachedTransaction()
      ..id = map['id'] as String
      ..accountId = map['account_id'] as String
      ..tenantId = map['tenant_id'] as String
      ..amount = (map['amount'] as num).toDouble()
      ..type = map['type'] as String
      ..category = map['category'] as String
      ..date = DateTime.parse(map['date'] as String)
      ..notes = map['notes'] as String?
      ..cachedAt = DateTime.now()
      ..isPendingSync = isPendingSync
      ..transferId = map['transfer_id'] as String?;
  }
}

Account _accountFromCache(CachedAccount account) {
  return Account(
    id: account.id,
    tenantId: account.tenantId,
    name: account.name,
    type: account.type,
    balance: account.balance,
  );
}

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(
    supabase,
    ref.read(connectivityServiceProvider),
    ref.read(hiveCacheServiceProvider),
    ref.read(offlineQueueServiceProvider),
  );
});

final accountsProvider = FutureProvider.family<List<Account>, String>((
  ref,
  tenantId,
) async {
  return ref.watch(transactionRepositoryProvider).getAccounts(tenantId);
});
