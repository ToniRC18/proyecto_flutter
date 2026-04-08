import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_routes.dart';

/// Determina a qué pantalla navegar según el campo `screen` del payload
/// de una notificación FCM.
class NotificationHandler {
  /// Navega a la pantalla correcta según los datos del payload.
  ///
  /// [context]  — BuildContext con acceso al GoRouter.
  /// [data]     — Mapa de datos del RemoteMessage (message.data).
  static void handle(BuildContext context, Map<String, dynamic> data) {
    final screen = data['screen'] as String?;

    switch (screen) {
      case 'transaction_detail':
        final transactionId = data['transaction_id'] as String?;
        if (transactionId != null) {
          // Navega al detalle de transacción pasando el id como query param
          context.push(
            '${AppRoutes.transactionDetail}?id=$transactionId',
          );
        } else {
          context.go(AppRoutes.dashboard);
        }
        break;

      case 'shared_space':
        // Navega a espacios compartidos
        context.push(AppRoutes.sharedSpaces);
        break;

      default:
        // Pantalla desconocida → Dashboard
        context.go(AppRoutes.dashboard);
        break;
    }
  }
}
