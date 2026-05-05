import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/account_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/balance_display.dart';
import '../data/accounts_repository.dart';
import '../../dashboard/domain/account_model.dart';

class AccountDetailScreen extends ConsumerWidget {
  final Account account;

  const AccountDetailScreen({
    super.key,
    required this.account,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveAccountAsync = ref.watch(allAccountsProvider(account.tenantId));
    final b = context.bruma;

    return Scaffold(
      backgroundColor: b.bg,
      appBar: AppBar(
        backgroundColor: b.bg,
        foregroundColor: b.textPrimary,
        elevation: 0,
        title: Text(
          account.name,
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: b.textPrimary,
          ),
        ),
      ),
      body: liveAccountAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: b.primary),
        ),
        error: (error, _) => Center(
          child: Text(
            'Error: $error',
            style: GoogleFonts.dmSans(color: b.textSecondary),
          ),
        ),
        data: (accounts) {
          final currentAccount = accounts.firstWhere(
            (item) => item.id == account.id,
            orElse: () => account,
          );
          final accountColor =
              kAccountTypeColors[currentAccount.type] ?? b.primary;
          final accountLabel =
              kAccountTypeLabels[currentAccount.type] ?? currentAccount.type;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            children: [
              AppCard(
                padding: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: accountColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        accountLabel,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: accountColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Balance actual',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: b.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    BalanceDisplay(value: currentAccount.balance, fontSize: 34),
                    const SizedBox(height: 18),
                    Text(
                      'Consulta rápida de la cuenta seleccionada.',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: b.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AppCard(
                padding: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: b.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _DetailRow(label: 'Nombre', value: currentAccount.name),
                    _DetailRow(label: 'Tipo', value: accountLabel),
                    _DetailRow(
                      label: 'Saldo',
                      value: _formatCurrency(currentAccount.balance),
                      emphasize: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Acciones rápidas',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: b.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Registrar gasto',
                      onPressed: () => context.push(AppRoutes.addExpense),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Transferir',
                      variant: AppButtonVariant.subtle,
                      onPressed: () => context.push(AppRoutes.addTransfer),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _DetailRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: b.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              color: b.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatCurrency(double value) {
  final isNegative = value < 0;
  final absValue = value.abs().toStringAsFixed(2);
  return '${isNegative ? '-' : ''}\$$absValue';
}
