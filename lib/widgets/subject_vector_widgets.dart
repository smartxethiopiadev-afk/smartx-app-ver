import 'package:flutter/material.dart';

// 1. Mathematics Geometry Vector Widget
class DraftingGeometryWidget extends StatelessWidget {
  const DraftingGeometryWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: 48,
      child: CustomPaint(
        painter: DraftingGeometryPainter(),
      ),
    );
  }
}

class DraftingGeometryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = const Color(0xFF0084FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final Paint fillPaint = Paint()
      ..color = const Color(0xFF0084FF).withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // Draw grid/compass drafting tool representation
    // Protractor base semi-circle
    final center = Offset(size.width * 0.45, size.height * 0.55);
    final rect = Rect.fromCircle(center: center, radius: 14);
    canvas.drawArc(rect, 3.14159, 3.14159, false, linePaint);
    canvas.drawLine(Offset(center.dx - 14, center.dy), Offset(center.dx + 14, center.dy), linePaint);

    // Drafting ruler triangle line representation
    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.85)
      ..lineTo(size.width * 0.85, size.height * 0.85)
      ..lineTo(size.width * 0.6, size.height * 0.25)
      ..close();
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, linePaint);

    // Dynamic compass divider outline
    canvas.drawLine(Offset(size.width * 0.5, size.height * 0.3), Offset(size.width * 0.35, size.height * 0.75), linePaint);
    canvas.drawLine(Offset(size.width * 0.5, size.height * 0.3), Offset(size.width * 0.65, size.height * 0.75), linePaint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.3), 3, Paint()..color = const Color(0xFF0084FF));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 2. Biology Cell Vector Widget
class CellBiologyWidget extends StatelessWidget {
  const CellBiologyWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: 48,
      child: CustomPaint(
        painter: CellBiologyPainter(),
      ),
    );
  }
}

class CellBiologyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2.0;
    final double cy = size.height / 2.0;

    // Main Cell body structure
    final Paint borderPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final Paint backgroundPaint = Paint()
      ..color = const Color(0xFF2E7D32).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    // Drawing organic cell boundary
    final Path cellPath = Path();
    cellPath.moveTo(cx + 18, cy);
    cellPath.quadraticBezierTo(cx + 17, cy + 14, cx + 5, cy + 18);
    cellPath.quadraticBezierTo(cx - 15, cy + 17, cx - 18, cy - 2);
    cellPath.quadraticBezierTo(cx - 14, cy - 18, cx, cy - 18);
    cellPath.quadraticBezierTo(cx + 18, cy - 14, cx + 18, cy);
    cellPath.close();

    canvas.drawPath(cellPath, backgroundPaint);
    canvas.drawPath(cellPath, borderPaint);

    // Drawing nucleus
    final Paint nucleusPaint = Paint()
      ..color = const Color(0xFF2E7D32).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - 3, cy - 2), 6, nucleusPaint);

    // Drawing minor cell organelles / lines
    final Paint organellePaint = Paint()
      ..color = const Color(0xFF1B5E20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(Offset(cx + 6, cy + 6), 2.5, Paint()..color = const Color(0xFF4CAF50));
    canvas.drawCircle(Offset(cx - 8, cy + 8), 2, Paint()..color = const Color(0xFF4CAF50));
    canvas.drawLine(Offset(cx + 8, cy - 6), Offset(cx + 11, cy - 10), organellePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 3. Physics Atom Vector Widget
class AtomPhysicsWidget extends StatelessWidget {
  const AtomPhysicsWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: 48,
      child: CustomPaint(
        painter: AtomPhysicsPainter(),
      ),
    );
  }
}

class AtomPhysicsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2.0;
    final double cy = size.height / 2.0;

    final Paint borderPaint = Paint()
      ..color = const Color(0xFFE53935)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final Paint centerPaint = Paint()
      ..color = const Color(0xFFE53935)
      ..style = PaintingStyle.fill;

    // Draw central nucleus proton
    canvas.drawCircle(Offset(cx, cy), 5, centerPaint);

    // Draw 3 orbiting ring ellipses
    canvas.save();
    canvas.translate(cx, cy);
    
    // Orbit 1
    canvas.rotate(0.0);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 36, height: 11), borderPaint);
    canvas.drawCircle(const Offset(18, 0), 2.5, centerPaint); // electron
    
    // Orbit 2
    canvas.rotate(1.047); // 60 degrees
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 36, height: 11), borderPaint);
    canvas.drawCircle(const Offset(-18, 0), 2.5, centerPaint); // electron

    // Orbit 3
    canvas.rotate(1.047); // 120 degrees
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 36, height: 11), borderPaint);
    canvas.drawCircle(const Offset(0, 5.5), 2.5, centerPaint); // electron

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 4. Chemistry Flask Vector Widget
class ChemistryFlaskWidget extends StatelessWidget {
  const ChemistryFlaskWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: 48,
      child: CustomPaint(
        painter: ChemistryFlaskPainter(),
      ),
    );
  }
}

class ChemistryFlaskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Paint linePaint = Paint()
      ..color = const Color(0xFFEF6C00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final Paint fillPaint = Paint()
      ..color = const Color(0xFFEF6C00).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // Create beaker/flask path
    final flaskPath = Path()
      ..moveTo(w * 0.4, h * 0.18) // neck left
      ..lineTo(w * 0.6, h * 0.18) // neck right
      ..lineTo(w * 0.6, h * 0.38) // neck bottom-right
      ..lineTo(w * 0.85, h * 0.78) // base right
      ..quadraticBezierTo(w * 0.88, h * 0.84, w * 0.8, h * 0.84) // curve bottom-right
      ..lineTo(w * 0.2, h * 0.84) // base left
      ..quadraticBezierTo(w * 0.12, h * 0.84, w * 0.15, h * 0.78) // curve bottom-left
      ..lineTo(w * 0.4, h * 0.38) // neck bottom-left
      ..close();

    canvas.drawPath(flaskPath, fillPaint);
    canvas.drawPath(flaskPath, linePaint);

    // Beaker lip
    canvas.drawLine(Offset(w * 0.35, h * 0.18), Offset(w * 0.65, h * 0.18), linePaint);

    // Beaker orange liquid line inside
    final liquidPath = Path()
      ..moveTo(w * 0.3, h * 0.58)
      ..lineTo(w * 0.7, h * 0.58)
      ..lineTo(w * 0.8, h * 0.78)
      ..quadraticBezierTo(w * 0.82, h * 0.84, w * 0.78, h * 0.84)
      ..lineTo(w * 0.22, h * 0.84)
      ..quadraticBezierTo(w * 0.18, h * 0.84, w * 0.2, h * 0.78)
      ..close();

    canvas.drawPath(liquidPath, Paint()..color = const Color(0xFFFF9800).withValues(alpha: 0.45));

    // Dynamic rising bubbles
    canvas.drawCircle(Offset(w * 0.45, h * 0.66), 2, linePaint);
    canvas.drawCircle(Offset(w * 0.58, h * 0.52), 3, Paint()..color = const Color(0xFFEF6C00));
    canvas.drawCircle(Offset(w * 0.36, h * 0.74), 1.5, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 5. Geography Map Vector Widget
class WorldMapGeographyWidget extends StatelessWidget {
  const WorldMapGeographyWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: 48,
      child: CustomPaint(
        painter: WorldMapGeographyPainter(),
      ),
    );
  }
}

class WorldMapGeographyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2.0;
    final double cy = size.height / 2.0;

    final Paint mapPaint = Paint()..style = PaintingStyle.fill;

    // Draw stylized continents as connected organic shapes
    // Africa-like polygon shape
    final Path africaPath = Path()
      ..moveTo(cx - 4, cy - 8)
      ..lineTo(cx + 8, cy - 10)
      ..lineTo(cx + 10, cy - 2)
      ..lineTo(cx + 4, cy + 6)
      ..lineTo(cx - 1, cy + 12)
      ..lineTo(cx - 3, cy + 6)
      ..lineTo(cx - 8, cy + 2)
      ..lineTo(cx - 6, cy - 4)
      ..close();
    canvas.drawPath(africaPath, mapPaint..color = const Color(0xFF8E24AA).withValues(alpha: 0.85));

    // America-like shapes
    final Path northAmerica = Path()
      ..moveTo(cx - 18, cy - 14)
      ..lineTo(cx - 10, cy - 14)
      ..lineTo(cx - 12, cy - 4)
      ..lineTo(cx - 16, cy + 2)
      ..close();
    canvas.drawPath(northAmerica, mapPaint..color = const Color(0xFF8E24AA).withValues(alpha: 0.4));

    final Path southAmerica = Path()
      ..moveTo(cx - 16, cy + 4)
      ..lineTo(cx - 12, cy + 4)
      ..lineTo(cx - 11, cy + 12)
      ..lineTo(cx - 15, cy + 14)
      ..close();
    canvas.drawPath(southAmerica, mapPaint..color = const Color(0xFF8E24AA).withValues(alpha: 0.6));

    // Asia/Europe shape
    final Path eurasia = Path()
      ..moveTo(cx - 2, cy - 14)
      ..lineTo(cx + 18, cy - 16)
      ..lineTo(cx + 19, cy - 6)
      ..lineTo(cx + 11, cy - 2)
      ..lineTo(cx + 4, cy - 4)
      ..close();
    canvas.drawPath(eurasia, mapPaint..color = const Color(0xFF8E24AA).withValues(alpha: 0.5));

    // Latitude longitude visual grid circle structure
    final Paint gridPaint = Paint()
      ..color = const Color(0xFF8E24AA).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(Offset(cx, cy), 18, gridPaint);
    canvas.drawLine(Offset(cx - 18, cy), Offset(cx + 18, cy), gridPaint); // equator
    canvas.drawLine(Offset(cx, cy - 18), Offset(cx, cy + 18), gridPaint); // meridian
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 6. History Obelisk of Aksum Vector Widget
class AksumObeliskWidget extends StatelessWidget {
  const AksumObeliskWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: 48,
      child: CustomPaint(
        painter: AksumObeliskPainter(),
      ),
    );
  }
}

class AksumObeliskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2.0;
    final double h = size.height;

    final Paint towerPaint = Paint()
      ..color = const Color(0xFFEFAD21)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final Paint fillPaint = Paint()
      ..color = const Color(0xFFEFAD21).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // Draw towering monument shape (wider down, narrower up, with circular decorated apex)
    final Path tower = Path()
      ..moveTo(cx - 6, h * 0.86) // left base
      ..lineTo(cx + 6, h * 0.86) // right base
      ..lineTo(cx + 2.8, h * 0.22) // right top
      ..quadraticBezierTo(cx, h * 0.12, cx - 2.8, h * 0.22) // curved apex
      ..lineTo(cx - 6, h * 0.86) // link closing
      ..close();

    canvas.drawPath(tower, fillPaint);
    canvas.drawPath(tower, towerPaint);

    // Architectural horizontal floor notches/rows
    for (double f = 0.35; f < 0.85; f += 0.14) {
      final double y = h * f;
      final double widthHalf = 6.0 * (1.0 - (f - 0.2) * 0.4);
      canvas.drawLine(Offset(cx - widthHalf, y), Offset(cx + widthHalf, y), towerPaint);
      
      // Little window dot
      canvas.drawCircle(Offset(cx, y - 4), 1.2, Paint()..color = const Color(0xFFEFAD21));
    }

    // Heavy platform slab base
    canvas.drawLine(Offset(cx - 12, h * 0.86), Offset(cx + 12, h * 0.86), towerPaint);
    canvas.drawLine(Offset(cx - 9, h * 0.91), Offset(cx + 9, h * 0.91), towerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 7. Civics Gavel Vector Widget
class CivicsGavelWidget extends StatelessWidget {
  const CivicsGavelWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: 48,
      child: CustomPaint(
        painter: CivicsGavelPainter(),
      ),
    );
  }
}

class CivicsGavelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = const Color(0xFF1E88E5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final Paint fillPaint = Paint()
      ..color = const Color(0xFF1E88E5).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    // Drawing judge block platform
    final Path blockPath = Path()
      ..moveTo(size.width * 0.15, size.height * 0.82)
      ..lineTo(size.width * 0.55, size.height * 0.82)
      ..lineTo(size.width * 0.48, size.height * 0.72)
      ..lineTo(size.width * 0.22, size.height * 0.72)
      ..close();
    canvas.drawPath(blockPath, fillPaint);
    canvas.drawPath(blockPath, linePaint);

    // Drawing Gavel mallet tilted
    canvas.save();
    canvas.translate(size.width * 0.5, size.height * 0.5);
    canvas.rotate(-0.5); // Tilt hammer

    // Gavel Head cylindrical container
    final Rect headRect = Rect.fromCenter(center: const Offset(0, -10), width: 14, height: 24);
    canvas.drawRRect(RRect.fromRectAndRadius(headRect, const Radius.circular(3)), fillPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(headRect, const Radius.circular(3)), linePaint);

    // Mallet Handle stem stick representation
    canvas.drawLine(const Offset(0, 0), const Offset(0, 22), linePaint);
    canvas.drawCircle(const Offset(0, 24), 2.5, Paint()..color = const Color(0xFF1E88E5));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 8. Agriculture Sprout Vector Widget
class AgricultureSproutWidget extends StatelessWidget {
  const AgricultureSproutWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: 48,
      child: CustomPaint(
        painter: AgricultureSproutPainter(),
      ),
    );
  }
}

class AgricultureSproutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2.0;

    final Paint stemPaint = Paint()
      ..color = const Color(0xFF43A047)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final Paint leafPaint = Paint()
      ..color = const Color(0xFF4CAF50).withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;

    // Draw ground level soil line inside seed-brown representation
    final Paint soilPaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(size.width * 0.15, size.height * 0.8), Offset(size.width * 0.85, size.height * 0.8), soilPaint);

    // Draw curved plant stem rising
    final Path stemPath = Path()
      ..moveTo(cx - 3, size.height * 0.8)
      ..quadraticBezierTo(cx - 4, size.height * 0.5, cx + 2, size.height * 0.3);
    canvas.drawPath(stemPath, stemPaint);

    // Leaf 1: Tilted Left
    final Path leafLeft = Path()
      ..moveTo(cx + 1, size.height * 0.44)
      ..quadraticBezierTo(cx - 10, size.height * 0.44, cx - 11, size.height * 0.3)
      ..quadraticBezierTo(cx, size.height * 0.28, cx + 1, size.height * 0.44)
      ..close();
    canvas.drawPath(leafLeft, leafPaint);
    canvas.drawPath(leafLeft, Paint()..color = const Color(0xFF1B5E20)..style = PaintingStyle.stroke..strokeWidth = 1.2);

    // Leaf 2: Tilted Right (Higher Apex)
    final Path leafRight = Path()
      ..moveTo(cx + 2, size.height * 0.32)
      ..quadraticBezierTo(cx + 12, size.height * 0.32, cx + 13, size.height * 0.18)
      ..quadraticBezierTo(cx + 4, size.height * 0.16, cx + 2, size.height * 0.32)
      ..close();
    canvas.drawPath(leafRight, leafPaint);
    canvas.drawPath(leafRight, Paint()..color = const Color(0xFF1B5E20)..style = PaintingStyle.stroke..strokeWidth = 1.2);

    // Stylized seed pod opening on ground
    final Paint seedPaint = Paint()
      ..color = const Color(0xFF795548)
      ..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 6, size.height * 0.78), width: 8, height: 5), seedPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 1, size.height * 0.79), width: 6, height: 4), seedPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 9. Economics Chart Vector Widget
