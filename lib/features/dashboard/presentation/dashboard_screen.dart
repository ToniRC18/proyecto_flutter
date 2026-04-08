import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/providers/tenant_provider.dart';
import '../../../core/widgets/glass_card.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../transactions/data/comments_repository.dart';
import '../data/dashboard_repository.dart';
import 'widgets/available_now_card.dart';
import 'widgets/shared_pockets.dart';
import 'widgets/weekly_spend_bar.dart';
import 'widgets/upcoming_bills.dart';

/// Mapa de categorías → emoji
const _catEmoji = {
  'comida': '🍔',
  'food': '🍔',
  'transporte': '🚗',
  'transport': '🚗',
  'renta': '🏠',
  'rent': '🏠',
  'ocio': '🎮',
  'leisure': '🎮',
  'super': '🛒',
  'grocery': '🛒',
  'salud': '💊',
  'health': '💊',
  'salary': '💼',
  'freelance': '💻',
  'gift': '🎁',
  'investment': '📈',
  'bonus': '💰',
};

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // StatusBar dark sobre fondo claro
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMM d').format(now);
    final tenantAsync = ref.watch(tenantProvider);
    final userNameAsync = ref.watch(userNameProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: tenantAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (tenantId) => ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              const SizedBox(height: 16),

              // ── Header: Saludo + fecha + botón grupos ─────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        userNameAsync.when(
                          data: (name) => Text(
                            'Hey, $name 👋',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          loading: () => const SizedBox(height: 36),
                          error: (_, __) => Text(
                            'Hey 👋',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          dateStr,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    // Botón de espacios compartidos (se conserva)
                    IconButton(
                      icon: const Icon(Iconsax.people,
                          color: AppColors.primary),
                      tooltip: 'Espacios compartidos',
                      onPressed: () =>
                          context.push(AppRoutes.sharedSpaces),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Balance disponible ────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: AvailableNowCard(tenantId: tenantId),
              ),
              const SizedBox(height: 32),

              // ── Pockets / Budgets ─────────────────────────────────
              SharedPockets(tenantId: tenantId),
              const SizedBox(height: 32),

              // ── Gasto semanal ─────────────────────────────────────
              WeeklySpendBar(tenantId: tenantId),
              const SizedBox(height: 32),

              // ── Transacciones recientes (tappables) ──────────────
              _RecentTransactions(tenantId: tenantId),
              const SizedBox(height: 32),

              // ── Próximos cobros ───────────────────────────────────
              const UpcomingBills(),
              const SizedBox(height: 120), // Espacio para navbar
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sección de transacciones recientes ──────────────────────────────────────

class _RecentTransactions extends ConsumerWidget {
  final String tenantId;
  const _RecentTransactions({required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync =
        ref.watch(recentTransactionsProvider(tenantId));
    final formatter =
        NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Recientes',
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        transactionsAsync.when(
          loading: () => const Center(
              child:
                  CircularProgressIndicator(color: AppColors.primary)),
          error: (err, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Error: $err',
                style: GoogleFonts.poppins(
                    color: AppColors.textSecondary)),
          ),
          data: (transactions) {
            if (transactions.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Sin transacciones aún',
                  style: GoogleFonts.poppins(
                      color: AppColors.textSecondary),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: transactions.length,
              itemBuilder: (ctx, i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TransactionTile(
                  transaction: transactions[i],
                  formatter: formatter,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Tile de transacción con badge de comentarios
class _TransactionTile extends ConsumerWidget {
  final Transaction transaction;
  final NumberFormat formatter;
  const _TransactionTile(
      {required this.transaction, required this.formatter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentCountAsync =
        ref.watch(commentCountProvider(transaction.id));
    final emoji = _catEmoji[transaction.category.toLowerCase()] ?? '💸';
    final isIncome = transaction.type == 'income';

    return GestureDetector(
      onTap: () => context.push(
        AppRoutes.transactionDetail,
        extra: transaction,
      ),
      child: GlassCard(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: 18,
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.category,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    DateFormat('dd MMM').format(transaction.date),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'}${formatter.format(transaction.amount)}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isIncome
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 8),
            // Badge de comentarios
            commentCountAsync.when(
              data: (count) => count > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chat_bubble_rounded,
                              color: Colors.white, size: 10),
                          const SizedBox(width: 2),
                          Text(
                            '$count',
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  : const Icon(Icons.chat_bubble_outline_rounded,
                      color: AppColors.textLight, size: 16),
              loading: () => const SizedBox(width: 16),
              error: (_, __) => const SizedBox(width: 16),
            ),
          ],
        ),
      ),
    );
  }
}
