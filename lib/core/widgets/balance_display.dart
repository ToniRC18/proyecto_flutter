import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// BalanceDisplay — Basado en AnimatedNumber de components.jsx
// TweenAnimationBuilder con easeOutCubic, símbolo + parte entera + decimal
// ═══════════════════════════════════════════════════════════════════════════════

class BalanceDisplay extends StatefulWidget {
  final double value;
  final double fontSize;
  final String currency;
  final Color? color;
  final Color? valueColor;
  final Color? symbolColor;
  final FontWeight fontWeight;
  final bool animate;

  const BalanceDisplay({
    super.key,
    required this.value,
    this.fontSize = 40,
    this.currency = 'MXN',
    this.color,
    this.valueColor,
    this.symbolColor,
    this.fontWeight = FontWeight.w700,
    this.animate = true,
  });

  @override
  State<BalanceDisplay> createState() => _BalanceDisplayState();
}

class _BalanceDisplayState extends State<BalanceDisplay> {
  double _oldValue = 0;

  @override
  void didUpdateWidget(BalanceDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _oldValue = oldWidget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final sym = widget.currency == 'EUR' ? '€' : '\$';
    final valueColor = widget.color ?? widget.valueColor ?? b.textPrimary;
    final symbolColor = widget.symbolColor ??
        (widget.color != null ? widget.color! : b.textSecondary);

    if (!widget.animate) {
      return _buildValue(
        value: widget.value,
        valueColor: valueColor,
        symbolColor: symbolColor,
        sym: sym,
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _oldValue, end: widget.value),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, val, _) => _buildValue(
        value: val,
        valueColor: valueColor,
        symbolColor: symbolColor,
        sym: sym,
      ),
    );
  }

  Widget _buildValue({
    required double value,
    required Color valueColor,
    required Color symbolColor,
    required String sym,
  }) {
    final absVal = value.abs();
    final intPart = absVal.truncate();
    final intStr = _formatWithCommas(intPart);
    final decPart =
        ((absVal - intPart) * 100).round().toString().padLeft(2, '0');

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: widget.fontSize * 0.08),
          child: Text(
            sym,
            style: GoogleFonts.dmSans(
              fontSize: widget.fontSize * 0.45,
              fontWeight: FontWeight.w400,
              color: symbolColor,
              height: 1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: intStr,
                style: GoogleFonts.dmSans(
                  fontSize: widget.fontSize,
                  fontWeight: widget.fontWeight,
                  color: valueColor,
                  height: 1,
                  letterSpacing: -0.03 * widget.fontSize,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              TextSpan(
                text: '.$decPart',
                style: GoogleFonts.dmSans(
                  fontSize: widget.fontSize * 0.5,
                  fontWeight: FontWeight.w500,
                  color: valueColor.withValues(alpha: 0.6),
                  height: 1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Formatea un entero con comas como separador de miles (estilo MX)
  String _formatWithCommas(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write(',');
      }
    }
    return buffer.toString().split('').reversed.join();
  }
}
