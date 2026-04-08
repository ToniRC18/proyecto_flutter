import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../dashboard/domain/account_model.dart';

/// Repositorio de cuentas (accounts).
/// Maneja lectura, creación y eliminación de cuentas en Supabase.
class AccountsRepository {
  final SupabaseClient _client;
  AccountsRepository(this._client);

  /// Obtiene todas las cuentas del tenant.
  Future<List<Account>> getAccounts(String tenantId) async {
    final raw = await _client
        .from('accounts')
        .select()
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: true);
    return (raw as List)
        .map((json) => Account.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Crea una cuenta nueva con balance inicial opcional.
  Future<void> createAccount({
    required String tenantId,
    required String name,
    required String type,
    double initialBalance = 0,
  }) async {
    await _client.from('accounts').insert({
      'tenant_id': tenantId,
      'name': name,
      'type': type,
      'balance': initialBalance,
    });
  }

  /// Elimina una cuenta por ID.
  Future<void> deleteAccount(String accountId) async {
    await _client.from('accounts').delete().eq('id', accountId);
  }

  /// Suma el balance de todas las cuentas del tenant.
  Future<double> getTotalBalance(String tenantId) async {
    final raw = await _client
        .from('accounts')
        .select('balance')
        .eq('tenant_id', tenantId);
    return (raw as List).fold<double>(
      0.0,
      (sum, item) => sum + (item['balance'] as num).toDouble(),
    );
  }

  /// Renombra una cuenta existente.
  Future<void> renameAccount(String accountId, String newName) async {
    await _client
        .from('accounts')
        .update({'name': newName})
        .eq('id', accountId);
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final accountsRepositoryProvider = Provider<AccountsRepository>((ref) {
  return AccountsRepository(supabase);
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
