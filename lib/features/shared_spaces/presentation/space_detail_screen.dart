import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../core/animations/bruma_animations.dart';
import '../../../core/providers/tenant_provider.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/amount_input_field.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/bruma_empty_state.dart';
import '../../../core/widgets/transaction_list_item.dart';
import '../../accounts/data/accounts_repository.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../../dashboard/domain/account_model.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/domain/transaction_model.dart';
import '../../transactions/split/data/split_repository.dart';
import '../../transactions/split/domain/transaction_split_model.dart';
import '../../transactions/split/presentation/split_expense_sheet.dart';
import '../data/shared_spaces_repository.dart';
import '../domain/shared_member_model.dart';
import 'widgets/invite_member_dialog.dart';

class SpaceDetailScreen extends ConsumerStatefulWidget {
  final String tenantId;

  const SpaceDetailScreen({super.key, required this.tenantId});

  @override
  ConsumerState<SpaceDetailScreen> createState() => _SpaceDetailScreenState();
}

class _SpaceDetailScreenState extends ConsumerState<SpaceDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activeTenantOverrideProvider.notifier).state = widget.tenantId;
    });
  }

  @override
  void dispose() {
    ref.read(activeTenantOverrideProvider.notifier).state = null;
    super.dispose();
  }

  Future<void> _openInviteSheet() async {
    HapticFeedback.lightImpact();
    final invited = await showInviteMemberSheet(context, widget.tenantId);
    if (invited == true) {
      ref.invalidate(membersProvider(widget.tenantId));
      ref.invalidate(sharedSpaceProvider(widget.tenantId));
    }
  }

  Future<void> _handleCreateSplitExpense() async {
    final b = context.bruma;
    HapticFeedback.lightImpact();

    try {
      final totalAmount = await showModalBottomSheet<double>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _SplitAmountSheet(),
      );

      if (totalAmount == null || totalAmount <= 0) return;
      if (!mounted) return;

      final splits = await showModalBottomSheet<List<TransactionSplitModel>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => SplitExpenseSheet(
          tenantId: widget.tenantId,
          totalAmount: totalAmount,
        ),
      );

      if (splits == null || splits.isEmpty) return;

      final accounts = await ref
          .read(transactionRepositoryProvider)
          .getAccounts(widget.tenantId);
      final selectedAccount = _resolveSharedSpaceAccount(accounts);

      if (selectedAccount == null) {
        throw Exception(
          'Este espacio no tiene cuentas disponibles para registrar el gasto.',
        );
      }

      final transactionId =
          await ref.read(transactionRepositoryProvider).saveExpense(
                tenantId: widget.tenantId,
                accountId: selectedAccount.id,
                amount: totalAmount,
                category: 'split',
                notes: 'Gasto compartido',
                hasSplit: true,
              );

      await ref.read(splitRepositoryProvider).createSplits(
            transactionId: transactionId,
            splits: splits,
          );

      _invalidateDetail();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Gasto compartido creado.', style: GoogleFonts.dmSans()),
          backgroundColor: b.success,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
            style: GoogleFonts.dmSans(),
          ),
          backgroundColor: b.error,
        ),
      );
    }
  }

  Account? _resolveSharedSpaceAccount(List<Account> accounts) {
    if (accounts.isEmpty) return null;
    for (final account in accounts) {
      final normalizedName = account.name.toLowerCase();
      final normalizedType = account.type.toLowerCase();
      if (normalizedType == 'cash' || normalizedName == 'efectivo') {
        return account;
      }
    }
    return accounts.first;
  }

  void _invalidateDetail() {
    ref.invalidate(sharedSpacesProvider);
    ref.invalidate(sharedSpaceProvider(widget.tenantId));
    ref.invalidate(membersProvider(widget.tenantId));
    ref.invalidate(memberBalancesProvider(widget.tenantId));
    ref.invalidate(spaceTransactionsProvider(widget.tenantId));
    ref.invalidate(balanceProvider(widget.tenantId));
    ref.invalidate(accountsProvider(widget.tenantId));
    ref.invalidate(allAccountsProvider(widget.tenantId));
    ref.invalidate(totalBalanceProvider(widget.tenantId));
    ref.invalidate(availableBalanceProvider(widget.tenantId));
    ref.invalidate(weeklySpendProvider(widget.tenantId));
    ref.invalidate(recentTransactionsProvider(widget.tenantId));
  }

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final spaceAsync = ref.watch(sharedSpaceProvider(widget.tenantId));

    return Scaffold(
      backgroundColor: b.bg,
      appBar: AppBar(
        backgroundColor: b.bg,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Iconsax.arrow_left, color: b.textPrimary),
        ),
        title: spaceAsync.maybeWhen(
          data: (space) => Text(
            space.name,
            style: GoogleFonts.dmSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: b.textPrimary,
            ),
          ),
          orElse: () => Text(
            'Espacio',
            style: GoogleFonts.dmSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: b.textPrimary,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _openInviteSheet,
            icon: Icon(Iconsax.user_add, color: b.primary),
          ),
          IconButton(
            onPressed: _handleCreateSplitExpense,
            icon: Icon(Iconsax.money_send, color: b.primary),
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          FadeUpAnimation(
            child: _SummarySection(tenantId: widget.tenantId),
          ),
          const SizedBox(height: 18),
          FadeUpAnimation(
            delayMs: 80,
            child: _BalancesSection(
              tenantId: widget.tenantId,
              onSettled: _invalidateDetail,
            ),
          ),
          const SizedBox(height: 18),
          FadeUpAnimation(
            delayMs: 160,
            child: _TransactionsSection(tenantId: widget.tenantId),
          ),
          const SizedBox(height: 18),
          FadeUpAnimation(
            delayMs: 240,
            child: _MembersSection(tenantId: widget.tenantId),
          ),
        ],
      ),
    );
  }
}

