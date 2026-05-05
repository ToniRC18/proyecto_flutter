import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../features/budget/data/budget_repository.dart';
import '../domain/app_categories.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

class SpendingTrendsCard extends StatelessWidget {
  final AsyncValue<List<SpendingTrend>> trendsAsync;
  final String title;
  final String subtitle;
  final String emptyMessage;

  const SpendingTrendsCard({
    super.key,
    required this.trendsAsync,
    required this.title,
    required this.subtitle,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;

    return AppCard(
      padding: 20,
      child: trendsAsync.when(
        loading: () => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: CircularProgressIndicator(color: b.primary),
          ),
        ),
        error: (error, _) => _TrendsInlineState(message: 'Error: $error'),
        data: (trends) {
          if (trends.isEmpty) {
            return _TrendsInlineState(message: emptyMessage);
          }

          final increased = trends.where((trend) => trend.increased).toList()
            ..sort((a, b) => b.deltaAmount.compareTo(a.deltaAmount));
          final decreased = trends.where((trend) => trend.decreased).toList()
            ..sort((a, b) => a.deltaAmount.compareTo(b.deltaAmount));
          final visible = trends.take(3).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: b.textPrimary,
                  letterSpacing: -0.02 * 17,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: b.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              _TrendHeadline(
                increased: increased.isNotEmpty ? increased.first : null,
                decreased: decreased.isNotEmpty ? decreased.first : null,
              ),
              const SizedBox(height: 16),
              ...visible.map(
                (trend) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TrendRow(trend: trend),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TrendHeadline extends StatelessWidget {
  final SpendingTrend? increased;
  final SpendingTrend? decreased;

  const _TrendHeadline({
    required this.increased,
    required this.decreased,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final text = _buildText();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: b.primarySubtle,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: b.textPrimary,
          height: 1.35,
        ),
      ),
    );
  }

  String _buildText() {
    if (increased != null && decreased != null) {
      return 'Subiste más en ${AppCategories.labelForId(increased!.category)} y bajaste más en ${AppCategories.labelForId(decreased!.category)}.';
    }
    if (increased != null) {
      return 'Tu mayor alza fue en ${AppCategories.labelForId(increased!.category)} frente al periodo anterior.';
    }
    if (decreased != null) {
      return 'Tu mayor baja fue en ${AppCategories.labelForId(decreased!.category)} frente al periodo anterior.';
    }
    return 'Todavía no hay cambios suficientes para marcar una tendencia.';
  }
}

class _TrendRow extends StatelessWidget {
  final SpendingTrend trend;

  const _TrendRow({required this.trend});

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final color = trend.increased ? b.error : b.success;
    final sign = trend.increased ? '+' : '-';
    final arrow = trend.increased ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1;
    final formatter = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 0,
    );

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(arrow, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${AppCategories.emojiForId(trend.category)} ${AppCategories.labelForId(trend.category)}',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: b.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$sign${formatter.format(trend.deltaAmount.abs())} vs. periodo anterior',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: b.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$sign${trend.deltaPercent.abs().toStringAsFixed(0)}%',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _TrendsInlineState extends StatelessWidget {
  final String message;

  const _TrendsInlineState({required this.message});

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          color: b.textSecondary,
        ),
      ),
    );
  }
}
