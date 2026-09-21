import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/subscription_service.dart';

class AccountUpgradeDialog extends StatefulWidget {
  final bool isDarkMode;
  final String languageCode;
  final VoidCallback? onSuccess;

  const AccountUpgradeDialog({
    super.key,
    required this.isDarkMode,
    required this.languageCode,
    this.onSuccess,
  });

  static Future<bool?> show(
    BuildContext context, {
    required bool isDarkMode,
    required String languageCode,
    VoidCallback? onSuccess,
  }) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AccountUpgradeDialog(
        isDarkMode: isDarkMode,
        languageCode: languageCode,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<AccountUpgradeDialog> createState() => _AccountUpgradeDialogState();
}

class _AccountUpgradeDialogState extends State<AccountUpgradeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _rawErrorDetails;
  bool _isDeviceMismatch = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyAndUpgrade() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _rawErrorDetails = null;
      _isDeviceMismatch = false;
    });

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    try {
      final result = await SubscriptionService.verifyAndUpgradeStudent(
        phone: phone,
        name: name,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        setState(() => _isLoading = false);

        // Show Success Feedback with device binding status
        final String successText = result.deviceBindingConfirmed
            ? '${result.message} (Device ID ወደ ዳታቤዝ ተመዝግቧል)'
            : result.message;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    successText,
                    style: GoogleFonts.notoSansEthiopic(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );

        widget.onSuccess?.call();
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result.message;
          _rawErrorDetails = result.rawError;
          _isDeviceMismatch = result.isDeviceMismatch;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'የማረጋገጫ ስህተት አጋጥሟል: $e';
          _rawErrorDetails = e.toString();
        });
      }
    }
  }

  Future<void> _contactTelegram() async {
    const telegramUrl = 'https://t.me/smart_x_help';
    final Uri uri = Uri.parse(telegramUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (mounted) {
        Clipboard.setData(const ClipboardData(text: '@smart_x_help'));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('የቴሌግራም አድራሻው ተቀድቷል: @smart_x_help'),
            backgroundColor: Color(0xFF0088CC),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = !widget.isDarkMode;
    final bool isAm = widget.languageCode == 'am';

    final Color bgColor = isLight ? Colors.white : const Color(0xFF1E293B);
    final Color textColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final Color subColor = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final Color borderColor = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155);
    final Color inputFillColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header with close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_user_rounded, size: 14, color: Color(0xFF0284C7)),
                          const SizedBox(width: 5),
                          Text(
                            isAm ? 'የፈቃድ ማረጋገጫ' : 'Account Upgrade',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22),
                      color: subColor,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Title & Subtitle
                Text(
                  isAm ? 'የቴሌግራም ክፍያዎን ያረጋግጡ' : 'Verify Your Telegram Purchase',
                  style: GoogleFonts.notoSansEthiopic(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isAm
                      ? 'በቴሌግራም (@smart_x_help) ክፍያ የፈጸሙበትን ስልክ ቁጥር እና ሙሉ ስም ያስገቡ። ስርዓቱ ፈቃድዎን አረጋግጦ በዚህ ስልክ ላይ ይዘቶቹን ይከፍታል።'
                      : 'Enter the phone number and full name used on Telegram. The system will verify your payment and unlock content on this device.',
                  style: GoogleFonts.notoSansEthiopic(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: subColor,
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 16),

                // Hardware Protection Warning Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.security_rounded, color: Color(0xFF10B981), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isAm
                              ? 'የደህንነት ህግ፡ እያንዳንዱ መለያ ለአንድ ስልክ ብቻ የተፈቀደ ነው (Single Device Protection)።'
                              : 'Security: Each account is strictly bound to a single physical device.',
                          style: GoogleFonts.notoSansEthiopic(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isLight ? const Color(0xFF065F46) : const Color(0xFF6EE7B7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Full Name Input
                Text(
                  isAm ? 'ሙሉ ስም (Full Name)' : 'Full Name',
                  style: GoogleFonts.notoSansEthiopic(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(fontSize: 14, color: textColor, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: isAm ? 'ለምሳሌ፡ አበበ በቀለ' : 'e.g., Abebe Bekele',
                    hintStyle: TextStyle(color: subColor.withValues(alpha: 0.6), fontSize: 13),
                    filled: true,
                    fillColor: inputFillColor,
                    prefixIcon: Icon(Icons.person_outline_rounded, color: subColor, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 2) {
                      return isAm ? 'እባክዎ ሙሉ ስምዎን ያስገቡ' : 'Please enter your full name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // Phone Number Input
                Text(
                  isAm ? 'ስልክ ቁጥር (Phone Number)' : 'Phone Number',
                  style: GoogleFonts.notoSansEthiopic(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(fontSize: 14, color: textColor, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: isAm ? '0911234567 ወይም 0711234567' : '0911234567 or 0711234567',
                    hintStyle: TextStyle(color: subColor.withValues(alpha: 0.6), fontSize: 13),
                    filled: true,
                    fillColor: inputFillColor,
                    prefixIcon: Icon(Icons.phone_outlined, color: subColor, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return isAm ? 'እባክዎ ስልክ ቁጥር ያስገቡ' : 'Please enter your phone number';
                    }
                    final clean = SubscriptionService.sanitizeEthiopianPhone(value);
                    if (!RegExp(r'^0[79]\d{8}$').hasMatch(clean)) {
                      return isAm
                          ? 'እባክዎ ትክክለኛ 10 አሃዝ ስልክ ቁጥር ያስገቡ (09... ወይም 07...)'
                          : 'Please enter a valid 10-digit phone (09... or 07...)';
                    }
                    return null;
                  },
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isDeviceMismatch
                          ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                          : const Color(0xFFF59E0B).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isDeviceMismatch
                            ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                            : const Color(0xFFF59E0B).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _isDeviceMismatch ? Icons.gpp_bad_rounded : Icons.info_outline_rounded,
                              color: _isDeviceMismatch ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.notoSansEthiopic(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _isDeviceMismatch
                                      ? const Color(0xFFEF4444)
                                      : (isLight ? const Color(0xFFB45309) : const Color(0xFFFBBF24)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Copy Error Button for Debugging & Support
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () {
                              final textToCopy = _rawErrorDetails != null && _rawErrorDetails!.isNotEmpty
                                  ? 'Error: $_errorMessage\nDetails: $_rawErrorDetails'
                                  : 'Error: $_errorMessage';
                              Clipboard.setData(ClipboardData(text: textToCopy));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isAm ? 'የስህተት መልእክቱ ተቀድቷል (Copied)' : 'Error copied to clipboard'),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: const Color(0xFF1E293B),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: (isLight ? Colors.white : Colors.black26),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: (_isDeviceMismatch ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)).withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.copy_rounded,
                                    size: 13,
                                    color: _isDeviceMismatch
                                        ? const Color(0xFFEF4444)
                                        : (isLight ? const Color(0xFFB45309) : const Color(0xFFFBBF24)),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    isAm ? 'ስህተቱን ቅዳ (Copy Error)' : 'Copy Error',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _isDeviceMismatch
                                          ? const Color(0xFFEF4444)
                                          : (isLight ? const Color(0xFFB45309) : const Color(0xFFFBBF24)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleVerifyAndUpgrade,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            isAm ? 'ፈቃዴን አረጋግጥና ክፈት' : 'Verify & Upgrade Now',
                            style: GoogleFonts.notoSansEthiopic(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                // Telegram Admin Contact Link
                SizedBox(
                  height: 42,
                  child: TextButton.icon(
                    onPressed: _contactTelegram,
                    icon: const Icon(Icons.send_rounded, size: 16, color: Color(0xFF0088CC)),
                    label: Text(
                      isAm ? 'ክፍያ ገና አልከፈሉም? በቴሌግራም ይክፈሉ (@smart_x_help)' : 'Not paid yet? Pay via Telegram (@smart_x_help)',
                      style: GoogleFonts.notoSansEthiopic(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0088CC),
                      ),
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
