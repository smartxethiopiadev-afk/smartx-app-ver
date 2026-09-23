import 'package:flutter/material.dart';
import '../services/quiz_service.dart';
import '../main.dart';

/// Interactive modal sheets for the two-step Quiz selection flow:
/// Step 1: Mode Selection (Practice Mode vs Exam Mode)
/// Step 2: Question Type Selection (MCQs, True/False, Blank Space, Matching, All)
class QuizSelectionDialogs {
  /// Step 1: Show Mode Selection Modal (Practice vs Exam)
  static Future<void> showModeSelectionModal({
    required BuildContext context,
    required int grade,
    required String subject,
    required int unitNumber,
    String? unitTitle,
    required void Function(QuizMode mode) onModeChosen,
  }) {
    final bool isDark = AppStateProvider.of(context).isDarkMode;
    final bool isAm = AppStateProvider.of(context).languageCode == 'am';

    final Color sheetBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final Color borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Material(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header Badge & Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Grade $grade • Unit $unitNumber",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          subject,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: subTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Text(
                    isAm ? "የፈተና ዓይነት ይምረጡ" : "Select Quiz Mode",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAm
                        ? "ለክፍል $unitNumber የሚፈልጉትን የመማሪያ ወይም የመፈተኛ ዓይነት ይምረጡ"
                        : "Choose how you would like to test your knowledge for Unit $unitNumber",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: subTextColor,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Option 1: Practice Mode Card
                  _buildModeCard(
                    context: context,
                    icon: Icons.school_rounded,
                    iconColor: const Color(0xFF2563EB),
                    iconBg: const Color(0xFF2563EB).withValues(alpha: 0.12),
                    title: isAm ? "የልምምድ ዓይነት (Practice Mode)" : "Practice Mode",
                    subtitle: isAm
                        ? "የጥያቄ ዓይነቶችን መርጠው በደረጃ ይለማመዱ። ፈጣን መልስ፣ ማብራሪያና ፍንጮችን ያገኛሉ።"
                        : "Interactive study with instant feedback, step-by-step explanations, and hints.",
                    badgeText: isAm ? "ፈጣን ማብራሪያ" : "Instant Feedback",
                    badgeColor: const Color(0xFF2563EB),
                    borderColor: borderColor,
                    isDark: isDark,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      onModeChosen(QuizMode.practice);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Option 2: Exam Mode Card
                  _buildModeCard(
                    context: context,
                    icon: Icons.timer_outlined,
                    iconColor: const Color(0xFFEA580C),
                    iconBg: const Color(0xFFEA580C).withValues(alpha: 0.12),
                    title: isAm ? "የፈተና ዓይነት (Exam Mode)" : "Exam Mode",
                    subtitle: isAm
                        ? "በተወሰነ ጊዜ ውስጥ የብሔራዊ ፈተናዎችን አስመስለው ይፈተኑ። ጥያቄዎች እና ምርጫዎች ይዘበራረቃሉ።"
                        : "Timed simulation test with randomized questions, shuffled choices, and score evaluation.",
                    badgeText: isAm ? "በጊዜ የተገደበ" : "Timed Test",
                    badgeColor: const Color(0xFFEA580C),
                    borderColor: borderColor,
                    isDark: isDark,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      onModeChosen(QuizMode.exam);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Step 2: Show Question Type Selection Modal (Triggered when Practice Mode is selected)
  static Future<void> showQuestionTypeModal({
    required BuildContext context,
    required int grade,
    required String subject,
    required int unitNumber,
    required void Function(String questionType) onTypeSelected,
  }) {
    final bool isDark = AppStateProvider.of(context).isDarkMode;
    final bool isAm = AppStateProvider.of(context).languageCode == 'am';

    final Color sheetBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final Color borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final List<Map<String, dynamic>> questionTypes = [
      {
        'id': 'all',
        'title': isAm ? "ሁሉም የጥያቄ ዓይነቶች" : "All Question Types",
        'subtitle': isAm ? "ሁሉንም ዓይነት ጥያቄዎች (ምርጫ፣ እውነት/ሐሰት፣ ባዶ ቦታ) በአንድ ላይ" : "Comprehensive mix of MCQs, True/False, and Blank Space",
        'icon': Icons.auto_awesome_rounded,
        'color': const Color(0xFF6366F1), // Indigo
      },
      {
        'id': 'multiple_choice',
        'title': isAm ? "ምርጫ ጥያቄዎች (MCQs)" : "Multiple Choice Questions",
        'subtitle': isAm ? "ከ 4 ምርጫዎች ትክክለኛውን በመምረጥ ከነማብራሪያው ይማሩ" : "Standard 4-choice questions with complete step-by-step rationale",
        'icon': Icons.radio_button_checked_rounded,
        'color': const Color(0xFF2563EB), // Blue
      },
      {
        'id': 'true_false',
        'title': isAm ? "እውነት / ሐሰት (True / False)" : "True / False Questions",
        'subtitle': isAm ? "ፅንሰ-ሀሳቦችን በፍጥነት በማረጋገጥ ግንዛቤዎን ይገምግሙ" : "Quick conceptual validation to reinforce core syllabus principles",
        'icon': Icons.check_circle_outline_rounded,
        'color': const Color(0xFF059669), // Emerald
      },
      {
        'id': 'blank_space',
        'title': isAm ? "ባዶ ቦታ ሙላ (Blank Space)" : "Fill in the Blanks",
        'subtitle': isAm ? "ሳይንሳዊ ቃላትንና ትርጓሜዎችን በመፃፍ የማስታወስ ችሎታዎን ይፈትሹ" : "Type accurate terms and definitions to test precise recall",
        'icon': Icons.edit_note_rounded,
        'color': const Color(0xFF9333EA), // Purple
      },
      {
        'id': 'matching',
        'title': isAm ? "ማዛመድ (Matching)" : "Matching Pairs",
        'subtitle': isAm ? "ቃላትን ከትክክለኛ ትርጓሜያቸውና ቀመሮቻቸው ጋር ያዛምዱ" : "Connect terms, units, and definitions with their pairs",
        'icon': Icons.compare_arrows_rounded,
        'color': const Color(0xFFD97706), // Amber
      },
    ];

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Material(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Header Info
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Practice Mode • Unit $unitNumber",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Text(
                      isAm ? "የጥያቄ ዓይነት ይምረጡ" : "Choose Question Format",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAm
                          ? "ለመለማመድ የሚፈልጉትን የጥያቄ ቅርጸት ይምረጡ"
                          : "Select which question type you want to focus on for this session",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: subTextColor,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Question Types List
                    ...questionTypes.map((type) {
                      final Color col = type['color'] as Color;
                      final IconData ic = type['icon'] as IconData;
                      final String typeId = type['id'] as String;
                      final String title = type['title'] as String;
                      final String subtitle = type['subtitle'] as String;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(ctx).pop();
                            onTypeSelected(typeId);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
                              border: Border.all(color: borderColor, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: col.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(ic, color: col, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w800,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        subtitle,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                          color: subTextColor,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.arrow_forward_ios_rounded, color: subTextColor.withValues(alpha: 0.6), size: 14),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Exam Mode Confirmation Modal
  static Future<void> showExamConfirmationModal({
    required BuildContext context,
    required int grade,
    required String subject,
    required int unitNumber,
    required VoidCallback onStartExam,
  }) {
    final bool isDark = AppStateProvider.of(context).isDarkMode;
    final bool isAm = AppStateProvider.of(context).languageCode == 'am';

    final Color sheetBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final Color borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Material(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEA580C).withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.timer_outlined, color: Color(0xFFEA580C), size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAm ? "የፈተና ዝግጅት" : "Exam Mode Setup",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                              ),
                            ),
                            Text(
                              "Grade $grade • $subject • Unit $unitNumber",
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: subTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        _buildExamRuleRow(
                          icon: Icons.shuffle_rounded,
                          text: isAm ? "ጥያቄዎችና ምርጫዎች በዘፈቀደ ይዘበራረቃሉ" : "Questions & options are randomized to test authentic mastery",
                          isDark: isDark,
                        ),
                        const SizedBox(height: 10),
                        _buildExamRuleRow(
                          icon: Icons.hourglass_top_rounded,
                          text: isAm ? "የጊዜ ገደብ አለ (በጥያቄ 90 ሰከንዶች)" : "Enforced timer countdown (90 seconds per question)",
                          isDark: isDark,
                        ),
                        const SizedBox(height: 10),
                        _buildExamRuleRow(
                          icon: Icons.visibility_off_outlined,
                          text: isAm ? "ፈተናውን ሲጨርሱ ሙሉ ውጤትና ማብራሪያ ይሰጣል" : "Answers & full explanations revealed only upon exam submission",
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      onStartExam();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isAm ? "ፈተናውን አሁን ጀምር" : "Start Exam Now",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _buildExamRuleRow({
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFFEA580C)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildModeCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required Color borderColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
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
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
