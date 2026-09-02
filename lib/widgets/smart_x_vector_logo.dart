import 'package:flutter/material.dart';

/// A pure vector emblem widget for Smart X Ethiopian.
/// Features a dark midnight blue squircle badge, a bright white center circle,
/// a prominent big 'X' mark in electric cyan/blue, and Ethiopian tricolor accent (Green, Yellow, Red).
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

/// Custom painter for the Smart X Ethiopian vector emblem
class SmartXVectorPainter extends CustomPainter {
  final bool showBorder;

  SmartXVectorPainter({this.showBorder = true});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Offset center = Offset(w / 2, h / 2);

    // 1. Dark Blue Squircle Outer Shield
    final RRect squircle = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.05, h * 0.05, w * 0.90, h * 0.90),
      Radius.circular(w * 0.22),
    );

    final Paint squircleBg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0E2246), Color(0xFF07142A)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRRect(squircle, squircleBg);

    if (showBorder) {
      final Paint squircleBorder = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF00F0FF), Color(0xFF0072FF)],
        ).createShader(Rect.fromLTWH(0, 0, w, h))
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.03;
      canvas.drawRRect(squircle, squircleBorder);
    }

    // 2. Ethiopian Flag Top Accent Bar (Green, Yellow, Red)
    final double flagW = w * 0.50;
    final double flagH = h * 0.05;
    final double flagY = h * 0.14;
    final double flagLeft = center.dx - flagW / 2;

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(flagLeft, flagY, flagW / 3, flagH),
        topLeft: const Radius.circular(3),
        bottomLeft: const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF009A44),
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(flagLeft + flagW / 3, flagY, flagW / 3, flagH),
      ),
      Paint()..color = const Color(0xFFFFD100),
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(flagLeft + 2 * flagW / 3, flagY, flagW / 3, flagH),
        topRight: const Radius.circular(3),
        bottomRight: const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFEF3340),
    );

    // 3. Bright White Center Circle Badge
    final Offset circleCenter = Offset(center.dx, center.dy - h * 0.02);
    final double circleRadius = w * 0.27;

    // Outer Cyan Glow Ring around White Circle
    canvas.drawCircle(
      circleCenter,
      circleRadius + w * 0.02,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF00F0FF), Color(0xFF38BDF8)],
        ).createShader(Rect.fromLTWH(0, 0, w, h))
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.02,
    );

    // White Fill
    canvas.drawCircle(
      circleCenter,
      circleRadius,
      Paint()..color = Colors.white,
    );

    // 4. PROMINENT BIG 'X' MARK INSIDE THE WHITE CIRCLE
    final Paint xPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF00B4FF), Color(0xFF3B82F6), Color(0xFF6366F1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.11 // Bold & Big!
      ..strokeCap = StrokeCap.round;

    final double xSize = circleRadius * 0.68;
    canvas.drawLine(
      Offset(circleCenter.dx - xSize, circleCenter.dy - xSize * 0.9),
      Offset(circleCenter.dx + xSize, circleCenter.dy + xSize * 0.9),
      xPaint,
    );
    canvas.drawLine(
      Offset(circleCenter.dx + xSize, circleCenter.dy - xSize * 0.9),
      Offset(circleCenter.dx - xSize, circleCenter.dy + xSize * 0.9),
      xPaint,
    );

    // Center Gold Sparkle Point
    canvas.drawCircle(circleCenter, w * 0.035, Paint()..color = const Color(0xFFFFD100));

    // Bottom Underline Accent
    canvas.drawLine(
      Offset(w * 0.30, h * 0.82),
      Offset(w * 0.70, h * 0.82),
      Paint()
        ..color = const Color(0xFFFFD100)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.022
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
