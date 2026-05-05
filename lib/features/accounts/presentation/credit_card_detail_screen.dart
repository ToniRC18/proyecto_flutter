import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/amount_input_field.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/balance_display.dart';
import '../../dashboard/domain/account_model.dart';
import '../data/accounts_repository.dart';
import '../data/credit_card_repository.dart';
import '../domain/msi_plan_model.dart';

class CreditCardDetailScreen extends ConsumerWidget {
  final Account account;

  const CreditCardDetailScreen({
    super.key,
    required this.account,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = context.bruma;
    final plansAsync = ref.watch(msiPlansProvider(account.id));
    final totalMonthlyAsync = ref.watch(totalMonthlyMsiProvider(account.id));

    return Scaffold(
      backgroundColor: b.bg,
      appBar: AppBar(
        backgroundColor: b.bg,
        foregroundColor: b.textPrimary,
        elevation: 0,
        title: Text(
          account.name,
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: b.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          _CreditCardOverviewCard(account: account),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Compras a meses',
                style: GoogleFonts.dmSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: b.textPrimary,
                  letterSpacing: -0.02 * 17,
                ),
              ),
              AppButton(
                label: '+ Agregar',
                expanded: false,
                small: true,
                variant: AppButtonVariant.subtle,
                onPressed: () => _showAddMsiSheet(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 16),
          plansAsync.when(
            loading: () => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: CircularProgressIndicator(color: b.primary),
              ),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Error: $error',
                style: GoogleFonts.dmSans(color: b.textSecondary),
              ),
            ),
            data: (plans) {
              if (plans.isEmpty) {
                return AppCard(
                  padding: 24,
                  child: Column(
                    children: [
                      Icon(Iconsax.card_tick, color: b.textTertiary, size: 36),
                      const SizedBox(height: 12),
                      Text(
                        'Sin compras a meses',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: b.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: plans
                    .map((plan) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _MsiPlanCard(
                            account: account,
                            plan: plan,
                          ),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 4),
          totalMonthlyAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (total) => AppCard(
              padding: 18,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total MSI este mes:',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: b.textPrimary,
                    ),
                  ),
                  Text(
                    _formatCurrency(total),
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: b.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddMsiSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMsiPlanSheet(account: account),
    );
    ref.invalidate(msiPlansProvider(account.id));
    ref.invalidate(totalMonthlyMsiProvider(account.id));
  }
}

class _CreditCardOverviewCard extends StatelessWidget {
  final Account account;

  const _CreditCardOverviewCard({required this.account});

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final usageColor = _usageColor(b, account.usagePercent);

    return AppCard(
      padding: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Crédito disponible',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: b.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          BalanceDisplay(value: account.availableCredit, fontSize: 34),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: account.usagePercent,
              minHeight: 10,
              backgroundColor: b.surfaceAlt,
              valueColor: AlwaysStoppedAnimation<Color>(usageColor),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Límite total: ${_formatCurrency(account.creditLimit ?? 0)}',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: b.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Usado: ${_formatCurrency(account.balance)}',
                  textAlign: TextAlign.end,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: b.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          if (account.billingCloseDay != null) ...[
            const SizedBox(height: 12),
            Text(
              'Corte: día ${account.billingCloseDay}',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: b.textPrimary,
              ),
            ),
          ],
          if (account.paymentDueDay != null) ...[
            const SizedBox(height: 6),
            Text(
              'Pago límite: día ${account.paymentDueDay}',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: b.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MsiPlanCard extends ConsumerWidget {
  final Account account;
  final MsiPlanModel plan;

  const _MsiPlanCard({
    required this.account,
    required this.plan,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = context.bruma;

    return AppCard(
      padding: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.storeName,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: b.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatCurrency(plan.monthlyAmount)}/mes',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: b.primary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _deletePlan(context, ref),
                icon: Icon(Iconsax.trash, color: b.error, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${plan.monthsPaid} de ${plan.monthsTotal} meses pagados',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: b.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatCurrency(plan.amountRemaining)} restante',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: b.textSecondary,
            ),
          ),
          if ((plan.notes ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              plan.notes!.trim(),
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: b.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 14),
          AppButton(
            label: 'Mes pagado',
            small: true,
            onPressed:
                plan.isCompleted ? null : () => _markMonthPaid(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _markMonthPaid(BuildContext context, WidgetRef ref) async {
    final b = context.bruma;
    try {
      HapticFeedback.lightImpact();
      await ref
          .read(creditCardRepositoryProvider)
          .markMonthPaid(plan.id, plan.monthsPaid);
      ref.invalidate(msiPlansProvider(account.id));
      ref.invalidate(totalMonthlyMsiProvider(account.id));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: b.error,
          content: Text('Error: $e'),
        ),
      );
    }
  }

  Future<void> _deletePlan(BuildContext context, WidgetRef ref) async {
    final b = context.bruma;
    try {
      await ref.read(creditCardRepositoryProvider).deleteMsiPlan(plan.id);
      ref.invalidate(msiPlansProvider(account.id));
      ref.invalidate(totalMonthlyMsiProvider(account.id));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: b.error,
          content: Text('Error: $e'),
        ),
      );
    }
  }
}

class _AddMsiPlanSheet extends ConsumerStatefulWidget {
  final Account account;

  const _AddMsiPlanSheet({required this.account});

  @override
  ConsumerState<_AddMsiPlanSheet> createState() => _AddMsiPlanSheetState();
}

class _AddMsiPlanSheetState extends ConsumerState<_AddMsiPlanSheet> {
  final _storeNameCtrl = TextEditingController();
  final _totalAmountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  int _monthsTotal = 3;
  DateTime _startDate = DateTime.now();
  bool _loading = false;

  static const _monthOptions = [3, 6, 9, 12, 18, 24];

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _totalAmountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: b.bgSecondary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: b.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Agregar compra a meses',
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: b.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _storeNameCtrl,
                  style: GoogleFonts.dmSans(color: b.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Tienda',
                    labelStyle: GoogleFonts.dmSans(color: b.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AmountInputField(
                  controller: _totalAmountCtrl,
                  autofocus: false,
                ),
                const SizedBox(height: 16),
                Text(
                  'Meses',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: b.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _monthOptions.map((value) {
                    final selected = _monthsTotal == value;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _monthsTotal = value);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected ? b.primarySubtle : b.surfaceAlt,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: selected ? b.primary : b.border,
                          ),
                        ),
                        child: Text(
                          '$value',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? b.primary : b.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                AppCard(
                  padding: 16,
                  onTap: _loading ? null : _pickDate,
                  child: Row(
                    children: [
                      Icon(Iconsax.calendar, color: b.primary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Inicio: ${DateFormat('dd MMM yyyy', 'es_MX').format(_startDate)}',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: b.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesCtrl,
                  minLines: 2,
                  maxLines: 4,
                  style: GoogleFonts.dmSans(color: b.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Notas (opcional)',
                    labelStyle: GoogleFonts.dmSans(color: b.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Agregar',
                  loading: _loading,
                  onPressed: _loading ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final b = context.bruma;
    try {
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: _startDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
        locale: const Locale('es'),
      );

      if (pickedDate != null && mounted) {
        setState(() => _startDate = pickedDate);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: b.error,
          content: Text('Error: $e'),
        ),
      );
    }
  }

  Future<void> _submit() async {
    final b = context.bruma;
    final storeName = _storeNameCtrl.text.trim();
    final totalAmount = AmountInputField.parseAmount(_totalAmountCtrl.text);

    if (storeName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: b.error,
          content: const Text('Ingresa el nombre de la tienda.'),
        ),
      );
      return;
    }

    if (totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: b.error,
          content: const Text('Ingresa un monto mayor a cero.'),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(creditCardRepositoryProvider).createMsiPlan(
            MsiPlanModel(
              id: const Uuid().v4(),
              accountId: widget.account.id,
              tenantId: widget.account.tenantId,
              storeName: storeName,
              totalAmount: totalAmount,
              monthsTotal: _monthsTotal,
              monthsPaid: 0,
              startDate: _startDate,
              isActive: true,
              notes: _notesCtrl.text.trim().isEmpty
                  ? null
                  : _notesCtrl.text.trim(),
              createdAt: DateTime.now(),
            ),
          );

      ref.invalidate(msiPlansProvider(widget.account.id));
      ref.invalidate(totalMonthlyMsiProvider(widget.account.id));
      ref.invalidate(allAccountsProvider(widget.account.tenantId));

      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: b.error,
          content: Text('Error: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

Color _usageColor(BrumaTheme b, double usagePercent) {
  if (usagePercent > 0.8) return b.error;
  if (usagePercent > 0.5) return b.warning;
  return b.success;
}

String _formatCurrency(double value) {
  final formatted = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  ).format(value);
  return formatted;
}
