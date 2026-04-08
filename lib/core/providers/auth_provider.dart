import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/supabase_client.dart';

/// Escucha los cambios de sesión de Supabase.
/// Emite AuthState cada vez que el usuario inicia o cierra sesión.
final authProvider = StreamProvider<AuthState>((ref) {
  return supabase.auth.onAuthStateChange;
});
