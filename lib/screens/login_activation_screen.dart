import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/credential_auth_service.dart';
import 'payment_screen.dart';

class LoginActivationScreen extends StatefulWidget {
  final bool isDarkMode;
  final String languageCode;
  final int preferredGrade;
  final String? preferredSubject;

  const LoginActivationScreen({
    super.key,
    required this.isDarkMode,
    required this.languageCode,
    this.preferredGrade = 12,
    this.preferredSubject,
  });

  static Future<bool?> push(
    BuildContext context, {
    required bool isDarkMode,
    required String languageCode,
    int preferredGrade = 12,
    String? preferredSubject,
  }) async {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (ctx) => LoginActivationScreen(
          isDarkMode: isDarkMode,
          languageCode: languageCode,
          preferredGrade: preferredGrade,
          preferredSubject: preferredSubject,
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
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

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
    _passwordController.dispose();
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
    final password = _passwordController.text.trim();

    final result = await CredentialAuthService.loginWithCredentials(
      fullName: fullName,
      phoneNumber: phone,
      password: password,
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
                  isAm ? 'በተሳካ ሁኔታ ገብተዋል! ይዘቶች ተከፍተዋል' : 'Login successful! Content unlocked.',
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
          isAm ? 'የተማሪ መግቢያ / ማግበር' : 'Student Login & Activation',
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
                    color: const Color(0xFF0084FF).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_person_rounded,
                    size: 42,
                    color: Color(0xFF0084FF),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isAm ? 'በአስተዳዳሪ የተሰጠውን የይለፍ ቃል ያስገቡ' : 'Enter Admin-Issued Credentials',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isAm
                    ? 'ክፍያ ከፈጸሙ በኋላ የተሰጦትን ስልክ ቁጥር እና የይለፍ ቃል ያስገቡ።'
                    : 'Enter the registered phone number and password provided by Smart X Admin after payment.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),

              // Single Device Notice Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phonelink_lock_rounded, color: Color(0xFFF59E0B), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isAm
                            ? 'ማስታወሻ፡ መለያዎ በመጀመሪያ በሚገቡበት ስልክ ላይ በቋሚነት ይቆለፋል። መለያ ማጋራት አይቻልም።'
                            : 'Notice: Your account binds strictly to this device on first login to prevent unauthorized sharing.',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isLight ? const Color(0xFFB45309) : const Color(0xFFFBBF24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Error Message if any
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444), fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Full Name Field (Optional)
              Text(
                isAm ? 'ሙሉ ስም (አማራጭ)' : 'Student Name (Optional)',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: textPrimary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
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
                isAm ? 'ስልክ ቁጥር (መለያ)' : 'Phone Number (Account ID)',
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

              const SizedBox(height: 16),

              // Password Field
              Text(
                isAm ? 'የይለፍ ቃል (Password)' : 'Password',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: textPrimary),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return isAm ? 'እባክዎ የይለፍ ቃል ያስገቡ' : 'Please enter your password';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: '••••••••',
                  filled: true,
                  fillColor: cardBg,
                  prefixIcon: const Icon(Icons.vpn_key_outlined, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
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
                          isAm ? 'ግባ እና ይዘቶችን ክፈት' : 'Login & Unlock Content',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Don't have credentials yet? Go to Payment Screen
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
                      isAm ? 'እስካሁን ክፍያ አልፈጸሙም?' : "Haven't paid yet?",
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAm
                          ? 'የቴሌብር እና የኢትዮጵያ ንግድ ባንክ ሂሳቦችን ለማየትና ክፍያ ለመፈጸም ይጫኑ።'
                          : 'View verified Telebirr & CBE bank accounts to complete your transfer.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11.5, color: textSecondary),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        PaymentScreen.push(
                          context,
                          isDarkMode: widget.isDarkMode,
                          languageCode: widget.languageCode,
                          grade: widget.preferredGrade,
                          subject: widget.preferredSubject,
                        );
                      },
                      icon: const Icon(Icons.account_balance_wallet_rounded, size: 18),
                      label: Text(
                        isAm ? 'የባንክ ሂሳቦች እና የክፍያ ገጽ' : 'View Bank Accounts & Pay',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0084FF),
                        side: const BorderSide(color: Color(0xFF0084FF)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
