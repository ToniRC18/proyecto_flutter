import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

enum BrumaEmptyType {
  transactions,
  pockets,
  bills,
  budgets,
  stats,
  sharedSpaces,
  search,
}

class BrumaEmptyState extends StatelessWidget {
  final BrumaEmptyType type;
  final String title;
  final String? subtitle;
  final Widget? action;

  const BrumaEmptyState({
    super.key,
    required this.type,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: CustomPaint(
            painter: _BrumaEmptyPainter(
              type: type,
              primary: b.primary,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: b.textPrimary,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: b.textSecondary,
            ),
          ),
        ],
        if (action != null) ...[
          const SizedBox(height: 20),
          action!,
        ],
      ],
    );
  }
}

class _BrumaEmptyPainter extends CustomPainter {
  final BrumaEmptyType type;
  final Color primary;

  const _BrumaEmptyPainter({
    required this.type,
    required this.primary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = primary.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = primary.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      fillPaint,
    );

    switch (type) {
      case BrumaEmptyType.transactions:
        _drawTransactions(canvas, size, strokePaint);
        break;
      case BrumaEmptyType.pockets:
        _drawPockets(canvas, size, strokePaint);
        break;
      case BrumaEmptyType.bills:
        _drawBills(canvas, size, strokePaint);
        break;
      case BrumaEmptyType.budgets:
        _drawBudgets(canvas, size, strokePaint);
        break;
      case BrumaEmptyType.stats:
        _drawStats(canvas, size, strokePaint);
        break;
      case BrumaEmptyType.sharedSpaces:
        _drawSharedSpaces(canvas, size, strokePaint);
        break;
      case BrumaEmptyType.search:
        _drawSearch(canvas, size, strokePaint);
        break;
    }
  }

  void _drawTransactions(Canvas canvas, Size size, Paint paint) {
    final rect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(34, 24, 52, 70),
      const Radius.circular(12),
    );
    canvas.drawRRect(rect, paint);
    canvas.drawLine(const Offset(46, 42), const Offset(74, 42), paint);
    canvas.drawLine(const Offset(46, 53), const Offset(74, 53), paint);
    canvas.drawLine(const Offset(46, 64), const Offset(68, 64), paint);
    final dollar = TextPainter(
      text: TextSpan(
        text: '\$',
        style: TextStyle(
          color: paint.color,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    dollar.paint(canvas, const Offset(52, 12));
  }

  void _drawPockets(Canvas canvas, Size size, Paint paint) {
    canvas.drawCircle(const Offset(60, 64), 26, paint);
    canvas.drawLine(const Offset(42, 50), const Offset(78, 50), paint);
    canvas.drawLine(const Offset(52, 64), const Offset(68, 64), paint);
    canvas.drawLine(const Offset(60, 28), const Offset(60, 40), paint);
    canvas.drawCircle(const Offset(60, 22), 7, paint);
  }

  void _drawBills(Canvas canvas, Size size, Paint paint) {
    final rect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(30, 28, 60, 56),
      const Radius.circular(12),
    );
    canvas.drawRRect(rect, paint);
    canvas.drawLine(const Offset(30, 44), const Offset(90, 44), paint);
    canvas.drawLine(const Offset(44, 20), const Offset(44, 34), paint);
    canvas.drawLine(const Offset(76, 20), const Offset(76, 34), paint);
    final path = Path()
      ..moveTo(46, 61)
      ..lineTo(56, 71)
      ..lineTo(74, 53);
    canvas.drawPath(path, paint);
  }

  void _drawBudgets(Canvas canvas, Size size, Paint paint) {
    canvas.drawLine(const Offset(34, 84), const Offset(88, 84), paint);
    canvas.drawRect(const Rect.fromLTWH(40, 62, 8, 22), paint);
    canvas.drawRect(const Rect.fromLTWH(56, 52, 8, 32), paint);
    canvas.drawRect(const Rect.fromLTWH(72, 42, 8, 42), paint);
    final arrow = Path()
      ..moveTo(38, 56)
      ..lineTo(56, 42)
      ..lineTo(68, 48)
      ..lineTo(82, 32);
    canvas.drawPath(arrow, paint);
    canvas.drawLine(const Offset(82, 32), const Offset(80, 42), paint);
    canvas.drawLine(const Offset(82, 32), const Offset(72, 34), paint);
  }

  void _drawStats(Canvas canvas, Size size, Paint paint) {
    final path = Path()
      ..moveTo(28, 72)
      ..cubicTo(40, 52, 52, 58, 60, 44)
      ..cubicTo(68, 32, 82, 38, 92, 24);
    canvas.drawPath(path, paint);
    for (final point in const [
      Offset(28, 72),
      Offset(45, 57),
      Offset(60, 44),
      Offset(78, 40),
      Offset(92, 24),
    ]) {
      canvas.drawCircle(point, 3.5, paint);
    }
  }

  void _drawSharedSpaces(Canvas canvas, Size size, Paint paint) {
    canvas.drawCircle(const Offset(50, 60), 20, paint);
    canvas.drawCircle(const Offset(70, 60), 20, paint);
  }

  void _drawSearch(Canvas canvas, Size size, Paint paint) {
    canvas.drawCircle(const Offset(54, 54), 22, paint);
    canvas.drawLine(const Offset(69, 69), const Offset(86, 86), paint);
    final question = TextPainter(
      text: TextSpan(
        text: '?',
        style: TextStyle(
          color: paint.color,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    question.paint(canvas, const Offset(49, 40));
  }

  @override
  bool shouldRepaint(covariant _BrumaEmptyPainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.primary != primary;
  }
}
