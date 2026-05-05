import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class SplitMemberTile extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final bool selected;
  final bool isCurrentUser;
  final bool isEqualMode;
  final double amount;
  final ValueChanged<bool>? onSelected;
  final TextEditingController? amountController;
  final ValueChanged<String>? onAmountChanged;

  const SplitMemberTile({
    super.key,
    required this.name,
    required this.avatarUrl,
    required this.selected,
    required this.isCurrentUser,
    required this.isEqualMode,
    required this.amount,
    required this.onSelected,
    this.amountController,
    this.onAmountChanged,
  });

  String _initials() {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty) return parts.first[0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: b.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: b.border),
      ),
      child: Row(
        children: [
          Checkbox(
            value: selected,
            activeColor: b.primary,
            onChanged: onSelected == null ? null : (value) => onSelected!(value ?? false),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: b.primarySubtle,
            child: Text(
              _initials(),
              style: GoogleFonts.dmSans(
                color: b.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: b.textPrimary,
                        ),
                      ),
                    ),
                    if (isCurrentUser)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: b.primarySubtle,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          'Tú',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: b.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  selected ? 'Incluido en la división' : 'Excluido del split',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: b.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: isEqualMode ? 86 : 110,
            child: isEqualMode
                ? Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      selected ? '\$${amount.toStringAsFixed(2)}' : '\$0.00',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: selected ? b.primary : b.textTertiary,
                      ),
                    ),
                  )
                : TextField(
                    controller: amountController,
                    enabled: selected,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: onAmountChanged,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected ? b.textPrimary : b.textTertiary,
                    ),
                    decoration: InputDecoration(
                      prefixText: '\$',
                      prefixStyle: GoogleFonts.dmSans(
                        color: b.textSecondary,
                        fontSize: 14,
                      ),
                      isDense: true,
                      filled: true,
                      fillColor: b.surfaceAlt,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: b.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: b.border),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: b.border),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
