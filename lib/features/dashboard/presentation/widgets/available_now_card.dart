import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../data/dashboard_repository.dart';

class AvailableNowCard extends ConsumerWidget {
  final String tenantId;
  const AvailableNowCard({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(availableBalanceProvider(tenantId));
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
          balanceAsync.when(
            loading: () => const SizedBox(
              height: 50,
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2.5,
                ),
              ),
            ),
            error: (err, __) => Text(
              formatter.format(0.00),
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontSize: 42,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
            data: (balance) {
              return Text(
                formatter.format(balance),
                style: GoogleFonts.poppins(
                  color: AppColors.primary,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            'total system balance',
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary.withAlpha(178),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
