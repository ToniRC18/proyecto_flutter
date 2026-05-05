import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/tenant_provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/amount_input_field.dart';
import '../../accounts/data/accounts_repository.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../../dashboard/domain/account_model.dart';
import '../../shared_spaces/data/shared_spaces_repository.dart';
import '../data/transaction_repository.dart';
import '../split/data/split_repository.dart';
import '../split/domain/transaction_split_model.dart';
import '../split/presentation/split_expense_sheet.dart';
import 'widgets/category_selector.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final CategoryItem? initialCategory;

  const AddExpenseScreen({super.key, this.initialCategory});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _amountCtrl = TextEditingController();
  late CategoryItem _selectedCategory;
  Account? _selectedAccount;
  bool _isLoading = false;
  bool _splitEnabled = false;
  List<TransactionSplitModel> _configuredSplits = const [];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? kCategories.first;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    final amountValue = AmountInputField.parseAmount(_amountCtrl.text);
    if (amountValue <= 0) return;
    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una cuenta')),
      );
      return;
    }

    final activeTenant = ref.read(activeTenantProvider).value;
    if (activeTenant == null) return;

    if (_splitEnabled && _configuredSplits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Configura el split antes de guardar el gasto')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final transactionId =
          await ref.read(transactionRepositoryProvider).saveExpense(
                tenantId: activeTenant.id,
                accountId: _selectedAccount!.id,
                amount: amountValue,
                category: _selectedCategory.id,
                hasSplit: _splitEnabled && _configuredSplits.isNotEmpty,
              );

      if (_splitEnabled && _configuredSplits.isNotEmpty) {
        try {
          // El repositorio decide si persiste online o encola offline.
          await ref.read(splitRepositoryProvider).createSplits(
                transactionId: transactionId,
                splits: _configuredSplits,
              );
        } catch (error, stackTrace) {
          debugPrint('Error al crear splits: $error');
          debugPrintStack(stackTrace: stackTrace);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('El gasto se guardó, pero el split falló: $error')),
            );
          }
        }
      }

      // Invalidar providers para refrescar dashboard, cuentas y balances compartidos.
      ref.invalidate(accountsProvider(activeTenant.id));
      ref.invalidate(allAccountsProvider(activeTenant.id));
      ref.invalidate(totalBalanceProvider(activeTenant.id));
      ref.invalidate(availableBalanceProvider(activeTenant.id));
      ref.invalidate(weeklySpendProvider(activeTenant.id));
      ref.invalidate(recentTransactionsProvider(activeTenant.id));
      ref.invalidate(sharedSpacesProvider);
      ref.invalidate(membersProvider(activeTenant.id));
      ref.invalidate(balanceProvider(activeTenant.id));

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openSplitSheet(String tenantId, double totalAmount) async {
    final result = await showModalBottomSheet<List<TransactionSplitModel>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SplitExpenseSheet(
        tenantId: tenantId,
        totalAmount: totalAmount,
        initialSplits: _configuredSplits,
      ),
    );

    if (result == null) return;

    setState(() {
      _configuredSplits = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final activeTenantAsync = ref.watch(activeTenantProvider);

    return Scaffold(
      backgroundColor: b.bg,
      body: SafeArea(
        child: activeTenantAsync.when(
          loading: () =>
              Center(child: CircularProgressIndicator(color: b.primary)),
          error: (err, __) => Center(child: Text('Error: $err')),
          data: (activeTenant) {
            final accountsAsync = ref.watch(accountsProvider(activeTenant.id));
            final amountValue = AmountInputField.parseAmount(_amountCtrl.text);

            return Column(
              children: [
                // Top Bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Iconsax.close_circle,
                            color: b.textPrimary, size: 22),
                        onPressed: () => context.pop(),
                      ),
                      Text(
                        'Nuevo Gasto',
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 32),
                        // Amount Display
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: AmountInputField(
                            controller: _amountCtrl,
                            amountColor: b.error,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Selector de cuenta
                        _AccountSelector(
                          accountsAsync: accountsAsync,
                          selectedAccount: _selectedAccount,
                          onSelected: (acc) =>
                              setState(() => _selectedAccount = acc),
                        ),

                        const SizedBox(height: 28),

                        // Category Selector
                        CategorySelector(
                          selected: _selectedCategory,
                          onSelected: (cat) {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          },
                        ),

                        if (activeTenant.isShared) ...[
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _SplitToggleCard(
                              enabled: _splitEnabled,
                              hasSplits: _configuredSplits.isNotEmpty,
                              splitCount: _configuredSplits.length,
                              onToggle: (value) {
                                setState(() {
                                  _splitEnabled = value;
                                  if (!value) _configuredSplits = const [];
                                });
                              },
                              onConfigure: amountValue > 0
                                  ? () => _openSplitSheet(
                                      activeTenant.id, amountValue)
                                  : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Save Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: AppButton(
                    label: 'Guardar Gasto',
                    onPressed: _isLoading ? null : _saveExpense,
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
}

// ── Account Selector ───────────────────────────────────────────────────────

class _AccountSelector extends StatelessWidget {
  final AsyncValue<List<Account>> accountsAsync;
  final Account? selectedAccount;
  final ValueChanged<Account> onSelected;

  const _AccountSelector({
    required this.accountsAsync,
    required this.selectedAccount,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'CUENTA',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: b.textSecondary,
              letterSpacing: 0.06 * 12,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: accountsAsync.when(
            data: (accounts) {
              if (accounts.isEmpty) {
                return Center(
                  child: Text('No hay cuentas',
                      style: GoogleFonts.dmSans(color: b.textTertiary)),
                );
              }
              final isCurrentValid = selectedAccount != null &&
                  accounts.any((a) => a.id == selectedAccount!.id);
              if (!isCurrentValid && accounts.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  onSelected(accounts.first);
                });
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: accounts.length,
                itemBuilder: (context, index) {
                  final acc = accounts[index];
                  final isSelected = selectedAccount?.id == acc.id;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => onSelected(acc),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? b.primary : b.surfaceAlt,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: isSelected ? b.primary : b.border,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            acc.name,
                            style: GoogleFonts.dmSans(
                              color: isSelected ? b.onPrimary : b.textPrimary,
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => Center(
                child: CircularProgressIndicator(
                    color: b.primary, strokeWidth: 2)),
            error: (_, __) => Center(
                child: Text('Error',
                    style: GoogleFonts.dmSans(color: b.textTertiary))),
          ),
        ),
      ],
    );
  }
}

// ── Split Toggle Card ──────────────────────────────────────────────────────

class _SplitToggleCard extends StatelessWidget {
  final bool enabled;
  final bool hasSplits;
  final int splitCount;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onConfigure;

  const _SplitToggleCard({
    required this.enabled,
    required this.hasSplits,
    required this.splitCount,
    required this.onToggle,
    required this.onConfigure,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: b.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: b.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Dividir este gasto',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: b.textPrimary,
                  ),
                ),
              ),
              Switch.adaptive(
                value: enabled,
                activeThumbColor: b.primary,
                onChanged: onToggle,
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onConfigure,
              child: Text(
                'Configurar split →',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w600,
                  color: b.primary,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hasSplits
                  ? 'Split configurado: $splitCount miembros'
                  : 'Aún no has configurado la división.',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: hasSplits ? b.primary : b.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
