import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A modern, sophisticated education technology vector logo for Smart X Ethiopian:
/// - Hexagonal futuristic wisdom emblem with royal indigo & cyan neon gradients
/// - Graduation Cap / Academic Diamond Crest at top
/// - Intersecting luminous 'X' intelligence ribbons
/// - Open wings / book leaves at base representing growth and scholarship
class AppVectorLogo extends StatelessWidget {
  final double size;
  final bool showGlow;
  final bool showText;
  final String? subtitle;

  const AppVectorLogo({
    super.key,
    this.size = 110,
    this.showGlow = true,
    this.showText = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    Widget emblem = SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showGlow)
            Container(
              width: size * 0.88,
              height: size * 0.88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.28),
                    blurRadius: size * 0.36,
                    spreadRadius: size * 0.04,
                  ),
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                    blurRadius: size * 0.22,
                  ),
                ],
              ),
            ),
          CustomPaint(
            size: Size(size, size),
            painter: _EduSmartXPainter(),
          ),
        ],
      ),
    );

    if (!showText) {
      return emblem;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        emblem,
        SizedBox(height: size * 0.16),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'Smart ',
              style: GoogleFonts.plusJakartaSans(
                fontSize: size * 0.28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: Colors.white,
              ),
            ),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF00F0FF), Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                'X',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: size * 0.32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              ' Ethiopian',
              style: GoogleFonts.plusJakartaSans(
                fontSize: size * 0.28,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: Colors.white,
              ),
            ),
          ],
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          SizedBox(height: size * 0.05),
          Text(
            subtitle!,
            style: GoogleFonts.plusJakartaSans(
              fontSize: size * 0.10,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.5,
              color: const Color(0xFF94A3B8).withValues(alpha: 0.85),
            ),
          ),
        ],
      ],
    );
  }
}

class _EduSmartXPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Offset center = Offset(w / 2, h / 2);
    final double radius = w * 0.44;

    // 1. Futuristic Rounded Hexagon Shield Canvas
    final Path hexPath = Path();
    for (int i = 0; i < 6; i++) {
      final double angle = (i * 60 - 30) * math.pi / 180;
      final double px = center.dx + radius * math.cos(angle);
      final double py = center.dy + radius * math.sin(angle);
      if (i == 0) {
        hexPath.moveTo(px, py);
      } else {
        hexPath.lineTo(px, py);
      }
    }
    hexPath.close();

    // Shield Deep Midnight Sapphire Fill
    final Paint hexFill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0D1B2A),
          Color(0xFF1B263B),
          Color(0xFF0F172A),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(hexPath, hexFill);

    // Shield Border Stroke with Neon Cyan to Indigo
    final Paint hexStroke = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF00F0FF),
          Color(0xFF38BDF8),
          Color(0xFF6366F1),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.032
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(hexPath, hexStroke);

    // 2. Academic Graduation Cap Crest at Top
    final Path mortarBoard = Path()
      ..moveTo(center.dx, h * 0.20)
      ..lineTo(w * 0.72, h * 0.30)
      ..lineTo(center.dx, h * 0.40)
      ..lineTo(w * 0.28, h * 0.30)
      ..close();

    final Paint capPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF38BDF8),
          Color(0xFF0284C7),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(mortarBoard, capPaint);

    final Paint capOutline = Paint()
      ..color = const Color(0xFFE0F2FE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.016
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(mortarBoard, capOutline);

    // Cap Tassel cord and bead
    final Path tassel = Path()
      ..moveTo(center.dx, h * 0.30)
      ..quadraticBezierTo(w * 0.74, h * 0.32, w * 0.75, h * 0.44);

    final Paint tasselPaint = Paint()
      ..color = const Color(0xFFFFD200)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.018
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(tassel, tasselPaint);

    canvas.drawCircle(Offset(w * 0.75, h * 0.45), w * 0.024, Paint()..color = const Color(0xFFFFD200));

    // 3. Open Book of Knowledge Leaves at Bottom
    final Path leftLeaf = Path()
      ..moveTo(center.dx, h * 0.72)
      ..cubicTo(w * 0.40, h * 0.70, w * 0.30, h * 0.74, w * 0.24, h * 0.81)
      ..cubicTo(w * 0.32, h * 0.73, w * 0.42, h * 0.77, center.dx, h * 0.81)
      ..close();

    final Path rightLeaf = Path()
      ..moveTo(center.dx, h * 0.72)
      ..cubicTo(w * 0.60, h * 0.70, w * 0.70, h * 0.74, w * 0.76, h * 0.81)
      ..cubicTo(w * 0.68, h * 0.73, w * 0.58, h * 0.77, center.dx, h * 0.81)
      ..close();

    final Paint bookFill = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF00E5FF), Color(0xFF0284C7)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(leftLeaf, bookFill);
    canvas.drawPath(rightLeaf, bookFill);

    // 4. Central Geometric 'X' Intelligence Core Ribbons
    // Blade 1: Top-Left to Bottom-Right
    final Path blade1 = Path()
      ..moveTo(w * 0.34, h * 0.42)
      ..lineTo(w * 0.44, h * 0.39)
      ..lineTo(w * 0.66, h * 0.67)
      ..lineTo(w * 0.56, h * 0.70)
      ..close();

    final Paint blade1Paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF00F0FF), Color(0xFF6366F1)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(blade1, blade1Paint);

    // Blade 2: Top-Right to Bottom-Left
    final Path blade2 = Path()
      ..moveTo(w * 0.66, h * 0.42)
      ..lineTo(w * 0.56, h * 0.39)
      ..lineTo(w * 0.34, h * 0.67)
      ..lineTo(w * 0.44, h * 0.70)
      ..close();

    final Paint blade2Paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFF818CF8), Color(0xFF0284C7)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(blade2, blade2Paint);

    // 5. Central Radiant Knowledge Spark / Diamond Core
    final Path coreDiamond = Path()
      ..moveTo(center.dx, center.dy - h * 0.08)
      ..lineTo(center.dx + w * 0.08, center.dy)
      ..lineTo(center.dx, center.dy + h * 0.08)
      ..lineTo(center.dx - w * 0.08, center.dy)
      ..close();

    final Paint corePaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFF00F0FF),
          Color(0xFF4F46E5),
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: w * 0.09));
    canvas.drawPath(coreDiamond, corePaint);

    final Paint coreStroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.014;
    canvas.drawPath(coreDiamond, coreStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
