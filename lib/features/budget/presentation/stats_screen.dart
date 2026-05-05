import 'dart:math' as math;

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
import '../../../core/widgets/bruma_offline_error.dart';
import '../../../core/widgets/bruma_empty_state.dart';
import '../../../core/widgets/spending_trends_card.dart';
import '../../../core/widgets/transaction_list_item.dart';
import '../../transactions/domain/transaction_model.dart';
import '../data/budget_repository.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

enum _StatsPeriod { day, week, month, year }

class _StatsScreenState extends ConsumerState<StatsScreen> {
  late DateTime _selectedDate;
  _StatsPeriod _selectedPeriod = _StatsPeriod.month;
  DateTimeRange? _selectedWeekRange;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final tenantAsync = ref.watch(tenantProvider);
    final range = _rangeFor(_selectedPeriod, _selectedDate, _selectedWeekRange);

    return Scaffold(
      backgroundColor: b.bg,
      body: SafeArea(
        child: tenantAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: b.primary),
          ),
          error: (error, stack) => buildAsyncError(
            error,
            stack,
            onRetry: () => ref.invalidate(tenantProvider),
            context: context,
          ),
          data: (tenantId) {
            final params = (
              tenantId: tenantId,
              range: range,
            );

            final monthlyTotalsAsync = ref.watch(statsTotalsProvider(params));
            final categorySpendAsync =
                ref.watch(statsSpendByCategoryProvider(params));
            final topExpensesAsync =
                ref.watch(statsTopExpensesProvider(params));
            final previousMonthAsync =
                ref.watch(statsPreviousExpensesProvider(params));
            final trendsAsync = ref.watch(statsTrendsProvider(params));

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _StatsHeader(
                    periodLabel: _labelForPeriod(
                      _selectedPeriod,
                      _selectedDate,
                      _selectedWeekRange,
                    ),
                    periodName: _nameForPeriod(_selectedPeriod),
                    onBack: _handleBack,
                    onPrevious: () => _changePeriod(-1),
                    onNext:
                        _canGoToNextPeriod() ? () => _changePeriod(1) : null,
                    onPeriodTap: _openPeriodPicker,
                    onExport:
                        _isExporting || _selectedPeriod != _StatsPeriod.month
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
                    comparisonLabel: _comparisonLabelForPeriod(_selectedPeriod),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _CategoryBreakdownCard(
                    categorySpendAsync: categorySpendAsync,
                    emptyTitle: _emptyStateTitleForPeriod(_selectedPeriod),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SpendingTrendsCard(
                    trendsAsync: trendsAsync,
                    title: 'Tendencias',
                    subtitle:
                        'Comparado con ${_comparisonLabelForPeriod(_selectedPeriod)}',
                    emptyMessage:
                        'Todavía no hay suficientes cambios para detectar tendencias.',
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

  void _handleBack() {
    HapticFeedback.lightImpact();
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.dashboard);
  }

  void _changePeriod(int offset) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedPeriod == _StatsPeriod.week && _selectedWeekRange != null) {
        final dayCount = _selectedWeekRange!.end
                .difference(_selectedWeekRange!.start)
                .inDays +
            1;
        final shiftedRange = DateTimeRange(
          start:
              _selectedWeekRange!.start.add(Duration(days: dayCount * offset)),
          end: _selectedWeekRange!.end.add(Duration(days: dayCount * offset)),
        );
        _selectedWeekRange = shiftedRange;
        _selectedDate = shiftedRange.start;
      } else {
        _selectedDate = _shiftDate(_selectedPeriod, _selectedDate, offset);
      }
    });
  }

  bool _canGoToNextPeriod() {
    final tomorrow = _startOfDay(DateTime.now()).add(const Duration(days: 1));
    final selectedRange =
        _rangeFor(_selectedPeriod, _selectedDate, _selectedWeekRange);
    return selectedRange.end.isBefore(tomorrow);
  }

  Future<void> _openPeriodPicker() async {
    final result = await showModalBottomSheet<_PeriodSheetResult>(
      context: context,
      backgroundColor: context.bruma.surface,
      isScrollControlled: true,
      builder: (context) => _PeriodPickerSheet(
        initialPeriod: _selectedPeriod,
        initialDate: _selectedDate,
      ),
    );

    if (result == null || !mounted) return;

    switch (result.action) {
      case _PeriodPickerAction.pickDay:
        await _pickDay();
        return;
      case _PeriodPickerAction.pickWeekRange:
        await _pickWeekRange();
        return;
      case _PeriodPickerAction.applySelection:
        HapticFeedback.lightImpact();
        setState(() {
          _selectedPeriod = result.period;
          _selectedDate = result.date!;
          _selectedWeekRange = null;
        });
        return;
    }
  }

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(now) ? now : _selectedDate,
      firstDate: DateTime(2020),
      lastDate: now,
      locale: const Locale('es', 'MX'),
    );

    if (picked == null || !mounted) return;

    HapticFeedback.lightImpact();
    setState(() {
      _selectedPeriod = _StatsPeriod.day;
      _selectedDate = _normalizeSelectedDate(_StatsPeriod.day, picked);
      _selectedWeekRange = null;
    });
  }

  Future<void> _pickWeekRange() async {
    final now = DateTime.now();
    final initialRange = _selectedWeekRange ??
        DateTimeRange(
          start: _normalizeSelectedDate(_StatsPeriod.week, _selectedDate),
          end: _normalizeSelectedDate(_StatsPeriod.week, _selectedDate)
              .add(const Duration(days: 6)),
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: initialRange.start.isAfter(now) ? now : initialRange.start,
        end: initialRange.end.isAfter(now) ? now : initialRange.end,
      ),
      locale: const Locale('es', 'MX'),
      saveText: 'Aplicar',
    );

    if (picked == null || !mounted) return;

    final normalized = _normalizeWeekRange(picked);

    HapticFeedback.lightImpact();
    setState(() {
      _selectedPeriod = _StatsPeriod.week;
      _selectedDate = normalized.start;
      _selectedWeekRange = normalized;
    });
  }

  Future<void> _exportMonthlyReport(String tenantId) async {
    final b = context.bruma;
    final selectedMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);

    try {
      setState(() => _isExporting = true);
      final pdfBytes =
          await ref.read(monthlyReportServiceProvider).generateMonthlyReport(
                tenantId: tenantId,
                year: selectedMonth.year,
                month: selectedMonth.month,
              );
      HapticFeedback.lightImpact();
      final monthName =
          DateFormat('MMMM', 'es_MX').format(selectedMonth).toLowerCase();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'bruma_${monthName}_${selectedMonth.year}.pdf',
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

class _StatsHeader extends StatelessWidget {
  final String periodLabel;
  final String periodName;
  final VoidCallback onBack;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onPeriodTap;
  final VoidCallback? onExport;
  final bool isExporting;

  const _StatsHeader({
    required this.periodLabel,
    required this.periodName,
    required this.onBack,
    required this.onPrevious,
    required this.onNext,
    required this.onPeriodTap,
    required this.onExport,
    required this.isExporting,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: Icon(
                Iconsax.arrow_left,
                color: b.textPrimary,
                size: 20,
              ),
            ),
            const Spacer(),
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
                        color:
                            onExport != null ? b.textSecondary : b.textTertiary,
                      ),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PeriodArrow(
              direction: _ArrowDirection.previous,
              enabled: true,
              onTap: onPrevious,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onPeriodTap,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Column(
                    children: [
                      Text(
                        periodName.toUpperCase(),
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: b.textSecondary,
                          letterSpacing: 0.08 * 10,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              periodLabel,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: b.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Iconsax.arrow_down_1,
                            size: 14,
                            color: b.textSecondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _PeriodArrow(
              direction: _ArrowDirection.next,
              enabled: onNext != null,
              onTap: onNext,
            ),
          ],
        ),
      ],
    );
  }
}

