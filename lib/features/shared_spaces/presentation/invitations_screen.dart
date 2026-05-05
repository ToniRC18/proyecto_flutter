import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../core/animations/bruma_animations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/bruma_empty_state.dart';
import '../data/shared_spaces_repository.dart';
import '../domain/invitation_model.dart';

class InvitationsScreen extends ConsumerWidget {
  const InvitationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = context.bruma;
    final invitationsAsync = ref.watch(pendingInvitationsProvider);

    return Scaffold(
      backgroundColor: b.bg,
      appBar: AppBar(
        backgroundColor: b.bg,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Iconsax.arrow_left, color: b.textPrimary),
        ),
        title: Text(
          'Invitaciones',
          style: GoogleFonts.dmSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: b.textPrimary,
          ),
        ),
      ),
      body: invitationsAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: b.primary)),
        error: (error, _) => Center(
          child: Text(
            'Error: $error',
            style: GoogleFonts.dmSans(fontSize: 14, color: b.textSecondary),
          ),
        ),
        data: (invitations) {
          if (invitations.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: BrumaEmptyState(
                  type: BrumaEmptyType.sharedSpaces,
                  title: 'Sin invitaciones',
                  subtitle: 'Cuando alguien te invite, aparecerá aquí',
                ),
              ),
            );
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            itemCount: invitations.length,
            itemBuilder: (context, index) {
              return FadeUpAnimation(
                delayMs: index * 40,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _InvitationCard(invitation: invitations[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _InvitationCard extends ConsumerWidget {
  final TenantInvitation invitation;

  const _InvitationCard({required this.invitation});

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final b = context.bruma;
    try {
      HapticFeedback.lightImpact();
      await ref
          .read(sharedSpacesRepositoryProvider)
          .rejectInvitation(invitation.id);
      ref.invalidate(pendingInvitationsProvider);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invitación rechazada.', style: GoogleFonts.dmSans()),
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

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    final b = context.bruma;
    try {
      HapticFeedback.lightImpact();
      await ref
          .read(sharedSpacesRepositoryProvider)
          .acceptInvitation(invitation.id);
      ref.invalidate(pendingInvitationsProvider);
      ref.invalidate(sharedSpacesProvider);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Te uniste a ${invitation.tenantName}.',
            style: GoogleFonts.dmSans(),
          ),
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
    final date =
        DateFormat('dd MMM yyyy', 'es_MX').format(invitation.createdAt);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: b.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Iconsax.people, color: b.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invitation.tenantName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: b.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'De: ${invitation.invitedBy} · $date',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: b.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                label: 'Rechazar',
                expanded: false,
                small: true,
                variant: AppButtonVariant.ghost,
                destructive: true,
                onPressed: () => _reject(context, ref),
              ),
              const SizedBox(width: 10),
              AppButton(
                label: 'Aceptar',
                expanded: false,
                small: true,
                onPressed: () => _accept(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
