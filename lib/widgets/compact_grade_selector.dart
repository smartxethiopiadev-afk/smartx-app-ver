import 'package:flutter/material.dart';

class CompactGradeSelector extends StatelessWidget {
  final int selectedGrade;
  final Function(int) onGradeSelected;
  final bool isLight;
  final String languageCode;

  const CompactGradeSelector({
    super.key,
    required this.selectedGrade,
    required this.onGradeSelected,
    required this.isLight,
    required this.languageCode,
  });

  @override
  Widget build(BuildContext context) {
    final List<int> grades = [9, 10, 11, 12];
    final Color activeColor = const Color(0xFF1E88E5); // Sleek brand blue
    final Color containerBg = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B);

    return Container(
      height: 32.0, // Ultra-compact and narrow height to save space
      padding: const EdgeInsets.all(3.0),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(100.0), // Pill shape
        border: Border.all(
          color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          width: 1.0,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double segmentWidth = constraints.maxWidth / grades.length;
          final int activeIndex = grades.indexOf(selectedGrade);

          return Stack(
            children: [
              // Sleek sliding background indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeInOutCubic,
                left: activeIndex * segmentWidth,
                top: 0,
                bottom: 0,
                width: segmentWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(100.0),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.35),
                        blurRadius: 6.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // Interactive text segments
              Row(
                children: grades.map((gradeNum) {
                  final bool isSelected = selectedGrade == gradeNum;
                  final String text = languageCode == 'en' ? 'G-$gradeNum' : 'ክ-$gradeNum';

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onGradeSelected(gradeNum),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                            fontWeight: FontWeight.w900,
                            fontSize: 12.0, // Clean and compact text sizing
                          ),
                          child: Text(text),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
