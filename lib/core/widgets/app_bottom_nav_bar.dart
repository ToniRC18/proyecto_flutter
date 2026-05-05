import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../theme/app_theme.dart';
import '../router/app_routes.dart';
import 'pending_sync_badge.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// BrumaBottomNav — Basado EXACTAMENTE en BottomNav de Bruma.html
// Row: 4 tabs (2 + FAB + 2), dot indicator, backdrop blur
// ═══════════════════════════════════════════════════════════════════════════════

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      height: 84 + bottomPadding,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: b.surface.withOpacity(0.88),
              border: Border(
                top: BorderSide(color: b.border, width: 1),
              ),
            ),
            padding: EdgeInsets.only(
              bottom: bottomPadding,
              left: 8,
              right: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Tab 0: Home
                _NavTab(
                  icon: Iconsax.home_2,
                  index: 0,
                  currentIndex: currentIndex,
                  onTap: onTap,
                  tokens: b,
                ),
                // Tab 1: Accounts
                _NavTab(
                  icon: Iconsax.wallet_2,
                  index: 1,
                  currentIndex: currentIndex,
                  onTap: onTap,
                  tokens: b,
                ),
                // FAB central
                _CenterFab(tokens: b),
                // Tab 2: Stats (internamente índice 3)
                _NavTab(
                  icon: Iconsax.chart_square,
                  index: 3,
                  currentIndex: currentIndex,
                  onTap: onTap,
                  tokens: b,
                ),
                // Tab 3: Profile (internamente índice 4)
                _NavTab(
                  icon: Iconsax.profile_circle,
                  index: 4,
                  currentIndex: currentIndex,
                  onTap: onTap,
                  tokens: b,
                  badge: const PendingSyncBadge(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tab individual con dot indicator ──────────────────────────────────────────

class _NavTab extends StatelessWidget {
  final IconData icon;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final BrumaTheme tokens;
  final Widget? badge;

  const _NavTab({
    required this.icon,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    required this.tokens,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        height: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  scale: isActive ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.elasticOut,
                  child: Icon(
                    icon,
                    size: 22,
                    color: isActive ? tokens.primary : tokens.textTertiary,
                  ),
                ),
                if (badge != null)
                  Positioned(
                    top: -6,
                    right: -8,
                    child: badge!,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            // Dot indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? 16 : 4,
              height: 4,
              decoration: BoxDecoration(
                color: isActive ? tokens.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── FAB central con sombra y scale ────────────────────────────────────────────

class _CenterFab extends StatefulWidget {
  final BrumaTheme tokens;
  const _CenterFab({required this.tokens});

  @override
  State<_CenterFab> createState() => _CenterFabState();
}

class _CenterFabState extends State<_CenterFab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.tokens;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.lightImpact();
        _mostrarOpciones(context);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.elasticOut,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: t.primary,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: t.primary.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            Icons.add_rounded,
            color: t.onPrimary,
            size: 28,
          ),
        ),
      ),
    );
  }

  /// Muestra bottom sheet con opciones de agregar
  void _mostrarOpciones(BuildContext context) {
    final b = context.bruma;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddOptionsSheet(tokens: b),
    );
  }
}

// ── Bottom sheet de opciones (rediseñado con tokens Bruma) ────────────────────

class _AddOptionsSheet extends StatelessWidget {
  final BrumaTheme tokens;
  const _AddOptionsSheet({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: tokens.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Agregar',
            style: GoogleFonts.dmSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: tokens.textPrimary,
              letterSpacing: -0.02 * 17,
            ),
          ),
          const SizedBox(height: 20),

          // Opciones
          _OptionRow(
            icon: Iconsax.money_send,
            label: 'Registrar gasto',
            color: tokens.error,
            tokens: tokens,
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.addExpense);
            },
          ),
          const SizedBox(height: 10),
          _OptionRow(
            icon: Iconsax.money_recive,
            label: 'Registrar ingreso',
            color: tokens.success,
            tokens: tokens,
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.addIncome);
            },
          ),
          const SizedBox(height: 10),
          _OptionRow(
            icon: Iconsax.arrow_swap_horizontal,
            label: 'Transferir',
            color: tokens.primary,
            tokens: tokens,
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.addTransfer);
            },
          ),
          const SizedBox(height: 10),
          _OptionRow(
            icon: Iconsax.calendar_1,
            label: 'Pago recurrente',
            color: tokens.warning,
            tokens: tokens,
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.addBill);
            },
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final BrumaTheme tokens;
  final VoidCallback onTap;

  const _OptionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.tokens,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
