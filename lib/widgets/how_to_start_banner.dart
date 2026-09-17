import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

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

  void _showHowToStartPopUp(BuildContext context) {
    final bool isLight = !isDarkMode;
    final bool isAm = languageCode == 'am';

    final Color dialogBg = isLight ? Colors.white : const Color(0xFF1E293B);
    final Color textPrimary = isLight ? const Color(0xFF0F172A) : Colors.white;
    final Color textSecondary = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    final steps = [
      {
        'num': '1',
        'title': isAm ? '1. ክፍልዎንና የትምህርት አይነትዎን ይምረጡ' : '1. Select Your Grade & Subject',
        'icon': Icons.school_rounded,
        'color': const Color(0xFF0284C7),
        'text': isAm
            ? 'በመተግበሪያው የመነሻ ገጽ ላይ ከ 9ኛ እስከ 12ኛ ክፍል የሚፈልጉትን ክፍል ይምረጡ። ከዚያም ሂሳብ፣ ፊዚክስ፣ ኬሚስትሪ፣ ባዮሎጂ ወይም ሌሎች የትምህርት አይነቶችን ይክፈቱ።'
            : 'Choose your enrolled grade level (Grade 9 to 12) from the home page. Browse Mathematics, Physics, Chemistry, Biology, English and other subjects.',
      },
      {
        'num': '2',
        'title': isAm ? '2. ክፍል 1ን በነፃ አጠናቀው እራስዎን ይፈትሹ' : '2. Study Unit 1 100% Free',
        'icon': Icons.check_circle_outline_rounded,
        'color': const Color(0xFF10B981),
        'text': isAm
            ? 'የሁሉም የትምህርት አይነቶች ክፍል 1 (Unit 1) ማስታወሻዎች፣ የቪዲዮ ማብራሪያዎች እና የፈተና ጥያቄዎች በነፃ ክፍት የተደረጉ ናቸው። የትምህርቱን ጥራት በነፃ ሞክረው ያረጋግጡ።'
            : 'Unit 1 for all subjects is completely free for all registered students. Access detailed textbook notes, video tutorials, and interactive quizzes without payment.',
      },
      {
        'num': '3',
        'title': isAm ? '3. ቀጣይ ክፍሎችን በ50 ብር ብቻ ይክፈቱ' : '3. Unlock Chapters for Only 50 ETB',
        'icon': Icons.admin_panel_settings_rounded,
        'color': const Color(0xFF0088CC),
        'text': isAm
            ? 'ክፍል 2 እና ቀጣዮቹን (Unit 2+) ሙሉ በሙሉ ለመክፈት በ 50 ብር ክፍያ ብቻ አድሚኑን በቴሌግራም ቀጥታ ያነጋግሩ (@smart_x_help)። ክፍያውን እንዳጠናቀቁ ፓኬጁ በስልክዎ ላይ በቋሚነት ይከፈትልዎታል።'
            : 'To unlock Unit 2 and all remaining chapters for only 50 ETB, contact our official Telegram Admin (@smart_x_help). Your package will be unlocked for your device lifetime.',
      },
      {
        'num': '4',
        'title': isAm ? '4. ያለ ኢንተርኔት (100% Offline) ያጥኑ' : '4. Download & Study 100% Offline',
        'icon': Icons.wifi_off_rounded,
        'color': const Color(0xFF8B5CF6),
        'text': isAm
            ? 'አንዴ የወረዱ ማስታወሻዎች እና ጥያቄዎች ያለ ምንም ኢንተርኔት በማንኛውም ቦታ እና ጊዜ ይሰራሉ። የፈተና ውጤትዎን በስልክዎ መዝግበው ይከታተሉ።'
            : 'Once unlocked and downloaded, study all short notes and practice quizzes completely offline without requiring any internet connection.',
      },
    ];

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Tag & Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.help_outline_rounded,
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
                          isAm ? 'እንዴት ልጀምር? (ግልፅ መመሪያ)' : 'How to Start? (Clear Guide)',
                          style: GoogleFonts.notoSansEthiopic(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isAm ? 'የስማርት ለርን ኢትዮጵያ አጠቃቀም መመሪያ' : 'Smart Learn Ethiopia Usage Workflow',
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

              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 18),

              // Steps List
              ...steps.map((step) {
                final Color itemColor = step['color'] as Color;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: itemColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            step['num'] as String,
                            style: TextStyle(
                              color: itemColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step['title'] as String,
                              style: GoogleFonts.notoSansEthiopic(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              step['text'] as String,
                              style: GoogleFonts.notoSansEthiopic(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 8),

              // Pricing highlight box (50 ETB / 50 ብር)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on_rounded, color: Color(0xFF10B981), size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isAm
                            ? 'የክፍያ ዋጋ፡ ለእያንዳንዱ ትምህርት / ዩኒት 50 ብር ብቻ! ለመክፈል አድሚኑን @smart_x_help ያነጋግሩ።'
                            : 'Price: Only 50 ETB per subject / unit! Contact admin @smart_x_help to unlock.',
                        style: GoogleFonts.notoSansEthiopic(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Contact Admin Button (@smart_x_help)
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    final Uri adminUri = Uri.parse('https://t.me/smart_x_help');
                    if (await canLaunchUrl(adminUri)) {
                      await launchUrl(adminUri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.person_outline_rounded, size: 20, color: Colors.white),
                  label: Text(
                    isAm ? 'አድሚኑን በቴሌግራም ያነጋግሩ (@smart_x_help)' : 'Contact Admin on Telegram (@smart_x_help)',
                    style: GoogleFonts.notoSansEthiopic(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0088CC),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Join Community Channel Button (https://t.me/SmartX_Discussion)
              SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    final Uri channelUri = Uri.parse('https://t.me/SmartX_Discussion');
                    if (await canLaunchUrl(channelUri)) {
                      await launchUrl(channelUri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.groups_rounded, size: 18, color: Color(0xFF0088CC)),
                  label: Text(
                    isAm ? 'የቴሌግራም ቻናላችንን ይቀላቀሉ' : 'Join Telegram Discussion Channel',
                    style: GoogleFonts.notoSansEthiopic(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
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
                    Icons.help_outline_rounded,
                    color: Color(0xFF0284C7),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isAm ? 'እንዴት ልጀምር? (ሙሉ ግልፅ መመሪያ)' : 'How to Start? (Clear Usage Guide)',
                    style: GoogleFonts.notoSansEthiopic(
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
                    isAm ? 'እይ (View)' : 'View',
                    style: GoogleFonts.notoSansEthiopic(
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
