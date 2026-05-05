import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// COMPATIBILIDAD: GlassCard ahora redirige a un Container con tokens Bruma.
// Se mantiene para que archivos que aún lo importen compilen sin errores.
// Los nuevos widgets deben usar AppCard directamente.
// ═══════════════════════════════════════════════════════════════════════════════

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets padding;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: b.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: b.border, width: 1),
      ),
      child: child,
    );
  }
}
