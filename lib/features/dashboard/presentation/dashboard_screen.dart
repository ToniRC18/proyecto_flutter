import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/domain/app_categories.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/providers/tenant_provider.dart';
import '../../../core/animations/bruma_animations.dart';
import '../../../core/widgets/balance_display.dart';
import '../../../core/widgets/account_card.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/spending_trends_card.dart';
import '../../../core/widgets/weekly_chart.dart';
import '../../../core/widgets/transaction_list_item.dart';
import '../../budget/data/budget_repository.dart';
import '../data/dashboard_repository.dart';
import '../domain/account_model.dart';
import '../../accounts/data/accounts_repository.dart';
import '../../accounts/data/credit_card_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DashboardScreen — Basado EXACTAMENTE en HomeScreen de Bruma.html
// Header saludo + campana, Balance total con BalanceDisplay,
// Cuentas horizontal, WeeklyChart en AppCard, Recientes con stagger
// ═══════════════════════════════════════════════════════════════════════════════

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = context.bruma;
    final tenantAsync = ref.watch(tenantProvider);
    final userNameAsync = ref.watch(userNameProvider);

    return Scaffold(
      backgroundColor: b.bg,
      body: SafeArea(
        child: tenantAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: b.primary),
          ),
          error: (err, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.warning_2, color: b.textTertiary, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Error: $err',
                  style: GoogleFonts.dmSans(color: b.textTertiary),
                ),
              ],
            ),
          ),
          data: (tenantId) => ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              const SizedBox(height: 20),

              // ── Header: Saludo + campana ──────────────────────────
              FadeUpAnimation(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hola,',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: b.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          userNameAsync.when(
                            data: (name) => Text(
                              '$name 👋',
                              style: GoogleFonts.dmSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: b.textPrimary,
                                letterSpacing: -0.03 * 22,
                              ),
                            ),
                            loading: () => const SizedBox(height: 30),
                            error: (_, __) => Text(
                              'Hey 👋',
                              style: GoogleFonts.dmSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: b.textPrimary,
                                letterSpacing: -0.03 * 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.sharedSpaces),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: b.primarySubtle,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Iconsax.notification,
                            color: b.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Balance total ────────────────────────────────────
              FadeUpAnimation(
                delayMs: 100,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _BalanceSection(tenantId: tenantId),
                ),
              ),
              const SizedBox(height: 28),

              // ── Mis cuentas (scroll horizontal) ──────────────────
              FadeUpAnimation(
                delayMs: 200,
                child: _AccountsSection(tenantId: tenantId),
              ),
              const SizedBox(height: 28),

              FadeUpAnimation(
                delayMs: 250,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _CreditCardSummarySection(tenantId: tenantId),
                ),
              ),
              const SizedBox(height: 28),

              // ── Gastos esta semana (WeeklyChart en AppCard) ──────
              FadeUpAnimation(
                delayMs: 300,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _WeeklySection(tenantId: tenantId),
                ),
              ),
              const SizedBox(height: 28),

              FadeUpAnimation(
                delayMs: 350,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _TrendsSection(tenantId: tenantId),
                ),
              ),
              const SizedBox(height: 28),

              // ── Recientes ────────────────────────────────────────
              FadeUpAnimation(
                delayMs: 400,
                child: _RecentSection(tenantId: tenantId),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Balance total con BalanceDisplay ─────────────────────────────────────────

class _BalanceSection extends ConsumerWidget {
  final String tenantId;
  const _BalanceSection({required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = context.bruma;
    final balanceAsync = ref.watch(availableBalanceProvider(tenantId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BALANCE TOTAL',
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: b.textSecondary,
            letterSpacing: 0.06 * 12,
          ),
        ),
        const SizedBox(height: 8),
        balanceAsync.when(
          loading: () => SizedBox(
            height: 48,
            child: Center(
              child: CircularProgressIndicator(
                color: b.primary,
                strokeWidth: 2.5,
              ),
            ),
          ),
          error: (_, __) => const BalanceDisplay(value: 0),
          data: (balance) => BalanceDisplay(value: balance),
        ),
      ],
    );
  }
}

// ── Mis cuentas (scroll horizontal con AccountCard compact) ─────────────────

