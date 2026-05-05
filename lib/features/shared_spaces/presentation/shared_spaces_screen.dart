import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../core/animations/bruma_animations.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/bruma_offline_error.dart';
import '../../../core/widgets/bruma_empty_state.dart';
import '../data/shared_spaces_repository.dart';
import '../domain/shared_member_model.dart';
import 'widgets/create_space_dialog.dart';

class SharedSpacesScreen extends ConsumerStatefulWidget {
  const SharedSpacesScreen({super.key});

  @override
  ConsumerState<SharedSpacesScreen> createState() => _SharedSpacesScreenState();
}

class _SharedSpacesScreenState extends ConsumerState<SharedSpacesScreen> {
  Future<void> _openCreateSheet() async {
    HapticFeedback.lightImpact();
    final created = await showCreateSpaceSheet(context);
    if (created == true) {
      ref.invalidate(sharedSpacesProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final spacesAsync = ref.watch(sharedSpacesProvider);
    final invitationsAsync = ref.watch(pendingInvitationsProvider);

    return Scaffold(
      backgroundColor: b.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Text(
                    'Espacios',
                    style: GoogleFonts.dmSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: b.textPrimary,
                      letterSpacing: -0.03 * 24,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _openCreateSheet,
                    icon: Icon(Iconsax.add_square, color: b.primary, size: 24),
                  ),
                ],
              ),
            ),
            Expanded(
              child: spacesAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: b.primary),
                ),
                error: (error, stack) => buildAsyncError(
                  error,
                  stack,
                  onRetry: () => ref.invalidate(sharedSpacesProvider),
                  context: context,
                ),
                data: (spaces) {
                  if (spaces.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: BrumaEmptyState(
                          type: BrumaEmptyType.sharedSpaces,
                          title: 'Sin espacios compartidos',
                          subtitle: 'Crea uno o acepta una invitación',
                          action: AppButton(
                            label: 'Crear espacio',
                            expanded: false,
                            onPressed: _openCreateSheet,
                          ),
                        ),
                      ),
                    );
                  }

                  final pendingCount = invitationsAsync.maybeWhen(
                    data: (invitations) => invitations.length,
                    orElse: () => 0,
                  );

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    itemCount: spaces.length + (pendingCount > 0 ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == spaces.length) {
                        return FadeUpAnimation(
                          delayMs: index * 40,
                          child: _PendingInvitationsCard(count: pendingCount),
                        );
                      }

                      return FadeUpAnimation(
                        delayMs: index * 40,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _SpaceCard(space: spaces[index]),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpaceCard extends StatelessWidget {
  final SharedTenant space;

  const _SpaceCard({required this.space});

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final formatter = NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 0,
    );

    return AppCard(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(AppRoutes.spaceDetail, extra: space.id);
      },
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: b.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Iconsax.people, color: b.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  space.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: b.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${space.memberCount} miembro(s)',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: b.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatter.format(space.totalThisMonth),
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: b.primary,
                ),
              ),
              Text(
                'este mes',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: b.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Icon(Iconsax.arrow_right, color: b.textTertiary, size: 18),
        ],
      ),
    );
  }
}

class _PendingInvitationsCard extends StatelessWidget {
  final int count;

  const _PendingInvitationsCard({required this.count});

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    return AppCard(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(AppRoutes.invitations);
      },
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: b.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Iconsax.notification, color: b.warning, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tienes $count invitación(es) pendiente(s)',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: b.textPrimary,
              ),
            ),
          ),
          Icon(Iconsax.arrow_right, color: b.textTertiary, size: 18),
        ],
      ),
    );
  }
}
