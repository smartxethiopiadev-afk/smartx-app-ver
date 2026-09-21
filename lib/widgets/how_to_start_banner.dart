import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/video_model.dart';
import '../services/video_service.dart';
import '../screens/login_activation_screen.dart';

/// Interactive "How to Start" widget that displays a video-first guide
/// fetched directly from the Supabase database.
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

  static void showUsageGuide(
    BuildContext context, {
    required bool isDarkMode,
    required String languageCode,
    int? grade,
  }) {
    final bool isLight = !isDarkMode;
    final bool isAm = languageCode == 'am';

    final Color dialogBg = isLight ? Colors.white : const Color(0xFF1E293B);
    final Color textPrimary = isLight ? const Color(0xFF0F172A) : Colors.white;
    final Color textSecondary = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.smart_display_rounded,
                      color: Color(0xFF0284C7),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAm ? 'እንዴት ልጀምር? (የቪዲዮ መመሪያ)' : 'How to Start? (Video Tutorial)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isAm ? 'የመተግበሪያውን አጠቃቀም በቪዲዮ ይመልከቱ' : 'Step-by-step video guide from Supabase',
                          style: GoogleFonts.notoSansEthiopic(
                            fontSize: 11.5,
                            color: textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textSecondary, size: 22),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Dynamic Tutorial Video Card from Supabase Database
              FutureBuilder<VideoModel>(
                future: VideoService.fetchAppTutorialVideo(),
                builder: (context, snapshot) {
                  final video = snapshot.data ?? VideoService.getAppOverviewVideo();
                  final String thumbUrl = video.thumbnailUrl;

                  return Container(
                    decoration: BoxDecoration(
                      color: !isLight ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          final streamUrl = video.streamUrl;
                          if (streamUrl.isNotEmpty) {
                            final uri = Uri.parse(streamUrl);
                            canLaunchUrl(uri).then((can) {
                              if (can) {
                                launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isAm
                                      ? 'የቪዲዮ መመሪያ ከ Supabase በመጫን ላይ ነው።'
                                      : 'Video tutorial is loading from Supabase database.',
                                ),
                                backgroundColor: const Color(0xFF0284C7),
                              ),
                            );
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                  child: AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: thumbUrl.isNotEmpty
                                        ? Image.network(
                                            thumbUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              color: const Color(0xFF0F172A),
                                              child: const Center(
                                                child: Icon(Icons.video_library_rounded, color: Colors.white54, size: 40),
                                              ),
                                            ),
                                          )
                                        : Container(
                                            color: const Color(0xFF0F172A),
                                            child: const Center(
                                              child: Icon(Icons.play_arrow_rounded, color: Colors.white54, size: 48),
                                            ),
                                          ),
                                  ),
                                ),
                                Container(
                                  height: 140,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.35),
                                  ),
                                ),
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0284C7),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0284C7).withValues(alpha: 0.5),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      video.title.isNotEmpty
                                          ? video.title
                                          : (isAm
                                              ? 'የመተግበሪያው አጠቃቀም ሙሉ ገለፃ ቪዲዮ'
                                              : 'Smart Learn Master Tutorial Video'),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: textPrimary,
                                        height: 1.3,
                                      ),
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
                                          isAm ? 'እይ' : 'Watch',
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

              const SizedBox(height: 18),

              // Action Buttons
              SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    LoginActivationScreen.push(
                      context,
                      isDarkMode: isDarkMode,
                      languageCode: languageCode,
                      preferredGrade: grade ?? 12,
                    );
                  },
                  icon: const Icon(Icons.login_rounded, size: 18, color: Colors.white),
                  label: Text(
                    isAm ? 'በአካውንት ይግቡ (Student Login)' : 'Student Login',
                    style: GoogleFonts.notoSansEthiopic(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Telegram Admin Contact
              SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    final Uri adminUri = Uri.parse('https://t.me/smart_x_help');
                    if (await canLaunchUrl(adminUri)) {
                      await launchUrl(adminUri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.support_agent_rounded, size: 18, color: Color(0xFF0088CC)),
                  label: Text(
                    isAm ? 'አድሚኑን በቴሌግራም ያግኙ (@smart_x_help)' : 'Contact Admin on Telegram',
                    style: GoogleFonts.notoSansEthiopic(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: const Color(0xFF0088CC),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0088CC), width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHowToStartPopUp(BuildContext context) {
    showUsageGuide(
      context,
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
          onTap: () => _showHowToStartPopUp(context),
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
                    isAm ? 'እንዴት ልጀምር? (የቪዲዮ አጠቃቀም መመሪያ)' : 'How to Start? (Video Tutorial)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isAm ? 'እይ (Watch)' : 'Watch',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0284C7),
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
