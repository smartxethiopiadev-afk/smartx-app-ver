import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/video_model.dart';
import '../services/video_service.dart';
import 'how_to_start_banner.dart';

class LockedUnitDialog extends StatelessWidget {
  final int grade;
  final String subject;
  final int unitNumber;
  final String? unitTitle;
  final bool isDarkMode;
  final String languageCode;
  final VoidCallback? onUnlocked;

  const LockedUnitDialog({
    super.key,
    required this.grade,
    required this.subject,
    required this.unitNumber,
    this.unitTitle,
    required this.isDarkMode,
    required this.languageCode,
    this.onUnlocked,
  });

  static Future<void> show(
    BuildContext context, {
    required int grade,
    required String subject,
    required int unitNumber,
    String? unitTitle,
    required bool isDarkMode,
    required String languageCode,
    VoidCallback? onUnlocked,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => LockedUnitDialog(
        grade: grade,
        subject: subject,
        unitNumber: unitNumber,
        unitTitle: unitTitle,
        isDarkMode: isDarkMode,
        languageCode: languageCode,
        onUnlocked: onUnlocked,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = !isDarkMode;
    final bool isAm = languageCode == 'am';

    final Color dialogBg = isLight ? Colors.white : const Color(0xFF1E293B);
    final Color borderColor = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155);
    final Color textPrimary = isLight ? const Color(0xFF0F172A) : Colors.white;
    final Color textSecondary = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: dialogBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isLight ? 0.08 : 0.35),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Lock Icon Header with glowing accent ring
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Color(0xFFEF4444),
                    size: 30,
                  ),
                ),

                const SizedBox(height: 12),

                // Title
                Text(
                  isAm ? 'ይህ ምዕራፍ ተቆልፏል 🔒' : 'Chapter Locked 🔒',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansEthiopic(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                  ),
                ),

                const SizedBox(height: 6),

                // Badge: Premium Curriculum Unit
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars_rounded, color: Color(0xFF0284C7), size: 15),
                      const SizedBox(width: 6),
                      Text(
                        isAm ? 'የተቆለፈ ትምህርት • ክፍል $grade ምዕራፍ $unitNumber' : 'Premium Unit • Grade $grade Unit $unitNumber',
                        style: GoogleFonts.notoSansEthiopic(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Dynamic Video Pop-up Card fetched directly from Database Thumbnail
                FutureBuilder<VideoModel>(
                  future: VideoService.fetchAppTutorialVideo(),
                  builder: (context, snapshot) {
                    final video = snapshot.data ?? VideoService.getAppOverviewVideo();
                    final String thumbUrl = video.thumbnailUrl;

                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.20),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            HowToStartBanner.showUsageGuide(
                              context,
                              isDarkMode: isDarkMode,
                              languageCode: languageCode,
                              grade: grade,
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Video Thumbnail with Play Button Overlay
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16.5)),
                                    child: AspectRatio(
                                      aspectRatio: 16 / 9,
                                      child: thumbUrl.isNotEmpty
                                          ? Image.network(
                                              thumbUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                color: const Color(0xFF1E293B),
                                                child: const Center(
                                                  child: Icon(Icons.video_library_rounded, color: Colors.white54, size: 40),
                                                ),
                                              ),
                                            )
                                          : Container(
                                              color: const Color(0xFF1E293B),
                                              child: const Center(
                                                child: Icon(Icons.smart_display_rounded, color: Colors.white54, size: 48),
                                              ),
                                            ),
                                    ),
                                  ),
                                  Container(
                                    height: 140,
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16.5)),
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.black.withValues(alpha: 0.30),
                                          Colors.black.withValues(alpha: 0.65),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),
                                  // Play icon glowing button
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF0284C7), Color(0xFF00BFFF)],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF0284C7).withValues(alpha: 0.5),
                                          blurRadius: 14,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 34,
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                isAm ? '🎬 እንዴት እንደሚጀመር?' : '🎬 How to Start Video',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFEF4444),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  isAm ? 'ቪዲዮ' : 'VIDEO',
                                                  style: const TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w900,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            isAm ? 'መተግበሪያውን እንዴት ማስከፈት እንደሚችሉ በአጭር ቪዲዮ ይመልከቱ' : 'Watch step-by-step video guide on how to start.',
                                            style: GoogleFonts.notoSansEthiopic(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF94A3B8),
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0284C7),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.play_circle_fill_rounded, size: 14, color: Colors.white),
                                          const SizedBox(width: 4),
                                          Text(
                                            isAm ? 'እይ' : 'Pop-Up',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 14),

                // Primary Action: Telegram Contact (@smart_x_help)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      final Uri telegramUri = Uri.parse('https://t.me/smart_x_help');
                      try {
                        if (await canLaunchUrl(telegramUri)) {
                          await launchUrl(telegramUri, mode: LaunchMode.externalApplication);
                        } else {
                          throw Exception('Cannot launch Telegram');
                        }
                      } catch (_) {
                        if (context.mounted) {
                          HowToStartBanner.showUsageGuide(
                            context,
                            isDarkMode: isDarkMode,
                            languageCode: languageCode,
                            grade: grade,
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                    label: Text(
                      isAm ? 'በቴሌግራም አግኙን (@smart_x_help)' : 'Contact Telegram (@smart_x_help)',
                      style: GoogleFonts.notoSansEthiopic(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0088CC),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Dismiss Action: Close
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: borderColor,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      isAm ? 'ዝጋ / ተመለስ' : 'Dismiss',
                      style: GoogleFonts.notoSansEthiopic(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                      ),
                    ),
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

