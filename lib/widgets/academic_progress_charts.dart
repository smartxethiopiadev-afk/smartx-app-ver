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
  late AnimationController _animController;
  late Animation<double> _chartAnimation;

  final List<double> _weeklyHours = const [2.5, 3.8, 4.2, 3.0, 5.5, 6.0, 4.8];
  final List<String> _weekDaysEn = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> _weekDaysAm = const ['ሰኞ', 'ማክሰኞ', 'ረቡዕ', 'ሐሙስ', 'አርብ', 'ቅዳሜ', 'እሑድ'];

  final List<Map<String, dynamic>> _subjectScores = const [
    {'name': 'Mathematics', 'amName': 'ሒሳብ', 'score': 0.92, 'color': Color(0xFF3B82F6), 'units': '5/6', 'rank': 'Master'},
    {'name': 'Physics', 'amName': 'ፊዚክስ', 'score': 0.86, 'color': Color(0xFF8B5CF6), 'units': '4/5', 'rank': 'Scholar'},
    {'name': 'Chemistry', 'amName': 'ኬሚስትሪ', 'score': 0.79, 'color': Color(0xFFEC4899), 'units': '3/4', 'rank': 'Adept'},
    {'name': 'Biology', 'amName': 'ባዮሎጂ', 'score': 0.88, 'color': Color(0xFF10B981), 'units': '4/5', 'rank': 'Scholar'},
    {'name': 'Civics', 'amName': 'ስነ-ዜጋ', 'score': 0.94, 'color': Color(0xFFF59E0B), 'units': '5/5', 'rank': 'Elite'},
    {'name': 'Agriculture', 'amName': 'ግብርና', 'score': 0.82, 'color': Color(0xFF14B8A6), 'units': '3/4', 'rank': 'Adept'},
    {'name': 'ICT', 'amName': 'ኢንፎርሜሽን ቴክኖሎጂ', 'score': 0.90, 'color': Color(0xFF06B6D4), 'units': '4/4', 'rank': 'Master'},
  ];

  final List<double> _quizScores = const [72, 78, 84, 80, 89, 92, 96];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
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

  @override
  Widget build(BuildContext context) {
    final bool isLight = !widget.isDarkMode;
    final bool isAm = widget.languageCode == 'am';

    final Color cardBg = isLight ? Colors.white : const Color(0xFF1E293B);
    final Color borderColor = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155);
    final Color textColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final Color subColor = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // 1. STANDALONE SECTION: STUDY VELOCITY
            // ==========================================
            _buildSectionHeader(
              title: isAm ? 'የጥናት ፍጥነት (Study Velocity)' : 'Study Velocity',
              subtitle: isAm ? 'የሳምንታዊ ጥናት ሰዓታት እና የተከታታይነት ፍጥነት' : 'Weekly focus hours and persistence momentum',
              icon: Icons.speed_rounded,
              iconColor: const Color(0xFF0284C7),
              badgeText: isAm ? 'ደረጃ 4 ፍጥነት' : 'Level 4 Velocity',
              badgeColor: const Color(0xFF0284C7),
              textColor: textColor,
              subColor: subColor,
              isLight: isLight,
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI Overview Row
                  Row(
                    children: [
                      _buildVelocityKpi(
                        label: isAm ? 'ጠቅላላ ሰዓታት' : 'Total Hours',
                        val: '29.8 hrs',
                        sub: isAm ? '+4.2h በዚህ ሳምንት' : '+4.2h this week',
                        icon: Icons.timelapse_rounded,
                        color: const Color(0xFF0284C7),
                        isLight: isLight,
                      ),
                      const SizedBox(width: 10),
                      _buildVelocityKpi(
                        label: isAm ? 'ዕለታዊ አማካይ' : 'Daily Average',
                        val: '4.3 hrs/day',
                        sub: isAm ? 'የተረጋጋ ፍጥነት' : 'Optimal pace',
                        icon: Icons.trending_up_rounded,
                        color: const Color(0xFF10B981),
                        isLight: isLight,
                      ),
                      const SizedBox(width: 10),
                      _buildVelocityKpi(
                        label: isAm ? 'የጥናት ተከታታይ' : 'Study Streak',
                        val: '7 Days',
                        sub: isAm ? 'ምርጥ ሪከርድ' : 'Active streak',
                        icon: Icons.local_fire_department_rounded,
                        color: const Color(0xFFF59E0B),
                        isLight: isLight,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Animated Bar Chart
                  _buildStudyVelocityBarChart(isLight, isAm, textColor, subColor),

                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // Progressive Velocity Milestones
                  _buildVelocityProgressiveSystem(isLight, isAm, textColor, subColor),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ==========================================
            // 2. STANDALONE SECTION: SUBJECT MASTER
            // ==========================================
            _buildSectionHeader(
              title: isAm ? 'የትምህርት ብቃት ማስተሪ (Subject Master)' : 'Subject Master',
              subtitle: isAm ? 'በየክፍለ-ትምህርቱ የተመዘገበ የዕውቀት ደረጃ' : 'Curriculum competency & completion breakdown',
              icon: Icons.stars_rounded,
              iconColor: const Color(0xFF10B981),
              badgeText: isAm ? 'የሊቅ ደረጃ (Scholar)' : 'Scholar Tier',
              badgeColor: const Color(0xFF10B981),
              textColor: textColor,
              subColor: subColor,
              isLight: isLight,
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Highlight Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: isLight ? 0.08 : 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.workspace_premium_rounded, color: Color(0xFF10B981), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAm ? 'ከፍተኛ ውጤት፡ ሒሳብ እና ስነ-ዜጋ (94%)' : 'Peak Mastery: Civics & Mathematics (94%)',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                              ),
                              Text(
                                isAm ? '23 ከ32 ክፍሎች በተሳካ ሁኔታ ተጠናቀዋል' : '23 of 32 units fully completed with mastery',
                                style: TextStyle(fontSize: 11, color: subColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Multi-Subject Bars
                  _buildSubjectMasteryBars(isLight, isAm, textColor, subColor),

                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // Progressive Subject Mastery Tier System
                  _buildSubjectProgressiveTiers(isLight, isAm, textColor, subColor),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ==========================================
            // 3. STANDALONE SECTION: QUIZ TRADE PROGRESSIVE SYSTEM
            // ==========================================
            _buildSectionHeader(
              title: isAm ? 'የፈተና ንግድ እና ግስጋሴ (Quiz Trade)' : 'Quiz Trade Progressive System',
              subtitle: isAm ? 'የፈተና ውጤት ግስጋሴ ከነጥብ እና ደረጃ ማስተዋወቂያ ጋር' : 'Quiz performance trajectory & credit progression',
              icon: Icons.currency_exchange_rounded,
              iconColor: const Color(0xFF8B5CF6),
              badgeText: isAm ? '1,450 የጥናት ነጥቦች' : '1,450 Trade XP',
              badgeColor: const Color(0xFF8B5CF6),
              textColor: textColor,
              subColor: subColor,
              isLight: isLight,
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trade Stats Row
                  Row(
                    children: [
                      _buildTradeMetricCard(
                        title: isAm ? 'የንግድ ክሬዲት' : 'Trade Credits',
                        value: '1,450 XP',
                        badge: isAm ? '+150 ዛሬ' : '+150 today',
                        icon: Icons.toll_rounded,
                        color: const Color(0xFF8B5CF6),
                        isLight: isLight,
                      ),
                      const SizedBox(width: 10),
                      _buildTradeMetricCard(
                        title: isAm ? 'የማለፍ ምጣኔ' : 'Pass Rate',
                        value: '92.4%',
                        badge: isAm ? 'ከፍተኛ ብቃት' : 'Top Tier',
                        icon: Icons.verified_rounded,
                        color: const Color(0xFF10B981),
                        isLight: isLight,
                      ),
                      const SizedBox(width: 10),
                      _buildTradeMetricCard(
                        title: isAm ? 'ከፍተኛ ውጤት' : 'Peak Score',
                        value: '96%',
                        badge: isAm ? 'Unit 5 Quiz' : 'Unit 5 Quiz',
                        icon: Icons.military_tech_rounded,
                        color: const Color(0xFFF59E0B),
                        isLight: isLight,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Area Chart Curve
                  _buildQuizTrendAreaChart(isLight, isAm, textColor, subColor),

                  const SizedBox(height: 18),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // Quiz Trade Progressive Milestone Levels
                  _buildQuizTradeProgressiveBar(isLight, isAm, textColor, subColor),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Section Header Component
  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String badgeText,
    required Color badgeColor,
    required Color textColor,
    required Color subColor,
    required bool isLight,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: subColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Velocity KPI widget
  Widget _buildVelocityKpi({
    required String label,
    required String val,
    required String sub,
    required IconData icon,
    required Color color,
    required bool isLight,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isLight ? 0.07 : 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 5),
            Text(
              val,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                color: isLight ? const Color(0xFF0F172A) : Colors.white,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              sub,
              style: TextStyle(fontSize: 9, color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // 1. Weekly Study Velocity Bar Chart
  Widget _buildStudyVelocityBarChart(bool isLight, bool isAm, Color textCol, Color subCol) {
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
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0284C7)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
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
                          color: isHighest ? const Color(0xFF0284C7) : subCol,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Bar Pillar
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: 105 * heightRatio,
                            width: 22,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isHighest
                                    ? [const Color(0xFF0284C7), const Color(0xFF38BDF8)]
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
                                        color: const Color(0xFF0284C7).withValues(alpha: 0.35),
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

  // Progressive Velocity System
  Widget _buildVelocityProgressiveSystem(bool isLight, bool isAm, Color textCol, Color subCol) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isAm ? 'የፍጥነት ደረጃ ግስጋሴ (Progressive Velocity)' : 'Progressive Velocity Milestones',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textCol),
            ),
            Text(
              '85% To Level 5',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0284C7)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: 0.85 * _chartAnimation.value,
            minHeight: 8,
            backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.15),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isAm ? 'ደረጃ 4፡ ንቁ አጥኚ' : 'Level 4: Active Scholar',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: subCol),
            ),
            Text(
              isAm ? 'ደረጃ 5፡ የጥናት አርበኛ' : 'Level 5: Master Strategist',
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF0284C7)),
            ),
          ],
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
              isAm ? 'የትምህርቶች የብቃት ዝርዝር' : 'Subject Competency Breakdown',
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
          final String rank = s['rank'] as String;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
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
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: textCol,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: col.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            rank,
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: col),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          '$units ${isAm ? "ክፍል" : "units"}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: subCol),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$percent%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: col,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: score,
                    minHeight: 7.5,
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

  // Progressive Subject Tiers
  Widget _buildSubjectProgressiveTiers(bool isLight, bool isAm, Color textCol, Color subCol) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isAm ? 'የትምህርት ብቃት ደረጃዎች' : 'Curriculum Mastery Tier Progression',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textCol),
            ),
            Text(
              'Rank: Master',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTierBadge('Adept', '70%+', const Color(0xFF64748B), true),
            _buildTierBadge('Scholar', '80%+', const Color(0xFF0284C7), true),
            _buildTierBadge('Master', '90%+', const Color(0xFF10B981), true),
            _buildTierBadge('Elite', '95%+', const Color(0xFFF59E0B), false),
          ],
        ),
      ],
    );
  }

  Widget _buildTierBadge(String label, String pct, Color color, bool achieved) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: achieved ? 0.12 : 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: achieved ? 0.35 : 0.15)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(achieved ? Icons.check_circle_rounded : Icons.lock_outline_rounded, size: 12, color: color),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
          Text(pct, style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.85))),
        ],
      ),
    );
  }

  // 3. Quiz Trade Area Chart
  Widget _buildQuizTrendAreaChart(bool isLight, bool isAm, Color textCol, Color subCol) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isAm ? 'የፈተና ውጤቶች ግስጋሴ (Accuracy Curve)' : 'Quiz Mastery & Accuracy Trajectory',
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
              scores: _quizScores,
              animationProgress: _chartAnimation.value,
              isLight: isLight,
              primaryColor: const Color(0xFF8B5CF6),
              accentColor: const Color(0xFFC084FC),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_quizScores.length, (i) {
            return Text(
              'Quiz ${i + 1}',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: subCol),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTradeMetricCard({
    required String title,
    required String value,
    required String badge,
    required IconData icon,
    required Color color,
    required bool isLight,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isLight ? 0.08 : 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                color: isLight ? const Color(0xFF0F172A) : Colors.white,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              title,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              badge,
              style: TextStyle(fontSize: 9, color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Quiz Trade Progressive Milestone Bar
  Widget _buildQuizTradeProgressiveBar(bool isLight, bool isAm, Color textCol, Color subCol) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isAm ? 'የፈተና ንግድ ስርዓት ደረጃ (Quiz Trade Rank)' : 'Quiz Trade Progressive System',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textCol),
            ),
            Text(
              'Level 7: Matric Ready',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF8B5CF6)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: 0.92 * _chartAnimation.value,
            minHeight: 8,
            backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isAm ? '1,450 XP (የተከማቸ)' : '1,450 XP Accumulated',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: subCol),
            ),
            Text(
              isAm ? 'ቀጣይ ሽልማት በ1,600 XP' : 'Next unlock at 1,600 XP',
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF8B5CF6)),
            ),
          ],
        ),
      ],
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