enum _ArrowDirection { previous, next }

class _PeriodArrow extends StatelessWidget {
  final _ArrowDirection direction;
  final bool enabled;
  final VoidCallback? onTap;

  const _PeriodArrow({
    required this.direction,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final chevron = Icon(
      Icons.chevron_right_rounded,
      size: 18,
      color: enabled ? b.textPrimary : b.textTertiary,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: b.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? b.border : b.border.withValues(alpha: 0.5),
          ),
        ),
        alignment: Alignment.center,
        child: direction == _ArrowDirection.previous
            ? Transform.rotate(angle: math.pi, child: chevron)
            : chevron,
      ),
    );
  }
}

class _MonthlySummaryCard extends StatelessWidget {
  final AsyncValue<Map<String, double>> monthlyTotalsAsync;
  final AsyncValue<double> previousMonthAsync;
  final String comparisonLabel;

  const _MonthlySummaryCard({
    required this.monthlyTotalsAsync,
    required this.previousMonthAsync,
    required this.comparisonLabel,
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
        error: (error, stack) => buildAsyncError(
          error,
          stack,
          context: context,
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
                error: (error, stack) => buildAsyncError(
                  error,
                  stack,
                  context: context,
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
                      '↑ 100.0% más que $comparisonLabel',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: b.error,
                      ),
                    );
                  }

                  final differencePercent =
                      ((expenses - previousMonthExpenses) /
                              previousMonthExpenses) *
                          100;
                  final increased = differencePercent >= 0;
                  final prefix = increased ? '↑' : '↓';
                  final label = increased ? 'más' : 'menos';
                  final color = increased ? b.error : b.success;

                  return Text(
                    '$prefix ${differencePercent.abs().toStringAsFixed(1)}% $label que $comparisonLabel',
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
  final String emptyTitle;

  const _CategoryBreakdownCard({
    required this.categorySpendAsync,
    required this.emptyTitle,
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
        error: (error, stack) => buildAsyncError(
          error,
          stack,
          context: context,
        ),
        data: (categorySpend) {
          final entries = categorySpend.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final topEntries = entries.take(6).toList();
          final total =
              topEntries.fold<double>(0, (sum, item) => sum + item.value);

          if (topEntries.isEmpty || total <= 0) {
            return BrumaEmptyState(
              type: BrumaEmptyType.stats,
              title: emptyTitle,
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

class _PeriodPickerSheet extends StatefulWidget {
  final _StatsPeriod initialPeriod;
  final DateTime initialDate;

  const _PeriodPickerSheet({
    required this.initialPeriod,
    required this.initialDate,
  });

  @override
  State<_PeriodPickerSheet> createState() => _PeriodPickerSheetState();
}

class _PeriodPickerSheetState extends State<_PeriodPickerSheet> {
  late _StatsPeriod _selectedPeriod;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.initialPeriod;
    _selectedYear = widget.initialDate.year;
  }

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seleccionar periodo',
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: b.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Elige si quieres ver estadísticas por día, semana, mes o año.',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: b.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _StatsPeriod.values.map((period) {
                final selected = period == _selectedPeriod;
                return ChoiceChip(
                  label: Text(_nameForPeriod(period)),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedPeriod = period),
                  labelStyle: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? b.primary : b.textPrimary,
                  ),
                  selectedColor: b.primary.withValues(alpha: 0.14),
                  backgroundColor: b.surfaceAlt,
                  side: BorderSide(
                    color: selected ? b.primary : b.border,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            _buildPickerContent(context, b),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerContent(BuildContext context, BrumaTheme b) {
    switch (_selectedPeriod) {
      case _StatsPeriod.day:
        return _ActionPickerCard(
          icon: Iconsax.calendar_1,
          title: 'Elegir día',
          subtitle: 'Abre el calendario normal para seleccionar una fecha.',
          buttonLabel: 'Abrir calendario',
          onTap: () => Navigator.of(context).pop(
            const _PeriodSheetResult(
              action: _PeriodPickerAction.pickDay,
              period: _StatsPeriod.day,
            ),
          ),
        );
      case _StatsPeriod.week:
        return _ActionPickerCard(
          icon: Iconsax.calendar_search,
          title: 'Elegir rango semanal',
          subtitle:
              'Selecciona fecha de inicio y fecha de fin en un solo rango.',
          buttonLabel: 'Elegir rango',
          onTap: () => Navigator.of(context).pop(
            const _PeriodSheetResult(
              action: _PeriodPickerAction.pickWeekRange,
              period: _StatsPeriod.week,
            ),
          ),
        );
      case _StatsPeriod.month:
        return _MonthPickerCard(
          selectedYear: _selectedYear,
          activeYear: widget.initialDate.year,
          selectedMonth: widget.initialDate.month,
          onPreviousYear: () => setState(() => _selectedYear--),
          onNextYear: () {
            final nowYear = DateTime.now().year;
            if (_selectedYear < nowYear) {
              setState(() => _selectedYear++);
            }
          },
          onMonthTap: (month) {
            Navigator.of(context).pop(
              _PeriodSheetResult(
                action: _PeriodPickerAction.applySelection,
                period: _StatsPeriod.month,
                date: DateTime(_selectedYear, month, 1),
              ),
            );
          },
        );
      case _StatsPeriod.year:
        final nowYear = DateTime.now().year;
        final years = List<int>.generate(12, (index) => nowYear - index);
        return _YearPickerCard(
          years: years,
          selectedYear: widget.initialDate.year,
          onYearTap: (year) {
            Navigator.of(context).pop(
              _PeriodSheetResult(
                action: _PeriodPickerAction.applySelection,
                period: _StatsPeriod.year,
                date: DateTime(year, 1, 1),
              ),
            );
          },
        );
    }
  }
}

enum _PeriodPickerAction { pickDay, pickWeekRange, applySelection }

class _PeriodSheetResult {
  final _PeriodPickerAction action;
  final _StatsPeriod period;
  final DateTime? date;

  const _PeriodSheetResult({
    required this.action,
    required this.period,
    this.date,
  });
}

class _ActionPickerCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;

  const _ActionPickerCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: b.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: b.border),
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: b.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: b.primary, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: b.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: b.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: b.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                buttonLabel,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthPickerCard extends StatelessWidget {
  final int selectedYear;
  final int activeYear;
  final int selectedMonth;
  final VoidCallback onPreviousYear;
  final VoidCallback onNextYear;
  final ValueChanged<int> onMonthTap;

  const _MonthPickerCard({
    required this.selectedYear,
    required this.activeYear,
    required this.selectedMonth,
    required this.onPreviousYear,
    required this.onNextYear,
    required this.onMonthTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const monthLabels = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];

    return Column(
      children: [
        _PickerYearHeader(
          label: '$selectedYear',
          onPrevious: onPreviousYear,
          onNext: onNextYear,
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          itemCount: monthLabels.length,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.6,
          ),
          itemBuilder: (context, index) {
            final month = index + 1;
            final enabled = selectedYear < now.year ||
                (selectedYear == now.year && month <= now.month);
            final selected =
                selectedYear == activeYear && month == selectedMonth;
            return _PickerOptionTile(
              label: monthLabels[index],
              selected: selected,
              enabled: enabled,
              onTap: enabled ? () => onMonthTap(month) : null,
            );
          },
        ),
      ],
    );
  }
}

class _YearPickerCard extends StatelessWidget {
  final List<int> years;
  final int selectedYear;
  final ValueChanged<int> onYearTap;

  const _YearPickerCard({
    required this.years,
    required this.selectedYear,
    required this.onYearTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      itemCount: years.length,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (context, index) {
        final year = years[index];
        return _PickerOptionTile(
          label: '$year',
          selected: year == selectedYear,
          enabled: true,
          onTap: () => onYearTap(year),
        );
      },
    );
  }
}

class _PickerYearHeader extends StatelessWidget {
  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _PickerYearHeader({
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;

    return Row(
      children: [
        _PeriodArrow(
          direction: _ArrowDirection.previous,
          enabled: true,
          onTap: onPrevious,
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: b.textPrimary,
            ),
          ),
        ),
        _PeriodArrow(
          direction: _ArrowDirection.next,
          enabled: true,
          onTap: onNext,
        ),
      ],
    );
  }
}

class _PickerOptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  const _PickerOptionTile({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: enabled ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? b.primary.withValues(alpha: 0.14) : b.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? b.primary : b.border,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: enabled
                ? (selected ? b.primary : b.textPrimary)
                : b.textTertiary,
          ),
        ),
      ),
    );
  }
}

