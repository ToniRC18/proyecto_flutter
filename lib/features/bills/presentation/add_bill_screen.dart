import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/notifications/bills_notification_scheduler.dart';
import '../../../core/providers/tenant_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/amount_input_field.dart';
import '../../../core/widgets/bruma_offline_error.dart';
import '../../../features/accounts/data/accounts_repository.dart';
import '../../../features/dashboard/domain/account_model.dart';
import '../data/bills_repository.dart';
import '../domain/bill_model.dart';
import '../providers/bills_provider.dart';

class AddBillScreen extends ConsumerStatefulWidget {
  const AddBillScreen({super.key});

  @override
  ConsumerState<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends ConsumerState<AddBillScreen> {
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final _amountCtrl = TextEditingController();
  int _selectedDueDay = 1;
  BillFrequency _selectedFrequency = BillFrequency.monthly;
  Account? _selectedAccount;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _createBill(String tenantId) async {
    final amountValue = AmountInputField.parseAmount(_amountCtrl.text);
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un nombre para el pago.')),
      );
      return;
    }

    if (amountValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un monto mayor a cero.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final bill = ref.read(billsRepositoryProvider).buildNewBill(
            tenantId: tenantId,
            name: name,
            amount: amountValue,
            dueDay: _selectedDueDay,
            frequency: _selectedFrequency,
            category: 'bills',
            accountId: _selectedAccount?.id,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );

      await ref.read(billsRepositoryProvider).createBill(bill);
      ref.invalidate(billsProvider);
      final updatedBills = await ref.read(billsProvider.future);
      await BillsNotificationScheduler()
          .scheduleAllBillNotifications(updatedBills);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pago recurrente creado correctamente.')),
      );
      context.pop();
    } catch (error) {
      if (!mounted) return;
      final message = BrumaOfflineError.isOfflineError(error)
          ? 'Sin conexión. Intenta de nuevo cuando vuelvas a estar en línea.'
          : 'No se pudo crear el pago recurrente.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
            final accountsAsync = ref.watch(allAccountsProvider(tenantId));

            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Iconsax.close_circle,
                            color: b.textPrimary, size: 22),
                        onPressed: _isLoading ? null : () => context.pop(),
                      ),
                      Text(
                        'Nuevo pago recurrente',
                        style: GoogleFonts.dmSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: b.textPrimary,
                          letterSpacing: -0.02 * 17,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        AppCard(
                          padding: 16,
                          child: TextField(
                            controller: _nameController,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              labelText: 'Nombre',
                              labelStyle: GoogleFonts.dmSans(
                                color: b.textSecondary,
                              ),
                              border: InputBorder.none,
                            ),
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              color: b.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        AmountInputField(
                          controller: _amountCtrl,
                          autofocus: false,
                          amountColor: b.primary,
                        ),
                        const SizedBox(height: 20),
                        AppCard(
                          padding: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Día de vencimiento',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: b.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<int>(
                                key: ValueKey(
                                  '${_selectedFrequency.name}_$_selectedDueDay',
                                ),
                                initialValue: _selectedDueDay,
                                items: List.generate(
                                  _selectedFrequency == BillFrequency.weekly
                                      ? 7
                                      : 31,
                                  (index) => index + 1,
                                )
                                    .map(
                                      (day) => DropdownMenuItem<int>(
                                        value: day,
                                        child: Text(
                                          '$day',
                                          style: GoogleFonts.dmSans(),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _isLoading
                                    ? null
                                    : (day) {
                                        if (day == null) return;
                                        setState(() => _selectedDueDay = day);
                                      },
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: b.surfaceAlt,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppCard(
                          padding: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Frecuencia',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: b.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: BillFrequency.values.map((frequency) {
                                  final isSelected =
                                      _selectedFrequency == frequency;
                                  return GestureDetector(
                                    onTap: _isLoading
                                        ? null
                                        : () {
                                            setState(() {
                                              _selectedFrequency = frequency;
                                              if (_selectedFrequency ==
                                                      BillFrequency.weekly &&
                                                  _selectedDueDay > 7) {
                                                _selectedDueDay = 7;
                                              }
                                            });
                                          },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? b.primary
                                            : b.surfaceAlt,
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        border: Border.all(
                                          color:
                                              isSelected ? b.primary : b.border,
                                        ),
                                      ),
                                      child: Text(
                                        _frequencyLabel(frequency),
                                        style: GoogleFonts.dmSans(
                                          color: isSelected
                                              ? b.onPrimary
                                              : b.textPrimary,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppCard(
                          padding: 16,
                          child: accountsAsync.when(
                            loading: () => Center(
                              child: CircularProgressIndicator(
                                color: b.primary,
                              ),
                            ),
                            error: (error, stack) => buildAsyncError(
                              error,
                              stack,
                              onRetry: () => ref.invalidate(
                                allAccountsProvider(tenantId),
                              ),
                              context: context,
                            ),
                            data: (accounts) {
                              final options = <Account?>[null, ...accounts];

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cuenta asociada',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: b.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String?>(
                                    key: ValueKey(
                                        _selectedAccount?.id ?? 'none'),
                                    initialValue: _selectedAccount?.id,
                                    items: options
                                        .map(
                                          (account) =>
                                              DropdownMenuItem<String?>(
                                            value: account?.id,
                                            child: Text(
                                              account == null
                                                  ? 'Sin cuenta'
                                                  : account.name,
                                              style: GoogleFonts.dmSans(),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: _isLoading
                                        ? null
                                        : (value) {
                                            setState(() {
                                              _selectedAccount =
                                                  options.firstWhere(
                                                (account) =>
                                                    account?.id == value,
                                                orElse: () => null,
                                              );
                                            });
                                          },
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: b.surfaceAlt,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppCard(
                          padding: 16,
                          child: TextField(
                            controller: _notesController,
                            enabled: !_isLoading,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Notas opcionales',
                              labelStyle: GoogleFonts.dmSans(
                                color: b.textSecondary,
                              ),
                              border: InputBorder.none,
                            ),
                            style: GoogleFonts.dmSans(
                              color: b.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: AppButton(
                    label: 'Confirmar',
                    onPressed: _isLoading ? null : () => _createBill(tenantId),
                    loading: _isLoading,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _frequencyLabel(BillFrequency frequency) {
    switch (frequency) {
      case BillFrequency.monthly:
        return 'Mensual';
      case BillFrequency.weekly:
        return 'Semanal';
      case BillFrequency.yearly:
        return 'Anual';
    }
  }
}
