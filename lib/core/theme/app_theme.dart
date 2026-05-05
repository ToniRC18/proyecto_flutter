import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// BRUMA DESIGN SYSTEM — Tokens, ThemeExtension y ThemeData
// Basado al 100 % en makeTokens() de Bruma/components.jsx
// ═══════════════════════════════════════════════════════════════════════════════

// ── Temas de color seleccionables por el usuario ─────────────────────────────
enum BrumaColorTheme { mint, ember, cobalt }

class _BrumaAccent {
  final Color primary;
  final Color primaryDark;
  final Color onPrimary;
  const _BrumaAccent({
    required this.primary,
    required this.primaryDark,
    required this.onPrimary,
  });
}

const _accents = {
  BrumaColorTheme.mint: _BrumaAccent(
    primary: Color(0xFF00D4AA),
    primaryDark: Color(0xFF00EFBF),
    onPrimary: Color(0xFF001A14),
  ),
  BrumaColorTheme.ember: _BrumaAccent(
    primary: Color(0xFFFF6B35),
    primaryDark: Color(0xFFFF8C5A),
    onPrimary: Color(0xFFFFFFFF),
  ),
  BrumaColorTheme.cobalt: _BrumaAccent(
    primary: Color(0xFF0066FF),
    primaryDark: Color(0xFF3385FF),
    onPrimary: Color(0xFFFFFFFF),
  ),
};

// ── ThemeExtension con TODOS los tokens Bruma ────────────────────────────────
class BrumaTheme extends ThemeExtension<BrumaTheme> {
  // Fondos
  final Color bg;
  final Color bgSecondary;
  final Color surface;
  final Color surfaceAlt;
  final Color border;

  // Textos
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  // Color del tema
  final Color primary;
  final Color onPrimary;

  // Primario con opacidad
  final Color primarySubtle;
  final Color primaryMid;

  // Estados
  final Color success;
  final Color error;
  final Color warning;

  const BrumaTheme({
    required this.bg,
    required this.bgSecondary,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.primary,
    required this.onPrimary,
    required this.primarySubtle,
    required this.primaryMid,
    required this.success,
    required this.error,
    required this.warning,
  });

  /// Fábrica que genera los tokens exactos de makeTokens()
  factory BrumaTheme.fromMode({
    required bool dark,
    BrumaColorTheme colorTheme = BrumaColorTheme.cobalt,
  }) {
    final accent = _accents[colorTheme]!;
    final p = dark ? accent.primaryDark : accent.primary;

    return BrumaTheme(
      // Fondos
      bg:           dark ? const Color(0xFF090C0E) : const Color(0xFFF2F5F8),
      bgSecondary:  dark ? const Color(0xFF111518) : const Color(0xFFFFFFFF),
      surface:      dark ? const Color(0xFF161B1F) : const Color(0xFFFFFFFF),
      surfaceAlt:   dark ? const Color(0xFF1C2226) : const Color(0xFFF7F9FB),
      border:       dark ? const Color(0x12FFFFFF) : const Color(0x14000000),

      // Textos
      textPrimary:   dark ? const Color(0xFFF0F4F8) : const Color(0xFF0D1117),
      textSecondary: dark ? const Color(0xFF8A9099) : const Color(0xFF6B7280),
      textTertiary:  dark ? const Color(0xFF4A5260) : const Color(0xFF9CA3AF),

      // Color del tema
      primary:   p,
      onPrimary: accent.onPrimary,

      // Primario con opacidad — misma lógica que en el JSX
      primarySubtle: p.withOpacity(dark ? 0.094 : 0.07),   // hex 18 ≈ 9.4%  / 12 ≈ 7%
      primaryMid:    p.withOpacity(dark ? 0.188 : 0.145),   // hex 30 ≈ 18.8% / 25 ≈ 14.5%

      // Estados
      success: dark ? const Color(0xFF00C48C) : const Color(0xFF00A878),
      error:   dark ? const Color(0xFFFF4D6A) : const Color(0xFFE8284B),
      warning: dark ? const Color(0xFFFFB020) : const Color(0xFFF59E0B),
    );
  }

