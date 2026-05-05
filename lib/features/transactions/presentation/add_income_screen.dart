// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/domain/app_categories.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/tenant_provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/amount_input_field.dart';
import '../../accounts/data/accounts_repository.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../../dashboard/domain/account_model.dart';
import '../data/transaction_repository.dart';

class _IncomeCategory {
  final String id;
  final String emoji;
  final String label;
  const _IncomeCategory(this.id, this.emoji, this.label);

  factory _IncomeCategory.fromAppCategory(AppCategory category) {
    return _IncomeCategory(category.id, category.emoji, category.label);
  }
}

final List<_IncomeCategory> kIncomeCategories = AppCategories.income
    .map(_IncomeCategory.fromAppCategory)
    .toList(growable: false);

/// Pantalla para registrar un ingreso.
/// Layout idéntico al AddExpenseScreen pero con paleta verde (success).
class AddIncomeScreen extends ConsumerStatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  ConsumerState<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends ConsumerState<AddIncomeScreen> {
  final _amountCtrl = TextEditingController();
  _IncomeCategory _selectedCategory = kIncomeCategories.first;
  Account? _selectedAccount;
  final _notesCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveIncome() async {
    final amountValue = AmountInputField.parseAmount(_amountCtrl.text);
    if (amountValue <= 0) return;
    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una cuenta')),
      );
      return;
    }

    final tenantId = ref.read(tenantProvider).value;
    if (tenantId == null) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(transactionRepositoryProvider).saveIncome(
            tenantId: tenantId,
            accountId: _selectedAccount!.id,
            amount: amountValue,
            category: _selectedCategory.id,
            notes:
                _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          );

      // Refresca tanto métricas globales como listas de cuentas individuales.
      ref.invalidate(accountsProvider(tenantId));
      ref.invalidate(allAccountsProvider(tenantId));
      ref.invalidate(totalBalanceProvider(tenantId));
      ref.invalidate(availableBalanceProvider(tenantId));
      ref.invalidate(weeklySpendProvider(tenantId));
      ref.invalidate(recentTransactionsProvider(tenantId));

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

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final tenantAsync = ref.watch(tenantProvider);

    return Scaffold(
      backgroundColor: b.bg,
      body: SafeArea(
        child: tenantAsync.when(
          loading: () =>
              Center(child: CircularProgressIndicator(color: b.success)),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (tenantId) {
            final accountsAsync = ref.watch(accountsProvider(tenantId));

            return Column(
              children: [
                // ── Top Bar ──────────────────────────────────────────
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
                        'Nuevo Ingreso',
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
                      children: [
                        const SizedBox(height: 32),

                        // ── Monto en verde ───────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: AmountInputField(
                            controller: _amountCtrl,
                            amountColor: b.success,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Selector de cuenta ───────────────────────
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
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
                                            style: GoogleFonts.dmSans(
                                                color: b.textTertiary)));
                                  }
                                  if (_selectedAccount == null &&
                                      accounts.isNotEmpty) {
                                    _selectedAccount = accounts.first;
                                  }
                                  return ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    itemCount: accounts.length,
                                    itemBuilder: (context, i) {
                                      final acc = accounts[i];
                                      final isSelected =
                                          _selectedAccount?.id == acc.id;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        child: GestureDetector(
                                          onTap: () => setState(
                                              () => _selectedAccount = acc),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 200),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? b.success
                                                  : b.surfaceAlt,
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                              border: Border.all(
                                                color: isSelected
                                                    ? b.success
                                                    : b.border,
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                acc.name,
                                                style: GoogleFonts.dmSans(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : b.textPrimary,
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
                                        color: b.success, strokeWidth: 2)),
                                error: (_, __) => Center(
                                    child: Text('Error',
                                        style: GoogleFonts.dmSans(
                                            color: b.textTertiary))),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── Selector de categoría ────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'CATEGORÍA',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: b.textSecondary,
                                letterSpacing: 0.06 * 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 44,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: kIncomeCategories.length,
                            itemBuilder: (context, i) {
                              final cat = kIncomeCategories[i];
                              final isSelected =
                                  cat.label == _selectedCategory.label;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedCategory = cat),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected ? b.success : b.surfaceAlt,
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(
                                      color: isSelected ? b.success : b.border,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(cat.emoji,
                                          style: const TextStyle(fontSize: 18)),
                                      const SizedBox(width: 6),
                                      Text(
                                        cat.label,
                                        style: GoogleFonts.dmSans(
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? Colors.white
                                              : b.textPrimary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Campo de notas ───────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: TextField(
                            controller: _notesCtrl,
                            decoration: InputDecoration(
                              hintText: 'Agregar nota...',
                              hintStyle:
                                  GoogleFonts.dmSans(color: b.textTertiary),
                              filled: true,
                              fillColor: b.surfaceAlt,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    BorderSide(color: b.success, width: 1.5),
                              ),
                            ),
                            style: GoogleFonts.dmSans(color: b.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Botón Save Income ─────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: AppButton(
                    label: 'Guardar Ingreso',
                    onPressed: _isLoading ? null : _saveIncome,
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
