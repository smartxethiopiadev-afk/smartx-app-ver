import 'package:flutter/material.dart';

/// A pure vector education emblem widget for Smart X Ethiopian.
/// Renders an academic shield of wisdom, open book of knowledge,
/// growth sprout, and a golden glowing light bulb featuring the central 'X'.
class SmartXVectorLogo extends StatelessWidget {
  final double size;
  final bool showGlow;
  final bool showBorder;

  const SmartXVectorLogo({
    super.key,
    this.size = 100,
    this.showGlow = true,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showGlow)
            Container(
              width: size * 0.85,
              height: size * 0.85,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D2FF).withValues(alpha: 0.35),
                    blurRadius: size * 0.35,
                    spreadRadius: size * 0.05,
                  ),
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                    blurRadius: size * 0.18,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          CustomPaint(
            size: Size(size * 0.95, size * 0.95),
            painter: SmartXVectorPainter(showBorder: showBorder),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the Smart X education vector emblem
class SmartXVectorPainter extends CustomPainter {
  final bool showBorder;

  SmartXVectorPainter({this.showBorder = true});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 1. Shield Path
    final Path shieldPath = Path();
    shieldPath.moveTo(w * 0.20, h * 0.16);
    shieldPath.lineTo(w * 0.80, h * 0.16);
    shieldPath.cubicTo(
      w * 0.84, h * 0.46,
      w * 0.72, h * 0.76,
      w * 0.50, h * 0.90,
    );
    shieldPath.cubicTo(
      w * 0.28, h * 0.76,
      w * 0.16, h * 0.46,
      w * 0.20, h * 0.16,
    );
    shieldPath.close();

    // Shield Background Fill
    final Paint shieldBg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0E2246),
          Color(0xFF07142A),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(shieldPath, shieldBg);

    // Shield Border Stroke
    if (showBorder) {
      final Paint shieldBorder = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF00F0FF),
            Color(0xFF0072FF),
            Color(0xFF00E5FF),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h))
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.028
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(shieldPath, shieldBorder);
    }

    // 2. Open Book at base
    final Path leftPage = Path()
      ..moveTo(w * 0.50, h * 0.73)
      ..cubicTo(w * 0.42, h * 0.70, w * 0.32, h * 0.72, w * 0.26, h * 0.77)
      ..lineTo(w * 0.26, h * 0.83)
      ..cubicTo(w * 0.33, h * 0.78, w * 0.42, h * 0.77, w * 0.50, h * 0.80)
      ..close();

    final Path rightPage = Path()
      ..moveTo(w * 0.50, h * 0.73)
      ..cubicTo(w * 0.58, h * 0.70, w * 0.68, h * 0.72, w * 0.74, h * 0.77)
      ..lineTo(w * 0.74, h * 0.83)
      ..cubicTo(w * 0.67, h * 0.78, w * 0.58, h * 0.77, w * 0.50, h * 0.80)
      ..close();

    final Paint bookPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF38BDF8),
          Color(0xFF0284C7),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(leftPage, bookPaint);
    canvas.drawPath(rightPage, bookPaint);

    final Paint bookBorder = Paint()
      ..color = const Color(0xFFE0F2FE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.012;
    canvas.drawPath(leftPage, bookBorder);
    canvas.drawPath(rightPage, bookBorder);

    // 3. Green Growth Sprout Leaves
    final Paint leafPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF4ADE80), Color(0xFF16A34A)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final Path leftLeaf = Path()
      ..moveTo(w * 0.48, h * 0.66)
      ..cubicTo(w * 0.38, h * 0.62, w * 0.36, h * 0.53, w * 0.42, h * 0.48)
      ..cubicTo(w * 0.48, h * 0.54, w * 0.46, h * 0.62, w * 0.48, h * 0.66)
      ..close();

    final Path rightLeaf = Path()
      ..moveTo(w * 0.52, h * 0.66)
      ..cubicTo(w * 0.62, h * 0.62, w * 0.64, h * 0.53, w * 0.58, h * 0.48)
      ..cubicTo(w * 0.52, h * 0.54, w * 0.54, h * 0.62, w * 0.52, h * 0.66)
      ..close();

    canvas.drawPath(leftLeaf, leafPaint);
    canvas.drawPath(rightLeaf, leafPaint);

    // 4. Glowing Golden Lightbulb / Idea Core
    final Offset bulbCenter = Offset(w * 0.50, h * 0.42);
    final double bulbRadius = w * 0.17;

    final Paint auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFBBF24).withValues(alpha: 0.45),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: bulbCenter, radius: bulbRadius * 1.5));
    canvas.drawCircle(bulbCenter, bulbRadius * 1.5, auraPaint);

    final Paint bulbPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFEF08A),
          Color(0xFFF59E0B),
          Color(0xFFD97706),
        ],
      ).createShader(Rect.fromCircle(center: bulbCenter, radius: bulbRadius));
    canvas.drawCircle(bulbCenter, bulbRadius, bulbPaint);

    final Paint bulbOutline = Paint()
      ..color = const Color(0xFFFFFBEB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.016;
    canvas.drawCircle(bulbCenter, bulbRadius, bulbOutline);

    // 5. Central 'X' glyph inside the glowing bulb
    final Paint xPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.032
      ..strokeCap = StrokeCap.round;

    final double xOffset = bulbRadius * 0.45;
    canvas.drawLine(
      Offset(bulbCenter.dx - xOffset, bulbCenter.dy - xOffset),
      Offset(bulbCenter.dx + xOffset, bulbCenter.dy + xOffset),
      xPaint,
    );
    canvas.drawLine(
      Offset(bulbCenter.dx + xOffset, bulbCenter.dy - xOffset),
      Offset(bulbCenter.dx - xOffset, bulbCenter.dy + xOffset),
      xPaint,
    );

    // Inner bright spark on the X
    final Paint sparkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.012
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(bulbCenter.dx - xOffset * 0.7, bulbCenter.dy - xOffset * 0.7),
      Offset(bulbCenter.dx + xOffset * 0.7, bulbCenter.dy + xOffset * 0.7),
      sparkPaint,
    );
    canvas.drawLine(
      Offset(bulbCenter.dx + xOffset * 0.7, bulbCenter.dy - xOffset * 0.7),
      Offset(bulbCenter.dx - xOffset * 0.7, bulbCenter.dy + xOffset * 0.7),
      sparkPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
