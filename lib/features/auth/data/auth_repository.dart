import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/notifications/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/onboarding/onboarding_service.dart';
import '../../../core/supabase/supabase_client.dart';

class AuthRepository {
  /// Registro: crea usuario + perfil (via trigger automático de Supabase)
  Future<void> signUp(String email, String password, String name) async {
    // Enviar el nombre en ambos campos para mantener compatibilidad con el trigger.
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'full_name': name},
      emailRedirectTo: null,
    );

    // Esperar a que el trigger de Supabase termine
    // (handle_new_user puede tardar hasta 1-2 segundos)
    if (response.user != null) {
      await _waitForProfileCreation(response.user!.id);
    }
  }

  /// Inicio de sesión con email y contraseña
  Future<void> signIn(String email, String password) async {
    await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Cierre de sesión
  Future<void> signOut() async {
    await NotificationService.clearPushTokenForCurrentUser();
    await supabase.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_completed');
    await onboardingService.reset();
  }

  /// Usuario autenticado actual (null si no hay sesión)
  User? get currentUser => supabase.auth.currentUser;

  Future<void> _waitForProfileCreation(
    String userId, {
    int maxAttempts = 5,
    Duration delay = const Duration(milliseconds: 600),
  }) async {
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        // Consultar si el perfil ya fue creado por el trigger de Auth.
        final profile = await supabase
            .from('profiles')
            .select('id')
            .eq('id', userId)
            .maybeSingle();

        // Si el perfil ya existe, continuar con el flujo normal.
        if (profile != null) return;

        // Si aún no existe y quedan intentos, esperar antes de consultar otra vez.
        if (attempt < maxAttempts) {
          await Future.delayed(delay);
        }
      } catch (_) {
        // Si la consulta falla de forma temporal, esperar y reintentar.
        if (attempt < maxAttempts) {
          await Future.delayed(delay);
        }
      }
    }

    // Si el perfil sigue sin existir, continuar de todos modos.
    // El retry del tenantProvider cubrirá el resto del flujo.
  }
}

final authRepositoryProvider = Provider((ref) => AuthRepository());