BudgetStatsRange _rangeFor(
  _StatsPeriod period,
  DateTime date,
  DateTimeRange? weekRange,
) {
  final normalized = _normalizeSelectedDate(period, date);

  switch (period) {
    case _StatsPeriod.day:
      return BudgetStatsRange(
        start: DateTime(normalized.year, normalized.month, normalized.day),
        end: DateTime(normalized.year, normalized.month, normalized.day + 1),
      );
    case _StatsPeriod.week:
      if (weekRange != null) {
        return BudgetStatsRange(
          start: _startOfDay(weekRange.start),
          end: _startOfDay(weekRange.end).add(const Duration(days: 1)),
        );
      }
      final start = DateTime(
        normalized.year,
        normalized.month,
        normalized.day,
      );
      return BudgetStatsRange(
        start: start,
        end: start.add(const Duration(days: 7)),
      );
    case _StatsPeriod.month:
      return BudgetStatsRange(
        start: DateTime(normalized.year, normalized.month, 1),
        end: DateTime(normalized.year, normalized.month + 1, 1),
      );
    case _StatsPeriod.year:
      return BudgetStatsRange(
        start: DateTime(normalized.year, 1, 1),
        end: DateTime(normalized.year + 1, 1, 1),
      );
  }
}

DateTime _normalizeSelectedDate(_StatsPeriod period, DateTime date) {
  switch (period) {
    case _StatsPeriod.day:
      return DateTime(date.year, date.month, date.day);
    case _StatsPeriod.week:
      final weekdayOffset = date.weekday - DateTime.monday;
      return DateTime(date.year, date.month, date.day - weekdayOffset);
    case _StatsPeriod.month:
      return DateTime(date.year, date.month, 1);
    case _StatsPeriod.year:
      return DateTime(date.year, 1, 1);
  }
}

