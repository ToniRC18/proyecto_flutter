import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../transactions/domain/transaction_model.dart';
import 'widgets/comments_section.dart';

/// Mapa de categorías a emoji — consistente con el resto de la app.
const _categoryEmoji = {
  '🍔 Food': '🍔',
  '🚗 Transport': '🚗',
  '🏠 Rent': '🏠',
  '🎮 Leisure': '🎮',
  '🛒 Grocery': '🛒',
  '💊 Health': '💊',
  'Other': '💸',
};

/// Pantalla de detalle de una transacción.
/// Muestra información completa del gasto + sección de comentarios en tiempo real.
class TransactionDetailScreen extends ConsumerWidget {
  final Transaction transaction;
  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amountFormatter =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final dateFormatter = DateFormat('EEEE, d MMMM yyyy');

    final emoji = _categoryEmoji.entries
            .firstWhere(
              (e) => transaction.category.contains(e.key.split(' ').last),
              orElse: () => const MapEntry('Other', '💸'),
            )
            .value;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(80),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: const Icon(Icons.close,
                          color: AppColors.textPrimary, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Detalle de gasto',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // ── Tarjeta principal de detalles ──────────────
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Monto grande
                        Text(
                          amountFormatter.format(transaction.amount),
                          style: GoogleFonts.poppins(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Categoría con emoji
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(emoji, style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 8),
                            Text(
                              transaction.category,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: Colors.white54),
                        const SizedBox(height: 16),

                        // Detalles en filas
                        _DetailRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Fecha',
                          value: dateFormatter.format(transaction.date),
                        ),
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'Tipo',
                          value: transaction.type == 'expense'
                              ? 'Gasto'
                              : 'Ingreso',
                          valueColor: transaction.type == 'expense'
                              ? Colors.red.shade600
                              : Colors.green.shade600,
                        ),
                        if (transaction.notes != null &&
                            transaction.notes!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _DetailRow(
                            icon: Icons.notes_outlined,
                            label: 'Notas',
                            value: transaction.notes!,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Sección de comentarios ─────────────────────
                  CommentsSection(transactionId: transaction.id),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: valueColor ?? AppColors.textPrimary,
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
