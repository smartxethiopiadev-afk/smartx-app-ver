import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/package_model.dart';
import '../services/package_service.dart';
import 'login_activation_screen.dart';

class PaymentScreen extends StatefulWidget {
  final bool isDarkMode;
  final String languageCode;
  final int grade;
  final String? subject;
  final int? unitNumber;
  final String? unitTitle;
  final VoidCallback? onPaymentVerified;

  const PaymentScreen({
    super.key,
    required this.isDarkMode,
    required this.languageCode,
    required this.grade,
    this.subject,
    this.unitNumber,
    this.unitTitle,
    this.onPaymentVerified,
  });

  static Future<bool?> push(
    BuildContext context, {
    required bool isDarkMode,
    required String languageCode,
    required int grade,
    String? subject,
    int? unitNumber,
    String? unitTitle,
    VoidCallback? onPaymentVerified,
  }) async {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (ctx) => PaymentScreen(
          isDarkMode: isDarkMode,
          languageCode: languageCode,
          grade: grade,
          subject: subject,
          unitNumber: unitNumber,
          unitTitle: unitTitle,
          onPaymentVerified: onPaymentVerified,
        ),
      ),
    );
  }

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // Official Smart X Ethiopian Bank & Contact Details
  static const String telebirrAccount = '0978254242';
  static const String telebirrHolder = 'Habtamu Yifiru (Smart X)';
  static const String cbeAccount = '1000345678912';
  static const String cbeHolder = 'Habtamu Yifiru';
  static const String supportPhone = '+251978254242';
  static const String telegramAdminUsername = 'HabIT_Dev';

  final TextEditingController _studentNameController = TextEditingController();
  final TextEditingController _studentPhoneController = TextEditingController();

  late List<PackageModel> _packages;
  late PackageModel _selectedPackage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _packages = PackageService.getFallbackPackages(widget.grade, subject: widget.subject);
    _selectedPackage = _findBestMatchingPackage();
    _loadSavedStudentInfo();
  }

  PackageModel _findBestMatchingPackage() {
    if (widget.subject != null && widget.subject!.isNotEmpty) {
      final match = _packages.firstWhere(
        (p) =>
            p.tier == PackageTier.singleSubject &&
            p.subject?.toLowerCase() == widget.subject!.toLowerCase(),
        orElse: () => _packages.firstWhere(
          (p) => p.tier == PackageTier.streamOrGrade,
          orElse: () => _packages.first,
        ),
      );
      return match;
    }
    return _packages.firstWhere(
      (p) => p.tier == PackageTier.streamOrGrade,
      orElse: () => _packages.first,
    );
  }

  Future<void> _loadSavedStudentInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_fullName') ??
        prefs.getString('user_name') ??
        prefs.getString('smartx_student_full_name') ??
        '';
    final phone = prefs.getString('user_phoneNumber') ??
        prefs.getString('phone_number') ??
        prefs.getString('smartx_student_phone') ??
        '';

    if (mounted) {
      setState(() {
        _studentNameController.text = name;
        _studentPhoneController.text = phone;
        _isLoading = false;
      });
    }

    try {
      final onlinePkgs = await PackageService.fetchPackagesForGrade(widget.grade, subject: widget.subject);
      if (mounted && onlinePkgs.isNotEmpty) {
        setState(() {
          _packages = onlinePkgs;
          _selectedPackage = _findBestMatchingPackage();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _studentNameController.dispose();
    _studentPhoneController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    final bool isAm = widget.languageCode == 'am';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              isAm ? '$label ተቀድቷል (Copied)' : '$label copied to clipboard!',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _callSupportPhone() async {
    final Uri callUri = Uri(scheme: 'tel', path: supportPhone);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {
      _copyToClipboard(supportPhone, 'ስልክ ቁጥር (Phone)');
    }
  }

  Future<void> _sendReceiptViaTelegram() async {
    final bool isAm = widget.languageCode == 'am';
    final studentName = _studentNameController.text.trim().isNotEmpty
        ? _studentNameController.text.trim()
        : 'Student';
    final studentPhone = _studentPhoneController.text.trim().isNotEmpty
        ? _studentPhoneController.text.trim()
        : 'Not provided';

    final String message =
        "Hello Admin, I have completed the payment. Please provide my login credentials.\n\n"
        "👤 Name: $studentName\n"
        "📞 Phone: $studentPhone\n"
        "📚 Package: ${_selectedPackage.title}\n"
        "💰 Amount: ${_selectedPackage.priceEtb.toInt()} ETB\n"
        "🎓 Grade: Grade ${widget.grade}${widget.subject != null ? ' (${widget.subject})' : ''}";

    final encodedMsg = Uri.encodeComponent(message);
    final Uri directTelegramUri = Uri.parse("https://t.me/$telegramAdminUsername?text=$encodedMsg");

    try {
      if (await canLaunchUrl(directTelegramUri)) {
        await launchUrl(directTelegramUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(directTelegramUri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      Clipboard.setData(ClipboardData(text: message));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAm
                ? 'የክፍያ መልዕክቱ ተቀድቷል! ቴሌግራም ላይ ለ@$telegramAdminUsername ይላኩ።'
                : 'Receipt message copied! Please send to @$telegramAdminUsername on Telegram.',
          ),
          backgroundColor: const Color(0xFF0084FF),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = !widget.isDarkMode;
    final bool isAm = widget.languageCode == 'am';

    final Color bgColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0B1120);
    final Color cardBg = isLight ? Colors.white : const Color(0xFF1E293B);
    final Color borderColor = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155);
    final Color textPrimary = isLight ? const Color(0xFF0F172A) : Colors.white;
    final Color textSecondary = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isAm ? 'የክፍያ እና የባንክ ሂሳቦች' : 'Payment & Bank Accounts',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: textPrimary,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0084FF)))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Unit 1 Free & Unit 2+ Info Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0084FF).withValues(alpha: isLight ? 0.08 : 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF0084FF).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFF0084FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAm ? 'ምዕራፍ 1 100% ነጻ ነው!' : 'Unit 1 is 100% FREE!',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                isAm
                                    ? 'ቀሪ ምዕራፎችን (Unit 2+)፣ የቀመር ማጠቃለያዎችን እና ያለ ኢንተርኔት ማውረጃዎችን ለመክፈት ከታች ባሉት የባንክ ሂሳቦች ይክፈሉ።'
                                    : 'Unlock Unit 2+, formula cheat sheets, and offline downloads by transferring via our verified bank accounts.',
                                style: TextStyle(fontSize: 11.5, color: textSecondary, height: 1.35),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Package Selection Chips
                  Text(
                    isAm ? 'የትምህርት ፓኬጅ ይምረጡ' : 'Select Learning Package',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _packages.map((pkg) {
                        final isSelected = pkg.id == _selectedPackage.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('${pkg.title} (${pkg.priceEtb.toInt()} ETB)'),
                            selected: isSelected,
                            selectedColor: const Color(0xFF0084FF),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : textPrimary,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 12,
                            ),
                            backgroundColor: cardBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected ? const Color(0xFF0084FF) : borderColor,
                              ),
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedPackage = pkg;
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Selected Package Price Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedPackage.title,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isAm ? 'የአንድ ጊዜ ክፍያ (ለአንድ ስልክ ሙሉ መብት)' : 'One-time payment • Lifetime access on 1 device',
                              style: TextStyle(fontSize: 11, color: textSecondary),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF10B981)),
                          ),
                          child: Text(
                            '${_selectedPackage.priceEtb.toInt()} ETB',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // SECTION: Official Bank Accounts
                  Text(
                    isAm ? 'ኦፊሴላዊ የባንክ ሂሳቦች (Bank Accounts)' : 'Official Bank Transfer Accounts',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 1. Telebirr Account Card
                  _buildBankCard(
                    isLight: isLight,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    bankName: 'Telebirr (ቴሌብር)',
                    accountNumber: telebirrAccount,
                    accountHolder: telebirrHolder,
                    badgeColor: const Color(0xFF0075FF),
                    icon: Icons.phone_android_rounded,
                  ),

                  const SizedBox(height: 12),

                  // 2. CBE Account Card
                  _buildBankCard(
                    isLight: isLight,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    bankName: 'Commercial Bank of Ethiopia (CBE)',
                    accountNumber: cbeAccount,
                    accountHolder: cbeHolder,
                    badgeColor: const Color(0xFF7E22CE),
                    icon: Icons.account_balance_rounded,
                  ),

                  const SizedBox(height: 20),

                  // Student Name & Phone Inputs for Receipt
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAm ? 'የተማሪው መረጃ (ክፍያ ማረጋገጫ)' : 'Your Details for Receipt Verification',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _studentNameController,
                          decoration: InputDecoration(
                            hintText: isAm ? 'የተማሪው ሙሉ ስም' : 'Student Full Name',
                            isDense: true,
                            filled: true,
                            fillColor: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                            prefixIcon: const Icon(Icons.person_rounded, size: 18),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: borderColor),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _studentPhoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: isAm ? 'ስልክ ቁጥር (09xxxxxxxx)' : 'Phone Number (09xxxxxxxx)',
                            isDense: true,
                            filled: true,
                            fillColor: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                            prefixIcon: const Icon(Icons.phone_rounded, size: 18),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: borderColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Action Button 1: Send Payment Receipt via Telegram
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _sendReceiptViaTelegram,
                      icon: const Icon(Icons.send_rounded, size: 20),
                      label: Text(
                        isAm ? 'የክፍያ ደረሰኝ በቴሌግራም ላክ (ክፍያ አረጋግጥ)' : 'Send Payment Receipt via Telegram',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0088CC),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Direct Phone Call Support Button
                  SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: _callSupportPhone,
                      icon: const Icon(Icons.phone_in_talk_rounded, size: 18, color: Color(0xFF10B981)),
                      label: Text(
                        isAm ? 'ጥያቄ ካለዎት በቀጥታ ይደውሉ ($supportPhone)' : 'Call Direct Support ($supportPhone)',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF10B981), width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Action Button 2: Already Have Password? Go to Login Screen
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.vpn_key_rounded, color: Color(0xFF0084FF), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAm ? 'የይለፍ ቃል ተቀብለዋል?' : 'Already received password?',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                isAm ? 'ስልክ እና የይለፍ ቃል በማስገባት ይዘቶችን ይክፈቱ' : 'Enter your credentials to unlock immediately',
                                style: TextStyle(fontSize: 11, color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final navigator = Navigator.of(context);
                            final loggedIn = await LoginActivationScreen.push(
                              context,
                              isDarkMode: widget.isDarkMode,
                              languageCode: widget.languageCode,
                              preferredGrade: widget.grade,
                              preferredSubject: widget.subject,
                            );
                            if (!mounted) return;
                            if (loggedIn == true) {
                              widget.onPaymentVerified?.call();
                              navigator.pop(true);
                            }
                          },
                          child: Text(
                            isAm ? 'አግብር' : 'Login',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0084FF),
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildBankCard({
    required bool isLight,
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required String bankName,
    required String accountNumber,
    required String accountHolder,
    required Color badgeColor,
    required IconData icon,
  }) {
    final bool isAm = widget.languageCode == 'am';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? 0.03 : 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: badgeColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bankName,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        accountNumber,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: Color(0xFF0084FF),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${isAm ? "ስም" : "Name"}: $accountHolder',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _copyToClipboard(accountNumber, bankName),
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  label: Text(
                    isAm ? 'ቅዳ' : 'Copy',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0084FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
