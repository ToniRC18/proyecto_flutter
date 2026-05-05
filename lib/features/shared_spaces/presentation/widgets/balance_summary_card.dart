import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/supabase/supabase_client.dart';
import '../../data/shared_spaces_repository.dart';

/// Tarjeta que muestra el balance de gastos entre miembros
/// del espacio compartido: quién gastó cuánto y quién le debe a quién.
class BalanceSummaryCard extends ConsumerWidget {
  final String tenantId;
  const BalanceSummaryCard({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = context.bruma;
    final balanceAsync = ref.watch(balanceProvider(tenantId));
    final membersAsync = ref.watch(membersProvider(tenantId));
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final currentUserId = supabase.auth.currentUser?.id ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: AppCard(
        padding: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Balance del grupo',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: b.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            balanceAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: b.primary),
              ),
              error: (err, _) => Text(
                'Error al calcular balance',
                style: GoogleFonts.dmSans(color: b.error),
              ),
              data: (balance) {
                if (balance.isEmpty) {
                  return Text(
                    'Sin gastos registrados aún',
                    style: GoogleFonts.dmSans(color: b.textSecondary),
                  );
                }

                // Calcular promedio
                final total = balance.values.fold(0.0, (a, b) => a + b);
                final promedio = total / balance.length;

                return membersAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (members) {
                    final memberNameMap = {
                      for (final m in members) m.userId: m.name
                    };

                    return Column(
                      children: balance.entries.map((entry) {
                        final userId = entry.key;
                        final spent = entry.value;
                        final diff = spent - promedio;
                        final isMe = userId == currentUserId;
                        final name = isMe
                            ? 'Tú'
                            : memberNameMap[userId] ?? 'Usuario';

                        final color = diff > 0
                            ? b.success
                            : diff < 0
                                ? b.error
                                : b.textSecondary;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '$name gastó ${formatter.format(spent)}',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: b.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                diff > 0
                                    ? '· le deben ${formatter.format(diff.abs())}'
                                    : diff < 0
                                        ? '· debe ${formatter.format(diff.abs())}'
                                        : '· en equilibrio',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
