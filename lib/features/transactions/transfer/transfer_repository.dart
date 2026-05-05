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
import '../../accounts/data/accounts_repository.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../../dashboard/domain/account_model.dart';
import '../data/transaction_repository.dart';

class TransferRepository {
  final SupabaseClient _client;
  final ConnectivityService _connectivityService;
  final HiveCacheService _cacheService;
  final OfflineQueueService _queueService;
  final Uuid _uuid;

  TransferRepository(
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
      final raw = await _client
          .from('accounts')
          .select()
          .eq('tenant_id', tenantId)
          .order('created_at', ascending: true);

      final accounts = List<Map<String, dynamic>>.from(raw as List);
      await _cacheService.cacheAccounts(accounts);
      return accounts.map(Account.fromJson).toList();
    } catch (_) {
      final cached = _cacheService.getAccounts(tenantId: tenantId);
      if (cached.isNotEmpty) {
        return cached.map(_accountFromCache).toList();
      }
      throw Exception('No se pudieron cargar las cuentas para transferir.');
    }
  }

  Future<void> createTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required String tenantId,
    String? notes,
    DateTime? date,
  }) async {
    if (fromAccountId == toAccountId) {
      throw Exception('La cuenta origen y destino deben ser diferentes.');
    }

    if (amount <= 0) {
      throw Exception('El monto debe ser mayor a cero.');
    }

    final transferId = _uuid.v4();
    final outId = _uuid.v4();
    final inId = _uuid.v4();
    final transferDate = (date ?? DateTime.now()).toIso8601String();
    final cleanNotes = notes?.trim().isEmpty ?? true ? null : notes!.trim();

    final transferOut = <String, dynamic>{
      'id': outId,
      'tenant_id': tenantId,
      'account_id': fromAccountId,
      'amount': amount,
      'type': 'transfer_out',
      'category': 'transfer',
      'transfer_id': transferId,
      'linked_account_id': toAccountId,
      'date': transferDate,
      'notes': cleanNotes,
    };
    final transferIn = <String, dynamic>{
      'id': inId,
      'tenant_id': tenantId,
      'account_id': toAccountId,
      'amount': amount,
      'type': 'transfer_in',
      'category': 'transfer',
      'transfer_id': transferId,
      'linked_account_id': fromAccountId,
      'date': transferDate,
      'notes': cleanNotes,
    };

    if (_connectivityService.isOnline) {
      try {
        await _createOnlineTransfer(
          fromAccountId: fromAccountId,
          toAccountId: toAccountId,
          amount: amount,
          transferId: transferId,
          transferOut: transferOut,
          transferIn: transferIn,
        );
        return;
      } catch (error) {
        if (!_shouldFallbackOffline(error)) {
          throw Exception(
            'No se pudo completar la transferencia: ${_cleanErrorMessage(error)}',
          );
        }
      }
    }

    await _createOfflineTransfer(
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      amount: amount,
      transferOut: transferOut,
      transferIn: transferIn,
    );
  }

  Future<void> _createOnlineTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required String transferId,
    required Map<String, dynamic> transferOut,
    required Map<String, dynamic> transferIn,
  }) async {
    double? previousFromBalance;
    double? previousToBalance;

    try {
      final accountsData = await _client
          .from('accounts')
          .select('id, balance')
          .inFilter('id', [fromAccountId, toAccountId]);

      final accounts = (accountsData as List).cast<Map<String, dynamic>>();
      if (accounts.length != 2) {
        throw Exception('No se pudieron validar las cuentas de la transferencia.');
      }

      final fromAccount = accounts.firstWhere((acc) => acc['id'] == fromAccountId);
      final toAccount = accounts.firstWhere((acc) => acc['id'] == toAccountId);

      previousFromBalance = (fromAccount['balance'] as num).toDouble();
      previousToBalance = (toAccount['balance'] as num).toDouble();

      if (previousFromBalance < amount) {
        throw Exception('Saldo insuficiente en la cuenta origen.');
      }

      await _client.from('transactions').insert(transferOut);
      await _client.from('transactions').insert(transferIn);

      await _client
          .from('accounts')
          .update({'balance': previousFromBalance - amount})
          .eq('id', fromAccountId);

      await _client
          .from('accounts')
          .update({'balance': previousToBalance + amount})
          .eq('id', toAccountId);

      await _cacheService.saveOfflineTransaction(
        _cachedTransactionFromMap(transferOut, isPendingSync: false),
      );
      await _cacheService.saveOfflineTransaction(
        _cachedTransactionFromMap(transferIn, isPendingSync: false),
      );
      await _cacheService.updateAccountBalance(fromAccountId, -amount);
      await _cacheService.updateAccountBalance(toAccountId, amount);
    } catch (error) {
      await _rollbackTransfer(
        transferId: transferId,
        fromAccountId: fromAccountId,
        toAccountId: toAccountId,
        previousFromBalance: previousFromBalance,
        previousToBalance: previousToBalance,
      );
      rethrow;
    }
  }

  Future<void> _createOfflineTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required Map<String, dynamic> transferOut,
    required Map<String, dynamic> transferIn,
  }) async {
    final cachedAccounts = {
      for (final account in _cacheService.getAccounts()) account.id: account,
    };
    final fromAccount = cachedAccounts[fromAccountId];
    if (fromAccount != null && fromAccount.balance < amount) {
      throw Exception('Saldo insuficiente en la cuenta origen.');
    }

    await _cacheService.saveOfflineTransaction(
      _cachedTransactionFromMap(transferOut, isPendingSync: true),
    );
    await _cacheService.saveOfflineTransaction(
      _cachedTransactionFromMap(transferIn, isPendingSync: true),
    );
    await _cacheService.updateAccountBalance(fromAccountId, -amount);
    await _cacheService.updateAccountBalance(toAccountId, amount);
    await _queueService.enqueue(
      type: 'create_transfer',
      payload: {
        'transfer_out': transferOut,
        'transfer_in': transferIn,
      },
    );
  }

  Future<void> _rollbackTransfer({
    required String transferId,
    required String fromAccountId,
    required String toAccountId,
    required double? previousFromBalance,
    required double? previousToBalance,
  }) async {
    try {
      await _client.from('transactions').delete().eq('transfer_id', transferId);

      if (previousFromBalance != null) {
        await _client
            .from('accounts')
            .update({'balance': previousFromBalance})
            .eq('id', fromAccountId);
      }

      if (previousToBalance != null) {
        await _client
            .from('accounts')
            .update({'balance': previousToBalance})
            .eq('id', toAccountId);
      }
    } catch (_) {
      // El método principal ya devuelve el error relevante.
    }
  }

  bool _shouldFallbackOffline(Object error) {
    final message = error.toString().toLowerCase();
    return error is SocketException ||
        error is TimeoutException ||
        error is HttpException ||
        message.contains('network') ||
        message.contains('socket') ||
        message.contains('timed out');
  }

  String _cleanErrorMessage(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
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

final transferRepositoryProvider = Provider<TransferRepository>((ref) {
  return TransferRepository(
    supabase,
    ref.read(connectivityServiceProvider),
    ref.read(hiveCacheServiceProvider),
    ref.read(offlineQueueServiceProvider),
  );
});

final transferAccountsProvider =
    FutureProvider.autoDispose.family<List<Account>, String>((ref, tenantId) {
  return ref.watch(transferRepositoryProvider).getAccounts(tenantId);
});

final transferRefreshProvider = Provider<void Function(String)>((ref) {
  return (tenantId) {
    ref.invalidate(accountsProvider(tenantId));
    ref.invalidate(allAccountsProvider(tenantId));
    ref.invalidate(totalBalanceProvider(tenantId));
    ref.invalidate(availableBalanceProvider(tenantId));
    ref.invalidate(recentTransactionsProvider(tenantId));
  };
});
