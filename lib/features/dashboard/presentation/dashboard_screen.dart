import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_routes.dart';
import 'widgets/available_now_card.dart';
import 'widgets/shared_pockets.dart';
import 'widgets/weekly_spend_bar.dart';
import 'widgets/upcoming_bills.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isFabPressed = false;

  @override
  Widget build(BuildContext context) {
    // StatusBar dark: contenido oscuro sobre fondo claro
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMM d').format(now);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            const SizedBox(height: 16),
            // Header: Saludo y fecha
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hey, Carlos 👋',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Sección principal de presupuesto
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: AvailableNowCard(),
            ),
            const SizedBox(height: 32),
            
            // Pockets compartidos
            const SharedPockets(),
            const SizedBox(height: 32),
            
            // Gráfico de gasto semanal
            const WeeklySpendBar(),
            const SizedBox(height: 32),
            
            // Próximos cobros
            const UpcomingBills(),
            const SizedBox(height: 100), // Espacio para scroll y FAB
          ],
        ),
      ),
      floatingActionButton: GestureDetector(
        onTapDown: (_) => setState(() => _isFabPressed = true),
        onTapUp: (_) {
          setState(() => _isFabPressed = false);
          // Navegar a la pantalla de agregar gasto usando GoRouter
          context.push(AppRoutes.addExpense);
          // context.push('/add?category=transport')
        },
        onTapCancel: () => setState(() => _isFabPressed = false),
        child: AnimatedScale(
          scale: _isFabPressed ? 0.9 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Iconsax.add,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}
