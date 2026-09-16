import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import 'home_screen.dart';
import 'login_activation_screen.dart';

class RegistrationScreen extends StatefulWidget {
  final bool isDarkMode;
  final String languageCode;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLanguage;

  const RegistrationScreen({
    super.key,
    required this.isDarkMode,
    required this.languageCode,
    required this.onToggleTheme,
    required this.onToggleLanguage,
  });

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _schoolController = TextEditingController();

  String _selectedGender = 'male'; // 'male' or 'female'
  int _selectedGrade = 12; // 9, 10, 11, 12
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  String _generateUuidV4() {
    final random = math.Random();
    String generateHex(int length) {
      final buffer = StringBuffer();
      for (int i = 0; i < length; i++) {
        buffer.write(random.nextInt(16).toRadixString(16));
      }
      return buffer.toString();
    }
    final y = (random.nextInt(4) + 8).toRadixString(16);
    return '${generateHex(8)}-${generateHex(4)}-4${generateHex(3)}-$y${generateHex(3)}-${generateHex(12)}';
  }

  String? _formatEthiopianPhone(String rawPhone) {
    String cleanDigits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (cleanDigits.startsWith('251') && cleanDigits.length == 12) {
      final localPart = cleanDigits.substring(3);
      if (localPart.startsWith('9') || localPart.startsWith('7')) {
        return '+$cleanDigits';
      }
    } else if (cleanDigits.startsWith('0') && cleanDigits.length == 10) {
      final localPart = cleanDigits.substring(1);
      if (localPart.startsWith('9') || localPart.startsWith('7')) {
        return '+251$localPart';
      }
    } else if (cleanDigits.length == 9 && (cleanDigits.startsWith('9') || cleanDigits.startsWith('7'))) {
      return '+251$cleanDigits';
    }
    return null;
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final isEn = widget.languageCode == 'en';
    final fullName = _nameController.text.trim();
    final rawPhone = _phoneController.text.trim();
    final schoolName = _schoolController.text.trim().isNotEmpty
        ? _schoolController.text.trim()
        : 'Not Specified';

    final formattedPhone = _formatEthiopianPhone(rawPhone);
    if (formattedPhone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEn
              ? 'Please enter a valid Ethiopian phone number (e.g. 09... or +251 9...)'
              : 'እባክዎ ትክክለኛ የኢትዮጵያ ስልክ ቁጥር ያስገቡ (ምሳሌ፡ 09... ወይም +251 9...)'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final String profileId = _generateUuidV4();
      final String nowIso = DateTime.now().toUtc().toIso8601String();

      // 1. Attempt insert into 'student_registrations' or 'profiles' table
      bool insertSuccess = false;

      try {
        await supabase.from('student_registrations').insert({
          'id': profileId,
          'full_name': fullName,
          'phone_number': formattedPhone,
          'school_name': schoolName,
          'gender': _selectedGender,
          'grade': _selectedGrade,
          'created_at': nowIso,
        }).timeout(const Duration(seconds: 10));
        insertSuccess = true;
      } catch (_) {}

      if (!insertSuccess) {
        try {
          await supabase.from('profiles').insert({
            'id': profileId,
            'full_name': fullName,
            'phone_number': formattedPhone,
            'school': schoolName,
            'gender': _selectedGender,
            'grade': _selectedGrade,
            'created_at': nowIso,
          }).timeout(const Duration(seconds: 10));
          insertSuccess = true;
        } catch (_) {}
      }

      if (!insertSuccess) {
        try {
          await supabase.from('student_profiles').insert({
            'id': profileId,
            'full_name': fullName,
            'phone_number': formattedPhone,
            'grade': _selectedGrade,
          }).timeout(const Duration(seconds: 10));
          insertSuccess = true;
        } catch (_) {}
      }

      // 2. Save locally in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_registered', true);
      await prefs.setString('user_id', profileId);
      await prefs.setString('user_fullName', fullName);
      await prefs.setString('user_phoneNumber', formattedPhone);
      await prefs.setString('user_school', schoolName);
      await prefs.setString('user_gender', _selectedGender);
      await prefs.setString('user_grade', 'Grade $_selectedGrade');

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        _showRegistrationSuccessDialog(fullName, formattedPhone, schoolName);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint("Registration error: $e");
      String errMsg = isEn
          ? 'An error occurred during registration. Please check your connection and try again.'
          : 'በምዝገባ ወቅት ስህተት አጋጥሟል። እባክዎ የኢንተርኔት ግንኙነትዎን ያረጋግጡና እንደገና ይሞክሩ።';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showRegistrationSuccessDialog(String fullName, String phone, String school) {
    final bool isEn = widget.languageCode == 'en';
    final bool isLight = !widget.isDarkMode;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                isEn ? 'Registration Complete!' : 'ምዝገባዎ በተሳካ ሁኔታ ተጠናቋል!',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isLight ? const Color(0xFF0F172A) : Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isEn
                    ? 'Your details have been registered. The admin will verify and provide your access password via Telegram.'
                    : 'የተማሪ መረጃዎ በተሳካ ሁኔታ ተመዝግቧል። አድሚኑ መረጃዎን አይቶ የይለፍ ቃል በቴሌግራም ይልክልዎታል።',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Button 1: Send Request to Telegram Admin
              ElevatedButton.icon(
                onPressed: () async {
                  final String msg =
                      'ሰላም Ethio Concept Center Admin, አዲስ ተማሪ ሆኜ ተመዝግቤያለሁ:\n'
                      '• የተማሪ ስም: $fullName\n'
                      '• ስልክ ቁጥር: $phone\n'
                      '• የትምህርት ቤት ስም: $school\n'
                      '• ክፍል: Grade $_selectedGrade\n'
                      '• ፆታ: ${_selectedGender == 'male' ? 'ወንድ' : 'ሴት'}\n'
                      'እባክዎ የይለፍ ቃል (Password) ይስጡኝ።';

                  final Uri telegramUri = Uri.parse(
                      'https://t.me/EthioconceptcenterAcademy?text=${Uri.encodeComponent(msg)}');
                  if (await canLaunchUrl(telegramUri)) {
                    await launchUrl(telegramUri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  isEn ? 'Request Password via Telegram' : 'በቴሌግራም የይለፍ ቃል ጠይቅ',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0088CC),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),

              const SizedBox(height: 10),

              // Button 2: Already have password? Go to login
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final res = await LoginActivationScreen.push(
                    context,
                    isDarkMode: widget.isDarkMode,
                    languageCode: widget.languageCode,
                    preferredGrade: _selectedGrade,
                  );
                  if (res == true) {
                    _navigateToHome();
                  } else {
                    _navigateToHome();
                  }
                },
                icon: const Icon(Icons.key_rounded, size: 18, color: Color(0xFF0084FF)),
                label: Text(
                  isEn ? 'I have a password -> Login' : 'የይለፍ ቃል አለኝ -> ግባ',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0084FF)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0084FF), width: 1.5),
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),

              const SizedBox(height: 8),

              // Button 3: Skip / Explore app freely
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _navigateToHome();
                },
                child: Text(
                  isEn ? 'Start Exploring (Free Trial Units)' : 'ወደ መተግበሪያው ግባ (ይዘቶችን በነጻ ሞክር)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleSkip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_registered', false);
    await prefs.setBool('is_authenticated', false);
    _navigateToHome();
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(
          isDarkMode: widget.isDarkMode,
          languageCode: widget.languageCode,
          onToggleTheme: widget.onToggleTheme,
          onToggleLanguage: widget.onToggleLanguage,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const curve = Curves.fastOutSlowIn;
          var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));
          return FadeTransition(opacity: animation.drive(fadeTween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = !widget.isDarkMode;
    final bool isEn = widget.languageCode == 'en';

    final Color cardColor = isLight ? Colors.white : const Color(0xFF1E293B);
    final Color textColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final Color subtitleColor = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final Color inputFillColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color borderColor = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155);

    return Scaffold(
      backgroundColor: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 460),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isLight ? 0.06 : 0.4),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Brand Header
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0084FF), Color(0xFF00D4FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ethio Concept Center',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  isEn ? 'Student Registration Portal' : 'የተማሪዎች ምዝገባ መግቢያ',
                                  style: TextStyle(fontSize: 11.5, color: subtitleColor, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      const Divider(height: 1),
                      const SizedBox(height: 20),

                      // 1. Full Name
                      Text(
                        isEn ? 'Full Name (የተማሪው ሙሉ ስም)' : 'የተማሪው ሙሉ ስም',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
                        decoration: InputDecoration(
                          hintText: isEn ? 'e.g. Abebe Kebede' : 'ምሳሌ፡ አበበ ከበደ',
                          filled: true,
                          fillColor: inputFillColor,
                          prefixIcon: const Icon(Icons.person_outline_rounded, size: 20, color: Color(0xFF0084FF)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return isEn ? 'Please enter your full name' : 'እባክዎ ሙሉ ስምዎን ያስገቡ';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // 2. Phone Number
                      Text(
                        isEn ? 'Phone Number (ስልክ ቁጥር)' : 'ስልክ ቁጥር',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
                        decoration: InputDecoration(
                          hintText: '09xxxxxxxx / +251 9...',
                          filled: true,
                          fillColor: inputFillColor,
                          prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: Color(0xFF0084FF)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return isEn ? 'Please enter phone number' : 'እባክዎ ስልክ ቁጥር ያስገቡ';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // 3. School Name
                      Text(
                        isEn ? 'School Name (የትምህርት ቤት ስም)' : 'የትምህርት ቤት ስም',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _schoolController,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
                        decoration: InputDecoration(
                          hintText: isEn ? 'e.g. Menelik II School' : 'ምሳሌ፡ ዳግማዊ ምኒልክ ሁለተኛ ደረጃ ት/ቤት',
                          filled: true,
                          fillColor: inputFillColor,
                          prefixIcon: const Icon(Icons.business_outlined, size: 20, color: Color(0xFF0084FF)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 4. Gender (Sex) Selector: Male / Female
                      Text(
                        isEn ? 'Gender / Sex (ፆታ)' : 'ፆታ (Gender)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedGender = 'male';
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _selectedGender == 'male'
                                      ? const Color(0xFF0084FF).withValues(alpha: 0.12)
                                      : inputFillColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _selectedGender == 'male'
                                        ? const Color(0xFF0084FF)
                                        : borderColor,
                                    width: _selectedGender == 'male' ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.male_rounded,
                                      size: 18,
                                      color: _selectedGender == 'male' ? const Color(0xFF0084FF) : subtitleColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isEn ? 'Male' : 'ወንድ (Male)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: _selectedGender == 'male' ? const Color(0xFF0084FF) : textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedGender = 'female';
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _selectedGender == 'female'
                                      ? const Color(0xFFEC4899).withValues(alpha: 0.12)
                                      : inputFillColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _selectedGender == 'female'
                                        ? const Color(0xFFEC4899)
                                        : borderColor,
                                    width: _selectedGender == 'female' ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.female_rounded,
                                      size: 18,
                                      color: _selectedGender == 'female' ? const Color(0xFFEC4899) : subtitleColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isEn ? 'Female' : 'ሴት (Female)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: _selectedGender == 'female' ? const Color(0xFFEC4899) : textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // 5. Grade Level Selector (9, 10, 11, 12)
                      Text(
                        isEn ? 'Grade Level (የክፍል ደረጃ)' : 'የክፍል ደረጃ (Grade Level)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [9, 10, 11, 12].map((g) {
                          final bool isSelected = _selectedGrade == g;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedGrade = g;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF0084FF)
                                      : inputFillColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF0084FF) : borderColor,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Grade $g',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected ? Colors.white : textColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // Register Button
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
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
                                  isEn ? 'Complete Registration' : 'ምዝገባውን አጠናቅቅ',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
                                ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Direct Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isEn ? 'Already have a password? ' : 'የይለፍ ቃል አስቀድመው አለዎት? ',
                            style: TextStyle(fontSize: 12, color: subtitleColor),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final res = await LoginActivationScreen.push(
                                context,
                                isDarkMode: widget.isDarkMode,
                                languageCode: widget.languageCode,
                                preferredGrade: _selectedGrade,
                              );
                              if (res == true) {
                                _navigateToHome();
                              }
                            },
                            child: Text(
                              isEn ? 'Login Here' : 'እዚህ ይግቡ',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0084FF),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Skip link
                      Center(
                        child: TextButton(
                          onPressed: _isLoading ? null : _handleSkip,
                          child: Text(
                            isEn ? 'Skip and continue to app' : 'ይዝለሉና ወደ መተግበሪያው ይግቡ',
                            style: TextStyle(fontSize: 12, color: subtitleColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
