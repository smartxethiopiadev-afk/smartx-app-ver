import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/credential_auth_service.dart';
import '../services/device_service.dart';
import '../services/subscription_service.dart';
import 'friendly_error_card.dart';

class AccountUpgradeDialog extends StatefulWidget {
  final bool isDarkMode;
  final String languageCode;
  final int? initialGrade;
  final int initialTabIndex; // 0 for Verify, 1 for Register
  final VoidCallback? onSuccess;

  const AccountUpgradeDialog({
    super.key,
    required this.isDarkMode,
    required this.languageCode,
    this.initialGrade,
    this.initialTabIndex = 0,
    this.onSuccess,
  });

  static Future<bool?> show(
    BuildContext context, {
    bool isDarkMode = false,
    String languageCode = 'am',
    int? initialGrade,
    int initialTabIndex = 0,
    VoidCallback? onSuccess,
  }) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AccountUpgradeDialog(
        isDarkMode: isDarkMode,
        languageCode: languageCode,
        initialGrade: initialGrade,
        initialTabIndex: initialTabIndex,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<AccountUpgradeDialog> createState() => _AccountUpgradeDialogState();
}

class _AccountUpgradeDialogState extends State<AccountUpgradeDialog> {
  late int _selectedTab;
  final _verifyFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final _verifyNameController = TextEditingController();
  final _verifyPhoneController = TextEditingController();

  final _regNameController = TextEditingController();
  final _regPhoneController = TextEditingController();
  late int _regGrade;
  String _deviceId = '';

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex.clamp(0, 1);
    _regGrade = (widget.initialGrade != null && [9, 10, 11, 12].contains(widget.initialGrade))
        ? widget.initialGrade!
        : 9;
    _loadDeviceId();
  }

  Future<void> _loadDeviceId() async {
    final id = await DeviceService.getDeviceId();
    if (mounted) {
      setState(() {
        _deviceId = id;
      });
    }
  }

  @override
  void dispose() {
    _verifyNameController.dispose();
    _verifyPhoneController.dispose();
    _regNameController.dispose();
    _regPhoneController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyAndUpgrade() async {
    if (!_verifyFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final name = _verifyNameController.text.trim();
    final phone = _verifyPhoneController.text.trim();

    try {
      final result = await SubscriptionService.verifyAndUpgradeStudent(
        phone: phone,
        name: name,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        setState(() => _isLoading = false);

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
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'የማረጋገጫ ስህተት አጋጥሟል: $e';
        });
      }
    }
  }

