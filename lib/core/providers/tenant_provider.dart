import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/supabase_client.dart';
import 'auth_provider.dart';

class ActiveTenant {
  final String id;
  final String name;
  final String type;

  const ActiveTenant({
    required this.id,
    required this.name,
    required this.type,
  });

  bool get isShared => type == 'shared';
}

/// Obtiene el tenant_id personal del usuario autenticado.
/// Se re-ejecuta automáticamente cuando cambia el estado de autenticación.
final tenantProvider = FutureProvider<String>((ref) async {
  // Dependencia en auth para re-ejecutar al cambiar sesión
  ref.watch(authProvider);

  final userId = supabase.auth.currentUser?.id;
  if (userId == null) throw Exception('No hay usuario autenticado');

  // Intentar varias veces para dar margen a que el trigger cree el tenant personal.
  return _fetchTenantIdWithRetry(supabase, userId);
});

Future<String> _fetchTenantIdWithRetry(
  SupabaseClient client,
  String userId, {
  int maxAttempts = 4,
  Duration delay = const Duration(milliseconds: 800),
}) async {
  for (int attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      // Buscar el tenant personal en el que el usuario quedó como owner.
      final response = await client
          .from('tenant_members')
          .select('tenant_id, tenants!inner(type)')
          .eq('user_id', userId)
          .eq('role', 'owner')
          .eq('tenants.type', 'personal')
          .limit(1);

      // Si ya existe el tenant personal, devolverlo de inmediato.
      if (response.isNotEmpty && response.first['tenant_id'] != null) {
        return response.first['tenant_id'] as String;
      }

      // Si todavía no aparece y quedan intentos, esperar con backoff incremental.
      if (attempt < maxAttempts) {
        await Future.delayed(delay * attempt);
      }
    } catch (e) {
      // Si falla la consulta y aún quedan intentos, volver a intentar tras una espera.
      if (attempt == maxAttempts) rethrow;
      await Future.delayed(delay * attempt);
    }
  }

  // Emitir un mensaje claro cuando el espacio personal no estuvo listo a tiempo.
  throw Exception(
    'No se encontró el espacio personal. '
    'Intenta cerrar sesión y volver a entrar.',
  );
}

/// Guarda el tenant compartido activo mientras el usuario navega en esa vista.
final activeTenantOverrideProvider = StateProvider<String?>((ref) => null);

/// Resuelve el tenant actualmente activo para operaciones contextuales.
final activeTenantProvider = FutureProvider<ActiveTenant>((ref) async {
  ref.watch(authProvider);

  final overrideTenantId = ref.watch(activeTenantOverrideProvider);
  final personalTenantId = await ref.watch(tenantProvider.future);
  final tenantId = overrideTenantId ?? personalTenantId;

  final data = await supabase
      .from('tenants')
      .select('id, name, type')
      .eq('id', tenantId)
      .maybeSingle();

  // Validar que el tenant activo exista antes de construir el estado expuesto.
  if (data == null) {
    throw Exception('No se encontró el espacio activo');
  }

  return ActiveTenant(
    id: data['id'] as String,
    name: data['name'] as String? ?? 'Espacio',
    type: data['type'] as String? ?? 'personal',
  );
});
