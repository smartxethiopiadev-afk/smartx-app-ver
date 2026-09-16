import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/login_activation_screen.dart';
import '../widgets/youtube_video_player_dialog.dart';
import '../models/video_model.dart';

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

  Future<void> _contactTelegramAdmin(BuildContext context) async {
    final String inquiry =
        'ሰላም Ethio Concept Center Admin, የ Grade $grade $subject ክፍል $unitNumber መለያ (Name, Phone, Password) ለማስከፈት ፈልጌ ነበር።';
    final Uri telegramUri = Uri.parse('https://t.me/EthioconceptcenterAcademy?text=${Uri.encodeComponent(inquiry)}');

    try {
      if (await canLaunchUrl(telegramUri)) {
        await launchUrl(telegramUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(telegramUri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ቴሌግራም ላይ @EthioconceptcenterAcademy ያነጋግሩ'),
            backgroundColor: Color(0xFF0088CC),
          ),
        );
      }
    }
  }

  void _openVideoGuide(BuildContext context) {
    // Demonstration video guide on how to activate account with Telegram admin
    YouTubeVideoPlayerDialog.show(
      context,
      video: VideoModel(
        id: 'guide_activation',
        grade: grade,
        subject: subject,
        unitNumber: unitNumber,
        title: languageCode == 'am'
            ? 'መለያዎን በአድሚን እንዴት እንደሚያስከፍቱ (የቪዲዮ መመሪያ)'
            : 'How to Unlock Account via Telegram Admin (Video Guide)',
        youtubeVideoId: 'fJ9rUzIMcZQ',
      ),
      isDarkMode: isDarkMode,
      languageCode: languageCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAm = languageCode == 'am';
    final bool isLight = !isDarkMode;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: isLight ? Colors.white : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with gradient banner & lock badge
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(22),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lock_rounded, size: 14, color: Colors.white),
                              const SizedBox(width: 5),
                              Text(
                                'Unit $unitNumber Locked',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_person_rounded,
                        color: Color(0xFFEF4444),
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isAm ? 'ይህ ክፍል ተቆልፏል!' : 'Content is Locked!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Grade $grade • $subject • Unit $unitNumber',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              // Content Body
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Video Guide Card
                    InkWell(
                      onTap: () => _openVideoGuide(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0088CC).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF0088CC).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0088CC),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        isAm ? 'የቪዲዮ መመሪያ (ቪዲዮ ይመልከቱ)' : 'Video Tutorial (Watch Guide)',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12.5,
                                          color: Color(0xFF0088CC),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isAm
                                        ? 'በቴሌግራም መለያ እንዴት እንደሚከፈት ደረጃ በደረጃ'
                                        : 'Step-by-step account activation via Telegram',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: Color(0xFF0088CC),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Explanation Notice
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStepRow(
                            '1',
                            isAm
                                ? 'ክፍል 1 (Unit 1) ለሁሉም ተማሪዎች 100% ነፃ ነው'
                                : 'Unit 1 is 100% free for preview',
                            isLight,
                          ),
                          const SizedBox(height: 8),
                          _buildStepRow(
                            '2',
                            isAm
                                ? 'ክፍል 2 እና ቀጣዮቹን ለመክፈት በቴሌግራም አድሚኑን ያነጋግሩ'
                                : 'Contact Admin on Telegram to unlock Unit 2 and above',
                            isLight,
                          ),
                          const SizedBox(height: 8),
                          _buildStepRow(
                            '3',
                            isAm
                                ? 'አድሚኑ ሙሉ ስም (Name)፣ ስልክ (Phone) እና ይለፍ ቃል (Password) ይሰጥዎታል'
                                : 'Admin will provide your Full Name, Phone, and Password',
                            isLight,
                          ),
                          const SizedBox(height: 8),
                          _buildStepRow(
                            '4',
                            isAm
                                ? 'ይህ መለያ ለአንዴና ለዚህ ስልክ ብቻ ቋሚ ሆኖ የተፈቀደለትን ትምህርት ብቻ ይከፍታል'
                                : 'Credentials permanently unlock authorized subjects on 1 device only',
                            isLight,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Telegram Contact DM Button
                    ElevatedButton(
                      onPressed: () => _contactTelegramAdmin(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0088CC),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                              Positioned(
                                right: -3,
                                top: -3,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add, size: 8, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isAm ? 'በቴሌግራም አድሚኑን አግኝ (DM Admin)' : 'Contact Admin on Telegram',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Login with Credentials Button
                    OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        final result = await LoginActivationScreen.push(
                          context,
                          isDarkMode: isDarkMode,
                          languageCode: languageCode,
                          preferredGrade: grade,
                          preferredSubject: subject,
                        );
                        if (result == true) {
                          onUnlocked?.call();
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: Icon(
                        Icons.key_rounded,
                        size: 18,
                        color: isLight ? const Color(0xFF0F172A) : Colors.white,
                      ),
                      label: Text(
                        isAm ? 'የይለፍ ቃል አለኝ (Login)' : 'I have credentials (Login)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isLight ? const Color(0xFF0F172A) : Colors.white,
                        ),
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
  }

  Widget _buildStepRow(String stepNumber, String text, bool isLight) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFEF4444),
            shape: BoxShape.circle,
          ),
          child: Text(
            stepNumber,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.35,
              color: isLight ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            ),
          ),
        ),
      ],
    );
  }
}