class _AccountsSection extends ConsumerWidget {
  final String tenantId;
  const _AccountsSection({required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = context.bruma;
    final accountsAsync = ref.watch(allAccountsProvider(tenantId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de sección
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mis cuentas',
                style: GoogleFonts.dmSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: b.textPrimary,
                  letterSpacing: -0.02 * 17,
                ),
              ),
              GestureDetector(
                onTap: () => context.go(AppRoutes.accounts),
                child: Text(
                  'Ver todas',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: b.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: accountsAsync.when(
            loading: () => Center(
              child: CircularProgressIndicator(color: b.primary),
            ),
            error: (_, __) => Center(
              child: Text(
                'Error al cargar cuentas',
                style: GoogleFonts.dmSans(color: b.textTertiary),
              ),
            ),
            data: (accounts) {
              if (accounts.isEmpty) {
                return Center(
                  child: Text(
                    'Sin cuentas aún',
                    style: GoogleFonts.dmSans(color: b.textTertiary),
                  ),
                );
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: accounts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final acc = accounts[index];
                  return AccountCard(
                    name: acc.name,
                    type: acc.type,
                    balance: acc.balance,
                    compact: true,
                    onTap: () => _openDashboardAccountDetail(context, acc),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

void _openDashboardAccountDetail(BuildContext context, Account account) {
  context.push(
    account.isCreditCard ? AppRoutes.creditCardDetail : AppRoutes.accountDetail,
    extra: account,
  );
}

// ── Gastos esta semana (WeeklyChart dentro de AppCard) ────────────────────────

class _WeeklySection extends ConsumerWidget {
  final String tenantId;
  const _WeeklySection({required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = context.bruma;
    final weeklyAsync = ref.watch(weeklySpendProvider(tenantId));
    final weeklyByDayAsync = ref.watch(weeklySpendByDayProvider(tenantId));

    return AppCard(
      padding: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gastos esta semana',
                    style: GoogleFonts.dmSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: b.textPrimary,
                      letterSpacing: -0.02 * 17,
                    ),
                  ),
                  const SizedBox(height: 2),
                  weeklyAsync.when(
                    data: (data) => Text(
                      '\$${data['spent']?.toStringAsFixed(0) ?? '0'} en 7 días',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: b.textSecondary,
                      ),
                    ),
                    loading: () => const SizedBox(height: 16),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          weeklyByDayAsync.when(
            loading: () => const WeeklyChart(data: [0, 0, 0, 0, 0, 0, 0]),
            error: (_, __) => const WeeklyChart(data: [0, 0, 0, 0, 0, 0, 0]),
            data: (data) => WeeklyChart(
              data: data,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendsSection extends ConsumerWidget {
  final String tenantId;

  const _TrendsSection({required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final range = BudgetStatsRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 1),
    );
    final trendsAsync = ref.watch(
      statsTrendsProvider((tenantId: tenantId, range: range)),
    );

    return SpendingTrendsCard(
      trendsAsync: trendsAsync,
      title: 'Tendencias del mes',
      subtitle: 'Cómo cambió tu gasto frente al mes pasado',
      emptyMessage:
          'Aún no hay suficiente historial para mostrar tendencias de este mes.',
    );
  }
}

class _CreditCardSummarySection extends ConsumerWidget {
  final String tenantId;

  const _CreditCardSummarySection({required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = context.bruma;
    final creditCardsAsync = ref.watch(creditCardAccountsProvider(tenantId));

    return creditCardsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (accounts) {
        if (accounts.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pagar este mes',
              style: GoogleFonts.dmSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: b.textPrimary,
                letterSpacing: -0.02 * 17,
              ),
            ),
            const SizedBox(height: 16),
            ...accounts.map((account) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CreditCardSummaryCard(account: account),
                )),
          ],
        );
      },
    );
  }
}

class _CreditCardSummaryCard extends ConsumerWidget {
  final Account account;

  const _CreditCardSummaryCard({required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = context.bruma;
    final totalMonthlyAsync = ref.watch(totalMonthlyMsiProvider(account.id));
    final usageColor = _creditCardUsageColor(b, account.usagePercent);

    return AppCard(
      padding: 18,
      onTap: () => context.push(AppRoutes.creditCardDetail, extra: account),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  account.name,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: b.textPrimary,
                  ),
                ),
              ),
              Text(
                'Disponible ${_dashboardCurrency(account.availableCredit)}',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: b.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: account.usagePercent,
              minHeight: 8,
              backgroundColor: b.surfaceAlt,
              valueColor: AlwaysStoppedAnimation<Color>(usageColor),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Usado: ${_dashboardCurrency(account.balance)} de ${_dashboardCurrency(account.creditLimit ?? 0)}',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: b.textSecondary,
            ),
          ),
          totalMonthlyAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (total) {
              if (total <= 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Pago mínimo este mes: ${_dashboardCurrency(total)}',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: b.textPrimary,
                  ),
                ),
              );
            },
          ),
          if (account.billingCloseDay != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Corte: día ${account.billingCloseDay}',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: b.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Transacciones recientes ──────────────────────────────────────────────────

class _RecentSection extends ConsumerWidget {
  final String tenantId;
  const _RecentSection({required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = context.bruma;
    final transactionsAsync = ref.watch(recentTransactionsProvider(tenantId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recientes',
                style: GoogleFonts.dmSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: b.textPrimary,
                  letterSpacing: -0.02 * 17,
                ),
              ),
              GestureDetector(
                onTap: () => context.push(AppRoutes.transactions),
                child: Text(
                  'Ver todas',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: b.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        transactionsAsync.when(
          loading: () => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: CircularProgressIndicator(color: b.primary),
            ),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Error: $err',
              style: GoogleFonts.dmSans(color: b.textSecondary),
            ),
          ),
          data: (transactions) {
            if (transactions.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Iconsax.receipt_2, color: b.textTertiary, size: 40),
                      const SizedBox(height: 8),
                      Text(
                        'Sin transacciones aún',
                        style: GoogleFonts.dmSans(color: b.textTertiary),
                      ),
                    ],
                  ),
                ),
              );
            }
            final limited = transactions.take(5).toList();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: limited.asMap().entries.map((entry) {
                  final tx = entry.value;
                  final isIncome = tx.type == 'income';
                  return TransactionListItem(
                    title: tx.notes ?? AppCategories.labelForId(tx.category),
                    category: tx.category,
                    amount: isIncome ? tx.amount : -tx.amount,
                    date: DateFormat('dd MMM', 'es_MX').format(tx.date),
                    index: entry.key,
                    onTap: () => context.push(
                      AppRoutes.transactionDetail,
                      extra: tx,
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}

Color _creditCardUsageColor(BrumaTheme b, double usagePercent) {
  if (usagePercent > 0.8) return b.error;
  if (usagePercent > 0.5) return b.warning;
  return b.success;
}

String _dashboardCurrency(double value) {
  return NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  ).format(value);
}
