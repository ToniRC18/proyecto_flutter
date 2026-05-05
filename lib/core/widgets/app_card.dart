import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// AppCard — Basado EXACTAMENTE en AppCard de components.jsx
// borderRadius 20, border 1px, hover/press effects, scale 0.985
// ═══════════════════════════════════════════════════════════════════════════════

class AppCard extends StatefulWidget {
  final Widget child;
  final double padding;
  final VoidCallback? onTap;
  final bool noBorder;

  const AppCard({
    super.key,
    required this.child,
    this.padding = 16,
    this.onTap,
    this.noBorder = false,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;

    return GestureDetector(
      onTapDown: widget.onTap != null
          ? (_) => setState(() => _pressed = true)
          : null,
      onTapUp: widget.onTap != null
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap!();
            }
          : null,
      onTapCancel: widget.onTap != null
          ? () => setState(() => _pressed = false)
          : null,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.ease,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(widget.padding),
          decoration: BoxDecoration(
            color: b.surface,
            borderRadius: BorderRadius.circular(20),
            border: widget.noBorder
                ? null
                : Border.all(color: b.border, width: 1),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
