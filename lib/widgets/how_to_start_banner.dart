import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/video_model.dart';
import '../services/video_service.dart';
import 'account_upgrade_dialog.dart';
import 'embedded_video_player.dart';

/// Interactive "How to Start" banner & popup dialog that displays an in-place video-first guide
/// directly on the Home page with Grade options and Action buttons without navigating away.
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

  /// Opens the in-place Usage Guide Popup Dialog on the Home page
  static void showUsageGuide(
    BuildContext context, {
    required bool isDarkMode,
    required String languageCode,
    int? grade,
    Function(int grade)? onGradeSelected,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _HowToStartPopupDialog(
        isDarkMode: isDarkMode,
        languageCode: languageCode,
        initialGrade: grade ?? 12,
        onGradeSelected: onGradeSelected,
      ),
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
          onTap: () => showUsageGuide(
            context,
            isDarkMode: isDarkMode,
            languageCode: languageCode,
            onGradeSelected: onGradeSelected,
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isAm ? 'እይ (Watch)' : 'Watch',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0284C7),
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

/// In-place stateful popup dialog that embeds the video player and grade guide
class _HowToStartPopupDialog extends StatefulWidget {
  final bool isDarkMode;
  final String languageCode;
  final int initialGrade;
  final Function(int grade)? onGradeSelected;

  const _HowToStartPopupDialog({
    required this.isDarkMode,
    required this.languageCode,
    required this.initialGrade,
    this.onGradeSelected,
  });

  @override
  State<_HowToStartPopupDialog> createState() => _HowToStartPopupDialogState();
}

class _HowToStartPopupDialogState extends State<_HowToStartPopupDialog> {
  late int _selectedGrade;
  bool _isPlayingInPopup = false;
  VideoModel? _tutorialVideo;
  bool _isLoadingVideo = true;

  @override
  void initState() {
    super.initState();
    _selectedGrade = widget.initialGrade;
    _fetchVideo();
  }

  Future<void> _fetchVideo() async {
    try {
      final v = await VideoService.fetchAppTutorialVideo();
      if (mounted) {
        setState(() {
          _tutorialVideo = v;
          _isLoadingVideo = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _tutorialVideo = VideoService.getAppOverviewVideo();
          _isLoadingVideo = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = !widget.isDarkMode;
    final bool isAm = widget.languageCode == 'am';

    final Color dialogBg = isLight ? Colors.white : const Color(0xFF1E293B);
    final Color textPrimary = isLight ? const Color(0xFF0F172A) : Colors.white;
    final Color textSecondary = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final Color borderColor = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155);

    final video = _tutorialVideo ?? VideoService.getAppOverviewVideo();
    final String streamUrl = video.streamUrl.isNotEmpty
        ? video.streamUrl
        : (video.videoUrl ?? 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header with Close Button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.smart_display_rounded,
                      color: Color(0xFF0284C7),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
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
                        Text(
                          isAm ? 'የመተግበሪያውን አጠቃቀም በቪዲዮ ይመልከቱ' : 'Step-by-step video guide & overview',
                          style: GoogleFonts.notoSansEthiopic(
                            fontSize: 11.5,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textSecondary, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 2. In-Popup Embedded Video Player Card
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                  ),
                  child: _isPlayingInPopup
                      ? EmbeddedVideoPlayer(
                          videoUrl: streamUrl,
                          title: video.title.isNotEmpty
                              ? video.title
                              : (isAm ? 'የመተግበሪያ አጠቃቀም መመሪያ' : 'Smart Learn Tutorial'),
                          subtitle: 'Smart Learn Ethiopian • Grade $_selectedGrade',
                          isDarkMode: widget.isDarkMode,
                          languageCode: widget.languageCode,
                          autoPlay: true,
                        )
                      : Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _isPlayingInPopup = true;
                              });
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (video.thumbnailUrl.isNotEmpty)
                                  Positioned.fill(
                                    child: Image.network(
                                      video.thumbnailUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                    ),
                                  ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black.withValues(alpha: 0.3),
                                        Colors.black.withValues(alpha: 0.75),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
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
                                    const SizedBox(height: 10),
                                    Text(
                                      isAm ? 'ቪዲዮውን ለማጫወት ይንኩ' : 'Tap to Play Tutorial Video',
                                      style: GoogleFonts.notoSansEthiopic(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // 3. Grade Options Selector
              Text(
                isAm ? 'የትምህርት ክፍል ይምረጡ (Select Grade)' : 'Select Your Grade',
                style: GoogleFonts.notoSansEthiopic(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [9, 10, 11, 12].map((g) {
                  final bool isSelected = _selectedGrade == g;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedGrade = g;
                          });
                          widget.onGradeSelected?.call(g);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF0284C7)
                                : (isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF0284C7) : borderColor,
                              width: isSelected ? 1.8 : 1.0,
                            ),
                          ),
                          child: Text(
                            'Grade $g',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                              color: isSelected ? Colors.white : textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 14),

              // 4. Feature Highlights Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    _buildFeatureItem(
                      Icons.offline_pin_rounded,
                      isAm ? '100% ከመስመር ውጭ ይሰራል (100% Offline)' : '100% Offline Capable without Internet',
                      const Color(0xFF10B981),
                      textPrimary,
                    ),
                    const SizedBox(height: 6),
                    _buildFeatureItem(
                      Icons.menu_book_rounded,
                      isAm ? 'ምዕራፍ 1 ለሁሉም ክፍሎች ሙሉ በሙሉ ነፃ ነው' : 'Unit 1 is 100% Free Trial for all subjects',
                      const Color(0xFF0284C7),
                      textPrimary,
                    ),
                    const SizedBox(height: 6),
                    _buildFeatureItem(
                      Icons.quiz_rounded,
                      isAm ? 'የብሔራዊ ፈተናዎች እና የልምምድ ጥያቄዎች' : 'National Model Exams & Practice Quizzes',
                      const Color(0xFFD97706),
                      textPrimary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 5. Action Buttons (In-place popup triggers)
              SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    AccountUpgradeDialog.show(
                      context,
                      isDarkMode: widget.isDarkMode,
                      languageCode: widget.languageCode,
                      initialGrade: _selectedGrade,
                    );
                  },
                  icon: const Icon(Icons.vpn_key_rounded, size: 18, color: Colors.white),
                  label: Text(
                    isAm ? 'አካውንት አረጋግጥና ክፈት' : 'Upgrade & Verify Account',
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

              const SizedBox(height: 8),

              // Telegram Support Link Button
              SizedBox(
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
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

  Widget _buildFeatureItem(IconData icon, String text, Color iconColor, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.notoSansEthiopic(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}
