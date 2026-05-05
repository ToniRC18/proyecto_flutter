import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// AppInputField — Basado EXACTAMENTE en InputField de components.jsx
// Focus: fillColor → primarySubtle, border → primary 1.5px
// Error: texto 12sp error color debajo del campo
// ═══════════════════════════════════════════════════════════════════════════════

class AppInputField extends StatefulWidget {
  final String label;
  final TextEditingController? controller;
  final String? errorText;
  final String? prefix;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final String? hintText;

  const AppInputField({
    super.key,
    required this.label,
    this.controller,
    this.errorText,
    this.prefix,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.autofocus = false,
    this.onChanged,
    this.hintText,
  });

  @override
  State<AppInputField> createState() => _AppInputFieldState();
}

class _AppInputFieldState extends State<AppInputField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          widget.label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _focused ? b.primary : b.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        // Campo
        Focus(
          onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
          child: TextField(
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText,
            autofocus: widget.autofocus,
            onChanged: widget.onChanged,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: b.textPrimary,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: _focused ? b.primarySubtle : b.surfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: b.border, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: b.primary, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              prefixText: widget.prefix,
              prefixStyle: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: b.textSecondary,
              ),
              hintText: widget.hintText,
              hintStyle: GoogleFonts.dmSans(
                fontSize: 15,
                color: b.textTertiary,
              ),
            ),
          ),
        ),
        // Error
        if (widget.errorText != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              widget.errorText!,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: b.error,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
