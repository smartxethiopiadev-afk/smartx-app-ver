import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/device_service.dart';
import '../services/subscription_service.dart';
import 'friendly_error_card.dart';

/// Clean, high-contrast modal dialog for Student License Verification & New Registration.
/// Strictly removed all top video widgets as requested.
class AccountUpgradeDialog extends StatefulWidget {
  final bool isDarkMode;
  final String languageCode;
  final int? initialGrade;
  final int initialTabIndex; // 0 for Verify Upgrade, 1 for Register Student
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

class _AccountUpgradeDialogState extends State<AccountUpgradeDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Verify Tab Form
  final _verifyFormKey = GlobalKey<FormState>();
  final _verifyNameController = TextEditingController();
  final _verifyPhoneController = TextEditingController();

  // Register Tab Form
  final _registerFormKey = GlobalKey<FormState>();
  final _registerNameController = TextEditingController();
  final _registerPhoneController = TextEditingController();
  late int _selectedGrade;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    _selectedGrade = widget.initialGrade ?? 12;
    _loadCachedProfile();
  }

  Future<void> _loadCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_fullName') ?? prefs.getString('user_name') ?? '';
    final phone = prefs.getString('user_phoneNumber') ?? prefs.getString('phone_number') ?? '';
    final cachedGrade = prefs.getInt('user_grade') ?? prefs.getInt('selected_grade');

    if (mounted) {
      setState(() {
        if (name.isNotEmpty) {
          _verifyNameController.text = name;
          _registerNameController.text = name;
        }
        if (phone.isNotEmpty) {
          _verifyPhoneController.text = phone;
          _registerPhoneController.text = phone;
        }
        if (cachedGrade != null && [9, 10, 11, 12].contains(cachedGrade)) {
          _selectedGrade = cachedGrade;
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _verifyNameController.dispose();
    _verifyPhoneController.dispose();
    _registerNameController.dispose();
    _registerPhoneController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // TAB 1: Verify Telegram Purchase & Unlock
  // --------------------------------------------------------------------------
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
        setState(() {
          _isLoading = false;
          _successMessage = result.message;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    result.message,
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

  // --------------------------------------------------------------------------
  // TAB 2: Register New Student in Supabase Database
  // --------------------------------------------------------------------------
  Future<void> _handleRegisterStudent() async {
    if (!_registerFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final isAm = widget.languageCode == 'am';
    final name = _registerNameController.text.trim();
    final cleanPhone = SubscriptionService.sanitizeEthiopianPhone(_registerPhoneController.text.trim());

    try {
      final currentDeviceId = await DeviceService.getDeviceId();
      final supabase = Supabase.instance.client;
      final nowIso = DateTime.now().toUtc().toIso8601String();

      final altPhone = cleanPhone.startsWith('0')
          ? '+251${cleanPhone.substring(1)}'
          : cleanPhone;

      // 1. Check if phone is already registered
      final existing = await supabase
          .from('students')
          .select('full_name, phone_number, device_id')
          .or('phone_number.eq.$cleanPhone,phone_number.eq.$altPhone')
          .maybeSingle()
          .timeout(const Duration(seconds: 8));

      if (existing != null) {
        setState(() {
          _isLoading = false;
          _errorMessage = isAm
              ? 'ይህ ስልክ ቁጥር አስቀድሞ ተመዝግቧል! እባክዎ ወደ "ማረጋገጫና ማግበሪያ (Verify Upgrade)" ትር በመሄድ ያረጋግጡ።'
              : 'This phone number is already registered! Please switch to the "Verify Upgrade" tab to unlock.';
        });
        _tabController.animateTo(0);
        return;
      }

      // 2. Check if device is bound to another student
      final deviceConflict = await supabase
          .from('students')
          .select('phone_number')
          .eq('device_id', currentDeviceId)
          .neq('phone_number', cleanPhone)
          .neq('phone_number', altPhone)
          .maybeSingle()
          .timeout(const Duration(seconds: 8));

      if (deviceConflict != null) {
        setState(() {
          _isLoading = false;
          _errorMessage = isAm
              ? 'ይህ ስልክ ከዚህ ቀደም ከሌላ መለያ ጋር ተገናኝቷል። የደህንነት ስርዓቱ 1 መለያ ለአንድ ስልክ ብቻ ይፈቅዳል (Single-Device Protection)።'
              : 'This device is already bound to another registered student account.';
        });
        return;
      }

      // 3. Perform Insert into Supabase `students` table
      await supabase.from('students').insert({
        'full_name': name,
        'phone_number': cleanPhone,
        'grade': _selectedGrade,
        'device_id': currentDeviceId,
        'is_active': true,
        'unlocked_packages': <String>[],
        'created_at': nowIso,
        'updated_at': nowIso,
      }).timeout(const Duration(seconds: 10));

      // Save Profile in Local SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_fullName', name);
      await prefs.setString('user_name', name);
      await prefs.setString('user_phoneNumber', cleanPhone);
      await prefs.setString('phone_number', cleanPhone);
      await prefs.setInt('user_grade', _selectedGrade);
      await prefs.setInt('selected_grade', _selectedGrade);
      await prefs.setBool('is_authenticated', true);
      await prefs.setBool('has_registered', true);
      await prefs.setString('device_id', currentDeviceId);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _successMessage = isAm
            ? 'እንኳን ደስ አለዎት! ምዝገባዎ በተሳካ ሁኔታ ተጠናቋል።'
            : 'Registration completed successfully! Welcome to Smart Learn Ethiopian.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isAm ? 'ምዝገባዎ በተሳካ ሁኔታ ተጠናቋል!' : 'Student Registered Successfully!',
                  style: GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );

      widget.onSuccess?.call();
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = isAm
              ? 'የምዝገባ ስህተት አጋጥሟል: እባክዎ የኢንተርኔት ግንኙነትዎን ያረጋግጡ ($e)'
              : 'Registration error: Please check your internet connection ($e)';
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
              color: Colors.black.withValues(alpha: isLight ? 0.08 : 0.35),
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
              // Top Header with Title Chip & Close Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_user_rounded, size: 15, color: Color(0xFF0284C7)),
                        const SizedBox(width: 6),
                        Text(
                          isAm ? 'የተማሪ ፈቃድ እና ምዝገባ' : 'Student License & Registration',
                          style: const TextStyle(
                            fontSize: 12,
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

              const SizedBox(height: 16),

              // Dual Pill Tabs: [Verify Upgrade] & [Register Student] (Clean & Modern)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isLight ? 0.06 : 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: const Color(0xFF0284C7),
                  unselectedLabelColor: subColor,
                  labelStyle: GoogleFonts.notoSansEthiopic(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                  unselectedLabelStyle: GoogleFonts.notoSansEthiopic(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 16),
                          const SizedBox(width: 6),
                          Text(isAm ? 'ፈቃድ ማረጋገጫ' : 'Verify Upgrade'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.person_add_rounded, size: 16),
                          const SizedBox(width: 6),
                          Text(isAm ? 'አዲስ ተማሪ ምዝገባ' : 'Register Student'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Tab Views
              AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  return _tabController.index == 0
                      ? _buildVerifyTabContent(isLight, isAm, textColor, subColor, borderColor)
                      : _buildRegisterTabContent(isLight, isAm, textColor, subColor, borderColor);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Tab 1 UI: Verify Telegram Purchase
  // --------------------------------------------------------------------------
  Widget _buildVerifyTabContent(
    bool isLight,
    bool isAm,
    Color textColor,
    Color subColor,
    Color borderColor,
  ) {
    final Color inputFillColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

    return Form(
      key: _verifyFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isAm ? 'የቴሌግራም ክፍያዎን ያረጋግጡ' : 'Verify Your Telegram Purchase',
            style: GoogleFonts.notoSansEthiopic(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isAm
                ? 'የተመዘገቡበትን ሙሉ ስም እና ስልክ ቁጥር በማስገባት የተፈቀደልዎትን ትምህርት በዚህ ስልክ ላይ ይክፈቱ።'
                : 'Enter your registered full name and phone number to unlock curriculum on this device.',
            style: GoogleFonts.notoSansEthiopic(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: subColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Full Name
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
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(fontSize: 13.5, color: textColor, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: isAm ? 'ለምሳሌ፡ አበበ በቀለ' : 'e.g., Abebe Bekele',
              hintStyle: TextStyle(color: subColor.withValues(alpha: 0.6), fontSize: 13),
              filled: true,
              fillColor: inputFillColor,
              prefixIcon: Icon(Icons.person_outline_rounded, color: subColor, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.8)),
            ),
            validator: (val) {
              if (val == null || val.trim().length < 2) {
                return isAm ? 'እባክዎ ሙሉ ስምዎን ያስገቡ' : 'Please enter your full name';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Phone Number
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
            style: TextStyle(fontSize: 13.5, color: textColor, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: isAm ? '0911234567 ወይም 0711234567' : '0911234567 or 0711234567',
              hintStyle: TextStyle(color: subColor.withValues(alpha: 0.6), fontSize: 13),
              filled: true,
              fillColor: inputFillColor,
              prefixIcon: Icon(Icons.phone_outlined, color: subColor, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.8)),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return isAm ? 'እባክዎ ስልክ ቁጥር ያስገቡ' : 'Please enter your phone number';
              }
              final clean = SubscriptionService.sanitizeEthiopianPhone(val);
              if (clean.length < 9) {
                return isAm ? 'እባክዎ ትክክለኛ ስልክ ቁጥር ያስገቡ' : 'Please enter a valid phone number';
              }
              return null;
            },
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            FriendlyErrorCard(
              errorMessage: _errorMessage!,
              isDarkMode: widget.isDarkMode,
              languageCode: widget.languageCode,
              onRetry: _handleVerifyAndUpgrade,
              onDismiss: () => setState(() => _errorMessage = null),
            ),
          ],

          const SizedBox(height: 18),

          // Submit Button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleVerifyAndUpgrade,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : Text(
                      isAm ? 'ፈቃዴን አረጋግጥና ክፈት' : 'Verify & Unlock',
                      style: GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
            ),
          ),

          const SizedBox(height: 10),

          // Contact Admin Option
          SizedBox(
            height: 42,
            child: OutlinedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await SubscriptionService.contactAdminOnTelegram(
                  studentName: _verifyNameController.text.trim(),
                  phoneNumber: _verifyPhoneController.text.trim(),
                  grade: widget.initialGrade,
                  customPurpose: 'የቴሌግራም ክፍያ ፈጽሜ የትምህርት ፈቃዴን ማስከፈት እፈልጋለሁ።',
                );
              },
              icon: const Icon(Icons.support_agent_rounded, size: 18, color: Color(0xFF0088CC)),
              label: Text(
                isAm ? 'አስተዳዳሪውን ያነጋግሩ (Contact Admin)' : 'Contact Admin',
                style: GoogleFonts.notoSansEthiopic(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0088CC),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF0088CC), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Tab 2 UI: Register New Student
  // --------------------------------------------------------------------------
  Widget _buildRegisterTabContent(
    bool isLight,
    bool isAm,
    Color textColor,
    Color subColor,
    Color borderColor,
  ) {
    final Color inputFillColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isAm ? 'አዲስ ተማሪ ምዝገባ' : 'Register New Student',
            style: GoogleFonts.notoSansEthiopic(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isAm
                ? 'መረጃዎ በዳታቤዝ ውስጥ ይመዘገባል እንዲሁም ለአንድ ስልክ ብቻ ደህንነቱ ይጠበቃል (Single Device Security)።'
                : 'Your details will be securely registered into the database and bound to this device.',
            style: GoogleFonts.notoSansEthiopic(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: subColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Full Name
          Text(
            isAm ? 'የተማሪ ሙሉ ስም (Student Name)' : 'Student Name',
            style: GoogleFonts.notoSansEthiopic(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _registerNameController,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(fontSize: 13.5, color: textColor, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: isAm ? 'ለምሳሌ፡ ሰላም ታደሰ' : 'e.g., Selam Tadesse',
              hintStyle: TextStyle(color: subColor.withValues(alpha: 0.6), fontSize: 13),
              filled: true,
              fillColor: inputFillColor,
              prefixIcon: Icon(Icons.badge_outlined, color: subColor, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.8)),
            ),
            validator: (val) {
              if (val == null || val.trim().length < 2) {
                return isAm ? 'እባክዎ ሙሉ ስም ያስገቡ' : 'Please enter student name';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Select Grade Selector
          Text(
            isAm ? 'የትምህርት ክፍል ይምረጡ (Select Grade)' : 'Select Grade',
            style: GoogleFonts.notoSansEthiopic(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [9, 10, 11, 12].map((g) {
              final bool isSelected = _selectedGrade == g;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    onTap: () => setState(() => _selectedGrade = g),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF059669) : inputFillColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF059669) : borderColor,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Text(
                        'Grade $g',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                          color: isSelected ? Colors.white : textColor,
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
            style: GoogleFonts.notoSansEthiopic(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _registerPhoneController,
            keyboardType: TextInputType.phone,
            style: TextStyle(fontSize: 13.5, color: textColor, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: isAm ? '0911234567 ወይም 0711234567' : '0911234567 or 0711234567',
              hintStyle: TextStyle(color: subColor.withValues(alpha: 0.6), fontSize: 13),
              filled: true,
              fillColor: inputFillColor,
              prefixIcon: Icon(Icons.phone_outlined, color: subColor, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.8)),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return isAm ? 'እባክዎ ስልክ ቁጥር ያስገቡ' : 'Please enter phone number';
              }
              final clean = SubscriptionService.sanitizeEthiopianPhone(val);
              if (clean.length < 9) {
                return isAm ? 'እባክዎ ትክክለኛ ስልክ ቁጥር ያስገቡ' : 'Please enter a valid phone number';
              }
              return null;
            },
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            FriendlyErrorCard(
              errorMessage: _errorMessage!,
              isDarkMode: widget.isDarkMode,
              languageCode: widget.languageCode,
              onRetry: _handleRegisterStudent,
              onDismiss: () => setState(() => _errorMessage = null),
            ),
          ],

          const SizedBox(height: 18),

          // Register Button
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleRegisterStudent,
              icon: _isLoading
                  ? const SizedBox.shrink()
                  : const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : Text(
                      isAm ? 'ተመዝገብ እና ጨርስ' : 'Register Student',
                      style: GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
