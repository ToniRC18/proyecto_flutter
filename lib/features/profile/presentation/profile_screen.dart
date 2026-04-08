import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/tenant_provider.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/data/auth_repository.dart';
import '../../dashboard/data/dashboard_repository.dart';

/// Pantalla de perfil simple con datos del usuario y opción de cerrar sesión.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantAsync = ref.watch(tenantProvider);
    final userNameAsync = ref.watch(userNameProvider);
    final authRepo = ref.read(authRepositoryProvider);
    final user = authRepo.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 32),

            // ── Avatar con iniciales ────────────────────────────────
            Center(
              child: userNameAsync.when(
                data: (name) => _Avatar(name: name),
                loading: () =>
                    const _Avatar(name: '?'),
                error: (_, __) => const _Avatar(name: '?'),
              ),
            ),
            const SizedBox(height: 16),

            // ── Nombre ──────────────────────────────────────────────
            Center(
              child: userNameAsync.when(
                data: (name) => Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                loading: () => const SizedBox(height: 28),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 4),

            // ── Email ────────────────────────────────────────────────
            Center(
              child: Text(
                user?.email ?? '',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Info card ────────────────────────────────────────────
            GlassCard(
              child: Column(
                children: [
                  _InfoRow(
                    label: 'Member since',
                    value: user?.createdAt != null
                        ? DateFormat('MMMM yyyy')
                            .format(DateTime.parse(user!.createdAt))
                        : '—',
                  ),
                  const Divider(color: Colors.white54, height: 24),
                  tenantAsync.when(
                    data: (tenantId) => _InfoRow(
                      label: 'Tenant ID',
                      value: tenantId.length >= 8
                          ? tenantId.substring(0, 8).toUpperCase()
                          : tenantId,
                    ),
                    loading: () => _InfoRow(label: 'Tenant ID', value: '…'),
                    error: (_, __) =>
                        _InfoRow(label: 'Tenant ID', value: '—'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Botón Sign Out ───────────────────────────────────────
            OutlinedButton(
              onPressed: () async {
                try {
                  await authRepo.signOut();
                  // GoRouter redirigirá automáticamente a /auth
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                minimumSize: const Size(double.infinity, 52),
              ),
              child: Text(
                'Sign Out',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

// ─── Avatar con iniciales ─────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  String _initials() {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initials(),
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─── Fila de información ──────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
