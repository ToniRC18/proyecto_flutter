import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart' as sc;
import '../../transactions/domain/transaction_model.dart';
import '../domain/invitation_model.dart';
import '../domain/shared_member_model.dart';

/// Repositorio de espacios compartidos.
/// Gestiona tenants shared, miembros, invitaciones, balances y movimientos.
class SharedSpacesRepository {
  final SupabaseClient _client;

  SharedSpacesRepository(this._client);

  // ─── Espacios ────────────────────────────────────────────────────────────

  /// Crea un nuevo espacio compartido.
  Future<void> createSharedSpace(String name) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('No hay usuario autenticado');

    await _client.rpc('create_shared_space', params: {'space_name': name});
  }

  /// Obtiene todos los espacios shared del usuario evitando el N+1 principal.
  Future<List<SharedTenant>> getSharedSpaces() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('No hay usuario autenticado');

    final data = await _client
        .from('tenant_members')
        .select('tenant_id, tenants!inner(id, name, type)')
        .eq('user_id', userId)
        .eq('tenants.type', 'shared');

    final memberships = (data as List).cast<Map<String, dynamic>>();
    if (memberships.isEmpty) return [];

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();

    final spaces = await Future.wait(memberships.map((membership) async {
      final tenant = membership['tenants'] as Map<String, dynamic>;
      final tenantId = tenant['id'] as String;

      final results = await Future.wait([
        _client
            .from('tenant_members')
            .select('user_id')
            .eq('tenant_id', tenantId),
        _client
            .from('transactions')
            .select('amount')
            .eq('tenant_id', tenantId)
            .eq('type', 'expense')
            .gte('date', startOfMonth),
      ]);

      final members = (results[0] as List);
      final transactions = (results[1] as List);
      final totalThisMonth = transactions.fold<double>(
        0,
        (sum, item) =>
            sum + ((item as Map<String, dynamic>)['amount'] as num).toDouble(),
      );

      return SharedTenant(
        id: tenantId,
        name: tenant['name'] as String,
        memberCount: members.length,
        totalThisMonth: totalThisMonth,
      );
    }));

    return spaces;
  }

  Future<SharedTenant> getSharedSpace(String tenantId) async {
    final tenant = await _client
        .from('tenants')
        .select('id, name')
        .eq('id', tenantId)
        .single();
    final members = await _client
        .from('tenant_members')
        .select('user_id')
        .eq('tenant_id', tenantId);
    final totalThisMonth = await _monthExpenses(tenantId);

    return SharedTenant(
      id: tenant['id'] as String,
      name: tenant['name'] as String,
      memberCount: (members as List).length,
      totalThisMonth: totalThisMonth,
    );
  }

  Future<double> _monthExpenses(String tenantId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
    final raw = await _client
        .from('transactions')
        .select('amount')
        .eq('tenant_id', tenantId)
        .eq('type', 'expense')
        .gte('date', startOfMonth);

    return (raw as List).fold<double>(
      0,
      (sum, item) =>
          sum + ((item as Map<String, dynamic>)['amount'] as num).toDouble(),
    );
  }

  // ─── Movimientos ─────────────────────────────────────────────────────────

  Future<List<Transaction>> getSpaceTransactions(
    String tenantId, {
    int limit = 30,
  }) async {
    final raw = await _client
        .from('transactions')
        .select()
        .eq('tenant_id', tenantId)
        .order('date', ascending: false)
        .limit(limit);

    return (raw as List)
        .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ─── Miembros y balances ─────────────────────────────────────────────────

  Future<List<SharedMember>> getMembers(String tenantId) async {
    final rawMembers = await _client
        .from('tenant_members')
        .select('user_id, role, profiles(name, avatar_url)')
        .eq('tenant_id', tenantId);

    return (rawMembers as List)
        .map((json) => SharedMember.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<MemberBalance>> getMemberBalances(String tenantId) async {
    final members = await getMembers(tenantId);
    if (members.isEmpty) return [];

    final currentUserId = _client.auth.currentUser?.id;

    final balances = await Future.wait(members.map((member) async {
      final owed = await _memberUnsettledOwed(tenantId, member.userId);

      // En el esquema real no hay payer_id/creditor_id; solo user_id del split.
      // Para la vista se modela al usuario actual como acreedor de splits ajenos.
      final paid = member.userId == currentUserId
          ? await _othersUnsettledOwed(tenantId, member.userId)
          : 0.0;

      return MemberBalance(
        userId: member.userId,
        name: member.name,
        avatarUrl: member.avatarUrl,
        totalPaid: paid,
        totalOwed: owed,
        netBalance: paid - owed,
      );
    }));

    return balances;
  }

  Future<double> _memberUnsettledOwed(String tenantId, String userId) async {
    final transactionIds = await _transactionIdsForTenant(tenantId);
    if (transactionIds.isEmpty) return 0;

    final raw = await _client
        .from('transaction_splits')
        .select('amount')
        .eq('user_id', userId)
        .eq('is_settled', false)
        .inFilter('transaction_id', transactionIds);

    return (raw as List).fold<double>(
      0,
      (sum, item) =>
          sum + ((item as Map<String, dynamic>)['amount'] as num).toDouble(),
    );
  }

  Future<double> _othersUnsettledOwed(String tenantId, String userId) async {
    final transactionIds = await _transactionIdsForTenant(tenantId);
    if (transactionIds.isEmpty) return 0;

    final raw = await _client
        .from('transaction_splits')
        .select('amount, user_id')
        .eq('is_settled', false)
        .inFilter('transaction_id', transactionIds);

    return (raw as List).fold<double>(0, (sum, item) {
      final row = item as Map<String, dynamic>;
      if (row['user_id'] == userId) return sum;
      return sum + (row['amount'] as num).toDouble();
    });
  }

  Future<Map<String, double>> getBalanceBetweenMembers(String tenantId) async {
    final balances = await getMemberBalances(tenantId);
    return {
      for (final balance in balances) balance.userId: balance.netBalance,
    };
  }

  Future<void> settleBalance({
    required String tenantId,
    required String debtorId,
    required String creditorId,
    required double amount,
  }) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('No autenticado');
      }

      // Solo el deudor o el acreedor pueden saldar esta deuda.
      if (currentUserId != debtorId && currentUserId != creditorId) {
        throw Exception('No tienes permiso para saldar esta deuda');
      }

      final transactionIds = await _transactionIdsForTenant(tenantId);
      if (transactionIds.isEmpty) return;

      await _client
          .from('transaction_splits')
          .update({
            'is_settled': true,
            'settled_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', debtorId)
          .eq('is_settled', false)
          .inFilter('transaction_id', transactionIds);

      final accountId = await _firstAccountId(tenantId);
      if (accountId == null) return;

      await _client.from('transactions').insert({
        'tenant_id': tenantId,
        'type': 'income',
        'amount': amount,
        'category': 'settlement',
        'notes': 'Saldo liquidado',
        'date': DateTime.now().toIso8601String(),
        'account_id': accountId,
      });
    } catch (_) {
      rethrow;
    }
  }

  Future<List<String>> _transactionIdsForTenant(String tenantId) async {
    final raw = await _client
        .from('transactions')
        .select('id')
        .eq('tenant_id', tenantId);

    return (raw as List)
        .map((item) => (item as Map<String, dynamic>)['id'] as String)
        .toList();
  }

  Future<String?> _firstAccountId(String tenantId) async {
    final raw = await _client
        .from('accounts')
        .select('id')
        .eq('tenant_id', tenantId)
        .limit(1);

    final accounts = (raw as List).cast<Map<String, dynamic>>();
    if (accounts.isEmpty) return null;
    return accounts.first['id'] as String?;
  }

  // ─── Invitaciones ────────────────────────────────────────────────────────

  Future<void> inviteMember(String tenantId, String email) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('No hay usuario autenticado');

    final existing = await _client
        .from('tenant_invitations')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('invited_email', email)
        .eq('status', 'pending')
        .maybeSingle();

    if (existing != null) {
      throw Exception('Ya existe una invitación pendiente para $email');
    }

    await _client.from('tenant_invitations').insert({
      'tenant_id': tenantId,
      'invited_by': userId,
      'invited_email': email,
      'status': 'pending',
    });
  }

  Future<List<TenantInvitation>> getPendingInvitations() async {
    final userEmail = _client.auth.currentUser?.email;
    if (userEmail == null) throw Exception('No hay usuario autenticado');

    final raw = await _client
        .from('tenant_invitations')
        .select(
          'id, tenant_id, invited_email, status, created_at, '
          'tenants(name), profiles!invited_by(name)',
        )
        .eq('invited_email', userEmail)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (raw as List)
        .map((json) => TenantInvitation.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> acceptInvitation(String invitationId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('No hay usuario autenticado');

    final invitation = await _client
        .from('tenant_invitations')
        .select('tenant_id')
        .eq('id', invitationId)
        .single();

    final tenantId = invitation['tenant_id'] as String;

    await _client
        .from('tenant_invitations')
        .update({'status': 'accepted'}).eq('id', invitationId);

    await _client.from('tenant_members').insert({
      'tenant_id': tenantId,
      'user_id': userId,
      'role': 'member',
    });
  }

  Future<void> rejectInvitation(String invitationId) async {
    await _client
        .from('tenant_invitations')
        .update({'status': 'rejected'}).eq('id', invitationId);
  }
}

// ─── Providers ─────────────────────────────────────────────────────────────

final sharedSpacesRepositoryProvider = Provider<SharedSpacesRepository>((ref) {
  return SharedSpacesRepository(sc.supabase);
});

final sharedSpacesProvider =
    FutureProvider.autoDispose<List<SharedTenant>>((ref) async {
  return ref.watch(sharedSpacesRepositoryProvider).getSharedSpaces();
});

final sharedSpaceProvider =
    FutureProvider.autoDispose.family<SharedTenant, String>((ref, tenantId) {
  return ref.watch(sharedSpacesRepositoryProvider).getSharedSpace(tenantId);
});

final pendingInvitationsProvider =
    FutureProvider.autoDispose<List<TenantInvitation>>((ref) async {
  return ref.watch(sharedSpacesRepositoryProvider).getPendingInvitations();
});

final membersProvider =
    FutureProvider.autoDispose.family<List<SharedMember>, String>(
  (ref, tenantId) async {
    return ref.watch(sharedSpacesRepositoryProvider).getMembers(tenantId);
  },
);

final memberBalancesProvider =
    FutureProvider.autoDispose.family<List<MemberBalance>, String>(
  (ref, tenantId) async {
    return ref
        .watch(sharedSpacesRepositoryProvider)
        .getMemberBalances(tenantId);
  },
);

final spaceTransactionsProvider =
    FutureProvider.autoDispose.family<List<Transaction>, String>(
  (ref, tenantId) async {
    return ref
        .watch(sharedSpacesRepositoryProvider)
        .getSpaceTransactions(tenantId, limit: 15);
  },
);

final balanceProvider =
    FutureProvider.autoDispose.family<Map<String, double>, String>(
  (ref, tenantId) async {
    return ref
        .watch(sharedSpacesRepositoryProvider)
        .getBalanceBetweenMembers(tenantId);
  },
);
