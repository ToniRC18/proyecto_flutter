import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../data/dashboard_mock_data.dart';

class AvailableNowCard extends ConsumerWidget {
  const AvailableNowCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amount = ref.watch(mockAvailableNowProvider);
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return GlassCard(
      width: double.infinity,
      padding: const EdgeInsets.all(28.0),
      child: Column(
        children: [
          Text(
            'Available Now',
            style: GoogleFonts.poppins(
              color: AppColors.primaryLight,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatter.format(amount),
            style: GoogleFonts.poppins(
              color: AppColors.primary,
              fontSize: 42,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'after upcoming bills',
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
