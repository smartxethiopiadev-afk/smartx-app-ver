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
          tooltip: isEn ? 'Back to Grades' : 'ወደ ክፍሎች ተመለስ',
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
            // Header Info Pill
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
                  const Icon(Icons.video_collection_rounded, color: Color(0xFF0084FF), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEn
                          ? 'Choose a subject to explore curriculum unit walkthroughs.'
                          : 'የዩኒት ማብራሪያዎችን ለመመልከት የትምህርት ዓይነት ይምረጡ።',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Subject Cards
            ...subjects.map((subj) {
              final Color color = subj['color'] as Color;
              final IconData icon = subj['icon'] as IconData;
              final String enTitle = subj['enTitle'] as String;
              final String amTitle = subj['amTitle'] as String;
              final int unitsCount = subj['units'] as int;

              final String displayTitle = isEn ? enTitle : amTitle;
              final String subTitle = isEn ? amTitle : enTitle;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isLight ? 0.03 : 0.16),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => VideoUnitSelectionScreen(
                            grade: grade,
                            subject: subj['id'] as String,
                            subjectColor: color,
                            isDarkMode: isDarkMode,
                            languageCode: languageCode,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          // Subject Icon Container
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: isLight ? 0.12 : 0.22),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: color.withValues(alpha: isLight ? 0.25 : 0.4),
                              ),
                            ),
                            child: Center(
                              child: Icon(icon, color: color, size: 24),
                            ),
                          ),

                          const SizedBox(width: 14),

                          // Titles
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayTitle,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subTitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: subColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Units & Free Badge
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: isLight ? 0.12 : 0.25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isEn ? 'Unit 1 Free' : 'ዩኒት 1 ነጻ',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isEn ? '$unitsCount Units' : '$unitsCount ዩኒቶች',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: subColor,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: subColor.withValues(alpha: 0.6),
                            size: 22,
                          ),
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