DateTime _shiftDate(_StatsPeriod period, DateTime date, int offset) {
  switch (period) {
    case _StatsPeriod.day:
      return DateTime(date.year, date.month, date.day + offset);
    case _StatsPeriod.week:
      return DateTime(date.year, date.month, date.day + (offset * 7));
    case _StatsPeriod.month:
      return DateTime(date.year, date.month + offset, 1);
    case _StatsPeriod.year:
      return DateTime(date.year + offset, 1, 1);
  }
}

String _labelForPeriod(
  _StatsPeriod period,
  DateTime date,
  DateTimeRange? weekRange,
) {
  switch (period) {
    case _StatsPeriod.day:
      return _capitalize(DateFormat('d MMMM yyyy', 'es_MX').format(date));
    case _StatsPeriod.week:
      final start = weekRange?.start ?? _normalizeSelectedDate(period, date);
      final end = weekRange?.end ?? start.add(const Duration(days: 6));
      return '${DateFormat('d MMM', 'es_MX').format(start)} - ${DateFormat('d MMM yyyy', 'es_MX').format(end)}';
    case _StatsPeriod.month:
      return _capitalize(DateFormat('MMMM yyyy', 'es_MX').format(date));
    case _StatsPeriod.year:
      return DateFormat('yyyy', 'es_MX').format(date);
  }
}

