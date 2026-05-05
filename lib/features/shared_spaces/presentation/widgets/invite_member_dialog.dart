import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/shared_spaces_repository.dart';

Future<bool?> showInviteMemberSheet(BuildContext context, String tenantId) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => InviteMemberDialog(tenantId: tenantId),
  );
}

/// Bottom sheet para invitar a un miembro por email.
class InviteMemberDialog extends ConsumerStatefulWidget {
  final String tenantId;

  const InviteMemberDialog({super.key, required this.tenantId});

  @override
  ConsumerState<InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends ConsumerState<InviteMemberDialog> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w.-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _invitar() async {
    final b = context.bruma;
    final email = _controller.text.trim();
    if (email.isEmpty || !_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Ingresa un email válido.', style: GoogleFonts.dmSans()),
          backgroundColor: b.error,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      HapticFeedback.lightImpact();
      await ref
          .read(sharedSpacesRepositoryProvider)
          .inviteMember(widget.tenantId, email);

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Invitación enviada a $email.', style: GoogleFonts.dmSans()),
          backgroundColor: b.success,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error', style: GoogleFonts.dmSans()),
          backgroundColor: b.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: b.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Invitar miembro',
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: b.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ingresa el email de la persona que quieres invitar.',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: b.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.dmSans(color: b.textPrimary),
                  onSubmitted: (_) => _invitar(),
                  decoration: InputDecoration(
                    hintText: 'correo@ejemplo.com',
                    hintStyle: GoogleFonts.dmSans(color: b.textTertiary),
                    prefixIcon:
                        Icon(Iconsax.sms, color: b.textSecondary, size: 20),
                    filled: true,
                    fillColor: b.surfaceAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Enviar invitación',
                  loading: _loading,
                  onPressed: _loading ? null : _invitar,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
