import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_fullName') ?? prefs.getString('user_name') ?? 'ተማሪ';
    final userPhone = prefs.getString('user_phoneNumber') ?? prefs.getString('phone_number') ?? '';

    final String message =
        'ሰላም አድሚን፣ የክፍል $grade $subject ክፍል $unitNumber ለማስከፈት ፈልጌ ነበር። የተማሪ ስም: $userName፣ ስልክ ቁጥር: $userPhone';

    final Uri telegramUri =
        Uri.parse('https://t.me/EthioconceptcenterAcademy?text=${Uri.encodeComponent(message)}');

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
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = !isDarkMode;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: isLight ? Colors.white : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
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
              // Lock Icon Header
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Color(0xFFEF4444),
                  size: 34,
                ),
              ),

              const SizedBox(height: 16),

              // Title
              Text(
                'ይህ ክፍል ተቆልፏል 🔒',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansEthiopic(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isLight ? const Color(0xFF0F172A) : Colors.white,
                ),
              ),

              const SizedBox(height: 12),

              // Short Copy
              Text(
                'ክፍል 1 ለሁሉም ተማሪዎች 100% ነፃ ነው! ክፍል $unitNumber እና ቀጣዮቹን ክፍሎች ለማስከፈት አድሚኑን በቴሌግራም ያነጋግሩ።',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansEthiopic(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: isLight ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 22),

              // Primary Action Button: "በቴሌግራም አድሚኑን ያነጋግሩ"
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => _contactTelegramAdmin(context),
                  icon: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                  label: Text(
                    'በቴሌግራም አድሚኑን ያነጋግሩ',
                    style: GoogleFonts.notoSansEthiopic(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0088CC),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Secondary Action Button: "ዝጋ (Close)"
              SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                  child: Text(
                    'ዝጋ (Close)',
                    style: GoogleFonts.notoSansEthiopic(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
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
