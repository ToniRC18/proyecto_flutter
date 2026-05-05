import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';

class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository(this._client);

  /// Obtiene el nombre visible del tenant.
  Future<String> getTenantName(String tenantId) async {
    final hasNameColumn = await _tenantHasNameColumn(tenantId);
    if (!hasNameColumn) return _formatShortTenantId(tenantId);

    final tenant = await _client
        .from('tenants')
        .select('name')
        .eq('id', tenantId)
        .maybeSingle();

    final tenantName = tenant?['name'] as String?;
    if (tenantName == null || tenantName.trim().isEmpty) {
      return _formatShortTenantId(tenantId);
    }
    return tenantName;
  }

  /// Actualiza el nombre del usuario autenticado.
  Future<void> updateUserName(String name) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('No hay usuario autenticado');

    final payload = {
      'name': name.trim(),
      'full_name': name.trim(),
    };

    try {
      await _client.from('profiles').update(payload).eq('id', userId);
    } catch (_) {
      await _client
          .from('profiles')
          .update({'name': name.trim()}).eq('id', userId);
    }
  }

  /// Actualiza el nombre del tenant si la columna existe.
  Future<void> updateTenantName(String tenantId, String name) async {
    final hasNameColumn = await _tenantHasNameColumn(tenantId);
    if (!hasNameColumn) return;

    await _client
        .from('tenants')
        .update({'name': name.trim()}).eq('id', tenantId);
  }

  Future<bool> _tenantHasNameColumn(String tenantId) async {
    final currentTenant = await _client
        .from('tenants')
        .select()
        .eq('id', tenantId)
        .maybeSingle();
    if (currentTenant != null) {
      return currentTenant.containsKey('name');
    }

    final anyTenant = await _client.from('tenants').select().limit(1);
    if (anyTenant.isEmpty) return false;
    return anyTenant.first.containsKey('name');
  }

  String _formatShortTenantId(String tenantId) {
    final normalized = tenantId.replaceAll('-', '').toUpperCase();
    return normalized.length >= 8 ? normalized.substring(0, 8) : normalized;
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(supabase);
});

final tenantNameProvider =
    FutureProvider.autoDispose.family<String, String>((ref, tenantId) async {
  return ref.watch(profileRepositoryProvider).getTenantName(tenantId);
});
