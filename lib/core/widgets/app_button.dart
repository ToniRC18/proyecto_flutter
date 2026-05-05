import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// AppButton — Basado EXACTAMENTE en AppButton de components.jsx
// Variantes: primary, ghost, subtle
// height: small ? 40 : 52 | borderRadius: 14 | scale 0.97 on tap
// ═══════════════════════════════════════════════════════════════════════════════

enum AppButtonVariant { primary, ghost, subtle }

class AppButton extends StatefulWidget {
  final String? label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expanded;
  final bool small;
  final AppButtonVariant variant;
  final Widget? icon;
  final bool destructive;

  const AppButton({
    super.key,
    this.label,
    this.onPressed,
    this.loading = false,
    this.expanded = true,
    this.small = false,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.destructive = false,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;

    // Colores según variante
    final Color bgColor;
    final Color fgColor;
    final Border? border;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        bgColor = b.primary;
        fgColor = b.onPrimary;
        border = null;
      case AppButtonVariant.ghost:
        bgColor = Colors.transparent;
        fgColor = widget.destructive ? b.error : b.textSecondary;
        border = Border.all(
          color:
              widget.destructive ? b.error.withValues(alpha: 0.35) : b.border,
          width: 1,
        );
      case AppButtonVariant.subtle:
        bgColor = widget.destructive
            ? b.error.withValues(alpha: 0.10)
            : b.primarySubtle;
        fgColor = widget.destructive ? b.error : b.primary;
        border = null;
    }

    final disabled = widget.onPressed == null && !widget.loading;

    return GestureDetector(
      onTapDown: !disabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: !disabled
          ? (_) {
              setState(() => _pressed = false);
              if (!widget.loading) widget.onPressed?.call();
            }
          : null,
      onTapCancel: !disabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.ease,
        child: AnimatedOpacity(
          opacity: disabled ? 0.4 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            height: widget.small ? 40 : 52,
            width: widget.expanded ? double.infinity : null,
            padding: EdgeInsets.symmetric(
              horizontal: widget.expanded ? 20 : 24,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: border,
            ),
            child: Center(
              child: widget.loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: fgColor,
                      ),
                    )
                  : Row(
                      mainAxisSize:
                          widget.expanded ? MainAxisSize.max : MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          widget.icon!,
                          const SizedBox(width: 8),
                        ],
                        if (widget.label != null)
                          Text(
                            widget.label!,
                            style: GoogleFonts.dmSans(
                              fontSize: widget.small ? 13 : 15,
                              fontWeight: FontWeight.w600,
                              color: fgColor,
                              letterSpacing: -0.01 * 15,
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
