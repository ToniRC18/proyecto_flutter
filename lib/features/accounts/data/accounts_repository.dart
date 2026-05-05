import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/offline/models/cached_account.dart';
import '../../../core/offline/providers/connectivity_provider.dart';
import '../../../core/offline/providers/offline_queue_provider.dart';
import '../../../core/offline/services/connectivity_service.dart';
import '../../../core/offline/services/hive_cache_service.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../dashboard/domain/account_model.dart';

/// Repositorio de cuentas (accounts).
/// Maneja lectura, creación y eliminación de cuentas en Supabase.
class AccountsRepository {
  final SupabaseClient _client;
  final ConnectivityService _connectivityService;
  final HiveCacheService _cacheService;

  AccountsRepository(
    this._client,
    this._connectivityService,
    this._cacheService,
  );

  /// Obtiene todas las cuentas del tenant.
  Future<List<Account>> getAccounts(String tenantId) async {
    if (!_connectivityService.isOnline) {
      return _cacheService
          .getAccounts(tenantId: tenantId)
          .map(_accountFromCache)
          .toList();
    }

    final raw = await _client
        .from('accounts')
        .select()
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: true);

    final accounts = (raw as List)
        .map((json) => json as Map<String, dynamic>)
        .toList(growable: false);

    await _cacheService.cacheAccounts(accounts);

    return accounts.map(Account.fromJson).toList();
  }

  /// Crea una cuenta nueva con balance inicial opcional.
  Future<String> createAccount({
    required String tenantId,
    required String name,
    required String type,
    double initialBalance = 0,
  }) async {
    final response = await _client
        .from('accounts')
        .insert({
          'tenant_id': tenantId,
          'name': name,
          'type': type,
          'balance': initialBalance,
        })
        .select('id')
        .single();

    return response['id'] as String;
  }

  /// Elimina una cuenta por ID.
  Future<void> deleteAccount(String accountId) async {
    await _client.from('accounts').delete().eq('id', accountId);
  }

  /// Suma el balance de todas las cuentas del tenant.
  Future<double> getTotalBalance(String tenantId) async {
    if (!_connectivityService.isOnline) {
      return _cacheService
          .getAccounts(tenantId: tenantId)
          .fold<double>(0.0, (sum, account) => sum + account.balance);
    }

    final raw = await _client
        .from('accounts')
        .select('balance')
        .eq('tenant_id', tenantId);

    final accounts = (raw as List).cast<Map<String, dynamic>>();

    final cachedAccounts = await _client
        .from('accounts')
        .select()
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: true);
    await _cacheService.cacheAccounts(
      List<Map<String, dynamic>>.from(cachedAccounts as List),
    );

    return accounts.fold<double>(
      0.0,
      (sum, item) => sum + (item['balance'] as num).toDouble(),
    );
  }

  /// Renombra una cuenta existente.
  Future<void> renameAccount(String accountId, String newName) async {
    await _client
        .from('accounts')
        .update({'name': newName}).eq('id', accountId);
  }
}

Account _accountFromCache(CachedAccount account) {
  return Account(
    id: account.id,
    tenantId: account.tenantId,
    name: account.name,
    type: account.type,
    balance: account.balance,
    creditLimit: account.creditLimit,
    billingCloseDay: account.billingCloseDay,
    paymentDueDay: account.paymentDueDay,
  );
}

// ─── Providers ────────────────────────────────────────────────────────────────

final accountsRepositoryProvider = Provider<AccountsRepository>((ref) {
  return AccountsRepository(
    supabase,
    ref.read(connectivityServiceProvider),
    ref.read(hiveCacheServiceProvider),
  );
});

/// Lista de cuentas del tenant.
final allAccountsProvider =
    FutureProvider.autoDispose.family<List<Account>, String>((ref, tenantId) {
  return ref.watch(accountsRepositoryProvider).getAccounts(tenantId);
});

/// Balance total del tenant.
final totalBalanceProvider =
    FutureProvider.autoDispose.family<double, String>((ref, tenantId) {
  return ref.watch(accountsRepositoryProvider).getTotalBalance(tenantId);
});
