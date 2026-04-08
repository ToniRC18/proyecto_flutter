import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/tenant_provider.dart';
import '../../../core/widgets/glass_card.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../../dashboard/domain/account_model.dart';
import '../data/accounts_repository.dart';
import '../../../core/router/app_routes.dart';
import '../../transactions/domain/transaction_model.dart';

/// Pantalla de cuentas bancarias y efectivo del usuario.
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantAsync = ref.watch(tenantProvider);
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: tenantAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (tenantId) {
            final accountsAsync = ref.watch(allAccountsProvider(tenantId));
            final totalAsync = ref.watch(totalBalanceProvider(tenantId));
            final recentAsync = ref.watch(recentTransactionsProvider(tenantId));

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const SizedBox(height: 16),

                // ── Header ──────────────────────────────────────────
                Text(
                  'My Accounts',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                totalAsync.when(
                  data: (total) => Text(
                    'Total balance: ${formatter.format(total)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  loading: () => const SizedBox(height: 20),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),

                // ── Lista de cuentas ─────────────────────────────────
                accountsAsync.when(
                  loading: () => const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary)),
                  error: (err, _) => Text('Error: $err'),
                  data: (accounts) {
                    if (accounts.isEmpty) {
                      return _EmptyAccounts();
                    }
                    return Column(
                      children: accounts
                          .map((acc) => _AccountCard(
                                account: acc,
                                formatter: formatter,
                                onDeleted: () =>
                                    ref.invalidate(allAccountsProvider(tenantId)),
                                onRenamed: () =>
                                    ref.invalidate(allAccountsProvider(tenantId)),
                              ))
                          .toList(),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // ── Botón Add Account ────────────────────────────────
                _AddAccountButton(
                  onCreated: () {
                    ref.invalidate(allAccountsProvider(tenantId));
                    ref.invalidate(totalBalanceProvider(tenantId));
                  },
                  tenantId: tenantId,
                ),

                const SizedBox(height: 32),

                // ── Transacciones recientes ──────────────────────────
                Text(
                  'Recent Transactions',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                recentAsync.when(
                  loading: () => const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary)),
                  error: (err, _) => Text('Error: $err'),
                  data: (transactions) {
                    final limited = transactions.take(5).toList();
                    if (limited.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Sin transacciones aún',
                          style: GoogleFonts.poppins(
                              color: AppColors.textSecondary),
                        ),
                      );
                    }
                    return Column(
                      children: limited
                          .map((tx) => _RecentTransactionTile(
                                transaction: tx,
                                formatter: formatter,
                              ))
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 100),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Account Card ─────────────────────────────────────────────────────────────

class _AccountCard extends ConsumerWidget {
  final Account account;
  final NumberFormat formatter;
  final VoidCallback onDeleted;
  final VoidCallback onRenamed;

  const _AccountCard({
    required this.account,
    required this.formatter,
    required this.onDeleted,
    required this.onRenamed,
  });

  /// Devuelve emoji e icono según tipo de cuenta
  (String, Color) _typeInfo() {
    switch (account.type.toLowerCase()) {
      case 'bank':
        return ('🏦', const Color(0xFF1565C0));
      case 'credit_card':
        return ('💳', AppColors.primary);
      default:
        return ('💵', const Color(0xFF2E7D32));
    }
  }

  String _typeLabel() {
    switch (account.type.toLowerCase()) {
      case 'bank':
        return 'Bank Account';
      case 'credit_card':
        return 'Credit Card';
      default:
        return 'Cash';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (emoji, color) = _typeInfo();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onLongPress: () => _showOptions(context, ref),
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          borderRadius: 20,
          child: Row(
            children: [
              // Ícono tipo cuenta
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _typeLabel(),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatter.format(account.balance),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _AccountOptionsDialog(
        account: account,
        onDeleted: onDeleted,
        onRenamed: onRenamed,
      ),
    );
  }
}

// ─── Account Options Dialog ───────────────────────────────────────────────────

class _AccountOptionsDialog extends ConsumerStatefulWidget {
  final Account account;
  final VoidCallback onDeleted;
  final VoidCallback onRenamed;

  const _AccountOptionsDialog({
    required this.account,
    required this.onDeleted,
    required this.onRenamed,
  });

  @override
  ConsumerState<_AccountOptionsDialog> createState() =>
      _AccountOptionsDialogState();
}

class _AccountOptionsDialogState
    extends ConsumerState<_AccountOptionsDialog> {
  final _nameController = TextEditingController();
  bool _editing = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.account.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.account.name,
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      ),
      content: _editing
          ? TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nuevo nombre'),
              autofocus: true,
            )
          : null,
      actions: [
        if (!_editing) ...[
          TextButton(
            onPressed: () => setState(() => _editing = true),
            child: Text('Renombrar',
                style: GoogleFonts.poppins(color: AppColors.primary)),
          ),
          TextButton(
            onPressed: _loading ? null : _deleteAccount,
            child: Text('Eliminar',
                style: GoogleFonts.poppins(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
        ] else ...[
          TextButton(
            onPressed: () => setState(() => _editing = false),
            child: Text('Cancelar',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          FilledButton(
            onPressed: _loading ? null : _renameAccount,
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text('Guardar', style: GoogleFonts.poppins()),
          ),
        ],
      ],
    );
  }

  Future<void> _deleteAccount() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(accountsRepositoryProvider)
          .deleteAccount(widget.account.id);
      if (mounted) Navigator.pop(context);
      widget.onDeleted();
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

  Future<void> _renameAccount() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(accountsRepositoryProvider)
          .renameAccount(widget.account.id, name);
      if (mounted) Navigator.pop(context);
      widget.onRenamed();
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

// ─── Add Account Button ────────────────────────────────────────────────────────

class _AddAccountButton extends ConsumerWidget {
  final VoidCallback onCreated;
  final String tenantId;

  const _AddAccountButton(
      {required this.onCreated, required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => _AddAccountDialog(
            tenantId: tenantId,
            onCreated: onCreated,
          ),
        );
      },
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary,
            width: 1.5,
            // Dashed border via CustomPaint no está disponible directamente,
            // usamos un borde sólido con opacidad
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Add Account',
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add Account Dialog ────────────────────────────────────────────────────────

class _AddAccountDialog extends ConsumerStatefulWidget {
  final String tenantId;
  final VoidCallback onCreated;

  const _AddAccountDialog(
      {required this.tenantId, required this.onCreated});

  @override
  ConsumerState<_AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends ConsumerState<_AddAccountDialog> {
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  String _selectedType = 'cash';
  bool _loading = false;

  static const _types = [
    ('cash', '💵', 'Cash'),
    ('bank', '🏦', 'Bank'),
    ('credit_card', '💳', 'Credit Card'),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nueva Cuenta',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Nombre de la cuenta',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _balanceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Balance inicial (opcional)',
                prefixText: '\$ ',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Tipo de cuenta',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _types.map((t) {
                final (value, emoji, label) = t;
                final selected = _selectedType == value;
                return ChoiceChip(
                  label:
                      Text('$emoji $label', style: GoogleFonts.poppins()),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedType = value),
                  selectedColor: AppColors.primary,
                  labelStyle: GoogleFonts.poppins(
                    color: selected ? Colors.white : AppColors.textPrimary,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar',
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary)),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _loading ? null : _create,
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text('Crear', style: GoogleFonts.poppins()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final balance = double.tryParse(_balanceCtrl.text) ?? 0;

    setState(() => _loading = true);
    try {
      await ref.read(accountsRepositoryProvider).createAccount(
            tenantId: widget.tenantId,
            name: name,
            type: _selectedType,
            initialBalance: balance,
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

// ─── Recent Transaction Tile ──────────────────────────────────────────────────

class _RecentTransactionTile extends StatelessWidget {
  final Transaction transaction;
  final NumberFormat formatter;

  const _RecentTransactionTile(
      {required this.transaction, required this.formatter});

  static const _catEmoji = {
    'comida': '🍔',
    'transporte': '🚗',
    'renta': '🏠',
    'ocio': '🎮',
    'super': '🛒',
    'salud': '💊',
    'salary': '💼',
    'freelance': '💻',
    'gift': '🎁',
    'investment': '📈',
    'bonus': '💰',
  };

  @override
  Widget build(BuildContext context) {
    final emoji = _catEmoji[transaction.category.toLowerCase()] ?? '💸';
    final isIncome = transaction.type == 'income';
    final color =
        isIncome ? const Color(0xFF2E7D32) : const Color(0xFFEF4444);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.transactionDetail, extra: transaction),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius: 16,
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.notes ?? transaction.category,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      DateFormat('dd MMM').format(transaction.date),
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Text(
                '${isIncome ? '+' : '-'}${formatter.format(transaction.amount)}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyAccounts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Text('🏦', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'No tienes cuentas aún',
            style: GoogleFonts.poppins(
                fontSize: 15, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
