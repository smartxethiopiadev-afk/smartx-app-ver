import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/subscription_service.dart';

class UpgradeTelegramModal extends StatefulWidget {
  final int grade;
  final String? packageName;
  final int? unitNumber;
  final String? unitTitle;
  final String languageCode;
  final bool isDarkMode;
  final VoidCallback? onPackageUnlocked;

  const UpgradeTelegramModal({
    super.key,
    required this.grade,
    this.packageName,
    this.unitNumber,
    this.unitTitle,
    this.languageCode = 'en',
    this.isDarkMode = false,
    this.onPackageUnlocked,
  });

  static Future<void> show(
    BuildContext context, {
    required int grade,
    String? packageName,
    int? unitNumber,
    String? unitTitle,
    String languageCode = 'en',
    bool isDarkMode = false,
    VoidCallback? onPackageUnlocked,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UpgradeTelegramModal(
        grade: grade,
        packageName: packageName,
        unitNumber: unitNumber,
        unitTitle: unitTitle,
        languageCode: languageCode,
        isDarkMode: isDarkMode,
        onPackageUnlocked: onPackageUnlocked,
      ),
    );
  }

  @override
  State<UpgradeTelegramModal> createState() => _UpgradeTelegramModalState();
}

class _UpgradeTelegramModalState extends State<UpgradeTelegramModal> {
  String _studentName = '';
  String _studentPhone = '';
  bool _isLoading = true;
  bool _isActivating = false;
  final TextEditingController _codeController = TextEditingController();
  bool _showCodeInput = false;

