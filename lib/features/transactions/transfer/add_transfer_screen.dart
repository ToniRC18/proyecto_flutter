import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/tenant_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/amount_input_field.dart';
import '../../dashboard/domain/account_model.dart';
import 'transfer_provider.dart';
import 'transfer_repository.dart';

/// Pantalla para mover dinero entre cuentas del mismo tenant.
class AddTransferScreen extends ConsumerStatefulWidget {
  const AddTransferScreen({super.key});

  @override
  ConsumerState<AddTransferScreen> createState() => _AddTransferScreenState();
}

class _AddTransferScreenState extends ConsumerState<AddTransferScreen> {
  final _amountCtrl = TextEditingController();
  Account? _fromAccount;
  Account? _toAccount;
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    try {
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
        locale: const Locale('es'),
      );

      if (pickedDate != null && mounted) {
        setState(() => _selectedDate = pickedDate);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar la fecha: $error')),
      );
    }
  }

  Future<void> _submitTransfer(String tenantId) async {
    final amountValue = AmountInputField.parseAmount(_amountCtrl.text);
    if (amountValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un monto mayor a cero.')),
      );
      return;
    }

    if (_fromAccount == null || _toAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una cuenta origen y una cuenta destino.'),
        ),
      );
      return;
    }

    if (_fromAccount!.id == _toAccount!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes transferir a la misma cuenta.'),
        ),
      );
      return;
    }

    try {
      await ref.read(transferControllerProvider.notifier).createTransfer(
            fromAccountId: _fromAccount!.id,
            toAccountId: _toAccount!.id,
            amount: amountValue,
            tenantId: tenantId,
            notes: _notesController.text.trim(),
            date: _selectedDate,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Transferencia registrada correctamente.')),
      );
      context.pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final tenantAsync = ref.watch(tenantProvider);
    final transferState = ref.watch(transferControllerProvider);
    final isLoading = transferState.isLoading;

    return Scaffold(
      backgroundColor: b.bg,
      body: SafeArea(
        child: tenantAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: b.primary),
          ),
          error: (error, _) => Center(child: Text('Error: $error')),
          data: (tenantId) {
            final accountsAsync = ref.watch(transferAccountsProvider(tenantId));

            return accountsAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: b.primary),
              ),
              error: (error, _) => Center(child: Text('Error: $error')),
              data: (accounts) {
                _syncSelectedAccounts(accounts);

                if (accounts.length < 2) {
                  return _TransferEmptyState(onClose: () => context.pop());
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(Iconsax.close_circle,
                                color: b.textPrimary, size: 22),
                            onPressed: isLoading ? null : () => context.pop(),
                          ),
                          Text(
                            'Transferencia',
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
                            const SizedBox(height: 24),
                            AmountInputField(
                              controller: _amountCtrl,
                              amountColor: b.primary,
                            ),
                            const SizedBox(height: 24),
                            _AccountSelectorCard(
                              title: 'De cuenta',
                              value: _fromAccount,
                              accounts: accounts,
                              enabled: !isLoading,
                              onChanged: (account) {
                                setState(() {
                                  _fromAccount = account;
                                  if (_toAccount?.id == account?.id) {
                                    _toAccount = _firstDestinationFor(
                                        accounts, account?.id);
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            _AccountSelectorCard(
                              title: 'A cuenta',
                              value: _toAccount,
                              accounts: accounts
                                  .where((account) =>
                                      account.id != _fromAccount?.id)
                                  .toList(),
                              enabled: !isLoading,
                              onChanged: (account) {
                                setState(() => _toAccount = account);
                              },
                            ),
                            const SizedBox(height: 12),
                            AppCard(
                              padding: 16,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Notas',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: b.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: _notesController,
                                    enabled: !isLoading,
                                    maxLines: 3,
                                    decoration: InputDecoration(
                                      hintText: 'Agregar una nota opcional',
                                      hintStyle: GoogleFonts.dmSans(
                                        color: b.textTertiary,
                                      ),
                                      filled: true,
                                      fillColor: b.surfaceAlt,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.all(14),
                                    ),
                                    style: GoogleFonts.dmSans(
                                        color: b.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            AppCard(
                              padding: 16,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Fecha',
                                          style: GoogleFonts.dmSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: b.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('dd/MM/yyyy')
                                              .format(_selectedDate),
                                          style: GoogleFonts.dmSans(
                                            fontSize: 14,
                                            color: b.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: isLoading ? null : _pickDate,
                                    child: Row(
                                      children: [
                                        Icon(Iconsax.calendar_1,
                                            color: b.primary, size: 18),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Cambiar',
                                          style: GoogleFonts.dmSans(
                                            color: b.primary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
                        onPressed:
                            isLoading ? null : () => _submitTransfer(tenantId),
                        loading: isLoading,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _syncSelectedAccounts(List<Account> accounts) {
    if (_fromAccount == null && accounts.isNotEmpty) {
      _fromAccount = accounts.first;
    } else if (_fromAccount != null &&
        accounts.every((account) => account.id != _fromAccount!.id)) {
      _fromAccount = accounts.isNotEmpty ? accounts.first : null;
    }

    final destinationAccounts =
        accounts.where((account) => account.id != _fromAccount?.id).toList();

    if (_toAccount == null && destinationAccounts.isNotEmpty) {
      _toAccount = destinationAccounts.first;
      return;
    }

    if (_toAccount != null &&
        destinationAccounts.every((account) => account.id != _toAccount!.id)) {
      _toAccount =
          destinationAccounts.isNotEmpty ? destinationAccounts.first : null;
    }
  }

  Account? _firstDestinationFor(List<Account> accounts, String? fromAccountId) {
    try {
      return accounts.firstWhere((account) => account.id != fromAccountId);
    } catch (_) {
      return null;
    }
  }
}

class _AccountSelectorCard extends StatelessWidget {
  final String title;
  final Account? value;
  final List<Account> accounts;
  final bool enabled;
  final ValueChanged<Account?> onChanged;

  const _AccountSelectorCard({
    required this.title,
    required this.value,
    required this.accounts,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return AppCard(
      padding: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: b.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('${title}_${value?.id ?? 'empty'}'),
            initialValue: value?.id,
            items: accounts
                .map(
                  (account) => DropdownMenuItem<String>(
                    value: account.id,
                    child: Text(
                      '${account.name} • ${formatter.format(account.balance)}',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        color: b.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: enabled
                ? (accountId) {
                    final selected = accounts.cast<Account?>().firstWhere(
                          (account) => account?.id == accountId,
                          orElse: () => null,
                        );
                    onChanged(selected);
                  }
                : null,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: b.primary,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: b.surfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            dropdownColor: b.surface,
            style: GoogleFonts.dmSans(color: b.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _TransferEmptyState extends StatelessWidget {
  final VoidCallback onClose;

  const _TransferEmptyState({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Iconsax.close_circle,
                      color: b.textPrimary, size: 22),
                  onPressed: onClose,
                ),
                Text(
                  'Transferencia',
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
          const Spacer(),
          AppCard(
            padding: 32,
            child: Column(
              children: [
                Icon(
                  Iconsax.convert,
                  size: 48,
                  color: b.textTertiary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Necesitas al menos 2 cuentas para transferir',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    color: b.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
