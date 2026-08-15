import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuizResultDialog extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final int percent;
  final bool isExam;
  final String? subject;
  final int grade;
  final int unit;
  final Color themeColor;
  final String languageCode;
  final bool isDark;
  final VoidCallback onReview;
  final VoidCallback onDone;
  final VoidCallback onStartRandomQuiz;

  const QuizResultDialog({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.percent,
    required this.isExam,
    this.subject,
    required this.grade,
    required this.unit,
    required this.themeColor,
    required this.languageCode,
    required this.isDark,
    required this.onReview,
    required this.onDone,
    required this.onStartRandomQuiz,
  });

  /// Displays the Celebratory Quiz Finished Dialog with a smooth slide-up and fade transition
  static Future<void> show(
    BuildContext context, {
    required int score,
    required int totalQuestions,
    int? percent,
    required bool isExam,
    String? subject,
    required int grade,
    int? unit,
    Color? themeColor,
    Color? subjectColor,
    String languageCode = 'en',
    bool? isDark,
    bool? isLight,
    VoidCallback? onReview,
    VoidCallback? onReviewAnswers,
    VoidCallback? onDone,
    VoidCallback? onStartRandomQuiz,
  }) {
    final int calculatedPercent = percent ??
        (totalQuestions > 0 ? (score / totalQuestions * 100).round() : 0);
    final Color effectiveThemeColor =
        subjectColor ?? themeColor ?? const Color(0xFF3B82F6);
    final bool effectiveIsDark =
        isDark ?? (isLight != null ? !isLight : false);
    final VoidCallback effectiveOnReview =
        onReviewAnswers ?? onReview ?? () => Navigator.of(context).pop();
    final VoidCallback effectiveOnDone =
        onDone ?? effectiveOnReview;
    final VoidCallback effectiveOnStartRandomQuiz =
        onStartRandomQuiz ?? () {};

    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'QuizResult',
      barrierColor: Colors.black.withValues(alpha: 0.72),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim1, anim2) {
        return PopScope(
          canPop: false,
          child: QuizResultDialog(
            score: score,
            totalQuestions: totalQuestions,
            percent: calculatedPercent,
            isExam: isExam,
            subject: subject,
            grade: grade,
            unit: unit ?? 1,
            themeColor: effectiveThemeColor,
            languageCode: languageCode,
            isDark: effectiveIsDark,
            onReview: effectiveOnReview,
            onDone: effectiveOnDone,
            onStartRandomQuiz: effectiveOnStartRandomQuiz,
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim1, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.15),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  State<QuizResultDialog> createState() => _QuizResultDialogState();
}

class _QuizResultDialogState extends State<QuizResultDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _trophyController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _trophyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _trophyController,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );
  }

  @override
  void dispose() {
    _trophyController.dispose();
    super.dispose();
  }

  String _getPerformanceTitle(bool isEn) {
    if (widget.percent >= 90) {
      return isEn ? "Outstanding Mastery!" : "ድንቅ ውጤት!";
    } else if (widget.percent >= 70) {
      return isEn ? "Great Job! Keep It Up!" : "በጣም ጥሩ ውጤት!";
    } else if (widget.percent >= 50) {
      return isEn ? "Good Effort!" : "ጥሩ ጥረት!";
    } else {
      return isEn ? "Keep Practicing!" : "ተጨማሪ ልምምድ ያስፈልጋል!";
    }
  }

  Color _getBadgeColor() {
    if (widget.percent >= 85) return const Color(0xFFF59E0B); // Gold
    if (widget.percent >= 70) return const Color(0xFF10B981); // Emerald
    if (widget.percent >= 50) return const Color(0xFF0284C7); // Blue
    return const Color(0xFFEF4444); // Red/Orange
  }

  @override
  Widget build(BuildContext context) {
    final bool isEn = widget.languageCode == 'en';
    final bool isDark = widget.isDark;

    final Color cardBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final Color sectionBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final Color borderCol = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final Color titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final Color badgeCol = _getBadgeColor();

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 440,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: borderCol, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: badgeCol.withValues(alpha: isDark ? 0.25 : 0.12),
                blurRadius: 36,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Close Icon row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.themeColor.withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.themeColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.school_rounded, size: 13, color: widget.themeColor),
                            const SizedBox(width: 5),
                            Text(
                              "Grade ${widget.grade} • Unit ${widget.unit}",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: widget.themeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (widget.isExam) {
                            widget.onReview();
                          } else {
                            widget.onDone();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Animated Celebratory Trophy Badge with Floating Stars / Confetti
                  AnimatedBuilder(
                    animation: _bounceAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _bounceAnimation.value,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            // Ambient Glow behind badge
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: badgeCol.withValues(alpha: 0.4),
                                    blurRadius: 28,
                                    spreadRadius: 6,
                                  ),
                                ],
                              ),
                            ),

                            // Multi-layered golden gradient trophy circle
                            Container(
                              width: 86,
                              height: 86,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    badgeCol,
                                    badgeCol.withValues(alpha: 0.75),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  width: 2.5,
                                ),
                              ),
                              child: Icon(
                                widget.percent >= 70
                                    ? Icons.emoji_events_rounded
                                    : Icons.military_tech_rounded,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),

                            // Confetti Star 1 (Top Left)
                            Positioned(
                              top: -4,
                              left: -6,
                              child: Icon(
                                Icons.auto_awesome,
                                color: const Color(0xFFFBBF24),
                                size: 22,
                              ),
                            ),
                            // Confetti Star 2 (Bottom Right)
                            Positioned(
                              bottom: -2,
                              right: -4,
                              child: Icon(
                                Icons.star_rounded,
                                color: const Color(0xFF38BDF8),
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),

                  // Modal Header Title
                  Text(
                    widget.isExam
                        ? (isEn ? "Exam Completed!" : "ፈተናው ተጠናቋል!")
                        : (isEn ? "Quiz Completed!" : "ልምምዱ ተጠናቋል!"),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Performance Headline
                  Text(
                    _getPerformanceTitle(isEn),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: badgeCol,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Metric Indicator Cards Row (Score, Accuracy, Status)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                    decoration: BoxDecoration(
                      color: sectionBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderCol),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Metric 1: Raw Score
                        _buildMetricCol(
                          title: isEn ? "SCORE" : "ውጤት",
                          value: "${widget.score} / ${widget.totalQuestions}",
                          valueColor: titleColor,
                          icon: Icons.check_circle_outline_rounded,
                          subColor: subColor,
                        ),

                        Container(width: 1.2, height: 40, color: borderCol),

                        // Metric 2: Accuracy %
                        _buildMetricCol(
                          title: isEn ? "ACCURACY" : "ትክክለኛነት",
                          value: "${widget.percent}%",
                          valueColor: widget.percent >= 70
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          icon: Icons.pie_chart_outline_rounded,
                          subColor: subColor,
                        ),

                        Container(width: 1.2, height: 40, color: borderCol),

                        // Metric 3: Grade / Status
                        _buildMetricCol(
                          title: isEn ? "RESULT" : "ደረጃ",
                          value: widget.percent >= 50
                              ? (isEn ? "PASS" : "አልፏል")
                              : (isEn ? "REVIEW" : "ይድገሙ"),
                          valueColor: widget.percent >= 50
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                          icon: Icons.verified_rounded,
                          subColor: subColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Informative summary line
                  Text(
                    isEn
                        ? "You can now review all questions with step-by-step explanations."
                        : "አሁን ሁሉንም ጥያቄዎች ከነዝርዝር ማብራሪያቸው መገምገም ይችላሉ።",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: subColor,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Encouraging "Ready to practice more?" Banner Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                            : [const Color(0xFF0F172A), const Color(0xFF1E3A8A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFF2563EB).withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
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
                            const Icon(Icons.bolt_rounded, color: Color(0xFFFBBF24), size: 18),
                            const SizedBox(width: 6),
                            Text(
                              isEn ? "Keep up the momentum!" : "ፍጥነትዎን ይቀጥሉ!",
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isEn
                              ? "Challenge yourself with another randomized unit from ${widget.subject ?? 'this subject'}."
                              : "ከዚህ የትምህርት አይነት በዘፈቀደ የተመረጠ ሌላ ክፍል ፈተና ይሞክሩ።",
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                            fontSize: 11.5,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              widget.onStartRandomQuiz();
                            },
                            icon: const Icon(Icons.shuffle_rounded, size: 16),
                            label: Text(
                              isEn ? "Start Random Unit Quiz" : "ሌላ ክፍል ፈተና ጀምር",
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              foregroundColor: const Color(0xFF0F172A),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Primary Action: Review Answers / Done
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (widget.isExam) {
                          widget.onReview();
                        } else {
                          widget.onDone();
                        }
                      },
                      icon: Icon(
                        widget.isExam
                            ? Icons.fact_check_rounded
                            : Icons.check_circle_rounded,
                        size: 18,
                      ),
                      label: Text(
                        widget.isExam
                            ? (isEn ? "Review All Explanations" : "ሁሉንም መልሶች ገምግም")
                            : (isEn ? "Done" : "ተጠናቋል"),
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.themeColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCol({
    required String title,
    required String value,
    required Color valueColor,
    required IconData icon,
    required Color subColor,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: subColor),
            const SizedBox(width: 4),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: subColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
