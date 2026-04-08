// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/tenant_provider.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../../dashboard/domain/account_model.dart';
import '../data/transaction_repository.dart';
import 'widgets/numeric_keyboard.dart';

/// Categorías de ingresos disponibles
const List<_IncomeCategory> kIncomeCategories = [
  _IncomeCategory('💼', 'Salary'),
  _IncomeCategory('💻', 'Freelance'),
  _IncomeCategory('🎁', 'Gift'),
  _IncomeCategory('📈', 'Investment'),
  _IncomeCategory('💰', 'Bonus'),
  _IncomeCategory('➕', 'Other'),
];

class _IncomeCategory {
  final String emoji;
  final String label;
  const _IncomeCategory(this.emoji, this.label);
}

/// Pantalla para registrar un ingreso.
/// Layout idéntico al AddExpenseScreen pero con paleta verde.
class AddIncomeScreen extends ConsumerStatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  ConsumerState<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends ConsumerState<AddIncomeScreen> {
  String _amount = '0';
  _IncomeCategory _selectedCategory = kIncomeCategories.first;
  Account? _selectedAccount;
  final _notesCtrl = TextEditingController();
  bool _isSavePressed = false;
  bool _isLoading = false;

  static const _incomeGreen = Color(0xFF2E7D32);

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  void _handleKeyPress(String key) {
    setState(() {
      if (_amount == '0' && key != '.') {
        _amount = key;
      } else if (key == '.' && _amount.contains('.')) {
        return;
      } else {
        if (_amount.length < 9) _amount += key;
      }
    });
  }

  void _handleBackspace() {
    setState(() {
      if (_amount.length > 1) {
        _amount = _amount.substring(0, _amount.length - 1);
      } else {
        _amount = '0';
      }
    });
  }

  Future<void> _saveIncome() async {
    final amountValue = double.tryParse(_amount) ?? 0.0;
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
            category: _selectedCategory.label,
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          );

      // Invalidar providers para refrescar datos del dashboard y accounts
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
    final tenantAsync = ref.watch(tenantProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: tenantAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: _incomeGreen)),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (tenantId) {
            final accountsAsync = ref.watch(accountsProvider(tenantId));

            return Column(
              children: [
                // ── Top Bar ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: AppColors.textPrimary),
                        onPressed: () => context.pop(),
                      ),
                      Text(
                        'New Income',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
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
                        Text(
                          '\$$_amount',
                          style: GoogleFonts.poppins(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: _incomeGreen,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Selector de cuenta ───────────────────────
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0),
                              child: Text(
                                'Seleccionar Cuenta',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 50,
                              child: accountsAsync.when(
                                data: (accounts) {
                                  if (accounts.isEmpty) {
                                    return const Center(
                                        child: Text('No hay cuentas'));
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
                                            horizontal: 4.0),
                                        child: ChoiceChip(
                                          label: Text(acc.name),
                                          selected: isSelected,
                                          onSelected: (val) {
                                            if (val) {
                                              setState(() =>
                                                  _selectedAccount = acc);
                                            }
                                          },
                                          selectedColor: _incomeGreen,
                                          labelStyle: GoogleFonts.poppins(
                                            color: isSelected
                                                ? Colors.white
                                                : AppColors.textPrimary,
                                            fontSize: 13,
                                          ),
                                          backgroundColor:
                                              Colors.white.withAlpha(127),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            side: BorderSide.none,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                loading: () =>
                                    const Center(child: CircularProgressIndicator()),
                                error: (_, __) => const Center(
                                    child: Text('Error al cargar cuentas')),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── Selector de categoría ────────────────────
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Categoría',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 48,
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
                                  duration:
                                      const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 6),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? _incomeGreen
                                        : AppColors.glassSurface,
                                    borderRadius:
                                        BorderRadius.circular(24),
                                    border: Border.all(
                                      color: isSelected
                                          ? _incomeGreen
                                          : AppColors.glassBorder,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(cat.emoji,
                                          style: const TextStyle(
                                              fontSize: 18)),
                                      const SizedBox(width: 6),
                                      Text(
                                        cat.label,
                                        style: GoogleFonts.poppins(
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? Colors.white
                                              : AppColors.textPrimary,
                                          fontSize: 14,
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24.0),
                          child: TextField(
                            controller: _notesCtrl,
                            decoration: InputDecoration(
                              hintText: 'Add a note...',
                              hintStyle: GoogleFonts.poppins(
                                  color: AppColors.textLight),
                              filled: true,
                              fillColor: Colors.white.withAlpha(127),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                    color: AppColors.glassBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                    color: AppColors.glassBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: _incomeGreen, width: 2),
                              ),
                            ),
                            style: GoogleFonts.poppins(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Teclado numérico ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: NumericKeyboard(
                    onKeyPress: _handleKeyPress,
                    onBackspace: _handleBackspace,
                  ),
                ),

                // ── Botón Save Income ─────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 16.0),
                  child: GestureDetector(
                    onTapDown: (_) =>
                        setState(() => _isSavePressed = true),
                    onTapUp: (_) {
                      setState(() => _isSavePressed = false);
                      if (!_isLoading) _saveIncome();
                    },
                    onTapCancel: () =>
                        setState(() => _isSavePressed = false),
                    child: AnimatedScale(
                      scale: _isSavePressed ? 0.95 : 1.0,
                      duration: const Duration(milliseconds: 100),
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _incomeGreen,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _incomeGreen.withAlpha(76),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(
                                'Save Income',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
    );
  }
}
