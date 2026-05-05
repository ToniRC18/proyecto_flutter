import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/domain/app_categories.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/tenant_provider.dart';
import '../../../core/animations/bruma_animations.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/amount_input_field.dart';
import '../../../core/widgets/bruma_empty_state.dart';
import '../../../core/widgets/category_pill.dart';
import '../../../core/widgets/transaction_list_item.dart';
import '../data/budget_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// BudgetScreen — Basado en StatsScreen/BudgetScreen de Bruma
// Resumen mensual centrado, categorías con barras de progreso, FAB agregar
// ═══════════════════════════════════════════════════════════════════════════════

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = context.bruma;
    final tenantAsync = ref.watch(tenantProvider);
    final now = DateTime.now();
    final monthYear = DateFormat('MMMM yyyy', 'es_MX').format(now);

    return Scaffold(
      backgroundColor: b.bg,
      body: SafeArea(
        child: tenantAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: b.primary),
          ),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (tenantId) {
            final budgetsAsync = ref.watch(budgetsListProvider(tenantId));
            final spentAsync = ref.watch(spentByCategoryProvider(tenantId));

            return Stack(
              children: [
                ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 120),
                  children: [
                    const SizedBox(height: 20),

                    // ── Header ──────────────────────────────────────
                    FadeUpAnimation(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Presupuesto',
                              style: GoogleFonts.dmSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: b.textPrimary,
                                letterSpacing: -0.03 * 22,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              monthYear,
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                color: b.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Summary card ─────────────────────────────────
                    FadeUpAnimation(
                      delayMs: 100,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: budgetsAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (budgets) => spentAsync.when(
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                            data: (spent) => _BudgetSummaryCard(
                              budgets: budgets,
                              spent: spent,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Lista de budgets ──────────────────────────────
                    FadeUpAnimation(
                      delayMs: 200,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: budgetsAsync.when(
                          loading: () => Center(
                            child: CircularProgressIndicator(color: b.primary),
                          ),
                          error: (err, _) => Text('Error: $err'),
                          data: (budgets) {
                            if (budgets.isEmpty) {
                              return _EmptyBudget(
                                onAdd: () =>
                                    _showAddBudgetSheet(context, ref, tenantId),
                              );
                            }
                            return spentAsync.when(
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                              data: (spent) => Column(
                                children: budgets.asMap().entries.map((entry) {
                                  final budget = entry.value;
                                  final spentAmt = spent[
                                          AppCategories.normalizeId(
                                              budget.category)] ??
                                      0;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _BudgetCategoryCard(
                                      budget: budget,
                                      spent: spentAmt,
                                      index: entry.key,
                                      onDeleted: () => ref.invalidate(
                                          budgetsListProvider(tenantId)),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                // ── FAB ──────────────────────────────────────────────
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: GestureDetector(
                    onTap: () => _showAddBudgetSheet(context, ref, tenantId),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: b.primary,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: b.primary.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: b.onPrimary,
                        size: 28,
                      ),
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

  void _showAddBudgetSheet(
      BuildContext context, WidgetRef ref, String tenantId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddBudgetBottomSheet(
        tenantId: tenantId,
        onCreated: () => ref.invalidate(budgetsListProvider(tenantId)),
      ),
    );
  }
}

// ── Summary Card ────────────────────────────────────────────────────────────

class _BudgetSummaryCard extends StatelessWidget {
  final List<Budget> budgets;
  final Map<String, double> spent;

  const _BudgetSummaryCard({
    required this.budgets,
    required this.spent,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final formatter = NumberFormat('#,##0', 'es_MX');
    final totalBudget = budgets.fold<double>(0, (sum, bg) => sum + bg.amount);
    final totalSpent = spent.values.fold<double>(0, (sum, v) => sum + v);
    final percentage =
        totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;
    final remaining = totalBudget - totalSpent;

    Color barColor;
    String message;
    if (percentage < 0.5) {
      barColor = b.success;
      message = 'Te quedan \$${formatter.format(remaining)} este mes 🌿';
    } else if (percentage < 0.8) {
      barColor = b.warning;
      message = 'Vas bien, sigue así 👍';
    } else {
      barColor = b.error;
      message = 'Casi al límite 🌊';
    }

    return AppCard(
      padding: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PRESUPUESTO TOTAL',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: b.textSecondary,
              letterSpacing: 0.06 * 12,
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '\$${formatter.format(totalSpent)}',
                  style: GoogleFonts.dmSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: b.textPrimary,
                    letterSpacing: -0.03 * 24,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                TextSpan(
                  text: ' / \$${formatter.format(totalBudget)}',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: b.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: percentage),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (_, val, __) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: val,
                  backgroundColor: b.surfaceAlt,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  minHeight: 6,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: b.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Budget Category Card ────────────────────────────────────────────────────

class _BudgetCategoryCard extends ConsumerWidget {
  final Budget budget;
  final double spent;
  final int index;
  final VoidCallback onDeleted;

  const _BudgetCategoryCard({
    required this.budget,
    required this.spent,
    required this.index,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = context.bruma;
    final formatter = NumberFormat('#,##0', 'es_MX');
    final percentage =
        budget.amount > 0 ? (spent / budget.amount).clamp(0.0, 1.0) : 0.0;
    final catColor = kCategoryColors[budget.category] ?? b.primary;

    Color barColor;
    if (percentage < 0.5) {
      barColor = b.success;
    } else if (percentage < 0.8) {
      barColor = b.warning;
    } else {
      barColor = b.error;
    }

    return FadeUpAnimation(
      delayMs: index * 50,
      child: GestureDetector(
        onLongPress: () => _confirmDelete(context, ref),
        child: AppCard(
          padding: 16,
          child: Column(
            children: [
              Row(
                children: [
                  // Ícono de categoría
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        budget.emoji,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppCategories.labelForId(budget.category),
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: b.textPrimary,
                          ),
                        ),
                        Text(
                          '\$${formatter.format(spent)} / \$${formatter.format(budget.amount)}',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: b.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: barColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '${(percentage * 100).toInt()}%',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: barColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: percentage),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (_, val, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: val,
                    backgroundColor: b.surfaceAlt,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    minHeight: 6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final b = context.bruma;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: b.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Eliminar presupuesto',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            color: b.textPrimary,
          ),
        ),
        content: Text(
          '¿Eliminar el presupuesto de ${AppCategories.labelForId(budget.category)}?',
          style: GoogleFonts.dmSans(color: b.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: GoogleFonts.dmSans(color: b.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await ref
                    .read(budgetRepositoryProvider)
                    .deleteBudget(budget.id);
                if (context.mounted) Navigator.pop(context);
                onDeleted();
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: b.error),
            child: Text('Eliminar', style: GoogleFonts.dmSans()),
          ),
        ],
      ),
    );
  }
}

// ── Add Budget Bottom Sheet ─────────────────────────────────────────────────

class _AddBudgetBottomSheet extends ConsumerStatefulWidget {
  final String tenantId;
  final VoidCallback onCreated;

  const _AddBudgetBottomSheet({
    required this.tenantId,
    required this.onCreated,
  });

  @override
  ConsumerState<_AddBudgetBottomSheet> createState() =>
      _AddBudgetBottomSheetState();
}

class _AddBudgetBottomSheetState extends ConsumerState<_AddBudgetBottomSheet> {
  final _amountCtrl = TextEditingController();
  String _selectedCategory = AppCategories.expenses.first.id;
  String _selectedPeriod = 'monthly';
  bool _loading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;

    return Container(
      decoration: BoxDecoration(
        color: b.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: b.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Nuevo presupuesto',
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: b.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Categoría
            Text(
              'Categoría',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: b.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppCategories.expenses.map((category) {
                return CategoryPill(
                  category: category.id,
                  label: '${category.emoji} ${category.label}',
                  selected: _selectedCategory == category.id,
                  onTap: () => setState(() => _selectedCategory = category.id),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Monto
            AmountInputField(
              controller: _amountCtrl,
              autofocus: false,
            ),
            const SizedBox(height: 16),

            // Período
            Text(
              'Período',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: b.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: b.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _PeriodButton(
                    label: 'Mensual',
                    selected: _selectedPeriod == 'monthly',
                    onTap: () => setState(() => _selectedPeriod = 'monthly'),
                  ),
                  _PeriodButton(
                    label: 'Semanal',
                    selected: _selectedPeriod == 'weekly',
                    onTap: () => setState(() => _selectedPeriod = 'weekly'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Botón guardar
            AppButton(
              label: 'Guardar presupuesto',
              onPressed: _save,
              loading: _loading,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final amount = AmountInputField.parseAmount(_amountCtrl.text);
    if (amount <= 0) return;

    setState(() => _loading = true);
    try {
      await ref.read(budgetRepositoryProvider).createBudget(
            tenantId: widget.tenantId,
            category: _selectedCategory,
            amount: amount,
            period: _selectedPeriod,
          );
      if (mounted) Navigator.pop(context);
      widget.onCreated();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ── Period Button ──────────────────────────────────────────────────────────

class _PeriodButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? b.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                color: selected ? b.onPrimary : b.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty State ──────────────────────────────────────────────────────────────

class _EmptyBudget extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyBudget({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: BrumaEmptyState(
        type: BrumaEmptyType.budgets,
        title: 'Sin presupuestos aún',
        subtitle: 'Define límites por categoría',
        action: AppButton(
          label: 'Crear presupuesto',
          onPressed: onAdd,
          expanded: false,
          small: true,
        ),
      ),
    );
  }
}
