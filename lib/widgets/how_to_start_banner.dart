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
            : 'Choose your enrolled grade level (Grade 9 to 12) from the home page header. Browse Mathematics, Physics, Chemistry, Biology, English and other subjects.',
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
        'title': isAm ? '3. ቀጣይ ክፍሎችን ለመክፈት አድሚኑን ያነጋግሩ' : '3. Contact Admin for Package Unlock',
        'icon': Icons.admin_panel_settings_rounded,
        'color': const Color(0xFF0088CC),
        'text': isAm
            ? 'ክፍል 2 እና ቀጣዮቹን (Unit 2+) ሙሉ በሙሉ ለመክፈት አድሚኑን በቴሌግራም ቀጥታ ያነጋግሩ (@EthioconceptcenterAdmin)። የተከፈተልዎት ፓኬጅ በስልክዎ ላይ በደህንነት ይዘጋጃል።'
            : 'To unlock Unit 2 and all remaining chapters, contact the official Telegram Admin directly (@EthioconceptcenterAdmin). The admin will instantly unlock your single-device package.',
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
                          isAm ? 'እንዴት ልጀምር? (ሙሉ ረዘም ያለ መመሪያ)' : 'How to Start? (Detailed Guide)',
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

              // Steps List in Dialog with Admin Contact emphasis
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

              const SizedBox(height: 12),

              // Single Direct Action Button: Direct Telegram Admin Contact (@EthioconceptcenterAdmin)
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    final Uri adminUri = Uri.parse('https://t.me/EthioconceptcenterAdmin');
                    if (await canLaunchUrl(adminUri)) {
                      await launchUrl(adminUri, mode: LaunchMode.externalApplication);
                    } else {
                      final Uri fallbackAdminUri = Uri.parse('https://t.me/Ethioconceptcenter');
                      if (await canLaunchUrl(fallbackAdminUri)) {
                        await launchUrl(fallbackAdminUri, mode: LaunchMode.externalApplication);
                      }
                    }
                  },
                  icon: const Icon(Icons.person_outline_rounded, size: 20, color: Colors.white),
                  label: Text(
                    isAm ? 'አድሚኑን በቴሌግራም ያነጋግሩ (Contact Admin)' : 'Contact Admin on Telegram',
                    style: GoogleFonts.notoSansEthiopic(
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
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
                    isAm ? 'እንዴት ልጀምር? (ሙሉ መመሪያ)' : 'How to Start? (Usage Guide)',
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
