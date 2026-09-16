import 'package:flutter/material.dart';

class AcademicProgressCharts extends StatefulWidget {
  final bool isDarkMode;
  final String languageCode;
  final int currentGrade;

  const AcademicProgressCharts({
    super.key,
    required this.isDarkMode,
    required this.languageCode,
    this.currentGrade = 12,
  });

  @override
  State<AcademicProgressCharts> createState() => _AcademicProgressChartsState();
}

class _AcademicProgressChartsState extends State<AcademicProgressCharts>
    with SingleTickerProviderStateMixin {
  int _selectedChartTab = 0; // 0: Weekly Velocity, 1: Subject Mastery, 2: Quiz Trends
  late AnimationController _animController;
  late Animation<double> _chartAnimation;

  final List<double> _weeklyHours = const [2.5, 3.8, 4.2, 3.0, 5.5, 6.0, 4.8];
  final List<String> _weekDaysEn = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> _weekDaysAm = const ['ሰኞ', 'ማክሰኞ', 'ረቡዕ', 'ሐሙስ', 'አርብ', 'ቅዳሜ', 'እሑድ'];

  final List<Map<String, dynamic>> _subjectScores = const [
    {'name': 'Mathematics', 'amName': 'ሒሳብ', 'score': 0.92, 'color': Color(0xFF3B82F6), 'units': '5/6'},
    {'name': 'Physics', 'amName': 'ፊዚክስ', 'score': 0.86, 'color': Color(0xFF8B5CF6), 'units': '4/5'},
    {'name': 'Chemistry', 'amName': 'ኬሚስትሪ', 'score': 0.79, 'color': Color(0xFFEC4899), 'units': '3/4'},
    {'name': 'Biology', 'amName': 'ባዮሎጂ', 'score': 0.88, 'color': Color(0xFF10B981), 'units': '4/5'},
    {'name': 'Civics', 'amName': 'ስነ-ዜጋ', 'score': 0.94, 'color': Color(0xFFF59E0B), 'units': '5/5'},
    {'name': 'Agriculture', 'amName': 'ግብርና', 'score': 0.82, 'color': Color(0xFF14B8A6), 'units': '3/4'},
    {'name': 'ICT', 'amName': 'ኢንፎርሜሽን ቴክኖሎጂ', 'score': 0.90, 'color': Color(0xFF06B6D4), 'units': '4/4'},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _chartAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    if (_selectedChartTab == index) return;
    setState(() {
      _selectedChartTab = index;
    });
    _animController.reset();
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = !widget.isDarkMode;
    final bool isAm = widget.languageCode == 'am';

    final Color cardBg = isLight ? Colors.white : const Color(0xFF1E293B);
    final Color borderColor = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155);
    final Color textColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final Color subColor = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Badge & Switcher
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0084FF).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.auto_graph_rounded,
                            size: 20,
                            color: Color(0xFF0084FF),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAm ? 'የጥናት እና የውጤት ትንታኔ (Analytics)' : 'Academic Analytics Engine',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                              ),
                            ),
                            Text(
                              isAm ? 'የቀጥታ የትምህርት አፈፃፀም ግስጋሴ' : 'Real-time performance metrics',
                              style: TextStyle(fontSize: 11, color: subColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF10B981)),
                          const SizedBox(width: 2),
                          Text(
                            isAm ? '88% ብቃት' : '88% Mastery',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Interactive Chart Mode Tabs
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildTabButton(
                        title: isAm ? 'የጥናት ሰዓት' : 'Study Velocity',
                        icon: Icons.timer_rounded,
                        index: 0,
                        isLight: isLight,
                      ),
                      _buildTabButton(
                        title: isAm ? 'የትምህርት ብቃት' : 'Subject Mastery',
                        icon: Icons.bar_chart_rounded,
                        index: 1,
                        isLight: isLight,
                      ),
                      _buildTabButton(
                        title: isAm ? 'የፈተና ውጤት' : 'Quiz Trends',
                        icon: Icons.show_chart_rounded,
                        index: 2,
                        isLight: isLight,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Main Chart Visualization Area
          AnimatedBuilder(
            animation: _chartAnimation,
            builder: (context, child) {
              return Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  children: [
                    if (_selectedChartTab == 0)
                      _buildStudyVelocityChart(isLight, isAm, textColor, subColor),
                    if (_selectedChartTab == 1)
                      _buildSubjectMasteryBars(isLight, isAm, textColor, subColor),
                    if (_selectedChartTab == 2)
                      _buildQuizTrendAreaChart(isLight, isAm, textColor, subColor),
                  ],
                ),
              );
            },
          ),

          const Divider(height: 1),

          // Mini KPI Summary Cards
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildKpiCard(
                  title: isAm ? 'የተጠኑ ሰዓታት' : 'Study Time',
                  value: '29.8 hrs',
                  subtitle: isAm ? '+4.2 hrs በዚህ ሳምንት' : '+4.2 hrs this week',
                  icon: Icons.access_time_filled_rounded,
                  color: const Color(0xFF0084FF),
                  isLight: isLight,
                ),
                const SizedBox(width: 10),
                _buildKpiCard(
                  title: isAm ? 'የተጠናቀቁ ምዕራፎች' : 'Units Done',
                  value: '23 Units',
                  subtitle: isAm ? 'ከ32 ምዕራፎች' : 'out of 32 units',
                  icon: Icons.task_alt_rounded,
                  color: const Color(0xFF10B981),
                  isLight: isLight,
                ),
                const SizedBox(width: 10),
                _buildKpiCard(
                  title: isAm ? 'የጥናት ቅደም ተከተል' : 'Streak',
                  value: '7 Days',
                  subtitle: isAm ? 'ያልተቋረጠ ጥናት' : 'Personal Record',
                  icon: Icons.local_fire_department_rounded,
                  color: const Color(0xFFF59E0B),
                  isLight: isLight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required int index,
    required bool isLight,
  }) {
    final bool isSelected = _selectedChartTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isLight ? Colors.white : const Color(0xFF1E293B))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? const Color(0xFF0084FF) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? (isLight ? const Color(0xFF0F172A) : Colors.white)
                        : const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Weekly Study Velocity Bar Chart
  Widget _buildStudyVelocityChart(bool isLight, bool isAm, Color textCol, Color subCol) {
    const double maxHours = 7.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isAm ? 'የሳምንታዊ የጥናት ስርጭት (በሰዓታት)' : 'Weekly Study Distribution (Hours/Day)',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: textCol),
            ),
            Text(
              isAm ? 'አማካይ፡ 4.3 ሰዓት/ቀን' : 'Avg: 4.3 hrs/day',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0084FF)),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 150,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(_weeklyHours.length, (i) {
              final val = _weeklyHours[i];
              final double heightRatio = (val / maxHours) * _chartAnimation.value;
              final bool isHighest = val >= 6.0;
              final dayLabel = isAm ? _weekDaysAm[i] : _weekDaysEn[i];

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Value Tag
                      Text(
                        '${val.toStringAsFixed(1)}h',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isHighest ? const Color(0xFF0084FF) : subCol,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Bar Pillar
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: 110 * heightRatio,
                            width: 22,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isHighest
                                    ? [const Color(0xFF0084FF), const Color(0xFF00D4FF)]
                                    : [
                                        const Color(0xFF3B82F6).withValues(alpha: 0.75),
                                        const Color(0xFF60A5FA).withValues(alpha: 0.85),
                                      ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: isHighest
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF0084FF).withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      )
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Day Label
                      Text(
                        dayLabel,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: isHighest ? FontWeight.w800 : FontWeight.w600,
                          color: isHighest ? (isLight ? const Color(0xFF0F172A) : Colors.white) : subCol,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // 2. Subject Mastery Bars
  Widget _buildSubjectMasteryBars(bool isLight, bool isAm, Color textCol, Color subCol) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isAm ? 'የትምህርቶች የብቃት ደረጃ' : 'Subject Competency Breakdown',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: textCol),
            ),
            Text(
              isAm ? 'ጠቅላላ፡ 7 ትምህርቶች' : 'Total: 7 Subjects',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: subCol),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ..._subjectScores.map((s) {
          final double score = (s['score'] as double) * _chartAnimation.value;
          final int percent = (score * 100).toInt();
          final Color col = s['color'] as Color;
          final String title = isAm ? (s['amName'] as String) : (s['name'] as String);
          final String units = s['units'] as String;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: col, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: textCol,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          '$units ምዕራፍ',
                          style: TextStyle(fontSize: 10.5, color: subCol),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$percent%',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: col,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: score,
                    minHeight: 6.5,
                    backgroundColor: col.withValues(alpha: isLight ? 0.15 : 0.25),
                    valueColor: AlwaysStoppedAnimation<Color>(col),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // 3. Quiz Trend Smooth Area Chart
  Widget _buildQuizTrendAreaChart(bool isLight, bool isAm, Color textCol, Color subCol) {
    final List<double> quizScores = [75, 80, 85, 82, 90, 88, 96];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isAm ? 'የፈተና ውጤት ግስጋሴ (Accuracy Curve)' : 'Quiz Mastery & Accuracy Trend',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: textCol),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isAm ? '↗ 96% ከፍተኛ' : '↗ 96% Peak',
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 140,
          width: double.infinity,
          child: CustomPaint(
            painter: _ChartJsAreaPainter(
              scores: quizScores,
              animationProgress: _chartAnimation.value,
              isLight: isLight,
              primaryColor: const Color(0xFF0084FF),
              accentColor: const Color(0xFF00D4FF),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(quizScores.length, (i) {
            return Text(
              'Quiz ${i + 1}',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: subCol),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isLight,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isLight ? 0.08 : 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                color: isLight ? const Color(0xFF0F172A) : Colors.white,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom Bezier Curve Area Painter styled like Chart.js / ApexCharts
class _ChartJsAreaPainter extends CustomPainter {
  final List<double> scores;
  final double animationProgress;
  final bool isLight;
  final Color primaryColor;
  final Color accentColor;

  _ChartJsAreaPainter({
    required this.scores,
    required this.animationProgress,
    required this.isLight,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;

    const double minVal = 60.0;
    const double maxVal = 100.0;
    const double range = maxVal - minVal;

    final double stepX = size.width / (scores.length - 1);

    // Draw horizontal grid lines
    final gridPaint = Paint()
      ..color = (isLight ? Colors.black : Colors.white).withValues(alpha: 0.06)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 4; i++) {
      final y = size.height * (i / 4.0);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final List<Offset> points = [];
    for (int i = 0; i < scores.length; i++) {
      final double normalized = (scores[i] - minVal) / range;
      final double x = i * stepX;
      final double y = size.height - (normalized * size.height * animationProgress);
      points.add(Offset(x, y.clamp(0.0, size.height)));
    }

    if (points.length < 2) return;

    // Build smooth Bezier path
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    // Gradient Area Fill
    final areaPath = Path.from(path);
    areaPath.lineTo(points.last.dx, size.height);
    areaPath.lineTo(points.first.dx, size.height);
    areaPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          primaryColor.withValues(alpha: isLight ? 0.35 : 0.45),
          primaryColor.withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(areaPath, fillPaint);

    // Line Stroke
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [primaryColor, accentColor],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, linePaint);

    // Data Point Dots
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (final p in points) {
      canvas.drawCircle(p, 4.5, dotPaint);
      canvas.drawCircle(p, 4.5, dotBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartJsAreaPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.scores != scores;
  }
}
