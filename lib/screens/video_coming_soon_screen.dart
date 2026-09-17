import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoComingSoonScreen extends StatelessWidget {
  final int grade;
  final String subject;
  final int unitNumber;
  final String unitTitle;
  final bool isDarkMode;
  final String languageCode;

  const VideoComingSoonScreen({
    super.key,
    required this.grade,
    required this.subject,
    required this.unitNumber,
    required this.unitTitle,
    required this.isDarkMode,
    required this.languageCode,
  });

  Future<void> _launchTelegram(BuildContext context) async {
    final String msg = Uri.encodeComponent(
      'ሰላም Smart Learn Ethiopia, Grade $grade $subject Unit $unitNumber የቪዲዮ ትምህርት መቼ እንደሚለቀቅ ለማወቅ እና ቻናሉን ለመቀላቀል ፈልጌ ነው።',
    );
    final Uri telegramUri = Uri.parse('https://t.me/SmartX_Discussion?text=$msg');
    try {
      if (await canLaunchUrl(telegramUri)) {
        await launchUrl(telegramUri, mode: LaunchMode.externalApplication);
      } else {
        final Uri fallbackUri = Uri.parse('https://t.me/SmartX_Discussion');
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Telegram. Please visit @SmartX_Discussion'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
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

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: isEn ? 'Back to Units' : 'ወደ ዩኒቶች ተመለስ',
        ),
        title: Text(
          isEn ? 'Grade $grade • $subject' : '$gradeኛ ክፍል • $subject',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: borderColor, height: 1.0),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Badge Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: isLight ? 0.1 : 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFFEF4444)),
                    const SizedBox(width: 6),
                    Text(
                      isEn ? 'Unit $unitNumber Video Lesson' : 'ክፍል $unitNumber የቪዲዮ ትምህርት',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Elegant Illustration with glow
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF0088CC).withValues(alpha: isLight ? 0.18 : 0.28),
                          const Color(0xFF0088CC).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: cardBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isLight ? 0.06 : 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.smart_display_rounded,
                        size: 48,
                        color: Color(0xFF0088CC),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                isEn ? 'Video Lessons Coming Soon!' : 'የቪዲዮ ትምህርቶች በቅርቡ ይለቀቃሉ!',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  height: 1.25,
                ),
              ),

              const SizedBox(height: 8),

              // Unit Title Subheading
              if (unitTitle.isNotEmpty)
                Text(
                  unitTitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0084FF),
                  ),
                ),

              const SizedBox(height: 16),

              // Descriptive Body Text
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Text(
                      isEn
                          ? 'High quality animated and conceptual video lectures are in active production by educators at Smart Learn Ethiopian and will be released in the upcoming update.'
                          : 'ለዚህ ዩኒት ጥራት ያላቸው የቪዲዮ ማብራሪያዎች በስማርት ለርን ኢትዮጵያን መምህራን በከፍተኛ ጥራት እየተዘጋጁ ሲሆን በቅርቡ ይለቀቃሉ።',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: subColor,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(color: borderColor, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.notifications_active_rounded,
                            size: 18, color: Color(0xFF0088CC)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isEn
                                ? 'Join our Telegram channel to receive instant notification as soon as new video lessons are uploaded.'
                                : 'አዳዲስ የቪዲዮ ትምህርቶች ሲጫኑ ፈጥነው ለማግኘት የቴሌግራም ቻናላችንን ይቀላቀሉ።',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Action 1: Join Telegram Channel
              ElevatedButton.icon(
                onPressed: () => _launchTelegram(context),
                icon: const Icon(Icons.send_rounded, size: 20),
                label: Text(
                  isEn ? 'Join Telegram Channel' : 'የቴሌግራም ቻናላችንን ተቀላቀል',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0088CC),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
              ),

              const SizedBox(height: 12),

              // Action 2: Back Button
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: Text(
                  isEn ? 'Back to Unit List' : 'ወደ ዩኒት ዝርዝር ተመለስ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: subColor,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: borderColor),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