  Future<void> _handleRegisterStudent() async {
    if (!_registerFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final name = _regNameController.text.trim();
    final phone = _regPhoneController.text.trim();

    try {
      final authRes = await CredentialAuthService.registerStudent(
        fullName: name,
        phoneNumber: phone,
        grade: _regGrade,
      );

      if (!mounted) return;

      if (authRes.isSuccess) {
        setState(() {
          _isLoading = false;
          _successMessage = widget.languageCode == 'am'
              ? 'ተማሪው በተሳካ ሁኔታ በዳታቤዝ ተመዝግቧል! አድሚኑ ፓኬጅ ሲጨምርልዎ በማረጋገጫ ክፍል ውስጥ ማረጋገጥ ይችላሉ።'
              : 'Student registered in database! Once the admin activates your package, you can verify and unlock.';
          _verifyNameController.text = name;
          _verifyPhoneController.text = phone;
          _selectedTab = 0; // Switch to verify tab
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.languageCode == 'am'
                  ? 'ምዝገባው ተጠናቋል! መረጃዎ በዳታቤዝ ተቀምጧል።'
                  : 'Registration complete! Your profile is saved.',
              style: GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.w700),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = authRes.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'የምዝገባ ስህተት አጋጥሟል: $e';
        });
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
        constraints: const BoxConstraints(maxWidth: 460),
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
                          isAm ? 'የተማሪ ፈቃድ እና ምዝገባ' : 'Student License & Registration',
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

              // Segmented Tab Switcher: [ 🔑 ማረጋገጫ (Verify) | 📝 ተመዝገብ (Register) ]
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selectedTab = 0;
                          _errorMessage = null;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0
                                ? (isLight ? Colors.white : const Color(0xFF0284C7))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _selectedTab == 0
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                size: 16,
                                color: _selectedTab == 0
                                    ? (_selectedTab == 0 && !isLight ? Colors.white : const Color(0xFF0284C7))
                                    : subColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isAm ? 'ፈቃድ ማረጋገጫ' : 'Verify Upgrade',
                                style: GoogleFonts.notoSansEthiopic(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: _selectedTab == 0
                                      ? (_selectedTab == 0 && !isLight ? Colors.white : textColor)
                                      : subColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selectedTab = 1;
                          _errorMessage = null;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1
                                ? (isLight ? Colors.white : const Color(0xFF10B981))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _selectedTab == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_add_rounded,
                                size: 16,
                                color: _selectedTab == 1
                                    ? (_selectedTab == 1 && !isLight ? Colors.white : const Color(0xFF10B981))
                                    : subColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isAm ? 'አዲስ ምዝገባ' : 'Register Student',
                                style: GoogleFonts.notoSansEthiopic(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: _selectedTab == 1
                                      ? (_selectedTab == 1 && !isLight ? Colors.white : textColor)
                                      : subColor,
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

              const SizedBox(height: 16),

              // TAB 0: VERIFY TAB
              if (_selectedTab == 0) ...[
                Text(
                  isAm ? 'የቴሌግራም ክፍያዎን ያረጋግጡ' : 'Verify Your Telegram Purchase',
                  style: GoogleFonts.notoSansEthiopic(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAm
                      ? 'የትምህርት ፈቃድዎን ለማረጋገጥ የተመዘገቡበትን ስም እና ስልክ ቁጥር ያስገቡ። ስርዓቱ በዚህ ስልክ ላይ ይዘቶቹን ይከፍታል።'
                      : 'Enter your registered full name and phone number to unlock curriculum on this device.',
                  style: GoogleFonts.notoSansEthiopic(
                    fontSize: 12,
                    color: subColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),

                Form(
                  key: _verifyFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isAm ? 'ሙሉ ስም (Full Name)' : 'Full Name',
                        style: GoogleFonts.notoSansEthiopic(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _verifyNameController,
                        textCapitalization: TextCapitalization.words,
                        style: TextStyle(fontSize: 14, color: textColor, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: isAm ? 'ለምሳሌ፡ አበበ በቀለ' : 'e.g., Abebe Bekele',
                          hintStyle: TextStyle(color: subColor.withValues(alpha: 0.6), fontSize: 13),
                          filled: true,
                          fillColor: inputFillColor,
                          prefixIcon: Icon(Icons.person_outline_rounded, color: subColor, size: 20),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().length < 2)
                            ? (isAm ? 'እባክዎ ሙሉ ስምዎን ያስገቡ' : 'Enter your name')
                            : null,
                      ),
                      const SizedBox(height: 12),

                      Text(
                        isAm ? 'ስልክ ቁጥር (Phone Number)' : 'Phone Number',
                        style: GoogleFonts.notoSansEthiopic(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _verifyPhoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(fontSize: 14, color: textColor, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: isAm ? '0911234567 ወይም 0711234567' : '0911234567 or 0711234567',
                          hintStyle: TextStyle(color: subColor.withValues(alpha: 0.6), fontSize: 13),
                          filled: true,
                          fillColor: inputFillColor,
                          prefixIcon: Icon(Icons.phone_outlined, color: subColor, size: 20),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return isAm ? 'ስልክ ቁጥር ያስገቡ' : 'Enter phone';
                          final clean = SubscriptionService.sanitizeEthiopianPhone(v);
                          if (!RegExp(r'^0[79]\d{8}$').hasMatch(clean)) {
                            return isAm ? 'ትክክለኛ 10 አሃዝ ስልክ (09.../07...)' : 'Invalid 10-digit phone';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleVerifyAndUpgrade,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : Text(
                                  isAm ? 'ፈቃዴን አረጋግጥና ክፈት' : 'Verify & Unlock',
                                  style: GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.w800, fontSize: 14),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // TAB 1: REGISTER TAB (User Request: Name, Grade, Device ID, Phone)
              if (_selectedTab == 1) ...[
                Text(
                  isAm ? 'አዲስ የተማሪ መለያ ይመዝገቡ' : 'Register New Student',
                  style: GoogleFonts.notoSansEthiopic(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAm
                      ? 'መረጃዎ በዳታቤዝ (students table) ተመዝግቦ ይቀመጣል። አድሚኑ ፓኬጅ ሲጨምር በቀላሉ ማረጋገጥ ይችላሉ።'
                      : 'Your details will be registered into the students database for admin package allocation.',
                  style: GoogleFonts.notoSansEthiopic(
                    fontSize: 12,
                    color: subColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),

                Form(
                  key: _registerFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Full Name
                      Text(
                        isAm ? 'የተማሪው ሙሉ ስም (Student Name)' : 'Student Name',
                        style: GoogleFonts.notoSansEthiopic(fontSize: 12, fontWeight: FontWeight.w800, color: textColor),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _regNameController,
                        textCapitalization: TextCapitalization.words,
                        style: TextStyle(fontSize: 14, color: textColor, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: isAm ? 'ለምሳሌ፡ ሰላም ታደሰ' : 'e.g., Selam Tadesse',
                          hintStyle: TextStyle(color: subColor.withValues(alpha: 0.6), fontSize: 13),
                          filled: true,
                          fillColor: inputFillColor,
                          prefixIcon: Icon(Icons.badge_outlined, color: subColor, size: 20),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().length < 2)
                            ? (isAm ? 'እባክዎ ሙሉ ስም ያስገቡ' : 'Enter name')
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // Grade Selection Chips (9, 10, 11, 12)
                      Text(
                        isAm ? 'የሚማሩበት ክፍል (Grade)' : 'Select Grade',
                        style: GoogleFonts.notoSansEthiopic(fontSize: 12, fontWeight: FontWeight.w800, color: textColor),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [9, 10, 11, 12].map((g) {
                          final bool isGSelected = _regGrade == g;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: InkWell(
                                onTap: () => setState(() => _regGrade = g),
                                borderRadius: BorderRadius.circular(10),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isGSelected ? const Color(0xFF10B981) : inputFillColor,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isGSelected ? const Color(0xFF10B981) : borderColor,
                                      width: isGSelected ? 1.8 : 1.0,
                                    ),
                                  ),
                                  child: Text(
                                    'Grade $g',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: isGSelected ? Colors.white : textColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      // Phone Number
                      Text(
                        isAm ? 'ስልክ ቁጥር (Phone Number)' : 'Phone Number',
                        style: GoogleFonts.notoSansEthiopic(fontSize: 12, fontWeight: FontWeight.w800, color: textColor),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _regPhoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(fontSize: 14, color: textColor, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: isAm ? '0911234567 ወይም 0711234567' : '0911234567 or 0711234567',
                          hintStyle: TextStyle(color: subColor.withValues(alpha: 0.6), fontSize: 13),
                          filled: true,
                          fillColor: inputFillColor,
                          prefixIcon: Icon(Icons.phone_android_rounded, color: subColor, size: 20),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return isAm ? 'ስልክ ቁጥር ያስገቡ' : 'Enter phone';
                          final clean = SubscriptionService.sanitizeEthiopianPhone(v);
                          if (!RegExp(r'^0[79]\d{8}$').hasMatch(clean)) {
                            return isAm ? 'ትክክለኛ 10 አሃዝ ስልክ (09.../07...)' : 'Invalid phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Register Button
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegisterStudent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : Text(
                                  isAm ? 'ተማሪውን መዝግብ (Register Student)' : 'Register Student',
                                  style: GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.w800, fontSize: 14),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Error / Success Feedback
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                FriendlyErrorCard(
                  errorMessage: _errorMessage!,
                  isDarkMode: widget.isDarkMode,
                  languageCode: widget.languageCode,
                  onRetry: _selectedTab == 0 ? _handleVerifyAndUpgrade : _handleRegisterStudent,
                  onDismiss: () => setState(() => _errorMessage = null),
                ),
              ],
              if (_successMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: GoogleFonts.notoSansEthiopic(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Telegram Help
              SizedBox(
                height: 40,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    final Uri telegramUri = Uri.parse('https://t.me/smart_x_help');
                    if (await canLaunchUrl(telegramUri)) {
                      await launchUrl(telegramUri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.send_rounded, size: 15, color: Color(0xFF0088CC)),
                  label: Text(
                    isAm ? 'በቴሌግራም አግኙን (@smart_x_help)' : 'Contact Telegram (@smart_x_help)',
                    style: GoogleFonts.notoSansEthiopic(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0088CC),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: const Color(0xFF0088CC).withValues(alpha: 0.35)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