DateTimeRange _normalizeWeekRange(DateTimeRange range) {
  return DateTimeRange(
    start: _startOfDay(range.start),
    end: _startOfDay(range.end),
  );
}

DateTime _startOfDay(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

String _nameForPeriod(_StatsPeriod period) {
  switch (period) {
    case _StatsPeriod.day:
      return 'Día';
    case _StatsPeriod.week:
      return 'Semana';
    case _StatsPeriod.month:
      return 'Mes';
    case _StatsPeriod.year:
      return 'Año';
  }
}

String _comparisonLabelForPeriod(_StatsPeriod period) {
  switch (period) {
    case _StatsPeriod.day:
      return 'el día anterior';
    case _StatsPeriod.week:
      return 'la semana anterior';
    case _StatsPeriod.month:
      return 'el mes pasado';
    case _StatsPeriod.year:
      return 'el año pasado';
  }
}

String _emptyStateTitleForPeriod(_StatsPeriod period) {
  switch (period) {
    case _StatsPeriod.day:
      return 'Sin movimientos este día';
    case _StatsPeriod.week:
      return 'Sin movimientos esta semana';
    case _StatsPeriod.month:
      return 'Sin movimientos este mes';
    case _StatsPeriod.year:
      return 'Sin movimientos este año';
  }
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}
