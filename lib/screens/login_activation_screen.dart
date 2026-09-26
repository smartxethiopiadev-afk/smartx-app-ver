import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/credential_auth_service.dart';
import '../services/subscription_service.dart';
import '../widgets/friendly_error_card.dart';
import 'registration_screen.dart';

class LoginActivationScreen extends StatefulWidget {
  final bool isDarkMode;
  final String languageCode;
  final int preferredGrade;
  final String? preferredSubject;
  final bool isOfflineWelcomeBack;

  const LoginActivationScreen({
    super.key,
    required this.isDarkMode,
    required this.languageCode,
    this.preferredGrade = 12,
    this.preferredSubject,
    this.isOfflineWelcomeBack = false,
  });

  static Future<bool?> push(
    BuildContext context, {
    required bool isDarkMode,
    required String languageCode,
    int preferredGrade = 12,
    String? preferredSubject,
    bool isOfflineWelcomeBack = false,
  }) async {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (ctx) => LoginActivationScreen(
          isDarkMode: isDarkMode,
          languageCode: languageCode,
          preferredGrade: preferredGrade,
          preferredSubject: preferredSubject,
          isOfflineWelcomeBack: isOfflineWelcomeBack,
        ),
      ),
    );
  }

  @override
  State<LoginActivationScreen> createState() => _LoginActivationScreenState();
}

class _LoginActivationScreenState extends State<LoginActivationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool get _isWelcomeBackMode => widget.isOfflineWelcomeBack;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_fullName') ?? prefs.getString('user_name') ?? '';
    final phone = prefs.getString('user_phoneNumber') ?? prefs.getString('phone_number') ?? '';
    if (mounted) {
      setState(() {
        _nameController.text = name;
        _phoneController.text = phone;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _performLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final fullName = _nameController.text.trim().isEmpty ? 'Student' : _nameController.text.trim();
    final phone = _phoneController.text.trim();

    final result = await CredentialAuthService.loginWithPhoneAndName(
      fullName: fullName,
      phoneNumber: phone,
      grade: widget.preferredGrade,
      subject: widget.preferredSubject,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.isSuccess) {
      final bool isAm = widget.languageCode == 'am';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.message ?? (isAm ? 'በተሳካ ሁኔታ ገብተዋል! ይዘቶች ተከፍተዋል' : 'Login successful! Content unlocked.'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _errorMessage = result.message;
      });

      if (result.status == CredentialAuthStatus.deviceMismatchLocked) {
        _showDeviceMismatchDialog(result.message ?? 'Account locked to another device.');
      }
    }
  }

  void _showDeviceMismatchDialog(String message) {
    final bool isAm = widget.languageCode == 'am';
    final isLight = !widget.isDarkMode;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 28),
            const SizedBox(width: 8),
            Text(
              isAm ? 'የመለያ መቆለፊያ ማስጠንቀቂያ' : 'Device Locked',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: isLight ? const Color(0xFF0F172A) : Colors.white,
              ),
            ),
          ],
        ),
        content: Text(
          isAm
              ? 'ይህ መለያ አስቀድሞ በሌላ ስልክ ላይ ተመዝግቧል። መለያ ማጋራት በጥብቅ የተከለከለ ነው። ስልክ ከቀየሩ አስተዳዳሪውን ያነጋግሩ።'
              : message,
          style: TextStyle(
            fontSize: 13.5,
            color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              isAm ? 'እሺ' : 'OK',
              style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0084FF)),
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
          isAm ? 'የተማሪ መግቢያ' : 'Student Login',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Icon & Title
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (_isWelcomeBackMode ? const Color(0xFF10B981) : const Color(0xFF0084FF))
                        .withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isWelcomeBackMode ? Icons.verified_user_rounded : Icons.lock_person_rounded,
                    size: 42,
                    color: _isWelcomeBackMode ? const Color(0xFF10B981) : const Color(0xFF0084FF),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                isAm ? 'ይግቡ (Login)' : 'Student Login',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isAm
                    ? 'በስም እና ስልክ ቁጥርዎ በቀላሉ ይግቡ'
                    : 'Sign in with your Full Name and registered Phone Number',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4),
              ),
              const SizedBox(height: 20),

              // Friendly Actionable Error Card
              if (_errorMessage != null) ...[
                FriendlyErrorCard(
                  errorMessage: _errorMessage!,
                  isDarkMode: widget.isDarkMode,
                  languageCode: widget.languageCode,
                  onRetry: _performLogin,
                  onDismiss: () {
                    setState(() {
                      _errorMessage = null;
                    });
                  },
                ),
                const SizedBox(height: 12),
              ],

              // Full Name Field
              Text(
                isAm ? 'ሙሉ ስም' : 'Full Name',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: textPrimary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return isAm ? 'እባክዎ ሙሉ ስም ያስገቡ' : 'Please enter your full name';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: isAm ? 'ለምሳሌ፡ አበበ ከበደ' : 'e.g., Abebe Kebede',
                  filled: true,
                  fillColor: cardBg,
                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Phone Number Field
              Text(
                isAm ? 'ስልክ ቁጥር' : 'Phone Number',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: textPrimary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return isAm ? 'እባክዎ ስልክ ቁጥር ያስገቡ' : 'Please enter your phone number';
                  }
                  final sanitized = SubscriptionService.sanitizeEthiopianPhone(val);
                  if (sanitized.isEmpty || sanitized.length < 9) {
                    return isAm ? 'እባክዎ ትክክለኛ ስልክ ቁጥር ያስገቡ' : 'Please enter a valid phone number';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: '09xxxxxxxx',
                  filled: true,
                  fillColor: cardBg,
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Login Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _performLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0084FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(
                          isAm ? 'ግባና ቀጥል' : 'Login & Continue',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Contact Admin Assistance
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Text(
                      isAm ? 'እገዛ ይፈልጋሉ?' : 'Need Assistance?',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAm
                          ? 'ክፍያ ለመፈጸም ወይም አካውንትዎን ለማስከፈት አስተዳዳሪውን ያነጋግሩ።'
                          : 'Contact support to complete payment or unlock your account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11.5, color: textSecondary),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await SubscriptionService.contactAdminOnTelegram(
                          studentName: _nameController.text.trim(),
                          phoneNumber: _phoneController.text.trim(),
                          grade: widget.preferredGrade,
                          customPurpose: 'የተማሪ መለያዬን ለማስከፈት ወይም ለመግባት እገዛ እፈልጋለሁ።',
                        );
                      },
                      icon: const Icon(Icons.support_agent_rounded, size: 18),
                      label: Text(
                        isAm ? 'አስተዳዳሪውን ያነጋግሩ (Contact Admin)' : 'Contact Admin',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0088CC),
                        side: const BorderSide(color: Color(0xFF0088CC), width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Register as New Student Link
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => RegistrationScreen(
                          isDarkMode: widget.isDarkMode,
                          languageCode: widget.languageCode,
                          onToggleTheme: () {},
                          onToggleLanguage: () {},
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_add_rounded, size: 18, color: Color(0xFF0084FF)),
                  label: Text(
                    isAm ? 'አዲስ ተማሪ ነዎት? መጀመሪያ ይመዝገቡ' : 'New student? Register First',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0084FF),
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
