import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../supabase/supabase_client.dart';
import 'auth_provider.dart';

/// Obtiene el tenant_id personal del usuario autenticado.
/// Se re-ejecuta automáticamente cuando cambia el estado de autenticación.
final tenantProvider = FutureProvider<String>((ref) async {
  // Dependencia en auth para re-ejecutar al cambiar sesión
  ref.watch(authProvider);

  final userId = supabase.auth.currentUser?.id;
  if (userId == null) throw Exception('No hay usuario autenticado');

  final data = await supabase
      .from('tenant_members')
      .select('tenant_id')
      .eq('user_id', userId)
      .eq('role', 'owner')
      .single();

  return data['tenant_id'] as String;
});
