import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/domain/app_categories.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../features/accounts/data/accounts_repository.dart';
import '../../../features/dashboard/data/dashboard_repository.dart';
import '../../../features/transactions/data/transaction_repository.dart';
import '../data/bills_repository.dart';
import '../domain/bill_model.dart';
import '../providers/bills_provider.dart';

class BillCard extends ConsumerStatefulWidget {
  final BillModel bill;

  const BillCard({super.key, required this.bill});

  @override
  ConsumerState<BillCard> createState() => _BillCardState();
}

class _BillCardState extends ConsumerState<BillCard> {
  bool _isLoading = false;

  Future<void> _markAsPaid() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(billsRepositoryProvider).payBill(bill: widget.bill);

      ref.invalidate(billsProvider);
      ref.invalidate(accountsProvider(widget.bill.tenantId));
      ref.invalidate(allAccountsProvider(widget.bill.tenantId));
      ref.invalidate(totalBalanceProvider(widget.bill.tenantId));
      ref.invalidate(availableBalanceProvider(widget.bill.tenantId));
      ref.invalidate(recentTransactionsProvider(widget.bill.tenantId));
      ref.invalidate(weeklySpendProvider(widget.bill.tenantId));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pago registrado correctamente.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
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
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final bill = widget.bill;

    return AppCard(
      padding: 18,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: b.primarySubtle,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(bill.emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.name,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: b.textPrimary,
                      ),
                    ),
                    Text(
                      AppCategories.labelForId(bill.category),
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: b.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatter.format(bill.amount),
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: b.textPrimary,
                  letterSpacing: -0.02 * 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatusChip(bill: bill),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bill.recurrenceLabel,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: b.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          if (bill.notes != null && bill.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                bill.notes!,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: b.textSecondary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _isLoading ? null : _markAsPaid,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: b.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Marcar pagado',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: b.onPrimary,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final BillModel bill;

  const _StatusChip({required this.bill});

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    late final Color background;
    late final Color foreground;
    late final String label;

    if (bill.isOverdue) {
      background = b.error.withValues(alpha: 0.1);
      foreground = b.error;
      label = '🔴 Vencido';
    } else if (bill.isUpcoming) {
      background = b.warning.withValues(alpha: 0.1);
      foreground = b.warning;
      label = '🟡 Vence en ${bill.daysUntilDue} días';
    } else {
      background = b.surfaceAlt;
      foreground = b.textSecondary;
      label = '⚪ ${bill.recurrenceLabel}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}
