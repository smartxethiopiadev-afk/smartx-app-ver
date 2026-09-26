import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_video_popup_dialog.dart';

/// Interactive "How to Start" widget that displays a video tutorial banner.
/// Tapping anywhere directly launches the in-place YouTube-style video popup player.
class HowToStartBanner extends StatelessWidget {
  final bool isDarkMode;
  final String languageCode;
  final Function(int grade)? onGradeSelected;

  const HowToStartBanner({
    super.key,
    required this.isDarkMode,
    required this.languageCode,
    this.onGradeSelected,
  });

  /// Plays the Supabase onboarding / tutorial video smoothly in-app using YouTube-style in-place pop-up
  static Future<void> playTutorialVideo(
    BuildContext context, {
    required bool isDarkMode,
    required String languageCode,
    int? grade,
  }) async {
    return AppVideoPopupDialog.show(
      context,
      grade: grade ?? 12,
      isDarkMode: isDarkMode,
      languageCode: languageCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = !isDarkMode;
    final bool isAm = languageCode == 'am';

    final Color cardBg = isLight ? Colors.white : const Color(0xFF1E293B);
    final Color borderColor = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155);
    final Color textPrimary = isLight ? const Color(0xFF0F172A) : Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.03 : 0.15),
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
          splashColor: const Color(0xFF00BFFF).withValues(alpha: 0.10),
          highlightColor: Colors.transparent,
          onTap: () => playTutorialVideo(
            context,
            isDarkMode: isDarkMode,
            languageCode: languageCode,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.smart_display_rounded,
                    color: Color(0xFF0284C7),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isAm ? 'እንዴት ልጀምር? (የቪዲዮ መመሪያ)' : 'How to Start? (Video Tutorial)',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ).copyWith(
                      fontFamilyFallback: const ['Roboto', 'SF Pro Display', 'sans-serif', 'Noto Sans Ethiopic'],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isAm ? 'እይ (Watch)' : 'Watch',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0284C7),
                        ).copyWith(
                          fontFamilyFallback: const ['Roboto', 'SF Pro Display', 'sans-serif'],
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Color(0xFF0284C7),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
