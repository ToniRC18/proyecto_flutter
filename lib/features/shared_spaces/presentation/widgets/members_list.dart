import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/shared_member_model.dart';

/// Muestra una lista de miembros de un espacio compartido con
/// avatar (iniciales), nombre y rol.
class MembersList extends ConsumerWidget {
  final List<SharedMember> members;
  const MembersList({super.key, required this.members});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = context.bruma;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Miembros',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: b.textPrimary,
            ),
          ),
        ),
        ...members.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _MemberTile(member: m),
            )),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  final SharedMember member;
  const _MemberTile({required this.member});

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final isOwner = member.role == 'owner';
    final initials = _initials(member.name);

    return AppCard(
      padding: 14,
      child: Row(
        children: [
          // Avatar circular con iniciales
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOwner ? b.primarySubtle : b.surfaceAlt,
            ),
            child: member.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      member.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _initialsWidget(initials, isOwner, b),
                    ),
                  )
                : _initialsWidget(initials, isOwner, b),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: b.textPrimary,
                  ),
                ),
                Text(
                  isOwner ? 'Propietario' : 'Miembro',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: isOwner ? b.primary : b.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Badge de rol
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isOwner ? b.primarySubtle : b.surfaceAlt,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              isOwner ? 'Owner' : 'Member',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isOwner ? b.primary : b.textSecondary,
              ),
            ),
          ),
        ],
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

  Widget _initialsWidget(String initials, bool isOwner, BrumaTheme b) {
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.dmSans(
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: isOwner ? b.primary : b.textSecondary,
        ),
      ),
    );
  }
}
