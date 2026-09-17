import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _AcademicProgressChartsState extends State<AcademicProgressCharts> {
  int _completedQuizzes = 0;
  int _highestScore = 0;
  String _registeredGrade = '12';
  String _fullName = '';

  // Progressive Metrics stored in SharedPreferences
  double _velocityStudyRate = 14.5; // Questions answered per 10 mins
  int _masterQuizScore = 88; // Master quiz score percentage
  int _tradeQuizCompleted = 12; // Practice/Trade Quizzes completed

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    int count = 0;
    int maxScore = 0;

    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('quiz_score_') || key.startsWith('best_score_')) {
        count++;
        final val = prefs.getInt(key) ?? 0;
        if (val > maxScore) maxScore = val;
      }
    }

    final double savedVelocity = prefs.getDouble('velocity_study_rate') ?? (count > 0 ? (count * 4.2) : 12.0);
    final int savedMasterScore = prefs.getInt('master_quiz_score') ?? maxScore;
    final int savedTradeQuiz = prefs.getInt('trade_quiz_completed') ?? count;

    setState(() {
      _completedQuizzes = count;
      _highestScore = maxScore;
      _registeredGrade = prefs.getString('user_grade') ?? '${widget.currentGrade}';
      _fullName = prefs.getString('user_fullName') ?? prefs.getString('user_name') ?? 'Student';
      _velocityStudyRate = savedVelocity;
      _masterQuizScore = savedMasterScore;
      _tradeQuizCompleted = savedTradeQuiz;
    });
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Color(0xFF0284C7),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAm ? 'የጥናት እና ፈተና ውጤት ማጠቃለያ' : 'Progressive Study & Quiz Metrics',
                      style: GoogleFonts.notoSansEthiopic(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    Text(
                      isAm ? 'የእርስዎን የትምህርት እንቅስቃሴ በስልክዎ ያንብቡ (SharedPreferences Data)' : 'Track local velocity, master & trade quiz stats',
                      style: GoogleFonts.notoSansEthiopic(
                        fontSize: 11.5,
                        color: subColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Stat Cards Grid
          Row(
            children: [
              _buildStatCard(
                label: isAm ? 'የጥናት ፍጥነት (Velocity)' : 'Velocity Study',
                value: '${_velocityStudyRate.toStringAsFixed(1)} q/10m',
                icon: Icons.speed_rounded,
                color: const Color(0xFF0284C7),
                isLight: isLight,
                textColor: textColor,
                subColor: subColor,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                label: isAm ? 'ማስተር ፈተና (Master Quiz)' : 'Master Quiz Score',
                value: _masterQuizScore > 0 ? '$_masterQuizScore%' : 'N/A',
                icon: Icons.military_tech_rounded,
                color: const Color(0xFFF59E0B),
                isLight: isLight,
                textColor: textColor,
                subColor: subColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(
                label: isAm ? 'የልምምድ ፈተና (Trade Quiz)' : 'Trade Quiz Count',
                value: '$_tradeQuizCompleted Solved',
                icon: Icons.quiz_rounded,
                color: const Color(0xFF10B981),
                isLight: isLight,
                textColor: textColor,
                subColor: subColor,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                label: isAm ? 'ከፍተኛ ውጤት' : 'Highest Quiz Score',
                value: _highestScore > 0 ? '$_highestScore%' : 'N/A',
                icon: Icons.workspace_premium_rounded,
                color: const Color(0xFF8B5CF6),
                isLight: isLight,
                textColor: textColor,
                subColor: subColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(
                label: isAm ? 'የተመዘገቡበት ክፍል' : 'Registered Grade',
                value: 'Grade $_registeredGrade',
                icon: Icons.school_rounded,
                color: const Color(0xFFEC4899),
                isLight: isLight,
                textColor: textColor,
                subColor: subColor,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                label: isAm ? 'የተማሪ ስም' : 'Student Name',
                value: _fullName,
                icon: Icons.person_rounded,
                color: const Color(0xFF06B6D4),
                isLight: isLight,
                textColor: textColor,
                subColor: subColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isLight,
    required Color textColor,
    required Color subColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isLight ? 0.08 : 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: subColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: textColor,
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
