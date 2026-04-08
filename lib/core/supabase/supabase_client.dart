import 'package:supabase_flutter/supabase_flutter.dart';

/// Referencia global al cliente de Supabase.
/// Disponible después de Supabase.initialize() en main.dart.
final supabase = Supabase.instance.client;
