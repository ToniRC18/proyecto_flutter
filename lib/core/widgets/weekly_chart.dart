import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// WeeklyChart — Basado EXACTAMENTE en WeeklyChart de components.jsx
// 7 barras, barra de hoy en primary, resto en primarySubtle
// Altura total 80px, label de hoy con monto encima
// ═══════════════════════════════════════════════════════════════════════════════

class WeeklyChart extends StatefulWidget {
  final List<double> data; // 7 valores, L-D
  final int? todayIndex;   // null = último elemento

  const WeeklyChart({
    super.key,
    required this.data,
    this.todayIndex,
  });

  @override
  State<WeeklyChart> createState() => _WeeklyChartState();
}

class _WeeklyChartState extends State<WeeklyChart> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    // Retraso para animar las barras al aparecer
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;
    final days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final todayIdx = widget.todayIndex ?? 6;
    final maxVal = widget.data.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 80,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final value = i < widget.data.length ? widget.data[i] : 0.0;
          final pct = maxVal > 0 ? value / maxVal : 0.0;
          final isToday = i == todayIdx;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: i == 0 ? 4 : 3,
                right: i == 6 ? 4 : 3,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Barra con label encima si es hoy
                  Expanded(
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.elasticOut,
                          width: double.infinity,
                          height: _visible
                              ? (pct * 64).clamp(4.0, 64.0)
                              : 4,
                          decoration: BoxDecoration(
                            color: isToday ? b.primary : b.primarySubtle,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        if (isToday && _visible)
                          Positioned(
                            top: 0,
                            child: Text(
                              '\$${(value / 1000).toStringAsFixed(1)}k',
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: b.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Label del día
                  Text(
                    days[i],
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                      color: isToday ? b.primary : b.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
