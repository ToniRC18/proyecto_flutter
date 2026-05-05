import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../core/domain/app_categories.dart';
import '../../../core/providers/tenant_provider.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/amount_input_field.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/bruma_offline_error.dart';
import '../../../core/widgets/bruma_empty_state.dart';
import '../../../core/widgets/category_pill.dart';
import '../../../core/widgets/transaction_list_item.dart';
import '../../budget/data/budget_repository.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../domain/transaction_model.dart';

class AllTransactionsScreen extends ConsumerStatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  ConsumerState<AllTransactionsScreen> createState() =>
      _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends ConsumerState<AllTransactionsScreen> {
  late final TextEditingController _searchCtrl;
  String _searchQuery = '';
  String? _filterType;
  String? _filterCategory;
  DateTime? _filterDateFrom;
  DateTime? _filterDateTo;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController()
      ..addListener(() {
        if (_searchQuery == _searchCtrl.text) return;
        setState(() => _searchQuery = _searchCtrl.text);
      });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
          error: (error, stack) => buildAsyncError(
            error,
            stack,
            onRetry: () => ref.invalidate(tenantProvider),
            context: context,
          ),
          data: (tenantId) {
            final transactionsAsync =
                ref.watch(allTransactionsProvider(tenantId));

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: Icon(
                          Iconsax.arrow_left,
                          color: b.textPrimary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Transacciones',
                          style: GoogleFonts.dmSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: b.textPrimary,
                            letterSpacing: -0.02 * 17,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          setState(() => _showFilters = !_showFilters);
                        },
                        icon: Icon(
                          Iconsax.filter,
                          color:
                              _hasActiveFilters ? b.primary : b.textSecondary,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: _SearchField(
                    controller: _searchCtrl,
                    onClear: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  child: _showFilters
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          child: _FiltersPanel(
                            filterType: _filterType,
                            filterCategory: _filterCategory,
                            filterDateFrom: _filterDateFrom,
                            filterDateTo: _filterDateTo,
                            hasActiveFilters: _hasActiveFilters,
                            onTypeChanged: (value) {
                              HapticFeedback.lightImpact();
                              setState(() => _filterType = value);
                            },
                            onCategoryChanged: (value) {
                              HapticFeedback.lightImpact();
                              setState(() => _filterCategory = value);
                            },
                            onPickFromDate: () => _pickDate(isFrom: true),
                            onPickToDate: () => _pickDate(isFrom: false),
                            onClear: _clearFilters,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Expanded(
                  child: transactionsAsync.when(
                    loading: () => Center(
                      child: CircularProgressIndicator(color: b.primary),
                    ),
                    error: (error, stack) => buildAsyncError(
                      error,
                      stack,
                      onRetry: () => ref.invalidate(
                        allTransactionsProvider(tenantId),
                      ),
                      context: context,
                    ),
                    data: (transactions) {
                      if (transactions.isEmpty) {
                        return const BrumaEmptyState(
                          type: BrumaEmptyType.transactions,
                          title: 'Sin transacciones aún',
                          subtitle: 'Tus movimientos aparecerán aquí',
                        );
                      }

                      final filtered = _applyFilters(transactions);
                      if (filtered.isEmpty) {
                        return BrumaEmptyState(
                          type: _searchQuery.trim().isNotEmpty
                              ? BrumaEmptyType.search
                              : BrumaEmptyType.transactions,
                          title: _searchQuery.trim().isNotEmpty
                              ? 'No encontramos coincidencias'
                              : 'No hay resultados con esos filtros',
                          subtitle: _searchQuery.trim().isNotEmpty
                              ? 'Prueba con otro término de búsqueda'
                              : 'Ajusta tus filtros para ver más movimientos',
                        );
                      }

                      final widgets = _buildGroupedTransactionWidgets(
                        context,
                        filtered,
                        tenantId,
                      );

                      return ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(8, 12, 8, 24),
                        children: widgets,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  bool get _hasActiveFilters =>
      _filterType != null ||
      _filterCategory != null ||
      _filterDateFrom != null ||
      _filterDateTo != null;

  Future<void> _pickDate({required bool isFrom}) async {
    final b = context.bruma;

    try {
      final picked = await showDatePicker(
        context: context,
        initialDate: isFrom
            ? (_filterDateFrom ?? DateTime.now())
            : (_filterDateTo ?? DateTime.now()),
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        builder: (context, child) {
          final theme = Theme.of(context);
          return Theme(
            data: theme.copyWith(
              colorScheme: theme.colorScheme.copyWith(
                primary: b.primary,
                onPrimary: b.onPrimary,
                surface: b.surface,
                onSurface: b.textPrimary,
              ),
              dialogTheme: DialogThemeData(backgroundColor: b.surface),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
      );

      if (picked == null) return;
      HapticFeedback.lightImpact();
      setState(() {
        if (isFrom) {
          _filterDateFrom = DateTime(picked.year, picked.month, picked.day);
        } else {
          _filterDateTo =
              DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: b.error,
          content: Text('Error: $error'),
        ),
      );
    }
  }

  void _clearFilters() {
    HapticFeedback.lightImpact();
    setState(() {
      _filterType = null;
      _filterCategory = null;
      _filterDateFrom = null;
      _filterDateTo = null;
    });
  }

  List<Transaction> _applyFilters(List<Transaction> transactions) {
    final query = _searchQuery.trim().toLowerCase();

    return transactions.where((tx) {
      final normalizedCategory = AppCategories.normalizeId(tx.category);
      final notes = (tx.notes ?? '').toLowerCase();
      final categoryLabel =
          AppCategories.labelForId(normalizedCategory).toLowerCase();

      final matchesQuery = query.isEmpty ||
          notes.contains(query) ||
          categoryLabel.contains(query);
      final matchesType = _filterType == null || tx.type == _filterType;
      final matchesCategory =
          _filterCategory == null || normalizedCategory == _filterCategory;
      final matchesFrom =
          _filterDateFrom == null || !tx.date.isBefore(_filterDateFrom!);
      final matchesTo =
          _filterDateTo == null || !tx.date.isAfter(_filterDateTo!);

      return matchesQuery &&
          matchesType &&
          matchesCategory &&
          matchesFrom &&
          matchesTo;
    }).toList();
  }

  List<Widget> _buildGroupedTransactionWidgets(
    BuildContext context,
    List<Transaction> transactions,
    String tenantId,
  ) {
    final widgets = <Widget>[];
    DateTime? currentGroup;

    for (var index = 0; index < transactions.length; index++) {
      final tx = transactions[index];
      final txDay = DateTime(tx.date.year, tx.date.month, tx.date.day);

      if (currentGroup == null || !DateUtils.isSameDay(currentGroup, txDay)) {
        currentGroup = txDay;
        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Text(
              _groupLabel(txDay),
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.bruma.textSecondary,
              ),
            ),
          ),
        );
      }

      widgets.add(
        GestureDetector(
          onLongPress: () => _showTransactionActions(tx, tenantId),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: TransactionListItem(
              title: tx.notes?.trim().isNotEmpty == true
                  ? tx.notes!.trim()
                  : AppCategories.labelForId(tx.category),
              category: tx.category,
              amount: tx.type == 'income' ? tx.amount : -tx.amount,
              date: DateFormat('dd MMM', 'es_MX').format(tx.date),
              index: index,
              onTap: () => context.push(
                AppRoutes.transactionDetail,
                extra: tx,
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  String _groupLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (DateUtils.isSameDay(day, today)) return 'Hoy';
    if (DateUtils.isSameDay(day, yesterday)) return 'Ayer';
    return DateFormat('dd MMM yyyy', 'es_MX').format(day);
  }

  Future<void> _showTransactionActions(
    Transaction transaction,
    String tenantId,
  ) async {
    final b = context.bruma;
    HapticFeedback.lightImpact();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: b.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: b.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                _ActionRow(
                  icon: Iconsax.edit,
                  label: 'Editar',
                  color: b.textPrimary,
                  onTap: () {
                    Navigator.pop(context);
                    _showEditTransactionSheet(transaction, tenantId);
                  },
                ),
                const SizedBox(height: 8),
                _ActionRow(
                  icon: Iconsax.trash,
                  label: 'Eliminar',
                  color: b.error,
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteTransaction(transaction, tenantId);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditTransactionSheet(
    Transaction transaction,
    String tenantId,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditTransactionSheet(
        transaction: transaction,
        tenantId: tenantId,
        onSaved: () {
          _invalidateTransactionProviders(tenantId);
        },
      ),
    );
  }

  Future<void> _confirmDeleteTransaction(
    Transaction transaction,
    String tenantId,
  ) async {
    final b = context.bruma;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: b.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Eliminar transacción',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            color: b.textPrimary,
          ),
        ),
        content: Text(
          'Esta acción no se puede deshacer.',
          style: GoogleFonts.dmSans(color: b.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.dmSans(color: b.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Eliminar',
              style: GoogleFonts.dmSans(
                color: b.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(deleteTransactionProvider)(transaction.id);
      _invalidateTransactionProviders(tenantId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transacción eliminada')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: b.error,
          content: Text('Error: $error'),
        ),
      );
    }
  }

  void _invalidateTransactionProviders(String tenantId) {
    ref.invalidate(allTransactionsProvider(tenantId));
    ref.invalidate(recentTransactionsProvider(tenantId));
    ref.invalidate(availableBalanceProvider(tenantId));
    ref.invalidate(weeklySpendProvider(tenantId));
    ref.invalidate(weeklySpendByDayProvider(tenantId));
    ref.invalidate(budgetsProvider(tenantId));
    ref.invalidate(spentByCategoryProvider(tenantId));
    ref.invalidate(statsSpendByCategoryProvider);
    ref.invalidate(statsTotalsProvider);
    ref.invalidate(statsTopExpensesProvider);
    ref.invalidate(statsPreviousExpensesProvider);
    ref.invalidate(statsTrendsProvider);
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;

    return TextField(
      controller: controller,
      style: GoogleFonts.dmSans(
        fontSize: 14,
        color: b.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'Buscar...',
        hintStyle: GoogleFonts.dmSans(
          fontSize: 14,
          color: b.textTertiary,
        ),
        prefixIcon:
            Icon(Iconsax.search_normal, color: b.textSecondary, size: 18),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                onPressed: onClear,
                icon:
                    Icon(Iconsax.close_circle, color: b.textTertiary, size: 18),
              )
            : null,
        filled: true,
        fillColor: b.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _FiltersPanel extends StatelessWidget {
  final String? filterType;
  final String? filterCategory;
  final DateTime? filterDateFrom;
  final DateTime? filterDateTo;
  final bool hasActiveFilters;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onPickFromDate;
  final VoidCallback onPickToDate;
  final VoidCallback onClear;

  const _FiltersPanel({
    required this.filterType,
    required this.filterCategory,
    required this.filterDateFrom,
    required this.filterDateTo,
    required this.hasActiveFilters,
    required this.onTypeChanged,
    required this.onCategoryChanged,
    required this.onPickFromDate,
    required this.onPickToDate,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final categories = <String, String>{};

    for (final category in AppCategories.all) {
      categories[AppCategories.normalizeId(category.id)] =
          '${category.emoji} ${category.label}';
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipo',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: b.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _TypeChip(
                label: 'Todos',
                selected: filterType == null,
                onTap: () => onTypeChanged(null),
              ),
              const SizedBox(width: 8),
              _TypeChip(
                label: 'Ingresos',
                selected: filterType == 'income',
                onTap: () => onTypeChanged('income'),
              ),
              const SizedBox(width: 8),
              _TypeChip(
                label: 'Gastos',
                selected: filterType == 'expense',
                onTap: () => onTypeChanged('expense'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Categoría',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: b.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                CategoryPill(
                  category: 'all',
                  label: 'Todas',
                  selected: filterCategory == null,
                  onTap: () => onCategoryChanged(null),
                ),
                const SizedBox(width: 8),
                ...categories.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CategoryPill(
                      category: entry.key,
                      label: entry.value,
                      selected: filterCategory == entry.key,
                      onTap: () => onCategoryChanged(entry.key),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Período',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: b.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DateFilterButton(
                  label: filterDateFrom == null
                      ? 'Desde'
                      : DateFormat('dd MMM yyyy', 'es_MX')
                          .format(filterDateFrom!),
                  onTap: onPickFromDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateFilterButton(
                  label: filterDateTo == null
                      ? 'Hasta'
                      : DateFormat('dd MMM yyyy', 'es_MX')
                          .format(filterDateTo!),
                  onTap: onPickToDate,
                ),
              ),
            ],
          ),
          if (hasActiveFilters) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: onClear,
                child: Text(
                  'Limpiar filtros',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: b.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? b.primary : b.surfaceAlt,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? b.onPrimary : b.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _DateFilterButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DateFilterButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: b.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Iconsax.calendar_1, size: 16, color: b.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: b.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: context.bruma.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditTransactionSheet extends ConsumerStatefulWidget {
  final Transaction transaction;
  final String tenantId;
  final VoidCallback onSaved;

  const _EditTransactionSheet({
    required this.transaction,
    required this.tenantId,
    required this.onSaved,
  });

  @override
  ConsumerState<_EditTransactionSheet> createState() =>
      _EditTransactionSheetState();
}

class _EditTransactionSheetState extends ConsumerState<_EditTransactionSheet> {
  late final TextEditingController _notesCtrl;
  late final TextEditingController _amountCtrl;
  late String _selectedCategory;
  late DateTime _selectedDate;
  bool _saving = false;

  List<_CategoryOption> get _availableCategories {
    final source = widget.transaction.type == 'expense'
        ? AppCategories.expenses
        : AppCategories.income;
    return source
        .map(
          (category) => _CategoryOption(
            id: AppCategories.normalizeId(category.id),
            label: '${category.emoji} ${category.label}',
          ),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController(text: widget.transaction.notes ?? '');
    _amountCtrl = TextEditingController(
      text: AmountInputField.formatAmount(
        (widget.transaction.amount * 100).round().toString(),
      ),
    );
    _selectedCategory = AppCategories.normalizeId(widget.transaction.category);
    _selectedDate = widget.transaction.date;
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
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
              'Editar transacción',
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: b.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesCtrl,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: b.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Notas',
                hintStyle: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: b.textTertiary,
                ),
                filled: true,
                fillColor: b.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
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
              children: _availableCategories.map((category) {
                return CategoryPill(
                  category: category.id,
                  label: category.label,
                  selected: _selectedCategory == category.id,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedCategory = category.id);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            AmountInputField(
              controller: _amountCtrl,
              autofocus: false,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: b.surfaceAlt,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Iconsax.calendar_1, color: b.textSecondary, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('dd MMM yyyy', 'es_MX').format(_selectedDate),
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: b.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Guardar cambios',
              loading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final b = context.bruma;

    try {
      final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        builder: (context, child) {
          final theme = Theme.of(context);
          return Theme(
            data: theme.copyWith(
              colorScheme: theme.colorScheme.copyWith(
                primary: b.primary,
                onPrimary: b.onPrimary,
                surface: b.surface,
                onSurface: b.textPrimary,
              ),
              dialogTheme: DialogThemeData(backgroundColor: b.surface),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
      );

      if (picked == null) return;
      HapticFeedback.lightImpact();
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: b.error,
          content: Text('Error: $error'),
        ),
      );
    }
  }

  Future<void> _save() async {
    final b = context.bruma;
    final amount = AmountInputField.parseAmount(_amountCtrl.text);
    if (amount <= 0) return;

    setState(() => _saving = true);
    try {
      await ref.read(updateTransactionProvider)(
        id: widget.transaction.id,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        category: _selectedCategory,
        amount: amount,
        date: _selectedDate,
      );

      widget.onSaved();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cambios guardados')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: b.error,
          content: Text('Error: $error'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _CategoryOption {
  final String id;
  final String label;

  const _CategoryOption({
    required this.id,
    required this.label,
  });
}
