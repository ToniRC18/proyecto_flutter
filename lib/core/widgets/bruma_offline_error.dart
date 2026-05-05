import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';

class BrumaOfflineError extends StatelessWidget {
  final VoidCallback? onRetry;
  final String message;

  const BrumaOfflineError({
    super.key,
    this.onRetry,
    this.message = 'Sin conexión a internet',
  });

  static bool isOfflineError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('socket') ||
        msg.contains('network') ||
        msg.contains('connection') ||
        msg.contains('timeout') ||
        msg.contains('clientexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('errno = 7') ||
        msg.contains('errno = 8') ||
        msg.contains('no address associated');
  }

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.wifi, size: 48, color: b.textTertiary),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: b.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Conéctate para ver esta información.',
              style: TextStyle(fontSize: 13, color: b.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              AppButton(label: 'Reintentar', onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}

// Helper global — úsalo en cualquier bloque .when(error:)
Widget buildAsyncError(
  Object error,
  StackTrace? stack, {
  VoidCallback? onRetry,
  BuildContext? context,
}) {
  if (BrumaOfflineError.isOfflineError(error)) {
    return BrumaOfflineError(onRetry: onRetry);
  }
  final b = context?.bruma;
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Iconsax.warning_2,
            size: 40,
            color: b?.error ?? Colors.red,
          ),
          const SizedBox(height: 12),
          const Text(
            'Algo salió mal',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Intenta de nuevo más tarde.',
            style: TextStyle(fontSize: 13),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            AppButton(label: 'Reintentar', onPressed: onRetry),
          ],
        ],
      ),
    ),
  );
}
