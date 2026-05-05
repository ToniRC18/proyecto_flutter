import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'transaction_list_item.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CategoryPill — Basado EXACTAMENTE en CategoryPill de components.jsx
// Pill (borderRadius 100), selected vs unselected states
// ═══════════════════════════════════════════════════════════════════════════════

class CategoryPill extends StatelessWidget {
  final String category;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const CategoryPill({
    super.key,
    required this.category,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final color = kCategoryColors[category] ?? b.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : b.surfaceAlt,
          border: Border.all(
            color: selected ? color.withOpacity(0.25) : b.border,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? color : b.textSecondary,
          ),
        ),
      ),
    );
  }
}
