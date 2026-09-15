import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/login_activation_screen.dart';

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
        'icon': Icons.school_rounded,
        'color': const Color(0xFF0084FF),
        'title': isAm ? 'ክፍልዎን ይምረጡ' : 'Select Your Grade',
        'desc': isAm
            ? 'ከክፍል 9 እስከ 12 ድረስ የእርስዎን ክፍል ይምረጡ። ክፍል 1 ለሁሉም ትምህርቶች ነፃ ነው።'
            : 'Choose your Grade (9–12). Unit 1 of every subject is 100% FREE.',
      },
      {
        'num': '2',
        'icon': Icons.menu_book_rounded,
        'color': const Color(0xFF10B981),
        'title': isAm ? 'ማጠቃለያ እና ቪዲዮዎችን ይክፈቱ' : 'Access Short Notes & Videos',
        'desc': isAm
            ? 'ምርጥ የአጭር ማጠቃለያ ማስታወሻዎችን፣ ቀመሮችን እና የማስተርክላስ ቪዲዮዎችን ያግኙ።'
            : 'Read chapter summary notes, vector formulas, and watch video masterclasses.',
      },
      {
        'num': '3',
        'icon': Icons.send_rounded,
        'color': const Color(0xFF0088CC),
        'title': isAm ? 'በቴሌግራም አድሚኑን ያነጋግሩ' : 'Contact Telegram Admin',
        'desc': isAm
            ? 'በቴሌግራም አድሚኑን በማነጋገር ስም፣ ስልክ እና የይለፍ ቃል ተቀብለው መለያዎን ለአንድ ስልክ ያግብሩ።'
            : 'Contact admin on Telegram to receive credentials and unlock subjects on this device.',
      },
      {
        'num': '4',
        'icon': Icons.wifi_off_rounded,
        'color': const Color(0xFF8B5CF6),
        'title': isAm ? '100% ከመስመር ውጭ (Offline) ይጠቀሙ' : 'Study 100% Offline',
        'desc': isAm
            ? 'ያለ ኢንተርኔት ኮኔክሽን በየትኛውም ቦታ እና ጊዜ በጥራት ያጥኑ።'
            : 'Download contents once and learn anytime without internet data fees.',
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
                      color: const Color(0xFF0084FF).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.rocket_launch_rounded,
                      color: Color(0xFF0084FF),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAm ? 'እንዴት እንጀምር?' : 'How to Get Started?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          isAm ? '4 ቀላል ደረጃዎች በስልክዎ ለማጠናናት' : '4 Simple steps to start learning',
                          style: TextStyle(fontSize: 12, color: textSecondary),
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

              // Steps List in Dialog
              ...steps.map((step) {
                final Color itemColor = step['color'] as Color;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Numbered Badge
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: itemColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: itemColor.withValues(alpha: 0.3), width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            step['num'] as String,
                            style: TextStyle(
                              color: itemColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(step['icon'] as IconData, size: 16, color: itemColor),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    step['title'] as String,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              step['desc'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                                height: 1.4,
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

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        LoginActivationScreen.push(
                          context,
                          isDarkMode: isDarkMode,
                          languageCode: languageCode,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF0084FF)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        isAm ? 'መለያ ግባ' : 'Login',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0084FF)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        final Uri telegramUri = Uri.parse('https://t.me/smartxsupport');
                        if (await canLaunchUrl(telegramUri)) {
                          await launchUrl(telegramUri, mode: LaunchMode.externalApplication);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0088CC),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                              Positioned(
                                right: -3,
                                top: -3,
                                child: Container(
                                  padding: const EdgeInsets.all(1.5),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add, size: 7, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isAm ? 'ቴሌግራም አግኙን' : 'Contact Admin',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
    final Color textSecondary = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Icon Box
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0084FF), Color(0xFF00BFFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0084FF).withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.rocket_launch_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Text details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            isAm ? 'እንዴት እንጀምር?' : 'How to Start?',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0084FF).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isAm ? '4 ደረጃዎች' : '4 STEPS',
                              style: const TextStyle(
                                color: Color(0xFF0084FF),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAm ? 'መመሪያዎቹን በይዘት Pop-up ለማየት ይጫኑ' : 'Tap to view step-by-step guide dialog',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Button Indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0084FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Text(
                        isAm ? 'መመሪያ' : 'Guide',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0084FF),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.open_in_new_rounded,
                        color: Color(0xFF0084FF),
                        size: 14,
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
