import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/providers/tenant_provider.dart';
import '../../../core/animations/bruma_animations.dart';
import '../../../core/widgets/amount_input_field.dart';
import '../../../core/widgets/balance_display.dart';
import '../../../core/widgets/account_card.dart';
import '../../../core/widgets/app_card.dart';
import '../../dashboard/domain/account_model.dart';
import '../data/accounts_repository.dart';
import '../data/credit_card_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// AccountsScreen — Basado EXACTAMENTE en AccountsScreen de Bruma.html
// Balance centrado, distribución, lista AccountCard full, botón dashed agregar
// ═══════════════════════════════════════════════════════════════════════════════

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = context.bruma;
    final tenantAsync = ref.watch(tenantProvider);

    return Scaffold(
      backgroundColor: b.bg,
      body: SafeArea(
        child: tenantAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: b.primary),
          ),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (tenantId) {
            final accountsAsync = ref.watch(allAccountsProvider(tenantId));
            final totalAsync = ref.watch(totalBalanceProvider(tenantId));

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                const SizedBox(height: 20),

                // ── Balance total centrado ──────────────────────────
                FadeUpAnimation(
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          'PATRIMONIO TOTAL',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: b.textSecondary,
                            letterSpacing: 0.06 * 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        totalAsync.when(
                          data: (total) =>
                              BalanceDisplay(value: total, fontSize: 36),
                          loading: () => SizedBox(
                            height: 44,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: b.primary,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          error: (_, __) =>
                              const BalanceDisplay(value: 0, fontSize: 36),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Distribución ──────────────────────────────────
                FadeUpAnimation(
                  delayMs: 100,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: accountsAsync.when(
                      data: (accounts) => _DistributionCard(accounts: accounts),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Título "Mis cuentas" ──────────────────────────
                FadeUpAnimation(
                  delayMs: 150,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Mis cuentas',
                      style: GoogleFonts.dmSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: b.textPrimary,
                        letterSpacing: -0.02 * 17,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Lista de cuentas ────────────────────────────────
                FadeUpAnimation(
                  delayMs: 200,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: accountsAsync.when(
                      loading: () => Center(
                        child: CircularProgressIndicator(color: b.primary),
                      ),
                      error: (err, _) => Text('Error: $err'),
                      data: (accounts) {
                        if (accounts.isEmpty) {
                          return _EmptyAccounts();
                        }
                        return Column(
                          children: [
                            ...accounts.map((acc) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _TappableAccountCard(
                                    account: acc,
                                    onDeleted: () => ref.invalidate(
                                        allAccountsProvider(tenantId)),
                                    onRenamed: () => ref.invalidate(
                                        allAccountsProvider(tenantId)),
                                  ),
                                )),

                            // ── Botón dashed "Agregar cuenta" ────────
                            const SizedBox(height: 4),
                            _AddAccountButton(
                              onCreated: () {
                                ref.invalidate(allAccountsProvider(tenantId));
                                ref.invalidate(totalBalanceProvider(tenantId));
                              },
                              tenantId: tenantId,
                            ),

                            // ── Botón transferir ────────────────────
                            const SizedBox(height: 12),
                            _TransferButton(),
                          ],
                        );
                      },
                    ),
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

// ── Distribución ────────────────────────────────────────────────────────────

class _DistributionCard extends StatelessWidget {
  final List<Account> accounts;
  const _DistributionCard({required this.accounts});

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final positiveAccounts = accounts.where((a) => a.balance > 0).toList();
    final totalPositive =
        positiveAccounts.fold<double>(0, (s, a) => s + a.balance);

    if (positiveAccounts.isEmpty) return const SizedBox.shrink();

    return AppCard(
      padding: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribución',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: b.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          // Barra de colores
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 6,
              child: Row(
                children: positiveAccounts.map((acc) {
                  final pct = acc.balance / totalPositive;
                  final color = kAccountTypeColors[acc.type] ?? b.primary;
                  return Expanded(
                    flex: (pct * 1000).toInt().clamp(1, 1000),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Leyenda
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: positiveAccounts.map((acc) {
              final color = kAccountTypeColors[acc.type] ?? b.primary;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    acc.name,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: b.textSecondary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── AccountCard con opciones (long press) ──────────────────────────────────

class _TappableAccountCard extends ConsumerWidget {
  final Account account;
  final VoidCallback onDeleted;
  final VoidCallback onRenamed;

  const _TappableAccountCard({
    required this.account,
    required this.onDeleted,
    required this.onRenamed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _openAccountDetail(context, account),
      onLongPress: () => _showOptions(context, ref),
      child: AccountCard(
        name: account.name,
        type: account.type,
        balance: account.balance,
        compact: false,
      ),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AccountOptionsDialog(
        account: account,
        onDeleted: onDeleted,
        onRenamed: onRenamed,
      ),
    );
  }
}

void _openAccountDetail(BuildContext context, Account account) {
  context.push(
    account.isCreditCard
        ? AppRoutes.creditCardDetail
        : AppRoutes.accountDetail,
    extra: account,
  );
}

// ── Account Options Dialog ──────────────────────────────────────────────────

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

class _AccountOptionsDialogState extends ConsumerState<_AccountOptionsDialog> {
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
    final b = context.bruma;
    return AlertDialog(
      backgroundColor: b.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.account.name,
        style: GoogleFonts.dmSans(
          fontWeight: FontWeight.w700,
          color: b.textPrimary,
        ),
      ),
      content: _editing
          ? TextField(
              controller: _nameController,
              style: GoogleFonts.dmSans(color: b.textPrimary),
              decoration: InputDecoration(
                labelText: 'Nuevo nombre',
                labelStyle: GoogleFonts.dmSans(color: b.textSecondary),
              ),
              autofocus: true,
            )
          : null,
      actions: [
        if (!_editing) ...[
          TextButton(
            onPressed: () => setState(() => _editing = true),
            child:
                Text('Renombrar', style: GoogleFonts.dmSans(color: b.primary)),
          ),
          TextButton(
            onPressed: _loading ? null : _deleteAccount,
            child: Text('Eliminar', style: GoogleFonts.dmSans(color: b.error)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar',
                style: GoogleFonts.dmSans(color: b.textSecondary)),
          ),
        ] else ...[
          TextButton(
            onPressed: () => setState(() => _editing = false),
            child: Text('Cancelar',
                style: GoogleFonts.dmSans(color: b.textSecondary)),
          ),
          FilledButton(
            onPressed: _loading ? null : _renameAccount,
            style: FilledButton.styleFrom(backgroundColor: b.primary),
            child: Text('Guardar', style: GoogleFonts.dmSans()),
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
          SnackBar(
            backgroundColor: context.bruma.error,
            content: Text('Error: $e'),
          ),
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
          SnackBar(
            backgroundColor: context.bruma.error,
            content: Text('Error: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ── Botón dashed "Agregar cuenta" ────────────────────────────────────────────

class _AddAccountButton extends ConsumerWidget {
  final VoidCallback onCreated;
  final String tenantId;

  const _AddAccountButton({
    required this.onCreated,
    required this.tenantId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = context.bruma;

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => _AddAccountDialog(
            tenantId: tenantId,
            onCreated: onCreated,
          ),
        );
      },
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: b.border,
          borderRadius: 20,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              '+ Agregar cuenta',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: b.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Dashed border painter ──────────────────────────────────────────────────

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;

  _DashedBorderPainter({required this.color, required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(borderRadius),
      ));

    // Dibujar dashes
    const dashWidth = 8.0;
    const dashSpace = 5.0;
    final metrics = path.computeMetrics().first;
    double distance = 0;

    while (distance < metrics.length) {
      final end = (distance + dashWidth).clamp(0.0, metrics.length);
      canvas.drawPath(
        metrics.extractPath(distance, end),
        paint,
      );
      distance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Botón de transferir ──────────────────────────────────────────────────────

class _TransferButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    return GestureDetector(
      onTap: () => context.push(AppRoutes.addTransfer),
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: b.primarySubtle,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swap_horiz_rounded, color: b.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Transferir entre cuentas',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: b.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add Account Dialog ──────────────────────────────────────────────────────

class _AddAccountDialog extends ConsumerStatefulWidget {
  final String tenantId;
  final VoidCallback onCreated;

  const _AddAccountDialog({
    required this.tenantId,
    required this.onCreated,
  });

  @override
  ConsumerState<_AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends ConsumerState<_AddAccountDialog> {
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  final _creditLimitCtrl = TextEditingController();
  final _billingCloseDayCtrl = TextEditingController();
  final _paymentDueDayCtrl = TextEditingController();
  String _selectedType = 'cash';
  bool _loading = false;

  static const _types = [
    ('cash', 'Efectivo'),
    ('bank', 'Banco'),
    ('credit_card', 'Crédito'),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    _creditLimitCtrl.dispose();
    _billingCloseDayCtrl.dispose();
    _paymentDueDayCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final maxDialogHeight = MediaQuery.of(context).size.height * 0.85;

    return Dialog(
      backgroundColor: b.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxDialogHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nueva Cuenta',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: b.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                style: GoogleFonts.dmSans(color: b.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Nombre de la cuenta',
                  labelStyle: GoogleFonts.dmSans(color: b.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_selectedType != 'credit_card') ...[
                AmountInputField(
                  controller: _balanceCtrl,
                  autofocus: false,
                ),
                const SizedBox(height: 16),
              ],
              Text(
                'Tipo de cuenta',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: b.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _types.map((t) {
                  final (value, label) = t;
                  final selected = _selectedType == value;
                  final typeColor = kAccountTypeColors[value] ?? b.primary;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? typeColor.withValues(alpha: 0.12)
                            : b.surfaceAlt,
                        border: Border.all(
                          color: selected
                              ? typeColor.withValues(alpha: 0.25)
                              : b.border,
                        ),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        label,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? typeColor : b.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                child: _selectedType == 'credit_card'
                    ? Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Column(
                          children: [
                            AmountInputField(
                              controller: _creditLimitCtrl,
                              autofocus: false,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _billingCloseDayCtrl,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.dmSans(color: b.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Día de corte',
                                labelStyle:
                                    GoogleFonts.dmSans(color: b.textSecondary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _paymentDueDayCtrl,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.dmSans(color: b.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Día límite de pago',
                                labelStyle:
                                    GoogleFonts.dmSans(color: b.textSecondary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.dmSans(color: b.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _loading ? null : _create,
                    style: FilledButton.styleFrom(
                      backgroundColor: b.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: b.onPrimary,
                              strokeWidth: 2,
                            ),
                          )
                        : Text('Crear', style: GoogleFonts.dmSans()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _create() async {
    final b = context.bruma;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final isCreditCard = _selectedType == 'credit_card';
    final balance =
        isCreditCard ? 0.0 : AmountInputField.parseAmount(_balanceCtrl.text);

    final creditLimit = isCreditCard
        ? AmountInputField.parseAmount(_creditLimitCtrl.text)
        : null;
    final billingCloseDay = _parseDay(_billingCloseDayCtrl.text);
    final paymentDueDay = _parseDay(_paymentDueDayCtrl.text);

    if (isCreditCard && creditLimit != null && creditLimit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: b.error,
          content: const Text('Ingresa un límite de crédito mayor a cero.'),
        ),
      );
      return;
    }

    if (isCreditCard &&
        !_isValidCreditCardDay(
          billingCloseDay,
          _billingCloseDayCtrl.text,
        )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: b.error,
          content: const Text('Ingresa un día de corte válido entre 1 y 31.'),
        ),
      );
      return;
    }

    if (isCreditCard &&
        !_isValidCreditCardDay(
          paymentDueDay,
          _paymentDueDayCtrl.text,
        )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: b.error,
          content:
              const Text('Ingresa un día límite de pago válido entre 1 y 31.'),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final newAccountId =
          await ref.read(accountsRepositoryProvider).createAccount(
                tenantId: widget.tenantId,
                name: name,
                type: _selectedType,
                initialBalance: balance,
              );

      if (isCreditCard) {
        await ref.read(creditCardRepositoryProvider).updateCreditCardDetails(
              accountId: newAccountId,
              creditLimit:
                  creditLimit == null || creditLimit <= 0 ? null : creditLimit,
              billingCloseDay: billingCloseDay,
              paymentDueDay: paymentDueDay,
            );
      }

      if (mounted) Navigator.pop(context);
      widget.onCreated();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: b.error,
            content: Text('Error: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int? _parseDay(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }

  bool _isValidCreditCardDay(int? value, String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) return true;
    return value != null && value >= 1 && value <= 31;
  }
}

// ── Empty State ──────────────────────────────────────────────────────────────

class _EmptyAccounts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              color: b.textTertiary, size: 48),
          const SizedBox(height: 12),
          Text(
            'No tienes cuentas aún',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              color: b.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
