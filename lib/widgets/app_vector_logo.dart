import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A clean, modern education technology vector logo for Smart X Ethiopian:
/// - Hexagonal futuristic wisdom emblem with royal midnight navy & cyan neon gradients
/// - Ethiopian flag tricolor crest (Green, Yellow, Red) at top
/// - Central geometric 'X' mark with radiant knowledge diamond
/// - Crisp typography: Smart X Ethiopian
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
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          children: [
            Text(
              'Smart',
              style: GoogleFonts.plusJakartaSans(
                fontSize: size * 0.26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: Colors.white,
              ),
            ),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF00F0FF), Color(0xFF38BDF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                'X',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: size * 0.30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF009A44), Color(0xFFD97706), Color(0xFFEF3340)],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Ethiopian',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: size * 0.18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ),
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
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(hexPath, hexStroke);

    // 2. Ethiopian Flag Top Accent Pill (Green, Yellow, Red)
    final double flagW = w * 0.44;
    final double flagH = h * 0.045;
    final double flagY = h * 0.18;
    final double flagLeft = center.dx - flagW / 2;

    final RRect greenPill = RRect.fromRectAndCorners(
      Rect.fromLTWH(flagLeft, flagY, flagW / 3, flagH),
      topLeft: const Radius.circular(4),
      bottomLeft: const Radius.circular(4),
    );
    final RRect yellowPill = RRect.fromRectAndCorners(
      Rect.fromLTWH(flagLeft + flagW / 3, flagY, flagW / 3, flagH),
    );
    final RRect redPill = RRect.fromRectAndCorners(
      Rect.fromLTWH(flagLeft + 2 * flagW / 3, flagY, flagW / 3, flagH),
      topRight: const Radius.circular(4),
      bottomRight: const Radius.circular(4),
    );

    canvas.drawRRect(greenPill, Paint()..color = const Color(0xFF009A44));
    canvas.drawRRect(yellowPill, Paint()..color = const Color(0xFFFFD100));
    canvas.drawRRect(redPill, Paint()..color = const Color(0xFFEF3340));

    // Academic Gold Diamond Sparkle
    final Path diamond = Path()
      ..moveTo(center.dx, h * 0.28)
      ..lineTo(center.dx + w * 0.05, h * 0.33)
      ..lineTo(center.dx, h * 0.38)
      ..lineTo(center.dx - w * 0.05, h * 0.33)
      ..close();
    canvas.drawPath(diamond, Paint()..color = const Color(0xFFFFD100));

    // 3. Central Geometric 'X' Ribbons
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

    // 4. Central Radiant Knowledge Spark
    final Path coreDiamond = Path()
      ..moveTo(center.dx, center.dy - h * 0.07)
      ..lineTo(center.dx + w * 0.07, center.dy)
      ..lineTo(center.dx, center.dy + h * 0.07)
      ..lineTo(center.dx - w * 0.07, center.dy)
      ..close();

    canvas.drawPath(coreDiamond, Paint()..color = Colors.white);

    // 5. Bottom Ethiopian Accent Underline
    final Path underline = Path()
      ..moveTo(w * 0.30, h * 0.78)
      ..lineTo(w * 0.70, h * 0.78);
    canvas.drawPath(
      underline,
      Paint()
        ..color = const Color(0xFFFFD100)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.02
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
