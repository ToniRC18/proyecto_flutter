import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/shared_spaces_repository.dart';

/// Dialog para crear un nuevo espacio compartido.
class CreateSpaceDialog extends ConsumerStatefulWidget {
  const CreateSpaceDialog({super.key});

  @override
  ConsumerState<CreateSpaceDialog> createState() => _CreateSpaceDialogState();
}

class _CreateSpaceDialogState extends ConsumerState<CreateSpaceDialog> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    final nombre = _controller.text.trim();
    if (nombre.isEmpty) {
      setState(() => _error = 'Ingresa un nombre para el espacio');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref
          .read(sharedSpacesRepositoryProvider)
          .createSharedSpace(nombre);

      // Invalidar lista de espacios para refrescar
      ref.invalidate(sharedSpacesProvider);

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    return Dialog(
      backgroundColor: b.bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              decoration: InputDecoration(
                hintText: 'Ej: Casa de la playa 🏖️',
                hintStyle: GoogleFonts.dmSans(color: b.textTertiary),
                filled: true,
                fillColor: b.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: b.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: b.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: b.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
              style: GoogleFonts.dmSans(color: b.textPrimary),
              onSubmitted: (_) => _crear(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: GoogleFonts.dmSans(color: b.error, fontSize: 12),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(false),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.dmSans(color: b.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _loading ? null : _crear,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: b.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'Crear',
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w600,
                              color: b.onPrimary,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