  @override
  void initState() {
    super.initState();
    _loadStudentInfo();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _studentName = prefs.getString('user_fullName') ??
          prefs.getString('user_name') ??
          'Smart X Student';
      _studentPhone = prefs.getString('user_phoneNumber') ??
          prefs.getString('phone_number') ??
          '';
      _isLoading = false;
    });
  }

  String get _effectivePackageName {
    if (widget.packageName != null && widget.packageName!.isNotEmpty) {
      return widget.packageName!;
    }
    switch (widget.grade) {
      case 9:
        return 'Grade 9 Foundation & Exam Prep';
      case 10:
        return 'Grade 10 National Exam Booster';
      case 11:
        return 'Grade 11 Prep Mastery Package';
      case 12:
        return 'Grade 12 EUEE Master Package';
      default:
        return 'Grade ${widget.grade} Premium Curriculum Package';
    }
  }

  int get _packagePrice {
    switch (widget.grade) {
      case 9:
        return 299;
      case 10:
        return 349;
      case 11:
        return 399;
      case 12:
        return 499;
      default:
        return 299;
    }
  }

  Future<void> _launchTelegram() async {
    final bool isAm = widget.languageCode == 'am';
    final String cleanPhone = _studentPhone.isNotEmpty ? _studentPhone : 'N/A';
    final String cleanName = _studentName.isNotEmpty ? _studentName : 'Student';

    final String message =
        "Hello Smart X Admin, I would like to unlock Grade ${widget.grade} $_effectivePackageName. My Name: $cleanName, Phone: $cleanPhone";

    final encodedMsg = Uri.encodeComponent(message);
    final Uri directTelegramUri = Uri.parse("https://t.me/HabIT_Dev?text=$encodedMsg");
    final Uri groupUri = Uri.parse("https://t.me/SmartX_Discussion?text=$encodedMsg");

    try {
      if (await canLaunchUrl(directTelegramUri)) {
        await launchUrl(directTelegramUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(groupUri)) {
        await launchUrl(groupUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(directTelegramUri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      try {
        await launchUrl(groupUri, mode: LaunchMode.platformDefault);
      } catch (e) {
        if (!mounted) return;
        Clipboard.setData(ClipboardData(text: message));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAm
                ? 'መልዕክቱ ተገልብጧል! በቴሌግራም (@HabIT_Dev) ይላኩት።'
                : 'Message copied to clipboard! Send to @HabIT_Dev on Telegram.'),
            backgroundColor: const Color(0xFF00BFFF),
          ),
        );
      }
    }
  }

  Future<void> _verifyActivationCode() async {
    final code = _codeController.text.trim().toUpperCase();
    final isAm = widget.languageCode == 'am';

    if (code.isEmpty) return;

    setState(() => _isActivating = true);
    await Future.delayed(const Duration(milliseconds: 600));

    // Valid codes: SMARTX, GRADE9, GRADE10, GRADE11, GRADE12, PROMO2026, HABIT
    final validCodes = [
      'SMARTX',
      'SMARTX${widget.grade}',
      'GRADE${widget.grade}',
      'PROMO2026',
      'HABIT',
      'VIP',
    ];

    if (validCodes.contains(code)) {
      await SubscriptionService.unlockGrade(widget.grade);
      if (mounted) {
        setState(() => _isActivating = false);
        Navigator.of(context).pop();
        widget.onPackageUnlocked?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.verified_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(isAm
                      ? 'እንኳን ደስ አለዎት! የክፍል ${widget.grade} ፓኬጅ ሙሉ በሙሉ ተከፍቷል!'
                      : 'Congratulations! Grade ${widget.grade} package has been unlocked!'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        setState(() => _isActivating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAm
                ? 'ልክ ያልሆነ የማግበሪያ ኮድ! እባክዎ በቴሌግራም አስተዳዳሪውን ያነጋግሩ።'
                : 'Invalid activation code! Please contact admin via Telegram.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAm = widget.languageCode == 'am';
    final bool isLight = !widget.isDarkMode;
    final Color sheetBg = isLight ? Colors.white : const Color(0xFF0F172A);
    final Color textPrimary = isLight ? const Color(0xFF0F172A) : Colors.white;
    final Color textSecondary = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    // Header Banner with Lock & Crown
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0084FF), Color(0xFF00BFFF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0084FF).withValues(alpha: 0.35),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.workspace_premium_rounded,
                              color: Colors.white,
                              size: 44,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF59E0B),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock_open_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Badge: PREMIUM PACKAGE
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0084FF).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF0084FF).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          isAm ? 'ስማርት ኤክስ ፕሪሚየም ጥቅል' : 'SMART X PREMIUM PACKAGE',
                          style: const TextStyle(
                            color: Color(0xFF0084FF),
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Title
                    Text(
                      _effectivePackageName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Locked Unit Context if triggered from unit
                    if (widget.unitNumber != null) ...[
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_rounded, color: Color(0xFFF59E0B), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isAm
                                    ? 'ክፍል 1 100% ነፃ ነው! ክፍል ${widget.unitNumber} እና ከዚያ በላይ ለመክፈት ጥቅሉን ያግብሩ።'
                                    : 'Unit 1 is 100% Free! Unlock this package to access Unit ${widget.unitNumber} and all curriculum units.',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Price Tag
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isLight
                              ? [const Color(0xFFF0F9FF), const Color(0xFFE0F2FE)]
                              : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF0084FF).withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAm ? 'የአንድ ጊዜ ክፍያ (ቋሚ ፈቃድ)' : 'One-Time Payment (Lifetime)',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '$_packagePrice',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0084FF),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isAm ? 'ብር (ETB)' : 'ETB',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF10B981)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.flash_on_rounded, color: Color(0xFF10B981), size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  isAm ? 'ቅናሽ 40%' : 'SAVE 40%',
                                  style: const TextStyle(
                                    color: Color(0xFF10B981),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Benefits Checklist
                    Text(
                      isAm ? 'የፕሪሚየም ጥቅሉ ጥቅሞች:' : 'Premium Package Benefits:',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildBenefitItem(
                      icon: Icons.menu_book_rounded,
                      title: isAm ? 'ሙሉ የክፍል ማጠቃለያ ማስታወሻዎች' : 'Full Unit Summaries & Short Notes',
                      subtitle: isAm
                          ? 'ከክፍል 1 እስከ መጨረሻው ሙሉ አጫጭርና ግልፅ ማስታወሻዎች'
                          : 'Units 1 through 10+ crystal-clear curriculum notes',
                      isLight: isLight,
                    ),
                    _buildBenefitItem(
                      icon: Icons.assignment_turned_in_rounded,
                      title: isAm ? 'የማትሪክና ሞዴል የልምምድ ወረቀቶች' : 'Matric & Model Exam Worksheets',
                      subtitle: isAm
                          ? 'የቀደሙት ዓመታት ጥያቄዎች ከደረጃ በደረጃ ማብራሪያ ጋር'
                          : 'Curriculum worksheets with step-by-step solutions',
                      isLight: isLight,
                    ),
                    _buildBenefitItem(
                      icon: Icons.functions_rounded,
                      title: isAm ? 'የቀመር ካርዶች እና ፎርሙላዎች' : 'Formula Cards & Quick Reference',
                      subtitle: isAm
                          ? 'ለሂሳብ እና ፊዚክስ አስፈላጊ ፎርሙላዎች በአንድ ቦታ'
                          : 'Solved formulas and physics constants at your fingertips',
                      isLight: isLight,
                    ),
                    _buildBenefitItem(
                      icon: Icons.quiz_rounded,
                      title: isAm ? 'ያልተገደቡ የፈተና ጥያቄዎች (Mock Tests)' : 'Unlimited Interactive Quizzes',
                      subtitle: isAm
                          ? 'የፈተና ፍጥነትዎን እና እውቀትዎን የሚለኩ ፈተናዎች'
                          : 'Instant scoring, answer reviews, and timed exam practice',
                      isLight: isLight,
                    ),
                    _buildBenefitItem(
                      icon: Icons.cloud_download_rounded,
                      title: isAm ? '100% ከመስመር ውጭ (Offline) አጠቃቀም' : '100% Offline Study Mode',
                      subtitle: isAm
                          ? 'አንዴ ካወረዱ ያለ ኢንተርኔት በየትኛውም ቦታ ማጥናት ይችላሉ'
                          : 'Download once and study anywhere without internet',
                      isLight: isLight,
                    ),

                    const SizedBox(height: 16),

                    // Primary Action: UNLOCK VIA TELEGRAM
                    ElevatedButton(
                      onPressed: _isLoading ? null : _launchTelegram,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0084FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: const Color(0xFF0084FF).withValues(alpha: 0.4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.telegram_rounded, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            isAm ? 'በቴሌግራም ክፈት' : 'Unlock via Telegram',
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Activation code toggle button
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _showCodeInput = !_showCodeInput;
                          });
                        },
                        icon: Icon(
                          _showCodeInput ? Icons.keyboard_arrow_up_rounded : Icons.key_rounded,
                          size: 18,
                          color: textSecondary,
                        ),
                        label: Text(
                          isAm ? 'የማግበሪያ ኮድ አለዎት?' : 'Have an activation code?',
                          style: TextStyle(
                            color: textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),

                    if (_showCodeInput) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _codeController,
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                hintText: 'Enter code (e.g. SMARTX)',
                                hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF0084FF), width: 2),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _isActivating ? null : _verifyActivationCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isActivating
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    isAm ? 'አግብር' : 'Apply',
                                    style: const TextStyle(fontWeight: FontWeight.w900),
                                  ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 14),
                    Text(
                      isAm
                          ? 'የቴሌግራም አድራሻችን @HabIT_Dev ወይም @SmartX_Discussion ነው።'
                          : 'Direct support: @HabIT_Dev or join @SmartX_Discussion.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isLight,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0084FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF0084FF), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isLight ? const Color(0xFF0F172A) : Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
