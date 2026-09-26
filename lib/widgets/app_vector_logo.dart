import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A clean, modern education technology vector logo for Ethio Concept Center (ECC):
/// - Academic squircle badge with bright royal blue and emerald accents
/// - Clean center emblem with graduation cap & book motif
/// - Ethiopian flag tricolor crest (Green, Yellow, Red)
/// - Crisp branding typography: Ethio Concept Center
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
              width: size * 0.92,
              height: size * 0.92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.20),
                    blurRadius: size * 0.30,
                    spreadRadius: size * 0.02,
                  ),
                ],
              ),
            ),
          ClipOval(
            child: Image.asset(
              'assets/images/app_logo.png',
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => CustomPaint(
                size: Size(size, size),
                painter: _EduSmartXPainter(),
              ),
            ),
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
        SizedBox(height: size * 0.14),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          children: [
            Text(
              'Smart Learn',
              style: GoogleFonts.plusJakartaSans(
                fontSize: size * 0.20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: const Color(0xFF0F172A),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
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
              letterSpacing: 2.0,
              color: const Color(0xFF64748B),
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

    // 1. Royal Blue & Sapphire Academic Squircle
    final RRect squircle = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.05, h * 0.05, w * 0.90, h * 0.90),
      Radius.circular(w * 0.22),
    );

    final Paint hexFill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0284C7),
          Color(0xFF0369A1),
          Color(0xFF075985),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRRect(squircle, hexFill);

    // Shield Border Stroke
    final Paint hexStroke = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF38BDF8),
          Color(0xFF0284C7),
          Color(0xFF6366F1),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.030
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
        ..color = const Color(0xFF38BDF8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.018,
    );

    // White Circle Fill
    canvas.drawCircle(
      circleCenter,
      circleRadius,
      Paint()..color = Colors.white,
    );

    // 4. Academic ECC Star / Open Book Motif
    final Paint bookPaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..style = PaintingStyle.fill;

    // Draw book pages
    final Path bookPath = Path()
      ..moveTo(circleCenter.dx, circleCenter.dy - circleRadius * 0.35)
      ..quadraticBezierTo(circleCenter.dx - circleRadius * 0.35, circleCenter.dy - circleRadius * 0.45, circleCenter.dx - circleRadius * 0.65, circleCenter.dy - circleRadius * 0.30)
      ..lineTo(circleCenter.dx - circleRadius * 0.65, circleCenter.dy + circleRadius * 0.35)
      ..quadraticBezierTo(circleCenter.dx - circleRadius * 0.35, circleCenter.dy + circleRadius * 0.20, circleCenter.dx, circleCenter.dy + circleRadius * 0.35)
      ..quadraticBezierTo(circleCenter.dx + circleRadius * 0.35, circleCenter.dy + circleRadius * 0.20, circleCenter.dx + circleRadius * 0.65, circleCenter.dy + circleRadius * 0.35)
      ..lineTo(circleCenter.dx + circleRadius * 0.65, circleCenter.dy - circleRadius * 0.30)
      ..quadraticBezierTo(circleCenter.dx + circleRadius * 0.35, circleCenter.dy - circleRadius * 0.45, circleCenter.dx, circleCenter.dy - circleRadius * 0.35)
      ..close();
    canvas.drawPath(bookPath, bookPaint);

    // Center Gold Star of Knowledge
    canvas.drawCircle(circleCenter, w * 0.032, Paint()..color = const Color(0xFFFFD100));

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
