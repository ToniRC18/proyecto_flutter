import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../core/export/monthly_report_service.dart';
import '../../../core/domain/app_categories.dart';
import '../../../core/providers/tenant_provider.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/balance_display.dart';
import '../../../core/widgets/bruma_empty_state.dart';
import '../../../core/widgets/transaction_list_item.dart';
import '../../transactions/domain/transaction_model.dart';
import '../data/budget_repository.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  late DateTime _selectedMonth;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final tenantAsync = ref.watch(tenantProvider);

    return Scaffold(
      backgroundColor: b.bg,
      body: SafeArea(
        child: tenantAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: b.primary),
          ),
          error: (error, _) => _InlineState(
            icon: Iconsax.warning_2,
            message: 'Error: $error',
          ),
          data: (tenantId) {
            final params = (
              tenantId: tenantId,
              year: _selectedMonth.year,
              month: _selectedMonth.month,
            );

            final monthlyTotalsAsync = ref.watch(monthlyTotalsProvider(params));
            final categorySpendAsync =
                ref.watch(monthlySpendByCategoryProvider(params));
            final topExpensesAsync = ref.watch(topExpensesProvider(params));
            final previousMonthAsync =
                ref.watch(previousMonthExpensesProvider(params));

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _MonthSelector(
                    selectedMonth: _selectedMonth,
                    onPrevious: () => _changeMonth(-1),
                    onNext: _canGoToNextMonth()
                        ? () => _changeMonth(1)
                        : null,
                    onExport: _isExporting
                        ? null
                        : () => _exportMonthlyReport(tenantId),
                    isExporting: _isExporting,
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _MonthlySummaryCard(
                    monthlyTotalsAsync: monthlyTotalsAsync,
                    previousMonthAsync: previousMonthAsync,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _CategoryBreakdownCard(
                    categorySpendAsync: categorySpendAsync,
                  ),
                ),
                topExpensesAsync.when(
                  data: (transactions) {
                    if (transactions.isEmpty) return const SizedBox.shrink();
                    return _TopExpensesSection(transactions: transactions);
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AppCard(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.push(AppRoutes.budget);
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: b.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Iconsax.chart_2,
                            color: b.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Presupuestos',
                                style: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: b.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Define límites por categoría',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: b.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Iconsax.arrow_right,
                          color: b.textTertiary,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _changeMonth(int offset) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + offset, 1);
    });
  }

  bool _canGoToNextMonth() {
    final now = DateTime.now();
    return _selectedMonth.year < now.year ||
        (_selectedMonth.year == now.year && _selectedMonth.month < now.month);
  }

  Future<void> _exportMonthlyReport(String tenantId) async {
    final b = context.bruma;

    try {
      setState(() => _isExporting = true);
      final pdfBytes = await ref.read(monthlyReportServiceProvider).generateMonthlyReport(
            tenantId: tenantId,
            year: _selectedMonth.year,
            month: _selectedMonth.month,
          );
      HapticFeedback.lightImpact();
      final monthName = DateFormat('MMMM', 'es_MX')
          .format(_selectedMonth)
          .toLowerCase();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'bruma_${monthName}_${_selectedMonth.year}.pdf',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: b.error,
          content: Text('Error: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }
}

class _MonthSelector extends StatelessWidget {
  final DateTime selectedMonth;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onExport;
  final bool isExporting;

  const _MonthSelector({
    required this.selectedMonth,
    required this.onPrevious,
    required this.onNext,
    required this.onExport,
    required this.isExporting,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final monthLabel = DateFormat('MMMM yyyy', 'es_MX').format(selectedMonth);

    return Row(
      children: [
        _MonthArrow(
          icon: Iconsax.arrow_left,
          enabled: true,
          onTap: onPrevious,
        ),
        Expanded(
          child: Center(
            child: Text(
              _capitalize(monthLabel),
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: b.textPrimary,
              ),
            ),
          ),
        ),
        _MonthArrow(
          icon: Iconsax.arrow_right,
          enabled: onNext != null,
          onTap: onNext,
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 32,
          height: 32,
          child: isExporting
              ? Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: b.textSecondary,
                  ),
                )
              : IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: onExport,
                  icon: Icon(
                    Iconsax.export,
                    size: 18,
                    color: b.textSecondary,
                  ),
                ),
        ),
      ],
    );
  }
}

class _MonthArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  const _MonthArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(
          icon,
          size: 18,
          color: enabled ? b.textPrimary : b.textTertiary,
        ),
      ),
    );
  }
}

class _MonthlySummaryCard extends StatelessWidget {
  final AsyncValue<Map<String, double>> monthlyTotalsAsync;
  final AsyncValue<double> previousMonthAsync;

