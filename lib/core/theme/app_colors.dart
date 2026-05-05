import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// COMPATIBILIDAD: AppColors ahora redirige a los tokens Bruma por defecto.
// Se mantiene para que archivos que aún lo importen compilen sin errores.
// Idealmente, cada pantalla debería usar context.bruma en su lugar.
// ═══════════════════════════════════════════════════════════════════════════════

class AppColors {
  AppColors._();

  // Los colores "estáticos" apuntan a los valores de light mode de Bruma
  // para que código legacy compile. Para soporte real de dark mode,
  // cada pantalla debería usar context.bruma.

  /// Fondo principal
  static const Color background = Color(0xFFF2F5F8);

  /// Primary — Cobalt
  static const Color primary = Color(0xFF0066FF);

  /// Primary (variante más clara)
  static const Color primaryLight = Color(0xFF3385FF);

  /// Superficies — usadas en componentes legacy
  static final Color glassSurface = Colors.white.withOpacity(0.95);
  static final Color glassBorder = const Color(0x14000000);

  /// Textos
  static const Color textPrimary = Color(0xFF0D1117);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);

  /// Semánticos
  static const Color success = Color(0xFF00A878);
  static const Color error = Color(0xFFE8284B);
  static const Color warning = Color(0xFFF59E0B);
}
