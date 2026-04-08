import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../../core/router/app_routes.dart';

/// BottomNavigationBar personalizada con botón "+" elevado en el centro.
/// Maneja 5 ítems: Home | Accounts | [+] | Budget | Profile
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
    return SizedBox(
      height: 65 + MediaQuery.of(context).padding.bottom,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Barra de fondo ─────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 65 + MediaQuery.of(context).padding.bottom,
                  decoration: const BoxDecoration(
                    color: Color(0xF2FFFFFF), // white 95% opacity
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    border: Border(
                      top: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _NavItem(
                          icon: Icons.home_rounded,
                          label: 'Home',
                          index: 0,
                          currentIndex: currentIndex,
                          onTap: onTap,
                        ),
                        _NavItem(
                          icon: Icons.account_balance_wallet_rounded,
                          label: 'Accounts',
                          index: 1,
                          currentIndex: currentIndex,
                          onTap: onTap,
                        ),
                        // Espacio para el botón central
                        const SizedBox(width: 64),
                        _NavItem(
                          icon: Icons.pie_chart_rounded,
                          label: 'Budget',
                          index: 3,
                          currentIndex: currentIndex,
                          onTap: onTap,
                        ),
                        _NavItem(
                          icon: Icons.person_rounded,
                          label: 'Profile',
                          index: 4,
                          currentIndex: currentIndex,
                          onTap: onTap,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Botón "+" central elevado ──────────────────────────────
          Positioned(
            top: -28,
            left: 0,
            right: 0,
            child: Center(
              child: _CenterPlusButton(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Ítem de navegación ───────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                size: 24,
                color: isActive ? AppColors.primary : Colors.grey,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.primary : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Botón central "+" ────────────────────────────────────────────────────────

class _CenterPlusButton extends StatefulWidget {
  @override
  State<_CenterPlusButton> createState() => _CenterPlusButtonState();
}

class _CenterPlusButtonState extends State<_CenterPlusButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _mostrarOpciones(context);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(102), // 0.4 opacity
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  /// Muestra BottomSheet glassmorphism con opciones Add Expense / Add Income
  void _mostrarOpciones(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddOptionsSheet(
        onExpense: () {
          Navigator.pop(context);
          context.push(AppRoutes.addExpense);
        },
        onIncome: () {
          Navigator.pop(context);
          context.push(AppRoutes.addIncome);
        },
      ),
    );
  }
}

// ─── BottomSheet glassmorphism ────────────────────────────────────────────────

class _AddOptionsSheet extends StatelessWidget {
  final VoidCallback onExpense;
  final VoidCallback onIncome;

  const _AddOptionsSheet({
    required this.onExpense,
    required this.onIncome,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(230),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: const Border(
              top: BorderSide(color: Color(0x99FFFFFF), width: 1.5),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            24 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Agregar',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              // Botón Add Expense
              _OptionButton(
                emoji: '💸',
                label: 'Add Expense',
                color: const Color(0xFFEF4444),
                bgColor: const Color(0x14EF4444),
                onTap: onExpense,
              ),
              const SizedBox(height: 12),

              // Botón Add Income
              _OptionButton(
                emoji: '💰',
                label: 'Add Income',
                color: const Color(0xFF2E7D32),
                bgColor: const Color(0x142E7D32),
                onTap: onIncome,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _OptionButton({
    required this.emoji,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(50), width: 1.5),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}
