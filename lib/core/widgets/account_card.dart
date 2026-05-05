import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// AccountCard — Basado EXACTAMENTE en AccountCard de components.jsx
// Compact (160x100 scroll horizontal) y Full (AppCard)
// ═══════════════════════════════════════════════════════════════════════════════

/// Colores por tipo de cuenta (exactos del JSX)
const Map<String, Color> kAccountTypeColors = {
  'efectivo':  Color(0xFF00A878),
  'banco':     Color(0xFF0066FF),
  'crédito':   Color(0xFFFF6B35),
  'inversion': Color(0xFF9333EA),
  // Aliases para tipos internos
  'cash':        Color(0xFF00A878),
  'bank':        Color(0xFF0066FF),
  'credit_card': Color(0xFFFF6B35),
};

/// Íconos por tipo de cuenta
const Map<String, IconData> kAccountTypeIcons = {
  'efectivo':  Iconsax.money,
  'banco':     Iconsax.bank,
  'crédito':   Iconsax.card,
  'inversion': Iconsax.chart_2,
  'cash':      Iconsax.money,
  'bank':      Iconsax.bank,
  'credit_card': Iconsax.card,
};

/// Etiquetas por tipo de cuenta
const Map<String, String> kAccountTypeLabels = {
  'efectivo':  'Efectivo',
  'banco':     'Banco',
  'crédito':   'Crédito',
  'inversion': 'Inversión',
  'cash':      'Efectivo',
  'bank':      'Banco',
  'credit_card': 'Crédito',
};

class AccountCard extends StatelessWidget {
  final String name;
  final String type;
  final double balance;
  final bool compact;
  final VoidCallback? onTap;

  const AccountCard({
    super.key,
    required this.name,
    required this.type,
    required this.balance,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final typeColor = kAccountTypeColors[type] ?? b.primary;
    final typeIcon = kAccountTypeIcons[type] ?? Iconsax.money;
    final typeLabel = kAccountTypeLabels[type] ?? type;

    if (compact) {
      return _buildCompact(context, b, typeColor, typeLabel);
    }
    return _buildFull(context, b, typeColor, typeIcon, typeLabel);
  }

  /// Versión compacta para scroll horizontal (160x100)
  Widget _buildCompact(
    BuildContext context,
    BrumaTheme b,
    Color typeColor,
    String typeLabel,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        height: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: b.surface,
          border: Border.all(color: b.border, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Nombre + pill tipo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    name,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: b.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    typeLabel,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: typeColor,
                    ),
                  ),
                ),
              ],
            ),
            // Balance
            Text(
              '\$${_formatBalance(balance)}',
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: b.textPrimary,
                letterSpacing: -0.02 * 18,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Versión full para pantalla Accounts (AppCard)
  Widget _buildFull(
    BuildContext context,
    BrumaTheme b,
    Color typeColor,
    IconData typeIcon,
    String typeLabel,
  ) {
    return AppCard(
      padding: 20,
      onTap: onTap,
      child: Row(
        children: [
          // Ícono 44x44
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(typeIcon, color: typeColor, size: 20),
          ),
          const SizedBox(width: 16),
          // Nombre + tipo pill
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: b.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    typeLabel,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: typeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Balance
          Text(
            '\$${_formatBalance(balance, decimals: true)}',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: b.textPrimary,
              letterSpacing: -0.02 * 18,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  String _formatBalance(double value, {bool decimals = false}) {
    final absVal = value.abs();
    if (decimals) {
      final parts = absVal.toStringAsFixed(2).split('.');
      final intStr = _addCommas(parts[0]);
      return '${value < 0 ? '-' : ''}$intStr.${parts[1]}';
    }
    return '${value < 0 ? '-' : ''}${_addCommas(absVal.truncate().toString())}';
  }

  String _addCommas(String number) {
    final buffer = StringBuffer();
    int count = 0;
    for (int i = number.length - 1; i >= 0; i--) {
      buffer.write(number[i]);
      count++;
      if (count % 3 == 0 && i > 0) buffer.write(',');
    }
    return buffer.toString().split('').reversed.join();
  }
}
