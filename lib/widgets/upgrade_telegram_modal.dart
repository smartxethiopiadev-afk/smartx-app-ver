import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/package_model.dart';
import '../services/subscription_service.dart';
import '../services/device_service.dart';
import '../services/activation_service.dart';

class UpgradeTelegramModal extends StatefulWidget {
  final int grade;
  final String? packageName;
  final String? subject;
  final int? unitNumber;
  final String? unitTitle;
  final String languageCode;
  final bool isDarkMode;
  final VoidCallback? onPackageUnlocked;

  const UpgradeTelegramModal({
    super.key,
    required this.grade,
    this.packageName,
    this.subject,
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
    String? subject,
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
        subject: subject,
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
  bool _isVerifying = false;
  int _selectedPackageIndex = 1; // Default to Grade / Stream pack (Index 1)

  final TextEditingController _phoneVerifyController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _activationCodeController = TextEditingController();
  bool _showPhoneVerifySheet = false;
  bool _showActivationCodeSheet = false;
  bool _isActivatingCode = false;

  late List<PackageModel> _packages;

  @override
  void initState() {
    super.initState();
    _packages = PackageModel.getPackagesForGrade(widget.grade, subject: widget.subject);
    _loadStudentInfo();
  }

  @override
  void dispose() {
    _phoneVerifyController.dispose();
    _nameController.dispose();
    _activationCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentInfo() async {
    final prefs = await SharedPreferences.getInstance();

    final name = prefs.getString('user_fullName') ??
        prefs.getString('user_name') ??
        '';
    final phone = prefs.getString('user_phoneNumber') ??
        prefs.getString('phone_number') ??
        '';

    _nameController.text = name;
    _phoneVerifyController.text = phone;

    if (mounted) {
      setState(() {
        _studentName = name.isNotEmpty ? name : 'Smart X Student';
        _studentPhone = phone;
        _isLoading = false;
      });
    }
  }

  PackageModel get _selectedPackage {
    if (_selectedPackageIndex >= 0 && _selectedPackageIndex < _packages.length) {
      return _packages[_selectedPackageIndex];
    }
    return _packages[0];
  }

  Future<void> _launchTelegram() async {
    final String cleanPhone = _studentPhone.isNotEmpty
        ? _studentPhone
        : (_phoneVerifyController.text.trim().isNotEmpty
            ? _phoneVerifyController.text.trim()
            : 'N/A');
    final String cleanName = _studentName.isNotEmpty
        ? _studentName
        : (_nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : 'Ethio Concept Student');
    final String selectedPkgTitle = _selectedPackage.title;

    final String message =
        "ሰላም ስማርት ለርን አድሚን (@smart_x_help)፣ $selectedPkgTitle በ 50 ብር ክፍያ ማስከፈት እፈልጋለሁ። የተማሪ ስም: $cleanName፣ ስልክ ቁጥር: $cleanPhone።";

    final encodedMsg = Uri.encodeComponent(message);
    final Uri directTelegramUri = Uri.parse("https://t.me/smart_x_help?text=$encodedMsg");

    try {
      if (await canLaunchUrl(directTelegramUri)) {
        await launchUrl(directTelegramUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(directTelegramUri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (!mounted) return;
      Clipboard.setData(ClipboardData(text: message));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.languageCode == 'am'
                ? 'የቴሌግራም መልእክት ተቀድቷል! ቴሌግራም ላይ ይለጥፉት (@smart_x_help)'
                : 'Message copied to clipboard! Paste it to @smart_x_help on Telegram.',
          ),
          backgroundColor: const Color(0xFF0084FF),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _verifySubscriptionOnline() async {
    final String phoneInput = _phoneVerifyController.text.replaceAll(RegExp(r'\s+'), '').trim();
    if (phoneInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.languageCode == 'am'
                ? 'እባክዎ የተመዘገቡበትን ስልክ ቁጥር ያስገቡ'
                : 'Please enter your registered phone number',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    final DeviceBindingResult result = await SubscriptionService.syncWithSupabaseAndVerifyDevice(
      phoneInput,
      packageId: _selectedPackage.id,
    );

    if (!mounted) return;
    setState(() {
      _isVerifying = false;
    });

    if (result.isAllowed) {
      await SubscriptionService.unlockPackage(_selectedPackage.id);
      await SubscriptionService.unlockGrade(widget.grade);

      if (mounted) {
        Navigator.of(context).pop();
        widget.onPackageUnlocked?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.verified_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.languageCode == 'am'
                        ? 'እንኳን ደስ አለዎት! ፓኬጁ በተሳካ ሁኔታ ለዚህ ስልክ ተከፍቷል።'
                        : 'Success! Package unlocked and bound to this device.',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else if (result.status == DeviceBindingStatus.mismatch) {
      _showDeviceMismatchDialog(result.registeredDeviceId ?? 'Other Device');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.languageCode == 'am'
                ? 'ምንም ንቁ ክፍያ አልተገኘም። በቴሌግራም አስተዳዳሪውን ያነጋግሩ (@smart_x_help)'
                : 'No active subscription found. Please contact admin on Telegram (@smart_x_help)',
          ),
          backgroundColor: Colors.orangeAccent,
          action: SnackBarAction(
            label: widget.languageCode == 'am' ? 'ቴሌግራም' : 'Telegram',
            textColor: Colors.white,
            onPressed: _launchTelegram,
          ),
        ),
      );
    }
  }

  Future<void> _handleActivateCode() async {
    final String codeInput = _activationCodeController.text.trim();
    final String phoneInput = _phoneVerifyController.text.replaceAll(RegExp(r'\s+'), '').trim();
    final String nameInput = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : _studentName;

    final bool isAm = widget.languageCode == 'am';

    if (codeInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAm ? 'እባክዎ የማግበሪያ ኮዱን ያስገቡ' : 'Please enter your activation code',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (phoneInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAm ? 'እባክዎ ስልክ ቁጥርዎን ያስገቡ' : 'Please enter your phone number',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isActivatingCode = true;
    });

    final result = await ActivationService.activateCode(
      code: codeInput,
      name: nameInput.isNotEmpty ? nameInput : 'Smart X Student',
      phone: phoneInput,
      languageCode: widget.languageCode,
    );

    if (!mounted) return;
    setState(() {
      _isActivatingCode = false;
    });

    if (result.isSuccess) {
      Navigator.of(context).pop();
      widget.onPackageUnlocked?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.verified_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(result.message),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: isAm ? 'ቴሌግራም' : 'Telegram',
            textColor: Colors.white,
            onPressed: _launchTelegram,
          ),
        ),
      );
    }
  }

  void _showDeviceMismatchDialog(String registeredDeviceId) {
    final bool isAm = widget.languageCode == 'am';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.phonelink_lock_rounded, color: Colors.redAccent, size: 48),
        title: Text(
          isAm ? 'አካውንቱ በሌላ ስልክ ላይ ተመዝግቧል!' : 'Account Bound to Another Device!',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: widget.isDarkMode ? Colors.white : const Color(0xFF0F172A),
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAm
                  ? 'ይህ አካውንት አስቀድሞ በሌላ ስልክ ($registeredDeviceId) ላይ ነቅቷል። እያንዳንዱ ፓኬጅ ለአንድ ስልክ ብቻ ነው የሚፈቀደው።'
                  : 'This account is already active on another device ($registeredDeviceId). Each subscription is valid for one phone only.',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: widget.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isAm
                          ? 'ስልክ ከቀየሩ ወይም ከጠፋብዎ በአስተዳዳሪው በኩል ማዘዋወር ይችላሉ።'
                          : 'If you changed your phone, contact admin to reset the device binding.',
                      style: const TextStyle(fontSize: 11.5, color: Colors.redAccent, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isAm ? 'ዝጋ' : 'Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _launchTelegram();
            },
            icon: const Icon(Icons.send_rounded, size: 16),
            label: Text(isAm ? 'አስተዳዳሪውን ያነጋግሩ' : 'Contact Admin'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0084FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = !widget.isDarkMode;
    final bool isAm = widget.languageCode == 'am';

    final Color bgColor = isLight ? Colors.white : const Color(0xFF0F172A);
    final Color cardBg = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
    final Color borderColor = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155);
    final Color textPrimary = isLight ? const Color(0xFF0F172A) : Colors.white;
    final Color textSecondary = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 250,
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF0084FF)),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header with Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  isAm ? 'የትምህርት ፓኬጅ ይምረጡ' : 'Select Learning Package',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isAm
                                  ? 'ክፍል 1 ነፃ ነው! የቀሪ ክፍሎችን በቴሌግራም ይክፈቱ'
                                  : 'Unit 1 is 100% Free! Unlock remaining units via Telegram.',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'GRADE ${widget.grade}',
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3 Package Tiers (Radio Cards)
                  ...List.generate(_packages.length, (idx) {
                    final pkg = _packages[idx];
                    final bool isSelected = _selectedPackageIndex == idx;

                    Color highlightColor = const Color(0xFF0084FF);
                    if (pkg.tier == PackageTier.allInclusiveMatric) {
                      highlightColor = const Color(0xFF8B5CF6);
                    } else if (pkg.tier == PackageTier.singleSubject) {
                      highlightColor = const Color(0xFF0EA5E9);
                    }

                    return GestureDetector(
                      onTap: () => setState(() => _selectedPackageIndex = idx),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? highlightColor.withValues(alpha: isLight ? 0.08 : 0.18)
                              : cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? highlightColor : borderColor,
                            width: isSelected ? 2.0 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Radio check indicator
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? highlightColor : textSecondary,
                                      width: 2,
                                    ),
                                    color: isSelected ? highlightColor : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              pkg.title,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w900,
                                                color: textPrimary,
                                              ),
                                            ),
                                          ),
                                          if (pkg.badgeText != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: highlightColor.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                pkg.badgeText!,
                                                style: TextStyle(
                                                  color: highlightColor,
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isAm ? "ለአንድ ስልክ ቋሚ መዳረሻ" : "Lifetime Access on 1 Device",
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                          color: highlightColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (isSelected) ...[
                              const SizedBox(height: 10),
                              const Divider(height: 1, thickness: 0.8),
                              const SizedBox(height: 8),
                              Text(
                                pkg.description,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: textSecondary,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: pkg.features.map((feat) {
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_rounded, size: 13, color: highlightColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        feat,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 8),

                  // Automated Single Device Protection Badge
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAm ? 'ደህንነቱ የተጠበቀ የመሣሪያ ማረጋገጫ' : 'Automated Single-Device Security',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isAm
                                    ? 'መግቢያው በራስ-ሰር ከአንድ ስልክ ጋር ብቻ ይተሳሰራል (Device ID በራስ-ሰር ይያዛል)'
                                    : 'Login is securely bound to this device automatically upon activation',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Primary CTA Button: "Upgrade via Telegram" (በቴሌግራም ክፈት)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _launchTelegram,
                      icon: const Icon(Icons.send_rounded, size: 20),
                      label: Text(
                        isAm
                            ? 'በቴሌግራም አድሚኑን አግኝ'
                            : 'Request Access on Telegram',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.1,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0084FF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Activation Code Card / Expandable
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _showActivationCodeSheet
                            ? const Color(0xFF0084FF)
                            : borderColor,
                        width: _showActivationCodeSheet ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0084FF).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.vpn_key_rounded, color: Color(0xFF0084FF), size: 18),
                          ),
                          title: Text(
                            isAm ? 'የማግበሪያ ኮድ አለዎት?' : 'Have an Activation Code?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            isAm ? 'ስም፣ ስልክ እና ኮድ በማስገባት አግብር' : 'Enter Name, Phone & Code to unlock',
                            style: TextStyle(fontSize: 11, color: textSecondary),
                          ),
                          trailing: Icon(
                            _showActivationCodeSheet ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            color: textSecondary,
                          ),
                          onTap: () {
                            setState(() {
                              _showActivationCodeSheet = !_showActivationCodeSheet;
                            });
                          },
                        ),
                        if (_showActivationCodeSheet) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 14, right: 14, bottom: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                // Activation Code
                                Text(
                                  isAm ? 'የማግበሪያ ኮድ (Activation Code)' : 'Activation Code',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: textPrimary),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _activationCodeController,
                                  textCapitalization: TextCapitalization.characters,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    letterSpacing: 1.2,
                                    color: Color(0xFF0084FF),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'e.g. SMARTX-G12-MATH-2026',
                                    hintStyle: TextStyle(
                                      fontFamily: 'sans-serif',
                                      fontSize: 12,
                                      letterSpacing: 0,
                                      color: textSecondary.withValues(alpha: 0.6),
                                    ),
                                    isDense: true,
                                    filled: true,
                                    fillColor: isLight ? Colors.white : const Color(0xFF0F172A),
                                    prefixIcon: const Icon(Icons.key_rounded, size: 16, color: Color(0xFF0084FF)),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: borderColor),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Full Name
                                Text(
                                  isAm ? 'የተማሪው ሙሉ ስም' : 'Student Full Name',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: textPrimary),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    hintText: isAm ? 'ስም እና የአባት ስም' : 'Full Name',
                                    isDense: true,
                                    filled: true,
                                    fillColor: isLight ? Colors.white : const Color(0xFF0F172A),
                                    prefixIcon: const Icon(Icons.person_rounded, size: 16),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: borderColor),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Phone Number
                                Text(
                                  isAm ? 'ስልክ ቁጥር' : 'Phone Number',
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: textPrimary),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _phoneVerifyController,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    hintText: '09xxxxxxxx',
                                    isDense: true,
                                    filled: true,
                                    fillColor: isLight ? Colors.white : const Color(0xFF0F172A),
                                    prefixIcon: const Icon(Icons.phone_rounded, size: 16),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: borderColor),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Activate Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: ElevatedButton.icon(
                                    onPressed: _isActivatingCode ? null : _handleActivateCode,
                                    icon: _isActivatingCode
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Icon(Icons.lock_open_rounded, size: 18),
                                    label: Text(
                                      isAm ? 'ኮዱን አረጋግጥ እና ክፈት' : 'Verify & Unlock Package',
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Alternative: "Already Paid? Verify Device" Expandable
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showPhoneVerifySheet = !_showPhoneVerifySheet;
                        });
                      },
                      icon: Icon(
                        _showPhoneVerifySheet ? Icons.keyboard_arrow_up : Icons.verified_user_outlined,
                        size: 18,
                        color: textSecondary,
                      ),
                      label: Text(
                        isAm ? 'አስቀድመው ከፍለዋል? ስልክዎን ያረጋግጡ' : 'Already Paid? Verify & Bind Device',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  ),

                  if (_showPhoneVerifySheet) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAm ? 'የተመዘገቡበት ስልክ ቁጥር:' : 'Registered Phone Number:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _phoneVerifyController,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    hintText: '09xxxxxxxx',
                                    isDense: true,
                                    prefixIcon: const Icon(Icons.phone_rounded, size: 18),
                                    filled: true,
                                    fillColor: isLight ? Colors.white : const Color(0xFF0F172A),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: borderColor),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _isVerifying ? null : _verifySubscriptionOnline,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: _isVerifying
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : Text(
                                        isAm ? 'አረጋግጥ' : 'Verify',
                                        style: const TextStyle(fontWeight: FontWeight.w900),
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isAm
                                ? 'ክፍያዎን ከፈጸሙ በኋላ ስልክ ቁጥርዎን በማስገባት ለዚህ ስልክ ወዲያውኑ ማግበር ይችላሉ።'
                                : 'After payment, enter your phone number to immediately bind and unlock this phone.',
                            style: TextStyle(fontSize: 11, color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
