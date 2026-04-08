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
import 'widgets/category_selector.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final CategoryItem? initialCategory;

  const AddExpenseScreen({super.key, this.initialCategory});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  String _amount = '0';
  late CategoryItem _selectedCategory;
  Account? _selectedAccount;
  bool _isSavePressed = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? kCategories.first;
  }

  void _handleKeyPress(String key) {
    setState(() {
      if (_amount == '0' && key != '.') {
        _amount = key;
      } else if (key == '.' && _amount.contains('.')) {
        return;
      } else {
        if (_amount.length < 9) {
          _amount += key;
        }
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

  Future<void> _saveExpense() async {
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
      await ref.read(transactionRepositoryProvider).saveExpense(
        tenantId: tenantId,
        accountId: _selectedAccount!.id,
        amount: amountValue,
        category: _selectedCategory.label,
      );
      
      // Invalidar providers del dashboard para refrescar datos
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
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, __) => Center(child: Text('Error: $err')),
          data: (tenantId) {
            final accountsAsync = ref.watch(accountsProvider(tenantId));
            
            return Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textPrimary),
                        onPressed: () => context.pop(),
                      ),
                      Text(
                        'Nuevo Gasto',
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        // Amount Display
                        Text(
                          '\$$_amount',
                          style: GoogleFonts.poppins(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Selector de cuenta (Chips horizontales)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                                  if (accounts.isEmpty) return const Center(child: Text('No hay cuentas'));
                                  if (_selectedAccount == null && accounts.isNotEmpty) {
                                    _selectedAccount = accounts.first;
                                  }
                                  return ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    itemCount: accounts.length,
                                    itemBuilder: (context, index) {
                                      final acc = accounts[index];
                                      final isSelected = _selectedAccount?.id == acc.id;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                        child: ChoiceChip(
                                          label: Text(acc.name),
                                          selected: isSelected,
                                          onSelected: (val) {
                                            if (val) setState(() => _selectedAccount = acc);
                                          },
                                          selectedColor: AppColors.primary,
                                          labelStyle: GoogleFonts.poppins(
                                            color: isSelected ? Colors.white : AppColors.textPrimary,
                                            fontSize: 13,
                                          ),
                                          backgroundColor: Colors.white.withAlpha(127),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                            side: BorderSide.none,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (_, __) => const Center(child: Text('Error al cargar cuentas')),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),
                        
                        // Horizontal Category Selector
                        CategorySelector(
                          selected: _selectedCategory,
                          onSelected: (cat) {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Keyboard
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: NumericKeyboard(
                    onKeyPress: _handleKeyPress,
                    onBackspace: _handleBackspace,
                  ),
                ),

                // Save Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: GestureDetector(
                    onTapDown: (_) => setState(() => _isSavePressed = true),
                    onTapUp: (_) {
                      setState(() => _isSavePressed = false);
                      if (!_isLoading) _saveExpense();
                    },
                    onTapCancel: () => setState(() => _isSavePressed = false),
                    child: AnimatedScale(
                      scale: _isSavePressed ? 0.95 : 1.0,
                      duration: const Duration(milliseconds: 100),
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(76),
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
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'Guardar Gasto',
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
