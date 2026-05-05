import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../animations/bruma_animations.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// TransactionListItem — Basado EXACTAMENTE en TransactionItem de components.jsx
// Ícono 44x44, stagger animation, colores de categoría
// ═══════════════════════════════════════════════════════════════════════════════

/// Colores de categoría EXACTOS de CATEGORY_COLORS en components.jsx
const Map<String, Color> kCategoryColors = {
  'food':      Color(0xFFFF6B35),
  'transport': Color(0xFF0066FF),
  'shopping':  Color(0xFF9333EA),
  'health':    Color(0xFF00A878),
  'home':      Color(0xFFF59E0B),
  'income':    Color(0xFF00D4AA),
  'transfer':  Color(0xFF6B7280),
  'other':     Color(0xFFEC4899),
  // Aliases legacy
  'entertainment': Color(0xFF9333EA),
  'servicios':     Color(0xFFF59E0B),
  'utilities':     Color(0xFFF59E0B),
};

/// Íconos de categoría
const Map<String, IconData> kCategoryIcons = {
  'food':      Iconsax.coffee,
  'transport': Iconsax.car,
  'shopping':  Iconsax.bag,
  'health':    Iconsax.health,
  'home':      Iconsax.home,
  'income':    Iconsax.money_recive,
  'transfer':  Iconsax.arrow_swap_horizontal,
  'other':     Iconsax.more_circle,
  'entertainment': Iconsax.bag,
  'servicios':     Iconsax.home,
  'utilities':     Iconsax.home,
};

class TransactionListItem extends StatelessWidget {
  final String title;
  final String category;
  final double amount;
  final String date;
  final int index;
  final VoidCallback? onTap;
  final String? subtitle; // Para payer badge en shared spaces

  const TransactionListItem({
    super.key,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.index = 0,
    this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final catColor = kCategoryColors[category] ?? kCategoryColors['other']!;
    final catIcon = kCategoryIcons[category] ?? kCategoryIcons['other']!;
    final isIncome = amount > 0;
    final formatter = NumberFormat('#,##0.00', 'es_MX');

    return FadeUpAnimation(
      delayMs: index * 40,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Ícono de categoría 44x44
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(catIcon, color: catColor, size: 20),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: b.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: b.textSecondary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: b.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Monto
              Text(
                '${isIncome ? '+' : '-'}\$${formatter.format(amount.abs())}',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isIncome ? b.success : b.error,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
