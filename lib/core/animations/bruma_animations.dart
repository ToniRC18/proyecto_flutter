import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// BRUMA — Animaciones reutilizables
// Basado en fadeUp + stagger de Bruma.html / components.jsx
// ═══════════════════════════════════════════════════════════════════════════════

/// Widget que aplica fade + slide-up con delay configurable (para stagger)
class FadeUpAnimation extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final int durationMs;
  final double offsetY;

  const FadeUpAnimation({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.durationMs = 400,
    this.offsetY = 0.04,
  });

  @override
  State<FadeUpAnimation> createState() => _FadeUpAnimationState();
}

class _FadeUpAnimationState extends State<FadeUpAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    );

    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _opacity = Tween<double>(begin: 0, end: 1).animate(curve);
    _offset = Tween<Offset>(
      begin: Offset(0, widget.offsetY),
      end: Offset.zero,
    ).animate(curve);

    // Delay para stagger
    if (widget.delayMs > 0) {
      Future.delayed(Duration(milliseconds: widget.delayMs), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: widget.child,
      ),
    );
  }
}

/// Widget para animar la escala al presionar (tap scale)
class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final int durationMs;

  const TapScale({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.97,
    this.durationMs = 120,
  });

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.onTap != null
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap!();
            }
          : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? widget.scaleDown : 1.0,
        duration: Duration(milliseconds: widget.durationMs),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
