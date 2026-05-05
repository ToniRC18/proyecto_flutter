import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../core/domain/app_categories.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/animations/bruma_animations.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/bruma_offline_error.dart';
import '../../shared_spaces/data/shared_spaces_repository.dart';
import '../../transactions/domain/transaction_model.dart';
import '../split/data/split_repository.dart';
import '../split/domain/transaction_split_model.dart';
import '../split/providers/split_provider.dart';
import 'widgets/comments_section.dart';

/// Pantalla de detalle de una transacción.
/// Muestra información completa del gasto + sección de comentarios en tiempo real.
class TransactionDetailScreen extends ConsumerStatefulWidget {
  final Transaction? transaction;
  final String? transactionId;

  const TransactionDetailScreen({
    super.key,
    this.transaction,
    this.transactionId,
  }) : assert(
         transaction != null || transactionId != null,
         'Se requiere transaction o transactionId',
       );

  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends ConsumerState<TransactionDetailScreen> {
  Transaction? _transaction;
  Object? _loadError;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _transaction = widget.transaction;
    if (_transaction == null && widget.transactionId != null) {
      _loadTransactionById(widget.transactionId!);
    }
  }

  Future<void> _loadTransactionById(String id) async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final tx = await supabase
          .from('transactions')
          .select('*, accounts(name, type)')
          .eq('id', id)
          .single();

      if (!mounted) return;
      setState(() {
        _transaction = Transaction.fromJson(tx);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transaction = _transaction;
    if (_loading && transaction == null) {
      return Scaffold(
        backgroundColor: context.bruma.bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null && transaction == null) {
      return Scaffold(
        backgroundColor: context.bruma.bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No se pudo cargar la transacción: $_loadError',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (transaction == null) {
      return Scaffold(
        backgroundColor: context.bruma.bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return _TransactionDetailContent(transaction: transaction);
  }
}

class _TransactionDetailContent extends ConsumerWidget {
  final Transaction transaction;

  const _TransactionDetailContent({required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = context.bruma;
    final amountFormatter =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormatter = DateFormat('EEEE, d MMMM yyyy', 'es_MX');
    final emoji = AppCategories.emojiForId(transaction.category);
    final isExpense = transaction.type == 'expense';

    return Scaffold(
      backgroundColor: b.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Iconsax.arrow_left,
                        color: b.textPrimary, size: 22),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Detalle',
                    style: GoogleFonts.dmSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: b.textPrimary,
                      letterSpacing: -0.02 * 17,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // ── Tarjeta principal ──────────────────────────
                  FadeUpAnimation(
                    child: AppCard(
                      padding: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Monto grande
                          Text(
                            amountFormatter.format(transaction.amount),
                            style: GoogleFonts.dmSans(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: isExpense ? b.error : b.success,
                              letterSpacing: -0.03 * 32,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Categoría con emoji
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(emoji,
                                  style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 8),
                              Text(
                                AppCategories.labelForId(
                                    transaction.category),
                                style: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  color: b.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          if (transaction.isPendingSync) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: b.warning.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                '⏳ Pendiente de sync',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: b.warning,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Container(height: 1, color: b.border),
                          const SizedBox(height: 16),

                          // Detalles en filas
                          _DetailRow(
                            icon: Iconsax.calendar_1,
                            label: 'Fecha',
                            value: dateFormatter.format(transaction.date),
                          ),
                          const SizedBox(height: 14),
                          _DetailRow(
                            icon: Iconsax.wallet_2,
                            label: 'Tipo',
                            value: isExpense ? 'Gasto' : 'Ingreso',
                            valueColor: isExpense ? b.error : b.success,
                          ),
                          if (transaction.notes != null &&
                              transaction.notes!.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _DetailRow(
                              icon: Iconsax.note_1,
                              label: 'Notas',
                              value: transaction.notes!,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  FadeUpAnimation(
                    delayMs: 100,
                    child: _SplitSection(transaction: transaction),
                  ),
                  const SizedBox(height: 16),

                  // ── Sección de comentarios ─────────────────────
                  FadeUpAnimation(
                    delayMs: 200,
                    child: CommentsSection(transactionId: transaction.id),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplitSection extends ConsumerWidget {
  final Transaction transaction;

  const _SplitSection({required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = context.bruma;
    final AsyncValue<List<TransactionSplitModel>> splitsAsync =
        transaction.hasSplit
            ? ref.watch(splitsForTransactionProvider(transaction.id))
            : const AsyncData<List<TransactionSplitModel>>([]);

    return splitsAsync.when(
      loading: () {
        return AppCard(
          padding: 24,
          child: Center(
            child: CircularProgressIndicator(color: b.primary),
          ),
        );
      },
      error: (error, stack) => AppCard(
        padding: 20,
        child: buildAsyncError(
          error,
          stack,
          onRetry: () => ref.invalidate(splitsForTransactionProvider(transaction.id)),
          context: context,
        ),
      ),
      data: (splits) {
        if (splits.isEmpty) {
          if (!transaction.hasSplit) return const SizedBox.shrink();
          return AppCard(
            padding: 24,
            child: Column(
              children: [
                Icon(Iconsax.chart_square, size: 40, color: b.textTertiary),
                const SizedBox(height: 10),
                Text(
                  'No hay divisiones registradas para este gasto.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: b.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return AppCard(
          padding: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'División del gasto',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: b.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              ...splits.map(
                (split) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SplitRow(
                    userName: split.displayName,
                    amount: split.amount,
                    isSettled: split.isSettled,
                    onSettle: split.isSettled
                        ? null
                        : () async {
                            try {
                              await ref
                                  .read(splitRepositoryProvider)
                                  .settleSplit(split.id);
                              ref.invalidate(
                                  splitsForTransactionProvider(
                                      transaction.id));
                              ref.invalidate(sharedSpacesProvider);
                              ref.invalidate(
                                  balanceProvider(transaction.tenantId));
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SplitRow extends StatelessWidget {
  final String userName;
  final double amount;
  final bool isSettled;
  final Future<void> Function()? onSettle;

  const _SplitRow({
    required this.userName,
    required this.amount,
    required this.isSettled,
    required this.onSettle,
  });

  String _initials() {
    final parts = userName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty) return parts.first[0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: b.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: b.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: b.primarySubtle,
            child: Text(
              _initials(),
              style: GoogleFonts.dmSans(
                color: b.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: b.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${amount.toStringAsFixed(2)}',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: b.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isSettled)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: b.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                'Saldado',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: b.success,
                ),
              ),
            )
          else
            GestureDetector(
              onTap: onSettle == null ? null : () => onSettle!.call(),
              child: Text(
                'Marcar saldado',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: b.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Fila de detalle con ícono, etiqueta y valor.
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: b.textTertiary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: b.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: valueColor ?? b.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