  const _MonthlySummaryCard({
    required this.monthlyTotalsAsync,
    required this.previousMonthAsync,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;

    return AppCard(
      padding: 20,
      child: monthlyTotalsAsync.when(
        loading: () => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: CircularProgressIndicator(color: b.primary),
          ),
        ),
        error: (error, _) => _InlineState(
          icon: Iconsax.warning_2,
          message: 'Error: $error',
          compact: true,
        ),
        data: (totals) {
          final income = totals['income'] ?? 0;
          final expenses = totals['expenses'] ?? 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RESUMEN',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: b.textSecondary,
                  letterSpacing: 0.08 * 11,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _SummaryColumn(
                      icon: Iconsax.arrow_down,
                      label: 'Ingresos',
                      amount: income,
                      amountColor: b.success,
                    ),
                  ),
                  Expanded(
                    child: _SummaryColumn(
                      icon: Iconsax.arrow_up,
                      label: 'Gastos',
                      amount: expenses,
                      amountColor: b.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                height: 1,
                color: b.border,
              ),
              const SizedBox(height: 14),
              previousMonthAsync.when(
                loading: () => Text(
                  'Cargando comparativa...',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: b.textSecondary,
                  ),
                ),
                error: (error, _) => Text(
                  'Error: $error',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: b.error,
                  ),
                ),
                data: (previousMonthExpenses) {
                  if (previousMonthExpenses <= 0 && expenses <= 0) {
                    return Text(
                      'Sin comparación disponible',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: b.textSecondary,
                      ),
                    );
                  }

                  if (previousMonthExpenses <= 0) {
                    return Text(
                      '↑ 100.0% más que el mes pasado',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: b.error,
                      ),
                    );
                  }

                  final differencePercent =
                      ((expenses - previousMonthExpenses) / previousMonthExpenses) *
                          100;
                  final increased = differencePercent >= 0;
                  final prefix = increased ? '↑' : '↓';
                  final label = increased ? 'más' : 'menos';
                  final color = increased ? b.error : b.success;

                  return Text(
                    '$prefix ${differencePercent.abs().toStringAsFixed(1)}% $label que el mes pasado',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;
  final Color amountColor;

  const _SummaryColumn({
    required this.icon,
    required this.label,
    required this.amount,
    required this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;

    return Column(
      children: [
        Icon(icon, size: 18, color: amountColor),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            color: b.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        BalanceDisplay(
          value: amount,
          fontSize: 20,
          valueColor: amountColor,
          symbolColor: amountColor,
        ),
      ],
    );
  }
}

class _CategoryBreakdownCard extends StatelessWidget {
  final AsyncValue<Map<String, double>> categorySpendAsync;

  const _CategoryBreakdownCard({
    required this.categorySpendAsync,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;

    return AppCard(
      padding: 20,
      child: categorySpendAsync.when(
        loading: () => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: CircularProgressIndicator(color: b.primary),
          ),
        ),
        error: (error, _) => _InlineState(
          icon: Iconsax.warning_2,
          message: 'Error: $error',
          compact: true,
        ),
        data: (categorySpend) {
          final entries = categorySpend.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final topEntries = entries.take(6).toList();
          final total = topEntries.fold<double>(0, (sum, item) => sum + item.value);

          if (topEntries.isEmpty || total <= 0) {
            return const BrumaEmptyState(
              type: BrumaEmptyType.stats,
              title: 'Sin movimientos este mes',
              subtitle: 'Registra tu primer gasto para ver tus estadísticas',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'POR CATEGORÍA',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: b.textSecondary,
                  letterSpacing: 0.08 * 11,
                ),
              ),
              const SizedBox(height: 18),
              ...topEntries.map((entry) {
                final amount = entry.value;
                final percent = total > 0 ? amount / total : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _CategoryBarRow(
                    category: entry.key,
                    amount: amount,
                    percent: percent,
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryBarRow extends StatelessWidget {
  final String category;
  final double amount;
  final double percent;

  const _CategoryBarRow({
    required this.category,
    required this.amount,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final color = kCategoryColors[category] ?? b.primary;
    final formatter = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 2,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${AppCategories.emojiForId(category)} ${AppCategories.labelForId(category)}',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: b.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              formatter.format(amount),
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: b.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: percent.clamp(0, 1)),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOut,
          builder: (context, value, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: b.surfaceAlt,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Text(
          '${(percent * 100).toStringAsFixed(1)}% del total',
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: b.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _TopExpensesSection extends StatelessWidget {
  final List<Transaction> transactions;

  const _TopExpensesSection({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'LOS MÁS GRANDES',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: b.textSecondary,
              letterSpacing: 0.08 * 11,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...transactions.asMap().entries.map((entry) {
          final tx = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TransactionListItem(
              title: tx.notes?.trim().isNotEmpty == true
                  ? tx.notes!.trim()
                  : AppCategories.labelForId(tx.category),
              category: tx.category,
              amount: -tx.amount,
              date: DateFormat('dd MMM', 'es_MX').format(tx.date),
              index: entry.key,
              onTap: () => context.push(
                AppRoutes.transactionDetail,
                extra: tx,
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _InlineState extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool compact;

  const _InlineState({
    required this.icon,
    required this.message,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final padding = compact ? const EdgeInsets.symmetric(vertical: 12) : const EdgeInsets.all(24);

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 32 : 48, color: b.textTertiary),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: compact ? 13 : 14,
                color: b.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}
