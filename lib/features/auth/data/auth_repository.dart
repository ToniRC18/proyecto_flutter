import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';

class AuthRepository {
  /// Registro: crea usuario + perfil (via trigger automático de Supabase)
  Future<void> signUp(String email, String password, String name) async {
    await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
      emailRedirectTo: null,
    );
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
    await supabase.auth.signOut();
  }

  /// Usuario autenticado actual (null si no hay sesión)
  User? get currentUser => supabase.auth.currentUser;
}

final authRepositoryProvider = Provider((ref) => AuthRepository());
