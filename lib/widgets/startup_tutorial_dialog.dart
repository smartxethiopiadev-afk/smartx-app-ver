import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video_model.dart';
import '../screens/fullscreen_video_player_screen.dart';
import '../screens/video_coming_soon_screen.dart';
import '../services/video_service.dart';
import 'youtube_video_player_dialog.dart';

/// A modal popup that appears when students open the mobile app.
/// Fetches the tutorial video from Supabase database, explaining how to use
/// the curriculum notes, quizzes, offline study, and Telegram support.
/// Includes "Continue" and "Never show again" actions.
class StartupTutorialDialog extends StatefulWidget {
  final bool isDarkMode;
  final String languageCode;

  const StartupTutorialDialog({
    super.key,
    required this.isDarkMode,
    required this.languageCode,
  });

  static Future<void> show(
    BuildContext context, {
    required bool isDarkMode,
    required String languageCode,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StartupTutorialDialog(
        isDarkMode: isDarkMode,
        languageCode: languageCode,
      ),
    );
  }

  @override
  State<StartupTutorialDialog> createState() => _StartupTutorialDialogState();
}

class _StartupTutorialDialogState extends State<StartupTutorialDialog> {
  late Future<VideoModel> _tutorialVideoFuture;

  @override
  void initState() {
    super.initState();
    _tutorialVideoFuture = VideoService.fetchAppTutorialVideo();
  }

  Future<void> _neverShowAgain() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('never_show_startup_tutorial', true);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _watchVideo(VideoModel video) {
    final streamUrl = video.streamUrl.isNotEmpty
        ? video.streamUrl
        : (video.videoUrl ?? '');

    if (streamUrl.isNotEmpty) {
      FullscreenVideoPlayerScreen.open(
        context,
        videoUrl: streamUrl,
        title: video.title.isNotEmpty ? video.title : 'Smart Learn Ethiopian - Tutorial',
        subtitle: widget.languageCode == 'am' ? 'የመተግበሪያ አጠቃቀም መመሪያ' : 'App Overview & User Guide',
        isDarkMode: widget.isDarkMode,
        languageCode: widget.languageCode,
      );
    } else if (video.youtubeVideoId.isNotEmpty) {
      YouTubeVideoPlayerDialog.show(
        context,
        video: video,
        isDarkMode: widget.isDarkMode,
        languageCode: widget.languageCode,
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VideoComingSoonScreen(
            grade: 12,
            subject: 'App Tutorial',
            unitNumber: 1,
            unitTitle: 'Getting Started',
            isDarkMode: widget.isDarkMode,
            languageCode: widget.languageCode,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = widget.isDarkMode;
    final bool isAmharic = widget.languageCode == 'am';

    final Color dialogBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final Color textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final Color borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: borderColor, width: 1.2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Header Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_circle_filled_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAmharic ? 'እንኳን ደህና መጡ!' : 'Welcome to Smart Learn!',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isAmharic ? 'የመተግበሪያውን አጠቃቀም ቪዲዮ ይመልከቱ' : 'Quick video guide on how to study',
                            style: GoogleFonts.notoSansEthiopic(
                              fontSize: 11.5,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Video Player Preview Card from Supabase database
                    FutureBuilder<VideoModel>(
                      future: _tutorialVideoFuture,
                      builder: (context, snapshot) {
                        final video = snapshot.data ?? VideoService.getAppOverviewVideo();
                        final String thumbUrl = video.thumbnailUrl;

                        return Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                              width: 1.2,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              splashColor: const Color(0xFF00BFFF).withValues(alpha: 0.10),
                              highlightColor: Colors.transparent,
                              onTap: () => _watchVideo(video),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Video Thumbnail with Play Button Overlay
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
                                      // Dark overlay
                                      Container(
                                        height: 140,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.35),
                                        ),
                                      ),
                                      // Play Button
                                      Container(
                                        width: 54,
                                        height: 54,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0284C7),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF0284C7).withValues(alpha: 0.5),
                                              blurRadius: 16,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                      ),
                                      // Live Badge
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.75),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.timer_rounded, size: 12, color: Colors.white),
                                              const SizedBox(width: 4),
                                              Text(
                                                video.durationText ?? 'Tutorial',
                                                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Video Title and Call to action
                                  Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          video.title.isNotEmpty
                                              ? video.title
                                              : (isAmharic
                                                  ? 'የመተግበሪያው አጠቃቀም እና የትምህርት አሰጣጥ ገለፃ'
                                                  : 'Smart Learn Ethiopian Master Tutorial'),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w800,
                                            color: textColor,
                                            height: 1.35,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.touch_app_rounded, size: 14, color: Color(0xFF0284C7)),
                                            const SizedBox(width: 6),
                                            Text(
                                              isAmharic ? 'ቪዲዮውን ለማየት እዚህ ይጫኑ' : 'Tap to watch video tutorial',
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF0284C7),
                                              ),
                                            ),
                                          ],
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

                    const SizedBox(height: 16),

                    // Quick App Highlights
                    _buildFeatureItem(
                      icon: Icons.menu_book_rounded,
                      color: const Color(0xFF0284C7),
                      title: isAmharic ? 'የፒዲኤፍ ማጠቃለያ ማስታወሻዎች' : 'Curriculum PDF Short Notes',
                      desc: isAmharic ? 'የእያንዳንዱን ዩኒት ዋና ዋና ቀመሮች እና ማጠቃለያዎች ያንብቡ' : 'Concise unit notes & formulas from Supabase Storage',
                      textColor: textColor,
                      subColor: subColor,
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureItem(
                      icon: Icons.quiz_rounded,
                      color: const Color(0xFF10B981),
                      title: isAmharic ? 'የፈተና ጥያቄዎች እና መልሶች' : 'National Exam & Unit Quizzes',
                      desc: isAmharic ? 'በጊዜ የተገደቡ ፈተናዎችን በመውሰድ እራስዎን ይፈትሹ' : 'Timed quizzes with detailed answers & explanations',
                      textColor: textColor,
                      subColor: subColor,
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureItem(
                      icon: Icons.cloud_download_rounded,
                      color: const Color(0xFF8B5CF6),
                      title: isAmharic ? 'ከመስመር ውጭ (100% Offline)' : 'Offline Study Access',
                      desc: isAmharic ? 'ያለ ኢንተርኔት በየትኛውም ቦታ እና ሰዓት ማጥናት ይችላሉ' : 'Download units once and study anywhere offline',
                      textColor: textColor,
                      subColor: subColor,
                    ),

                    const SizedBox(height: 22),

                    // Action Buttons: Continue & Never Show Again
                    Row(
                      children: [
                        // Never Show Again Button
                        Expanded(
                          flex: 2,
                          child: TextButton(
                            onPressed: _neverShowAgain,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              isAmharic ? 'ዳግም አታሳይ' : 'Never show again',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: subColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Continue Button
                        Expanded(
                          flex: 3,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              isAmharic ? 'ቀጥል (Continue)' : 'Continue',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
    required Color textColor,
    required Color subColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                desc,
                style: TextStyle(fontSize: 11, color: subColor, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
