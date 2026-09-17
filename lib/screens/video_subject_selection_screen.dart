import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'video_unit_selection_screen.dart';

class VideoSubjectSelectionScreen extends StatelessWidget {
  final int grade;
  final bool isDarkMode;
  final String languageCode;

  const VideoSubjectSelectionScreen({
    super.key,
    required this.grade,
    required this.isDarkMode,
    required this.languageCode,
  });

  List<Map<String, dynamic>> _getSubjects() {
    final List<Map<String, dynamic>> list = [
      {
        'id': 'Mathematics',
        'enTitle': 'Mathematics',
        'amTitle': 'ሂሳብ',
        'units': 9,
        'color': const Color(0xFF2563EB),
        'icon': Icons.calculate_rounded,
      },
      {
        'id': 'Physics',
        'enTitle': 'Physics',
        'amTitle': 'ፊዚክስ',
        'units': 6,
        'color': const Color(0xFFDC2626),
        'icon': Icons.bolt_rounded,
      },
      {
        'id': 'Chemistry',
        'enTitle': 'Chemistry',
        'amTitle': 'ኬሚስትሪ',
        'units': 6,
        'color': const Color(0xFFEA580C),
        'icon': Icons.science_rounded,
      },
      {
        'id': 'Biology',
        'enTitle': 'Biology',
        'amTitle': 'ስነ-ህይወት',
        'units': 6,
        'color': const Color(0xFF16A34A),
        'icon': Icons.eco_rounded,
      },
    ];

    if (grade == 9 || grade == 10) {
      list.add({
        'id': 'Civics',
        'enTitle': 'Civics',
        'amTitle': 'የዜግነት ትምህርት',
        'units': 5,
        'color': const Color(0xFF0284C7),
        'icon': Icons.gavel_rounded,
      });
    }

    if (grade == 11 || grade == 12) {
      list.add({
        'id': 'Agriculture',
        'enTitle': 'Agriculture',
        'amTitle': 'ግብርና',
        'units': 6,
        'color': const Color(0xFF059669),
        'icon': Icons.agriculture_rounded,
      });
      list.add({
        'id': 'Economics',
        'enTitle': 'Economics',
        'amTitle': 'ኢኮኖሚክስ',
        'units': 6,
        'color': const Color(0xFFD97706),
        'icon': Icons.trending_up_rounded,
      });
    }

    list.addAll([
      {
        'id': 'English',
        'enTitle': 'English',
        'amTitle': 'እንግሊዝኛ',
        'units': 8,
        'color': const Color(0xFF7C3AED),
        'icon': Icons.translate_rounded,
      },
      {
        'id': 'Geography',
        'enTitle': 'Geography',
        'amTitle': 'ጂኦግራፊ',
        'units': 6,
        'color': const Color(0xFF0D9488),
        'icon': Icons.public_rounded,
      },
      {
        'id': 'History',
        'enTitle': 'History',
        'amTitle': 'ታሪክ',
        'units': 6,
        'color': const Color(0xFF9333EA),
        'icon': Icons.history_edu_rounded,
      },
      {
        'id': 'ICT',
        'enTitle': 'ICT',
        'amTitle': 'ኢንፎርሜሽን ቴክኖሎጂ',
        'units': 5,
        'color': const Color(0xFF0284C7),
        'icon': Icons.computer_rounded,
      },
    ]);

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final bool isEn = languageCode == 'en';
    final bool isLight = !isDarkMode;

    final Color bgColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color cardBg = isLight ? Colors.white : const Color(0xFF1E293B);
    final Color textColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final Color subColor = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final Color borderColor = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155);

    final subjects = _getSubjects();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: isEn ? 'Back' : 'ተመለስ',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEn ? 'Grade $grade • Video Courses' : '$gradeኛ ክፍል • የቪዲዮ ትምህርቶች',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            Text(
              isEn ? 'Select your subject' : 'የትምህርት ዓይነት ይምረጡ',
              style: TextStyle(fontSize: 11.5, color: subColor),
            ),
          ],
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: borderColor, height: 1.0),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // Header Info Pill styled exactly like Quiz & Short Notes
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0084FF).withValues(alpha: isLight ? 0.08 : 0.16),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF0084FF).withValues(alpha: isLight ? 0.2 : 0.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF0084FF), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEn
                          ? 'Select a subject to watch chapter video walkthroughs aligned with Quiz & Short Notes.'
                          : 'ከፈተና እና ማስታወሻዎች ጋር የተጣጣሙ የዩኒት የቪዲዮ ማብራሪያዎችን ለማየት ትምህርት ይምረጡ።',
                      style: GoogleFonts.notoSansEthiopic(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Subject Cards Grid/List matching Quiz & Short Note screen styling
            ...subjects.map((sub) {
              final Color subjectColor = sub['color'] as Color;
              final IconData subjectIcon = sub['icon'] as IconData;
              final String title = isEn ? sub['enTitle'] : sub['amTitle'];
              final int unitsCount = sub['units'] as int;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isLight ? 0.03 : 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoUnitSelectionScreen(
                            grade: grade,
                            subjectId: sub['id'],
                            subjectTitle: title,
                            themeColor: subjectColor,
                            isDarkMode: isDarkMode,
                            languageCode: languageCode,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: subjectColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: subjectColor.withValues(alpha: 0.3)),
                            ),
                            child: Icon(subjectIcon, color: subjectColor, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: subjectColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isEn ? '$unitsCount Units Available' : '$unitsCount ዩኒቶች አሉ',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: subjectColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isEn ? '• Videos & Notes' : '• ቪዲዮ እና ማስታወሻ',
                                      style: TextStyle(fontSize: 11, color: subColor, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: subColor, size: 22),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
