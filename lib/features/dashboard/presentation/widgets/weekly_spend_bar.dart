import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../data/dashboard_repository.dart';

class WeeklySpendBar extends ConsumerWidget {
  final String tenantId;
  const WeeklySpendBar({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklySpendAsync = ref.watch(weeklySpendProvider(tenantId));
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'This Week',
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GlassCard(
            padding: const EdgeInsets.all(16.0),
            child: weeklySpendAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, __) => Center(child: Text('Error: $err')),
              data: (data) {
                final spent = data['spent']!;
                final limit = data['limit']!;
                final percentage = (spent / limit).clamp(0.0, 1.0);

                String message = "You're doing great 🌿";
                if (percentage > 0.8) {
                  message = "Almost there, slow down 🌊";
                } else if (percentage >= 0.5) {
                  message = "You're on track 👍";
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${formatter.format(spent)} of ${formatter.format(limit)}',
                          style: GoogleFonts.poppins(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${(percentage * 100).toInt()}%',
                          style: GoogleFonts.poppins(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: Colors.white.withAlpha(127),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        message,
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
