import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:uuid/uuid.dart';

import '../../../core/animations/bruma_animations.dart';
import '../../../core/providers/tenant_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/amount_input_field.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/balance_display.dart';
import '../../../core/widgets/bruma_offline_error.dart';
import '../../../core/widgets/bruma_empty_state.dart';
import '../../accounts/data/accounts_repository.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../../dashboard/domain/account_model.dart';
import '../../transactions/data/transaction_repository.dart';
import '../data/pockets_repository.dart';
import '../domain/pocket_model.dart';
import '../providers/pockets_provider.dart';

const List<String> _kPocketColorHexes = [
  '#0066FF',
  '#00A878',
  '#E8284B',
  '#F59E0B',
];

class PocketsScreen extends ConsumerWidget {
  const PocketsScreen({super.key});

  Future<void> _openCreatePocketSheet(
    BuildContext context,
    WidgetRef ref,
    String tenantId,
    int pocketCount,
  ) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreatePocketSheet(
        tenantId: tenantId,
        pocketCount: pocketCount,
      ),
    );

    if (created == true) {
      ref.invalidate(pocketsProvider(tenantId));
    }
  }

  Future<void> _openContributionSheet(
    BuildContext context,
    WidgetRef ref,
    String tenantId,
    PocketModel pocket,
  ) async {
    final contributed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PocketContributionSheet(
        tenantId: tenantId,
        pocket: pocket,
      ),
    );

    if (contributed == true) {
      ref.invalidate(pocketsProvider(tenantId));
      ref.invalidate(allAccountsProvider(tenantId));
      ref.invalidate(accountsProvider(tenantId));
      ref.invalidate(totalBalanceProvider(tenantId));
      ref.invalidate(availableBalanceProvider(tenantId));
      ref.invalidate(recentTransactionsProvider(tenantId));
      ref.invalidate(allTransactionsProvider(tenantId));
      ref.invalidate(weeklySpendProvider(tenantId));
      ref.invalidate(weeklySpendByDayProvider(tenantId));
    }
  }

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
          error: (error, stack) => buildAsyncError(
            error,
            stack,
            onRetry: () => ref.invalidate(tenantProvider),
            context: context,
          ),
          data: (tenantId) {
            final pocketsAsync = ref.watch(pocketsProvider(tenantId));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Iconsax.arrow_left,
                          color: b.textPrimary,
                          size: 22,
                        ),
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Pockets',
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: b.textPrimary,
                          letterSpacing: -0.02 * 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: pocketsAsync.when(
                    loading: () => Center(
                      child: CircularProgressIndicator(color: b.primary),
                    ),
                    error: (error, stack) => buildAsyncError(
                      error,
                      stack,
                      onRetry: () => ref.invalidate(pocketsProvider(tenantId)),
                      context: context,
                    ),
                    data: (pockets) {
                      if (pockets.isEmpty) {
                        return ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            const SizedBox(height: 60),
                            BrumaEmptyState(
                              type: BrumaEmptyType.pockets,
                              title: 'Aún no tienes metas',
                              subtitle: 'Crea tu primera meta de ahorro',
                              action: _AddPocketButton(
                                onTap: () => _openCreatePocketSheet(
                                  context,
                                  ref,
                                  tenantId,
                                  pockets.length,
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          ...pockets.asMap().entries.map((entry) {
                            final index = entry.key;
                            final pocket = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: FadeUpAnimation(
                                delayMs: index * 70,
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    _openContributionSheet(
                                      context,
                                      ref,
                                      tenantId,
                                      pocket,
                                    );
                                  },
                                  child: _PocketCard(pocket: pocket),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          _AddPocketButton(
                            onTap: () => _openCreatePocketSheet(
                              context,
                              ref,
                              tenantId,
                              pockets.length,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
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
}

class _PocketCard extends StatelessWidget {
  final PocketModel pocket;

  const _PocketCard({required this.pocket});

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final color = _colorFromHex(pocket.color, b.primary);

    return AppCard(
      padding: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(pocket.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  pocket.name,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: b.textPrimary,
                  ),
                ),
              ),
              Icon(
                pocket.isCompleted ? Iconsax.verify5 : Iconsax.safe_home,
                size: 18,
                color: b.textTertiary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pocket.progress),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (_, val, __) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: val,
                minHeight: 6,
                backgroundColor: b.surfaceAlt,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BalanceDisplay(
                value: pocket.savedAmount,
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w600,
                animate: true,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'meta ',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: b.textSecondary,
                    ),
                  ),
                  BalanceDisplay(
                    value: pocket.goalAmount,
                    fontSize: 12,
                    color: b.textSecondary,
                    animate: false,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PocketContributionSheet extends ConsumerStatefulWidget {
  final String tenantId;
  final PocketModel pocket;

  const _PocketContributionSheet({
    required this.tenantId,
    required this.pocket,
  });

  @override
  ConsumerState<_PocketContributionSheet> createState() =>
      _PocketContributionSheetState();
}

class _PocketContributionSheetState
    extends ConsumerState<_PocketContributionSheet> {
  final _amountCtrl = TextEditingController();
  Account? _selectedAccount;
  bool _loading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(List<Account> accounts) async {
    final b = context.bruma;
    final amount = AmountInputField.parseAmount(_amountCtrl.text);

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ingresa un monto mayor a cero.'),
          backgroundColor: b.error,
        ),
      );
      return;
    }

    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selecciona una cuenta para aportar.'),
          backgroundColor: b.error,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await ref.read(pocketsRepositoryProvider).contributeAmount(
            pocketId: widget.pocket.id,
            accountId: _selectedAccount!.id,
            amount: amount,
            tenantId: widget.tenantId,
          );

      if (!mounted) return;
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Aporte registrado correctamente.'),
          backgroundColor: b.success,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      final message = BrumaOfflineError.isOfflineError(error)
          ? 'Sin conexión. Intenta de nuevo cuando vuelvas a estar en línea.'
          : 'No se pudo crear la meta.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: b.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final accountsAsync = ref.watch(pocketAccountsProvider(widget.tenantId));

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: b.bg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: b.border),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: accountsAsync.when(
              loading: () => SizedBox(
                height: 260,
                child: Center(
                  child: CircularProgressIndicator(color: b.primary),
                ),
              ),
              error: (error, stack) => SizedBox(
                height: 260,
                child: buildAsyncError(
                  error,
                  stack,
                  onRetry: () => ref.invalidate(
                    pocketAccountsProvider(widget.tenantId),
                  ),
                  context: context,
                ),
              ),
              data: (accounts) {
                if (accounts.isNotEmpty) {
                  _selectedAccount ??= accounts.first;
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: b.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.pocket.name,
                            style: GoogleFonts.dmSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: b.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Iconsax.close_circle,
                            color: b.textPrimary,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        Text(
                          'Llevas',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: b.textSecondary,
                          ),
                        ),
                        BalanceDisplay(
                          value: widget.pocket.savedAmount,
                          fontSize: 13,
                          color: b.primary,
                        ),
                        Text(
                          'de',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: b.textSecondary,
                          ),
                        ),
                        BalanceDisplay(
                          value: widget.pocket.goalAmount,
                          fontSize: 13,
                          color: b.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    AmountInputField(
                      controller: _amountCtrl,
                      amountColor: b.primary,
                    ),
                    const SizedBox(height: 16),
                    if (accounts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'No tienes cuentas disponibles para aportar.',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: b.textTertiary,
                          ),
                        ),
                      )
                    else
                      _AccountDropdown(
                        accounts: accounts,
                        selected: _selectedAccount,
                        onChanged: (account) {
                          setState(() => _selectedAccount = account);
                        },
                      ),
                    const SizedBox(height: 20),
                    AppButton(
                      label: 'Aportar',
                      loading: _loading,
                      onPressed: _loading || accounts.isEmpty
                          ? null
                          : () => _submit(accounts),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CreatePocketSheet extends ConsumerStatefulWidget {
  final String tenantId;
  final int pocketCount;

  const _CreatePocketSheet({
    required this.tenantId,
    required this.pocketCount,
  });

  @override
  ConsumerState<_CreatePocketSheet> createState() => _CreatePocketSheetState();
}

class _CreatePocketSheetState extends ConsumerState<_CreatePocketSheet> {
  final _nameCtrl = TextEditingController();
  final _emojiCtrl = TextEditingController(text: '🎯');
  final _goalCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emojiCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  Future<void> _createPocket() async {
    final b = context.bruma;
    final name = _nameCtrl.text.trim();
    final emoji =
        _emojiCtrl.text.trim().isEmpty ? '🎯' : _emojiCtrl.text.trim();
    final goalAmount = AmountInputField.parseAmount(_goalCtrl.text);

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Escribe un nombre para la meta.'),
          backgroundColor: b.error,
        ),
      );
      return;
    }

    if (goalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ingresa una meta mayor a cero.'),
          backgroundColor: b.error,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final pocket = PocketModel(
        id: const Uuid().v4(),
        tenantId: widget.tenantId,
        name: name,
        emoji: emoji,
        goalAmount: goalAmount,
        savedAmount: 0,
        color:
            _kPocketColorHexes[widget.pocketCount % _kPocketColorHexes.length],
        storedIsCompleted: false,
        createdAt: DateTime.now(),
      );

      await ref.read(pocketsRepositoryProvider).createPocket(pocket);

      if (!mounted) return;
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Meta creada correctamente.'),
          backgroundColor: b.success,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      final message = BrumaOfflineError.isOfflineError(error)
          ? 'Sin conexión. Intenta aportar de nuevo cuando vuelvas a estar en línea.'
          : 'No se pudo registrar el aporte.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: b.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: b.bg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: b.border),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: b.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Nueva meta',
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: b.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Iconsax.close_circle,
                        color: b.textPrimary,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameCtrl,
                  style: GoogleFonts.dmSans(color: b.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    labelStyle: GoogleFonts.dmSans(color: b.textSecondary),
                    filled: true,
                    fillColor: b.surfaceAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emojiCtrl,
                  style: GoogleFonts.dmSans(color: b.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Emoji',
                    labelStyle: GoogleFonts.dmSans(color: b.textSecondary),
                    filled: true,
                    fillColor: b.surfaceAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AmountInputField(
                  controller: _goalCtrl,
                  autofocus: false,
                  amountColor: b.primary,
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Crear',
                  loading: _loading,
                  onPressed: _loading ? null : _createPocket,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountDropdown extends StatelessWidget {
  final List<Account> accounts;
  final Account? selected;
  final ValueChanged<Account?> onChanged;

  const _AccountDropdown({
    required this.accounts,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;

    return AppCard(
      padding: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cuenta origen',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: b.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: selected?.id,
            decoration: InputDecoration(
              filled: true,
              fillColor: b.surfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            dropdownColor: b.surface,
            items: accounts
                .map(
                  (account) => DropdownMenuItem<String>(
                    value: account.id,
                    child: Text(
                      '${account.name} · \$${account.balance.toStringAsFixed(0)}',
                      style: GoogleFonts.dmSans(color: b.textPrimary),
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              final account = accounts.cast<Account?>().firstWhere(
                    (item) => item?.id == value,
                    orElse: () => null,
                  );
              onChanged(account);
            },
          ),
        ],
      ),
    );
  }
}

class _AddPocketButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddPocketButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
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
              '+ Crear pocket',
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

    const dashWidth = 8.0;
    const dashSpace = 5.0;
    final metrics = path.computeMetrics().first;
    double distance = 0;

    while (distance < metrics.length) {
      final end = (distance + dashWidth).clamp(0.0, metrics.length);
      canvas.drawPath(metrics.extractPath(distance, end), paint);
      distance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Color _colorFromHex(String hex, Color fallback) {
  final normalized = hex.replaceFirst('#', '');
  if (normalized.length != 6) return fallback;

  final value = int.tryParse(normalized, radix: 16);
  if (value == null) return fallback;

  return Color(0xFF000000 | value);
}
