import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/tenant_provider.dart';
import '../../../core/widgets/glass_card.dart';
import '../data/budget_repository.dart';

/// Pantalla principal de presupuestos por categoría.
class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantAsync = ref.watch(tenantProvider);
    final now = DateTime.now();
    final monthYear = DateFormat('MMMM yyyy').format(now);
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: tenantAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (tenantId) {
            final budgetsAsync = ref.watch(budgetsListProvider(tenantId));
            final spentAsync = ref.watch(spentByCategoryProvider(tenantId));

            return Stack(
              children: [
                ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    const SizedBox(height: 16),

                    // ── Header ──────────────────────────────────────
                    Text(
                      'Budget',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      monthYear,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Summary card ─────────────────────────────────
                    budgetsAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (budgets) => spentAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (spent) => _BudgetSummaryCard(
                          budgets: budgets,
                          spent: spent,
                          formatter: formatter,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Lista de budgets por categoría ───────────────
                    budgetsAsync.when(
                      loading: () => const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary)),
                      error: (err, _) =>
                          Text('Error: $err', style: GoogleFonts.poppins()),
                      data: (budgets) {
                        if (budgets.isEmpty) {
                          return _EmptyBudget(
                            onAdd: () => _showAddBudgetSheet(
                                context, ref, tenantId),
                          );
                        }
                        return spentAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (spent) => Column(
                            children: budgets.map((b) {
                              final spentAmt =
                                  spent[b.category.toLowerCase()] ?? 0;
                              return _BudgetCategoryCard(
                                budget: b,
                                spent: spentAmt,
                                formatter: formatter,
                                onDeleted: () =>
                                    ref.invalidate(budgetsListProvider(tenantId)),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 120),
                  ],
                ),

                // ── FAB para agregar budget ──────────────────────────
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    onPressed: () =>
                        _showAddBudgetSheet(context, ref, tenantId),
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.add, color: Colors.white),
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

// ─── Summary Card ─────────────────────────────────────────────────────────────

class _BudgetSummaryCard extends StatelessWidget {
  final List<Budget> budgets;
  final Map<String, double> spent;
  final NumberFormat formatter;

  const _BudgetSummaryCard({
    required this.budgets,
    required this.spent,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final totalBudget =
        budgets.fold<double>(0, (sum, b) => sum + b.amount);
    final totalSpent =
        spent.values.fold<double>(0, (sum, v) => sum + v);
    final percentage =
        totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;
    final remaining = totalBudget - totalSpent;

    Color barColor;
    String message;
    if (percentage < 0.5) {
      barColor = AppColors.primary;
      message = 'You have ${formatter.format(remaining)} left this month 🌿';
    } else if (percentage < 0.8) {
      barColor = const Color(0xFFF59E0B);
      message = "You're on track 👍";
    } else {
      barColor = const Color(0xFFEF4444);
      message = 'Almost at your limit 🌊';
    }

    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Budget',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${formatter.format(totalSpent)} spent of ${formatter.format(totalBudget)}',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Barra de progreso animada
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: percentage),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (_, val, __) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: val,
                  backgroundColor: Colors.white.withAlpha(127),
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  minHeight: 12,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Budget Category Card ──────────────────────────────────────────────────────

class _BudgetCategoryCard extends ConsumerWidget {
  final Budget budget;
  final double spent;
  final NumberFormat formatter;
  final VoidCallback onDeleted;

  const _BudgetCategoryCard({
    required this.budget,
    required this.spent,
    required this.formatter,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final percentage =
        budget.amount > 0 ? (spent / budget.amount).clamp(0.0, 1.0) : 0.0;

    Color barColor;
    if (percentage < 0.5) {
      barColor = AppColors.primary;
    } else if (percentage < 0.8) {
      barColor = const Color(0xFFF59E0B);
    } else {
      barColor = const Color(0xFFEF4444);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onLongPress: () => _confirmDelete(context, ref),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 20,
          child: Column(
            children: [
              Row(
                children: [
                  Text(budget.emoji,
                      style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget.category,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${formatter.format(spent)} of ${formatter.format(budget.amount)}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(percentage * 100).toInt()}%',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: barColor,
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
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: val,
                    backgroundColor: Colors.white.withAlpha(127),
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    minHeight: 8,
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
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Eliminar presupuesto',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('¿Eliminar el presupuesto de ${budget.category}?',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
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
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            child: Text('Eliminar', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }
}

// ─── Add Budget Bottom Sheet ───────────────────────────────────────────────────

class _AddBudgetBottomSheet extends ConsumerStatefulWidget {
  final String tenantId;
  final VoidCallback onCreated;

  const _AddBudgetBottomSheet(
      {required this.tenantId, required this.onCreated});

  @override
  ConsumerState<_AddBudgetBottomSheet> createState() =>
      _AddBudgetBottomSheetState();
}

class _AddBudgetBottomSheetState
    extends ConsumerState<_AddBudgetBottomSheet> {
  final _amountCtrl = TextEditingController();
  String _selectedCategory = 'Comida';
  String _selectedPeriod = 'monthly';
  bool _loading = false;

  static const _categories = [
    ('🍔', 'Comida'),
    ('🚗', 'Transporte'),
    ('🏠', 'Renta'),
    ('🎮', 'Ocio'),
    ('🛒', 'Super'),
    ('💊', 'Salud'),
    ('👗', 'Ropa'),
    ('📱', 'Tech'),
    ('➕', 'Otro'),
  ];

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(230),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'New Budget',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Selector de categoría
                Text('Categoría',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((c) {
                    final (emoji, label) = c;
                    final isSelected = _selectedCategory == label;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedCategory = label),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey.withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey.withAlpha(50),
                          ),
                        ),
                        child: Text(
                          '$emoji $label',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Campo de monto
                TextField(
                  controller: _amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: '\$0.00',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 22,
                      color: AppColors.textLight,
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 2),
                    ),
                    prefixText: '\$ ',
                  ),
                ),

                const SizedBox(height: 16),

                // Selector de período
                Text('Período',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _PeriodButton(
                        label: 'Monthly',
                        selected: _selectedPeriod == 'monthly',
                        onTap: () =>
                            setState(() => _selectedPeriod = 'monthly'),
                      ),
                      _PeriodButton(
                        label: 'Weekly',
                        selected: _selectedPeriod == 'weekly',
                        onTap: () =>
                            setState(() => _selectedPeriod = 'weekly'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Botón Save Budget
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _loading ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            'Save Budget',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) return;

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

class _PeriodButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodButton(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyBudget extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyBudget({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Text('🎯', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            'Set your first budget',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: Text('Create Budget', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }
}