class _SummarySection extends ConsumerWidget {
  final String tenantId;

  const _SummarySection({required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = context.bruma;
    final spaceAsync = ref.watch(sharedSpaceProvider(tenantId));
    final formatter = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 0,
    );

    return AppCard(
      child: spaceAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: b.primary)),
        error: (error, _) => _SmallError(message: 'Error: $error'),
        data: (space) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('RESUMEN'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Gastos este mes',
                    value: formatter.format(space.totalThisMonth),
                    color: b.error,
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: 'Miembros',
                    value: '${space.memberCount}',
                    color: b.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: b.border),
            const SizedBox(height: 12),
            Text(
              'Espacio creado para gastos compartidos',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: b.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalancesSection extends ConsumerWidget {
  final String tenantId;
  final VoidCallback onSettled;

  const _BalancesSection({
    required this.tenantId,
    required this.onSettled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = context.bruma;
    final balancesAsync = ref.watch(memberBalancesProvider(tenantId));
    final currentUserId = supabase.auth.currentUser?.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('QUIÉN DEBE QUÉ'),
        const SizedBox(height: 10),
        balancesAsync.when(
          loading: () =>
              Center(child: CircularProgressIndicator(color: b.primary)),
          error: (error, _) => _SmallError(message: 'Error: $error'),
          data: (balances) {
            if (balances.isEmpty) {
              return Text(
                'Sin balances por ahora.',
                style: GoogleFonts.dmSans(fontSize: 13, color: b.textSecondary),
              );
            }
            return Column(
              children: [
                for (final balance in balances) ...[
                  _MemberBalanceCard(
                    tenantId: tenantId,
                    balance: balance,
                    isCurrentUser: balance.userId == currentUserId,
                    currentUserId: currentUserId,
                    onSettled: onSettled,
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MemberBalanceCard extends ConsumerWidget {
  final String tenantId;
  final MemberBalance balance;
  final bool isCurrentUser;
  final String? currentUserId;
  final VoidCallback onSettled;

  const _MemberBalanceCard({
    required this.tenantId,
    required this.balance,
    required this.isCurrentUser,
    required this.currentUserId,
    required this.onSettled,
  });

  Future<void> _settle(BuildContext context, WidgetRef ref) async {
    final b = context.bruma;
    final amount = balance.netBalance.abs();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: b.surface,
        title: Text(
          'Saldar balance',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: b.textPrimary,
          ),
        ),
        content: Text(
          '¿Marcar ${_formatCurrency(amount)} como saldado?',
          style: GoogleFonts.dmSans(color: b.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancelar',
                style: GoogleFonts.dmSans(color: b.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Saldar', style: GoogleFonts.dmSans(color: b.primary)),
          ),
        ],
      ),
    );

    if (confirm != true || currentUserId == null) return;

    try {
      HapticFeedback.lightImpact();
      await ref.read(sharedSpacesRepositoryProvider).settleBalance(
            tenantId: tenantId,
            debtorId: balance.netBalance < 0 ? balance.userId : currentUserId!,
            creditorId:
                balance.netBalance < 0 ? currentUserId! : balance.userId,
            amount: amount,
          );
      onSettled();
      ref.invalidate(memberBalancesProvider(tenantId));

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Balance saldado.', style: GoogleFonts.dmSans()),
          backgroundColor: b.success,
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error', style: GoogleFonts.dmSans()),
          backgroundColor: b.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = context.bruma;
    final label = balance.netBalance > 0
        ? 'Te deben ${_formatCurrency(balance.netBalance)}'
        : balance.netBalance < 0
            ? 'Debes ${_formatCurrency(balance.netBalance.abs())}'
            : 'Al corriente';
    final labelColor = balance.netBalance > 0
        ? b.success
        : balance.netBalance < 0
            ? b.error
            : b.textTertiary;

    return AppCard(
      padding: 12,
      child: Row(
        children: [
          _Avatar(name: balance.name, avatarUrl: balance.avatarUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  balance.name,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: b.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.dmSans(fontSize: 12, color: labelColor),
                ),
              ],
            ),
          ),
          if (balance.netBalance != 0 && !isCurrentUser)
            AppButton(
              label: 'Saldar',
              small: true,
              expanded: false,
              variant: AppButtonVariant.subtle,
              onPressed: () => _settle(context, ref),
            ),
        ],
      ),
    );
  }
}

class _TransactionsSection extends ConsumerWidget {
  final String tenantId;

  const _TransactionsSection({required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(spaceTransactionsProvider(tenantId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('MOVIMIENTOS'),
        const SizedBox(height: 10),
        transactionsAsync.when(
          loading: () {
            final b = context.bruma;
            return Center(child: CircularProgressIndicator(color: b.primary));
          },
          error: (error, _) => _SmallError(message: 'Error: $error'),
          data: (transactions) {
            if (transactions.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: BrumaEmptyState(
                  type: BrumaEmptyType.transactions,
                  title: 'Sin movimientos',
                  subtitle: 'Registra el primer gasto compartido',
                ),
              );
            }

            return AppCard(
              padding: 4,
              child: Column(
                children: [
                  for (var index = 0;
                      index < transactions.take(15).length;
                      index++)
                    _TransactionRow(
                      transaction: transactions[index],
                      index: index,
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final Transaction transaction;
  final int index;

  const _TransactionRow({
    required this.transaction,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd MMM', 'es_MX').format(transaction.date);
    final signedAmount =
        transaction.type == 'income' ? transaction.amount : -transaction.amount;

    return TransactionListItem(
      title: transaction.notes?.isNotEmpty == true
          ? transaction.notes!
          : transaction.category,
      category: transaction.category,
      amount: signedAmount,
      date: date,
      index: index,
    );
  }
}

class _MembersSection extends ConsumerWidget {
  final String tenantId;

  const _MembersSection({required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = context.bruma;
    final membersAsync = ref.watch(membersProvider(tenantId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('MIEMBROS'),
        const SizedBox(height: 10),
        membersAsync.when(
          loading: () =>
              Center(child: CircularProgressIndicator(color: b.primary)),
          error: (error, _) => _SmallError(message: 'Error: $error'),
          data: (members) => AppCard(
            padding: 12,
            child: Column(
              children: [
                for (final member in members) ...[
                  Row(
                    children: [
                      _Avatar(name: member.name, avatarUrl: member.avatarUrl),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          member.name,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: b.textPrimary,
                          ),
                        ),
                      ),
                      _RoleBadge(role: member.role),
                    ],
                  ),
                  if (member != members.last) const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SplitAmountSheet extends StatefulWidget {
  const _SplitAmountSheet();

  @override
  State<_SplitAmountSheet> createState() => _SplitAmountSheetState();
}

class _SplitAmountSheetState extends State<_SplitAmountSheet> {
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
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
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: b.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Dividir gasto',
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: b.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Ingresa el monto total para configurar el split.',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: b.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                AmountInputField(
                  controller: _amountCtrl,
                  amountColor: b.error,
                ),
                const SizedBox(height: 20),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _amountCtrl,
                  builder: (_, __, ___) {
                    final amount =
                        AmountInputField.parseAmount(_amountCtrl.text);
                    return AppButton(
                      label: 'Continuar',
                      onPressed: amount > 0
                          ? () {
                              HapticFeedback.lightImpact();
                              Navigator.of(context).pop(amount);
                            }
                          : null,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            color: b.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    return Text(
      text,
      style: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: b.textSecondary,
        letterSpacing: 0.08 * 11,
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;

  const _Avatar({
    required this.name,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: NetworkImage(avatarUrl!),
        backgroundColor: b.primary.withValues(alpha: 0.15),
      );
    }

    return CircleAvatar(
      radius: 18,
      backgroundColor: b.primary.withValues(alpha: 0.15),
      child: Text(
        initial,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: b.primary,
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final isOwner = role == 'owner';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isOwner ? b.primary.withValues(alpha: 0.10) : b.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isOwner ? 'Admin' : 'Miembro',
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isOwner ? b.primary : b.textSecondary,
        ),
      ),
    );
  }
}

class _SmallError extends StatelessWidget {
  final String message;

  const _SmallError({required this.message});

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    return Text(
      message,
      style: GoogleFonts.dmSans(fontSize: 13, color: b.textSecondary),
    );
  }
}

String _formatCurrency(double amount) {
  return NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
    decimalDigits: 0,
  ).format(amount);
}
