import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';

class PocketsScreen extends StatelessWidget {
  const PocketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Pockets',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const _PocketCard(
                    emoji: '✈️',
                    name: 'Viaje a Oaxaca',
                    saved: 3200,
                    goal: 8000,
                    color: Color(0xFF5F4A8B),
                  ),
                  const SizedBox(height: 16),
                  const _PocketCard(
                    emoji: '🎮',
                    name: 'Setup gaming',
                    saved: 1500,
                    goal: 5000,
                    color: Color(0xFF7E6AA8),
                  ),
                  const SizedBox(height: 16),
                  const _PocketCard(
                    emoji: '🚗',
                    name: 'Fondo de emergencia',
                    saved: 6000,
                    goal: 10000,
                    color: Color(0xFF4CAF50),
                  ),
                  const SizedBox(height: 32),

                  // Placeholder CTA
                  Center(
                    child: Text(
                      'Próximamente: crea pockets compartidos\ncon tu pareja o amigos.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textLight,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PocketCard extends StatelessWidget {
  final String emoji;
  final String name;
  final double saved;
  final double goal;
  final Color color;

  const _PocketCard({
    required this.emoji,
    required this.name,
    required this.saved,
    required this.goal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (saved / goal).clamp(0.0, 1.0);

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(Iconsax.people, size: 18, color: AppColors.textLight),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.glassBorder,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${saved.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  'meta \$${goal.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
