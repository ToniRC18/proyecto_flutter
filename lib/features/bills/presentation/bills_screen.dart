import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/animations/bruma_animations.dart';
import '../../../core/widgets/bruma_offline_error.dart';
import '../../../core/widgets/bruma_empty_state.dart';
import '../providers/bills_provider.dart';
import 'bill_card.dart';

class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = context.bruma;
    final billsAsync = ref.watch(billsProvider);

    return Scaffold(
      backgroundColor: b.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Iconsax.arrow_left,
                        color: b.textPrimary, size: 22),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Pagos recurrentes',
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

            // ── Content ──────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: b.primary,
                onRefresh: () async {
                  ref.invalidate(billsProvider);
                  await ref.read(billsProvider.future);
                },
                child: billsAsync.when(
                  loading: () => Center(
                    child: CircularProgressIndicator(color: b.primary),
                  ),
                  error: (error, stack) => ListView(
                    children: [
                      const SizedBox(height: 120),
                      buildAsyncError(
                        error,
                        stack,
                        onRetry: () => ref.invalidate(billsProvider),
                        context: context,
                      ),
                    ],
                  ),
                  data: (bills) {
                    if (bills.isEmpty) {
                      return ListView(
                        padding: const EdgeInsets.all(24),
                        children: const [
                          SizedBox(height: 120),
                          BrumaEmptyState(
                            type: BrumaEmptyType.bills,
                            title: 'Sin pagos recurrentes',
                            subtitle: 'Agrega tus gastos fijos del mes',
                          ),
                        ],
                      );
                    }

                    return ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                      itemBuilder: (context, index) => FadeUpAnimation(
                        delayMs: index * 50,
                        child: BillCard(bill: bills[index]),
                      ),
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemCount: bills.length,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: GestureDetector(
        onTap: () => context.push(AppRoutes.addBill),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: b.primary,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: b.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(Icons.add_rounded, color: b.onPrimary, size: 28),
        ),
      ),
    );
  }
}