  @override
  BrumaTheme copyWith({
    Color? bg,
    Color? bgSecondary,
    Color? surface,
    Color? surfaceAlt,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? primary,
    Color? onPrimary,
    Color? primarySubtle,
    Color? primaryMid,
    Color? success,
    Color? error,
    Color? warning,
  }) =>
      BrumaTheme(
        bg:            bg ?? this.bg,
        bgSecondary:   bgSecondary ?? this.bgSecondary,
        surface:       surface ?? this.surface,
        surfaceAlt:    surfaceAlt ?? this.surfaceAlt,
        border:        border ?? this.border,
        textPrimary:   textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textTertiary:  textTertiary ?? this.textTertiary,
        primary:       primary ?? this.primary,
        onPrimary:     onPrimary ?? this.onPrimary,
        primarySubtle: primarySubtle ?? this.primarySubtle,
        primaryMid:    primaryMid ?? this.primaryMid,
        success:       success ?? this.success,
        error:         error ?? this.error,
        warning:       warning ?? this.warning,
      );

  @override
  BrumaTheme lerp(ThemeExtension<BrumaTheme>? other, double t) {
    if (other is! BrumaTheme) return this;
    return BrumaTheme(
      bg:            Color.lerp(bg, other.bg, t)!,
      bgSecondary:   Color.lerp(bgSecondary, other.bgSecondary, t)!,
      surface:       Color.lerp(surface, other.surface, t)!,
      surfaceAlt:    Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      border:        Color.lerp(border, other.border, t)!,
      textPrimary:   Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary:  Color.lerp(textTertiary, other.textTertiary, t)!,
      primary:       Color.lerp(primary, other.primary, t)!,
      onPrimary:     Color.lerp(onPrimary, other.onPrimary, t)!,
      primarySubtle: Color.lerp(primarySubtle, other.primarySubtle, t)!,
      primaryMid:    Color.lerp(primaryMid, other.primaryMid, t)!,
      success:       Color.lerp(success, other.success, t)!,
      error:         Color.lerp(error, other.error, t)!,
      warning:       Color.lerp(warning, other.warning, t)!,
    );
  }
}

// ── Helper de acceso rápido ──────────────────────────────────────────────────
extension BrumaThemeContext on BuildContext {
  BrumaTheme get bruma => Theme.of(this).extension<BrumaTheme>()!;
}

// ── Generador de ThemeData ───────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  /// Genera ThemeData completo para light o dark con los tokens Bruma.
  static ThemeData _build(BrumaTheme b) {
    // TextTheme base con DM Sans
    final baseText = GoogleFonts.dmSansTextTheme();
    final textTheme = baseText.copyWith(
      displayLarge: GoogleFonts.dmSans(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.03 * 40, // -0.03em
        color: b.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      titleLarge: GoogleFonts.dmSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.03 * 22,
        color: b.textPrimary,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 17,
        color: b.textPrimary,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: b.textPrimary,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: b.textPrimary,
      ),
      bodySmall: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: b.textSecondary,
      ),
      labelSmall: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: b.textSecondary,
      ),
      labelMedium: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.06 * 11,
        color: b.textSecondary,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: b.bg.computeLuminance() < 0.5
          ? Brightness.dark
          : Brightness.light,
      scaffoldBackgroundColor: b.bg,
      primaryColor: b.primary,
      colorScheme: ColorScheme(
        brightness: b.bg.computeLuminance() < 0.5
            ? Brightness.dark
            : Brightness.light,
        primary: b.primary,
        onPrimary: b.onPrimary,
        secondary: b.primary,
        onSecondary: b.onPrimary,
        error: b.error,
        onError: Colors.white,
        surface: b.surface,
        onSurface: b.textPrimary,
      ),
      textTheme: textTheme,

      // InputDecorationTheme exacto del diseño
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: b.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: b.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: b.error, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        labelStyle: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: b.textSecondary,
        ),
        hintStyle: GoogleFonts.dmSans(
          fontSize: 15,
          color: b.textTertiary,
        ),
      ),

      // NavigationBarTheme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: b.surface.withOpacity(0.88),
        indicatorColor: Colors.transparent,
        elevation: 0,
      ),

      // ElevatedButtonTheme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: b.primary,
          foregroundColor: b.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Extensión Bruma
      extensions: [b],
    );
  }

  /// Light theme (cobalt por defecto)
  static ThemeData get lightTheme => _build(
        BrumaTheme.fromMode(dark: false),
      );

  /// Dark theme (cobalt por defecto)
  static ThemeData get darkTheme => _build(
        BrumaTheme.fromMode(dark: true),
      );
}
