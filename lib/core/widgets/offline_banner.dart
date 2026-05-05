import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../offline/providers/connectivity_provider.dart';
import '../offline/providers/offline_queue_provider.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = context.bruma;
    final isOnline = ref.watch(isOnlineSyncProvider);
    if (isOnline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: b.warning,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sin conexión — tus cambios se guardarán al reconectarte',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Builder(
            builder: (_) {
              final count = ref.watch(pendingOperationsCountProvider);
              if (count == 0) return const SizedBox.shrink();

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count pendiente${count > 1 ? 's' : ''}',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
