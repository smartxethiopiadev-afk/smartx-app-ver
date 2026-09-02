import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A clean, modern education technology vector logo for Smart X Ethiopian:
/// - Hexagonal/squircle midnight navy shield
/// - Bright clean white center circle badge
/// - Prominent big electric cyan 'X' mark
/// - Ethiopian flag tricolor crest (Green, Yellow, Red)
/// - Crisp branding typography: Smart X Ethiopian
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

    // 1. Dark Midnight Blue Shield Canvas
    final RRect squircle = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.05, h * 0.05, w * 0.90, h * 0.90),
      Radius.circular(w * 0.22),
    );

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
    canvas.drawRRect(squircle, hexFill);

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
    canvas.drawRRect(squircle, hexStroke);

    // 2. Ethiopian Flag Top Accent Pill (Green, Yellow, Red)
    final double flagW = w * 0.44;
    final double flagH = h * 0.045;
    final double flagY = h * 0.14;
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

    // 3. Bright White Center Circle Badge
    final Offset circleCenter = Offset(center.dx, center.dy - h * 0.02);
    final double circleRadius = w * 0.27;

    // Cyan Outer Ring
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

    // White Circle Fill
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
      ..strokeWidth = w * 0.11 // Prominent & Big!
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

    // 5. Bottom Ethiopian Accent Underline
    final Path underline = Path()
      ..moveTo(w * 0.30, h * 0.82)
      ..lineTo(w * 0.70, h * 0.82);
    canvas.drawPath(
      underline,
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