class EconomicsChartWidget extends StatelessWidget {
  const EconomicsChartWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: 48,
      child: CustomPaint(
        painter: EconomicsChartPainter(),
      ),
    );
  }
}

class EconomicsChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Background axis line
    final Paint axisPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Draw X and Y axes
    canvas.drawLine(Offset(w * 0.15, h * 0.85), Offset(w * 0.15, h * 0.15), axisPaint);
    canvas.drawLine(Offset(w * 0.15, h * 0.85), Offset(w * 0.85, h * 0.85), axisPaint);

    // Draw grid lines
    final Paint gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(w * 0.15, h * 0.5), Offset(w * 0.85, h * 0.5), gridPaint);
    canvas.drawLine(Offset(w * 0.5, h * 0.15), Offset(w * 0.5, h * 0.85), gridPaint);

    // Draw Economics Upward Chart Line
    final Paint chartPaint = Paint()
      ..color = const Color(0xFF0F766E) // Economics Theme color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final Path chartPath = Path()
      ..moveTo(w * 0.2, h * 0.75)
      ..quadraticBezierTo(w * 0.45, h * 0.7, w * 0.5, h * 0.45)
      ..quadraticBezierTo(w * 0.55, h * 0.3, w * 0.8, h * 0.25);

    canvas.drawPath(chartPath, chartPaint);

    // Draw little accent node circles at endpoints
    final Paint nodePaint = Paint()
      ..color = const Color(0xFFFF6D00) // Brand Accent Color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(w * 0.2, h * 0.75), 3.0, nodePaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.45), 3.0, nodePaint);
    canvas.drawCircle(Offset(w * 0.8, h * 0.25), 4.0, nodePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 10. English Book Vector Widget
class EnglishBookWidget extends StatelessWidget {
  const EnglishBookWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: 48,
      child: CustomPaint(
        painter: EnglishBookPainter(),
      ),
    );
  }
}

class EnglishBookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Draw Book cover
    final Paint coverPaint = Paint()
      ..color = const Color(0xFF6D28D9)
      ..style = PaintingStyle.fill;
    
    final RRect bookCover = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.18, w * 0.56, h * 0.64),
      const Radius.circular(4),
    );
    canvas.drawRRect(bookCover, coverPaint);

    // Book spine/binding lines
    final Paint spinePaint = Paint()
      ..color = const Color(0xFF4C1D95)
      ..style = PaintingStyle.fill;
    
    final RRect spineCover = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.22, h * 0.18, w * 0.1, h * 0.64),
      topLeft: const Radius.circular(4),
      bottomLeft: const Radius.circular(4),
    );
    canvas.drawRRect(spineCover, spinePaint);

    // Page edges on the right and bottom
    final Paint pagesPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(w * 0.74, h * 0.22, w * 0.04, h * 0.56), pagesPaint);

    // Gold ribbon bookmark or a 'A' letter on the cover
    final Paint bookmarkPaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..style = PaintingStyle.fill;
    
    // Draw an 'A' or elegant gold star on cover
    final Path starPath = Path()
      ..moveTo(w * 0.48, h * 0.38)
      ..lineTo(w * 0.51, h * 0.45)
      ..lineTo(w * 0.58, h * 0.45)
      ..lineTo(w * 0.53, h * 0.5)
      ..lineTo(w * 0.55, h * 0.57)
      ..lineTo(w * 0.48, h * 0.52)
      ..lineTo(w * 0.41, h * 0.57)
      ..lineTo(w * 0.43, h * 0.5)
      ..lineTo(w * 0.38, h * 0.45)
      ..lineTo(w * 0.45, h * 0.45)
      ..close();
    canvas.drawPath(starPath, bookmarkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


