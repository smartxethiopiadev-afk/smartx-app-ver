import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/video_model.dart';
import '../services/video_service.dart';
import 'account_upgrade_dialog.dart';
import 'activation_code_dialog.dart';
import 'embedded_video_player.dart';

/// Modal dialog shown when a student attempts to access a locked unit (Unit 2+).
/// Embeds an in-place video preview/tutorial, Upgrade Verification button,
/// Activation Code option, and Telegram Admin contact without navigating away.
class LockedUnitDialog extends StatefulWidget {
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
  State<LockedUnitDialog> createState() => _LockedUnitDialogState();
}

class _LockedUnitDialogState extends State<LockedUnitDialog> {
  bool _isPlayingInPopup = false;
  VideoModel? _unitVideo;
  bool _isLoadingVideo = true;

  @override
  void initState() {
    super.initState();
    _fetchUnitVideo();
  }

  Future<void> _fetchUnitVideo() async {
    try {
      final v = await VideoService.fetchAppTutorialVideo();
      if (mounted) {
        setState(() {
          _unitVideo = v;
          _isLoadingVideo = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _unitVideo = VideoService.getAppOverviewVideo();
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
    final Color borderColor = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155);
    final Color textPrimary = isLight ? const Color(0xFF0F172A) : Colors.white;
    final Color textSecondary = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    final video = _unitVideo ?? VideoService.getAppOverviewVideo();
    final String streamUrl = video.streamUrl.isNotEmpty
        ? video.streamUrl
        : (video.videoUrl ?? 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
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
              // 1. Header with Close Button & Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_rounded, color: Color(0xFFEF4444), size: 14),
                        const SizedBox(width: 5),
                        Text(
                          isAm ? 'ይህ ምዕራፍ ተቆልፏል' : 'Unit Locked',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFEF4444),
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

              const SizedBox(height: 12),

              // 2. Unit Title & Subject Badge
              Text(
                'Grade ${widget.grade} ${widget.subject} • Unit ${widget.unitNumber}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: textPrimary,
                ),
              ),
              if (widget.unitTitle != null && widget.unitTitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  widget.unitTitle!,
                  style: GoogleFonts.notoSansEthiopic(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // 3. In-Popup Embedded Video Player / Preview Card
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  height: 190,
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
                          title: 'Grade ${widget.grade} ${widget.subject} Unit ${widget.unitNumber}',
                          subtitle: isAm ? 'የመተግበሪያ አጠቃቀም እና ይዘት ማጠቃለያ' : 'Curriculum Overview Video',
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
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD97706),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFD97706).withValues(alpha: 0.5),
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
                                    const SizedBox(height: 8),
                                    Text(
                                      isAm ? 'የቪዲዮ መመሪያውን እይ' : 'Watch Tutorial & Overview Video',
                                      style: GoogleFonts.notoSansEthiopic(
                                        fontSize: 12,
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

              const SizedBox(height: 14),

              // 4. Trial & Single Device Explanation Note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFF0284C7), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isAm
                            ? 'ምዕራፍ 1 ነፃ የሙከራ (Free Trial) ሲሆን ቀጣዮቹን ምዕራፎች በ 50 ብር በመክፈል ለዚህ ስልክ በቋሚነት ይክፈቱ።'
                            : 'Unit 1 is free. Upgrade via Telegram to permanently unlock all units on this device.',
                        style: GoogleFonts.notoSansEthiopic(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 5. Button 1: Upgrade & Verify
              SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    final upgraded = await AccountUpgradeDialog.show(
                      context,
                      isDarkMode: widget.isDarkMode,
                      languageCode: widget.languageCode,
                      initialGrade: widget.grade,
                    );
                    if (upgraded == true) {
                      widget.onUnlocked?.call();
                    }
                  },
                  icon: const Icon(Icons.verified_user_rounded, size: 18, color: Colors.white),
                  label: Text(
                    isAm ? 'አካውንት አረጋግጥና ክፈት' : 'Verify & Unlock Account',
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

              // 6. Button 2: Enter Activation Code
              SizedBox(
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ActivationCodeDialog.show(
                      context,
                      isDarkMode: widget.isDarkMode,
                      languageCode: widget.languageCode,
                      preferredGrade: widget.grade,
                      onActivated: widget.onUnlocked,
                    );
                  },
                  icon: const Icon(Icons.vpn_key_rounded, size: 16, color: Color(0xFF0284C7)),
                  label: Text(
                    isAm ? 'የማግበሪያ ኮድ አስገባ (Activation Code)' : 'Enter Activation Code',
                    style: GoogleFonts.notoSansEthiopic(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0284C7),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // 7. Button 3: Telegram Admin Contact
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
                    isAm ? 'በቴሌግራም አድሚኑን ያግኙ (@smart_x_help)' : 'Contact Admin on Telegram',
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
}
