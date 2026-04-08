import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../data/shared_spaces_repository.dart';
import '../domain/invitation_model.dart';
import 'widgets/create_space_dialog.dart';
import 'widgets/invite_member_dialog.dart';
import 'widgets/members_list.dart';
import 'widgets/balance_summary_card.dart';

/// Pantalla con dos tabs: "Mis Espacios" e "Invitaciones".
/// Diseño glassmorphism consistente con el resto de la app.
class SharedSpacesScreen extends ConsumerStatefulWidget {
  const SharedSpacesScreen({super.key});

  @override
  ConsumerState<SharedSpacesScreen> createState() => _SharedSpacesScreenState();
}

class _SharedSpacesScreenState extends ConsumerState<SharedSpacesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedTenantId; // tenant activo para ver detalle

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Espacios compartidos',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          // Botón "+" para crear espacio (solo visible en Tab 1)
          IconButton(
            icon: const Icon(Iconsax.add_square, color: AppColors.primary),
            tooltip: 'Crear espacio',
            onPressed: () async {
              final created = await showDialog<bool>(
                context: context,
                builder: (_) => const CreateSpaceDialog(),
              );
              if (created == true) {
                ref.invalidate(sharedSpacesProvider);
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(),
          tabs: const [
            Tab(text: 'Mis Espacios'),
            Tab(text: 'Invitaciones'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── TAB 1: Mis Espacios ────────────────────────────────────
          _selectedTenantId == null
              ? _MisEspaciosTab(
                  onTapSpace: (tid) => setState(() => _selectedTenantId = tid),
                )
              : _SpaceDetailView(
                  tenantId: _selectedTenantId!,
                  onBack: () => setState(() => _selectedTenantId = null),
                ),

          // ── TAB 2: Invitaciones ────────────────────────────────────
          const _InvitacionesTab(),
        ],
      ),
    );
  }
}

// ─── Tab 1: Lista de espacios ─────────────────────────────────────────────────

class _MisEspaciosTab extends ConsumerWidget {
  final void Function(String tenantId) onTapSpace;
  const _MisEspaciosTab({required this.onTapSpace});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacesAsync = ref.watch(sharedSpacesProvider);
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return spacesAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (err, _) => Center(
        child: Text(
          'Error: $err',
          style: GoogleFonts.poppins(color: AppColors.textSecondary),
        ),
      ),
      data: (spaces) {
        if (spaces.isEmpty) {
          return _EmptyState(
            icon: Iconsax.people,
            message: 'No tienes espacios compartidos\n¡Crea uno con el botón +!',
          );
        }
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: spaces.length,
          itemBuilder: (context, i) {
            final space = spaces[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => onTapSpace(space.id),
                child: GlassCard(
                  child: Row(
                    children: [
                      // Ícono del espacio
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Iconsax.people,
                            color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              space.name,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${space.memberCount} miembro${space.memberCount != 1 ? 's' : ''}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textSecondary,
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
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'este mes',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right,
                          color: AppColors.textLight),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Detalle de espacio ───────────────────────────────────────────────────────

class _SpaceDetailView extends ConsumerWidget {
  final String tenantId;
  final VoidCallback onBack;
  const _SpaceDetailView({required this.tenantId, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersProvider(tenantId));

    return Column(
      children: [
        // Botón volver
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_back_ios_new,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Volver',
                        style: GoogleFonts.poppins(
                            color: AppColors.primary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Botón invitar miembro
              FilledButton.icon(
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (_) => InviteMemberDialog(tenantId: tenantId),
                  );
                },
                icon: const Icon(Iconsax.user_add, size: 16),
                label: Text('Invitar',
                    style: GoogleFonts.poppins(fontSize: 13)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              // Balance del grupo
              BalanceSummaryCard(tenantId: tenantId),
              const SizedBox(height: 8),
              // Lista de miembros
              membersAsync.when(
                loading: () => const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary)),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: $err',
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary)),
                ),
                data: (members) => MembersList(members: members),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Tab 2: Invitaciones ──────────────────────────────────────────────────────

class _InvitacionesTab extends ConsumerWidget {
  const _InvitacionesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitationsAsync = ref.watch(pendingInvitationsProvider);

    return invitationsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (err, _) => Center(
        child: Text('Error: $err', style: GoogleFonts.poppins()),
      ),
      data: (invitations) {
        if (invitations.isEmpty) {
          return _EmptyState(
            icon: Iconsax.notification,
            message: 'No tienes invitaciones pendientes',
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: invitations.length,
          itemBuilder: (context, i) =>
              _InvitationCard(invitation: invitations[i], ref: ref),
        );
      },
    );
  }
}

class _InvitationCard extends StatelessWidget {
  final TenantInvitation invitation;
  final WidgetRef ref;
  const _InvitationCard({required this.invitation, required this.ref});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy').format(invitation.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Iconsax.people,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invitation.tenantName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'De: ${invitation.invitedBy} · $dateStr',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Botón rechazar
                OutlinedButton(
                  onPressed: () async {
                    try {
                      await ref
                          .read(sharedSpacesRepositoryProvider)
                          .rejectInvitation(invitation.id);
                      ref.invalidate(pendingInvitationsProvider);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ));
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                    side: BorderSide(color: Colors.red.shade300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                  ),
                  child: Text('Rechazar', style: GoogleFonts.poppins(fontSize: 13)),
                ),
                const SizedBox(width: 10),
                // Botón aceptar
                FilledButton(
                  onPressed: () async {
                    try {
                      await ref
                          .read(sharedSpacesRepositoryProvider)
                          .acceptInvitation(invitation.id);
                      ref.invalidate(pendingInvitationsProvider);
                      ref.invalidate(sharedSpacesProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                            '¡Bienvenido a ${invitation.tenantName}!',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: Colors.green.shade600,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ));
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                  ),
                  child: Text('Aceptar', style: GoogleFonts.poppins(fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Estado vacío reutilizable ────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textLight),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
