import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../offline/providers/offline_queue_provider.dart';

class PendingSyncBadge extends ConsumerWidget {
  const PendingSyncBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = context.bruma;
    final count = ref.watch(pendingOperationsCountProvider);
    if (count == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: b.warning,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$count',
        style: GoogleFonts.dmSans(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
