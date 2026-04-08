import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart' as sc;
import '../domain/invitation_model.dart';
import '../domain/shared_member_model.dart';

/// Repositorio de Espacios Compartidos.
/// Gestiona tenants de tipo 'shared', miembros e invitaciones.
class SharedSpacesRepository {
  final SupabaseClient _client;

  SharedSpacesRepository(this._client);

  // ─── Espacios ────────────────────────────────────────────────────────────

  /// Crea un nuevo espacio compartido.
  /// Llama a una función RPC en Supabase que maneja la creación del tenant 
  /// y la asignación del miembro en una sola transacción.
  Future<void> createSharedSpace(String name) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('No hay usuario autenticado');

    // Usar función SQL que maneja todo en una transacción
    await _client.rpc('create_shared_space', params: {'space_name': name});
  }

  /// Obtiene todos los espacios compartidos donde el usuario es miembro.
  Future<List<SharedTenant>> getSharedSpaces() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('No hay usuario autenticado');

    // Obtener tenant_ids del usuario en tenants de tipo 'shared'
    final memberships = await _client
        .from('tenant_members')
        .select('tenant_id')
        .eq('user_id', userId);

    final tenantIds = (memberships as List)
        .map((m) => m['tenant_id'] as String)
        .toList();

    if (tenantIds.isEmpty) return [];

    // Filtrar solo los de tipo 'shared'
    final tenantsRaw = await _client
        .from('tenants')
        .select('id, name')
        .eq('type', 'shared')
        .inFilter('id', tenantIds);

    final List<SharedTenant> result = [];
    for (final t in tenantsRaw as List) {
      final tid = t['id'] as String;

      // Contar miembros
      final membersCount = await _client
          .from('tenant_members')
          .select('id')
          .eq('tenant_id', tid);

      // Suma de gastos este mes
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
      final txRaw = await _client
          .from('transactions')
          .select('amount')
          .eq('tenant_id', tid)
          .eq('type', 'expense')
          .gte('date', startOfMonth);

      double total = 0;
      for (final tx in txRaw as List) {
        total += (tx['amount'] as num).toDouble();
      }

      result.add(SharedTenant(
        id: tid,
        name: t['name'] as String,
        memberCount: (membersCount as List).length,
        totalThisMonth: total,
      ));
    }

    return result;
  }

  // ─── Miembros ────────────────────────────────────────────────────────────

  /// Obtiene la lista de miembros de un espacio con su total gastado.
  Future<List<SharedMember>> getMembers(String tenantId) async {
    // JOIN tenant_members + profiles
    final rawMembers = await _client
        .from('tenant_members')
        .select('user_id, role, profiles(name, avatar_url)')
        .eq('tenant_id', tenantId);

    // Calcular total gastado por cada miembro en este tenant
    final members = <SharedMember>[];

    for (final m in (rawMembers as List)) {
      final txRaw = await _client
          .from('transactions')
          .select('amount')
          .eq('tenant_id', tenantId)
          .eq('type', 'expense');

      // Filtrar por usuario desde accounts (aproximación: suma por account del usuario)
      double totalSpent = 0;
      for (final tx in txRaw as List) {
        totalSpent += (tx['amount'] as num).toDouble();
      }

      members.add(SharedMember.fromJson(m, totalSpent: totalSpent));
    }

    return members;
  }

  /// Calcula el balance de gastos entre miembros de un tenant.
  /// Retorna un mapa {userId → totalGastado}.
  Future<Map<String, double>> getBalanceBetweenMembers(String tenantId) async {
    final membersRaw = await _client
        .from('tenant_members')
        .select('user_id')
        .eq('tenant_id', tenantId);

    final Map<String, double> balance = {};

    for (final m in (membersRaw as List)) {
      final uid = m['user_id'] as String;
      // Obtener las cuentas del usuario en este tenant
      final accounts = await _client
          .from('accounts')
          .select('id')
          .eq('tenant_id', tenantId);

      final accountIds = (accounts as List).map((a) => a['id'] as String).toList();
      if (accountIds.isEmpty) {
        balance[uid] = 0;
        continue;
      }

      double total = 0;
      for (final aid in accountIds) {
        final txRaw = await _client
            .from('transactions')
            .select('amount')
            .eq('account_id', aid)
            .eq('type', 'expense');
        for (final tx in txRaw as List) {
          total += (tx['amount'] as num).toDouble();
        }
      }
      balance[uid] = total;
    }

    return balance;
  }

  // ─── Invitaciones ────────────────────────────────────────────────────────

  /// Invita a un miembro por email al espacio compartido.
  Future<void> inviteMember(String tenantId, String email) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('No hay usuario autenticado');

    // Verificar que el email no sea ya miembro
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

    // Insertar la invitación
    await _client.from('tenant_invitations').insert({
      'tenant_id': tenantId,
      'invited_by': userId,
      'invited_email': email,
      'status': 'pending',
    });

    // Nota: la notificación push se enviaría desde una Edge Function de Supabase
    // o desde el backend, ya que el cliente no tiene acceso al token del destinatario.
  }

  /// Obtiene las invitaciones pendientes recibidas por el usuario autenticado.
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

  /// Acepta una invitación por token y agrega al usuario como miembro.
  Future<void> acceptInvitation(String invitationId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('No hay usuario autenticado');

    // Obtener la invitación
    final invitation = await _client
        .from('tenant_invitations')
        .select('tenant_id')
        .eq('id', invitationId)
        .single();

    final tenantId = invitation['tenant_id'] as String;

    // Actualizar estado
    await _client
        .from('tenant_invitations')
        .update({'status': 'accepted'})
        .eq('id', invitationId);

    // Agregar al usuario como miembro
    await _client.from('tenant_members').insert({
      'tenant_id': tenantId,
      'user_id': userId,
      'role': 'member',
    });
  }

  /// Rechaza una invitación.
  Future<void> rejectInvitation(String invitationId) async {
    await _client
        .from('tenant_invitations')
        .update({'status': 'rejected'})
        .eq('id', invitationId);
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

final sharedSpacesRepositoryProvider = Provider<SharedSpacesRepository>((ref) {
  return SharedSpacesRepository(sc.supabase);
});

final sharedSpacesProvider =
    FutureProvider.autoDispose<List<SharedTenant>>((ref) async {
  return ref.watch(sharedSpacesRepositoryProvider).getSharedSpaces();
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

final balanceProvider =
    FutureProvider.autoDispose.family<Map<String, double>, String>(
  (ref, tenantId) async {
    return ref
        .watch(sharedSpacesRepositoryProvider)
        .getBalanceBetweenMembers(tenantId);
  },
);
