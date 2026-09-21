import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'account_upgrade_dialog.dart';
import 'upgrade_telegram_modal.dart';
import 'how_to_start_banner.dart';

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

  @override
  Widget build(BuildContext context) {
    final bool isLight = !isDarkMode;
    final bool isAm = languageCode == 'am';

    final Color dialogBg = isLight ? Colors.white : const Color(0xFF1E293B);
    final Color borderColor = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155);
    final Color textPrimary = isLight ? const Color(0xFF0F172A) : Colors.white;
    final Color textSecondary = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
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
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Lock Icon Header with glowing accent ring
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                    width: 2,
                  ),
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
                isAm ? 'ይህ ምዕራፍ ተቆልፏል 🔒' : 'Chapter Locked 🔒',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansEthiopic(
                  fontSize: 18.5,
                  fontWeight: FontWeight.w900,
                  color: textPrimary,
                ),
              ),

              const SizedBox(height: 6),

              // Badge: Unit 1 Free Information
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF0284C7), size: 15),
                    const SizedBox(width: 6),
                    Text(
                      isAm ? 'ምዕራፍ 1 ለሁሉም 100% ነፃ ነው' : 'Unit 1 is 100% Free Trial',
                      style: GoogleFonts.notoSansEthiopic(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Informative description
              Text(
                isAm
                    ? 'ክፍል $grade ምዕራፍ $unitNumber እና ቀጣዮቹን ትምህርቶች ለመክፈት አካውንትዎን ያሻሽሉ ወይም የማግበሪያ ኮድ (Activation Code) ያስገቡ።'
                    : 'To unlock Grade $grade Unit $unitNumber and complete curriculum materials, please upgrade your account or enter your activation code.',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansEthiopic(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 22),

              // 1. Primary Action: Account Upgrade / Activation (አካውንት ያሻሽሉ / Upgrade Account)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    final upgraded = await AccountUpgradeDialog.show(
                      context,
                      isDarkMode: isDarkMode,
                      languageCode: languageCode,
                      initialGrade: grade,
                    );
                    if (upgraded == true) {
                      onUnlocked?.call();
                    }
                  },
                  icon: const Icon(Icons.workspace_premium_rounded, size: 20, color: Colors.white),
                  label: Text(
                    isAm ? 'አካውንት ያሻሽሉ (Account Upgrade)' : 'Upgrade Account & Unlock',
                    style: GoogleFonts.notoSansEthiopic(
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 2. Secondary Action: Telegram Payment / Upgrade
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await UpgradeTelegramModal.show(
                      context,
                      grade: grade,
                      isDarkMode: isDarkMode,
                      languageCode: languageCode,
                    );
                    onUnlocked?.call();
                  },
                  icon: const Icon(Icons.send_rounded, size: 18, color: Color(0xFF0088CC)),
                  label: Text(
                    isAm ? 'በቴሌግራም ይክፈሉ / ያነጋግሩ (@smart_x_help)' : 'Purchase on Telegram (@smart_x_help)',
                    style: GoogleFonts.notoSansEthiopic(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: const Color(0xFF0088CC),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0088CC), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // 3. Dismiss Action: Close
              SizedBox(
                width: double.infinity,
                height: 38,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: textSecondary,
                  ),
                  child: Text(
                    isAm ? 'ዝጋ (Close)' : 'Close',
                    style: GoogleFonts.notoSansEthiopic(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
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
