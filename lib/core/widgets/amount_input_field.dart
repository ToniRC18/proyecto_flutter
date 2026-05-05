import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class MoneyInputFormatter extends TextInputFormatter {
  const MoneyInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = AmountInputField.formatAmount(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class AmountInputField extends StatefulWidget {
  final TextEditingController controller;
  final bool autofocus;
  final Color? amountColor;

  const AmountInputField({
    super.key,
    required this.controller,
    this.autofocus = true,
    this.amountColor,
  });

  static double parseAmount(String formatted) {
    final digits = formatted.replaceAll(RegExp(r'[^0-9]'), '');
    final cents = int.tryParse(digits) ?? 0;
    return cents / 100.0;
  }

  static String formatAmount(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    final capped =
        digits.length > 9 ? digits.substring(digits.length - 9) : digits;
    final cents = int.tryParse(capped) ?? 0;
    final pesos = cents ~/ 100;
    final centavos = cents % 100;
    final pesosStr = _formatThousands(pesos);
    return '\$$pesosStr.${centavos.toString().padLeft(2, '0')}';
  }

  static String _formatThousands(int n) {
    if (n < 1000) return n.toString();
    final s = n.toString();
    final result = StringBuffer();
    final offset = s.length % 3;

    for (var i = 0; i < s.length; i++) {
      if (i != 0 && (i - offset) % 3 == 0) {
        result.write(',');
      }
      result.write(s[i]);
    }

    return result.toString();
  }

  @override
  State<AmountInputField> createState() => _AmountInputFieldState();
}

class _AmountInputFieldState extends State<AmountInputField> {
  late final FocusNode _focusNode;
  bool _isSyncingController = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
    _focusNode = FocusNode()
      ..addListener(() {
        if (_isFocused == _focusNode.hasFocus) return;
        setState(() => _isFocused = _focusNode.hasFocus);
      });
    _normalizeControllerText(force: true);
  }

  @override
  void didUpdateWidget(covariant AmountInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;

    oldWidget.controller.removeListener(_handleControllerChanged);
    widget.controller.addListener(_handleControllerChanged);
    _normalizeControllerText(force: true);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (_isSyncingController) return;
    _normalizeControllerText();
  }

  void _normalizeControllerText({bool force = false}) {
    final formatted = AmountInputField.formatAmount(widget.controller.text);
    if (!force && widget.controller.text == formatted) return;

    _isSyncingController = true;
    widget.controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    _isSyncingController = false;
  }

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final fillColor = _isFocused ? b.primarySubtle : b.surfaceAlt;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: const TextInputType.numberWithOptions(decimal: false),
        inputFormatters: const [MoneyInputFormatter()],
        textAlign: TextAlign.center,
        autofocus: widget.autofocus,
        style: GoogleFonts.dmSans(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: widget.amountColor ?? b.textPrimary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: fillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 16,
          ),
        ),
      ),
    );
  }
}
