import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/shared_spaces_repository.dart';

Future<bool?> showCreateSpaceSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const CreateSpaceDialog(),
  );
}

/// Bottom sheet para crear un espacio compartido.
class CreateSpaceDialog extends ConsumerStatefulWidget {
  const CreateSpaceDialog({super.key});

  @override
  ConsumerState<CreateSpaceDialog> createState() => _CreateSpaceDialogState();
}

class _CreateSpaceDialogState extends ConsumerState<CreateSpaceDialog> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    final b = context.bruma;
    final nombre = _controller.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ingresa un nombre para el espacio.',
              style: GoogleFonts.dmSans()),
          backgroundColor: b.error,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      HapticFeedback.lightImpact();
      await ref.read(sharedSpacesRepositoryProvider).createSharedSpace(nombre);
      ref.invalidate(sharedSpacesProvider);

      if (mounted) Navigator.of(context).pop(true);
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
                  'Crear espacio',
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: b.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Crea un espacio compartido para dividir gastos con otras personas.',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: b.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  style: GoogleFonts.dmSans(color: b.textPrimary),
                  onSubmitted: (_) => _crear(),
                  decoration: InputDecoration(
                    hintText: 'Ej: Casa de la playa',
                    hintStyle: GoogleFonts.dmSans(color: b.textTertiary),
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
                  label: 'Crear espacio',
                  loading: _loading,
                  onPressed: _loading ? null : _crear,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
