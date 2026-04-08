import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/shared_member_model.dart';

/// Muestra una lista de miembros de un espacio compartido con
/// avatar (iniciales), nombre y rol.
class MembersList extends ConsumerWidget {
  final List<SharedMember> members;
  const MembersList({super.key, required this.members});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Miembros',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        ...members.map((m) => _MemberTile(member: m)),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  final SharedMember member;
  const _MemberTile({required this.member});

  @override
  Widget build(BuildContext context) {
    final isOwner = member.role == 'owner';
    final initials = _initials(member.name);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: 16,
        child: Row(
          children: [
            // Avatar circular con iniciales
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOwner
                    ? AppColors.primary.withAlpha(30)
                    : Colors.grey.withAlpha(30),
              ),
              child: member.avatarUrl != null
                  ? ClipOval(
                      child: Image.network(
                        member.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _initialsWidget(initials, isOwner),
                      ),
                    )
                  : _initialsWidget(initials, isOwner),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    isOwner ? 'Propietario' : 'Miembro',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isOwner ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Badge de rol
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isOwner
                    ? AppColors.primary.withAlpha(20)
                    : Colors.grey.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isOwner
                      ? AppColors.primary.withAlpha(60)
                      : Colors.grey.withAlpha(60),
                ),
              ),
              child: Text(
                isOwner ? 'Owner' : 'Member',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isOwner ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Iniciales del nombre (máx 2 caracteres).
  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Widget _initialsWidget(String initials, bool isOwner) {
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: isOwner ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }
}
