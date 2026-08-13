import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;
import 'home_screen.dart';

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
  
  int _selectedGrade = 12; // Default grade level
  bool _isLoading = false;
  int _currentStep = 1; // Step 1: Name, Step 2: Grade, Step 3: Phone

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
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
    final y = (random.nextInt(4) + 8).toRadixString(16); // 8, 9, a, or b
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

    // Validate Ethiopian phone number (must be 12 digits: 251 + 9 digits starting with 9 or 7)
    final formattedPhone = _formatEthiopianPhone(rawPhone);
    if (formattedPhone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEn
              ? 'Please enter a valid Ethiopian phone number (e.g. +251 9... or +251 7...)'
              : 'እባክዎ ትክክለኛ የኢትዮጵያ ስልክ ቁጥር ያስገቡ (ምሳሌ፡ +251 9... ወይም +251 7...)'),
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

      // Attempt to save directly into 'profiles' table first
      bool insertSuccess = false;
      try {
        await supabase.from('profiles').insert({
          'id': profileId,
          'full_name': fullName,
          'phone_number': formattedPhone,
          'grade': _selectedGrade,
          'created_at': nowIso,
        });
        insertSuccess = true;
        debugPrint("Successfully inserted user registration details into Supabase 'profiles' table.");
      } catch (e) {
        debugPrint("Failed insert into 'profiles' table, attempting fallback to 'student_profiles' table: $e");
      }

      // Fallback to 'student_profiles' if 'profiles' insert failed or table doesn't exist
      if (!insertSuccess) {
        await supabase.from('student_profiles').insert({
          'id': profileId,
          'full_name': fullName,
          'phone_number': formattedPhone,
          'grade': _selectedGrade,
        });
        debugPrint("Successfully inserted user registration details into fallback Supabase 'student_profiles' table.");
      }

      // Save registration state in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_registered', true);
      await prefs.setBool('is_authenticated', true);
      await prefs.setString('user_id', profileId);
      await prefs.setString('user_fullName', fullName);
      await prefs.setString('user_phoneNumber', formattedPhone);
      await prefs.setString('user_grade', 'Grade $_selectedGrade');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isEn
                        ? 'Successfully registered! Welcome to Smart X.'
                        : 'በስኬት ተመዝግበዋል! ወደ ስማርት ኤክስ እንኳን ደህና መጡ።',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _navigateToHome();
      }
    } catch (e) {
      debugPrint("Supabase insertion failed: $e");
      String errMsg = _getFriendlyDatabaseErrorMessage(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(errMsg, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSkip() async {
    // Allows users to skip registration for now and goes straight to HomeScreen
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
          return FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  String _getFriendlyDatabaseErrorMessage(dynamic e) {
    final isEn = widget.languageCode == 'en';
    String englishMsg = 'An error occurred. Please check your connection and try again.';
    String amharicMsg = 'ስህተት አጋጥሟል። እባክዎ የኢንተርኔት ግንኙነትዎን ያረጋግጡና እንደገና ይሞክሩ።';

    if (e is PostgrestException) {
      final code = e.code;
      final message = e.message.toLowerCase();
      final details = (e.details?.toString() ?? '').toLowerCase();

      if (code == '23505' || message.contains('unique') || details.contains('already exists')) {
        if (message.contains('phone_number') || details.contains('phone_number')) {
          englishMsg = 'This phone number is already registered. Please use another number or skip.';
          amharicMsg = 'ይህ ስልክ ቁጥር ቀድሞ ተመዝግቧል። እባክዎ ሌላ ስልክ ቁጥር ይጠቀሙ ወይም ይዝለሉት።';
        } else {
          englishMsg = 'A record with these details already exists in our database.';
          amharicMsg = 'እነዚህን ዝርዝሮች የያዘ ተማሪ ቀድሞ በመረጃ ቋቱ ውስጥ ተመዝግቧል።';
        }
      } else {
        englishMsg = 'We couldn\'t process your request. Please check your connection and try again.';
        amharicMsg = 'ጥያቄዎን ማስተናገድ አልቻልንም። እባክዎ ግንኙነትዎን ያረጋግጡና እንደገና ይሞክሩ።';
      }
    }
    return isEn ? englishMsg : amharicMsg;
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = !widget.isDarkMode;
    final bool isEn = widget.languageCode == 'en';

    final cardColor = isLight ? Colors.white : const Color(0xFF1E293B);
    final textColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final subtitleColor = isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8);
    final inputFillColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isLight ? 0.05 : 0.35),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Elegant Step Indicator Top Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          final stepNum = index + 1;
                          final isActive = _currentStep == stepNum;
                          final isCompleted = _currentStep > stepNum;
                          return Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isActive
                                      ? const Color(0xFF00BFFF)
                                      : isCompleted
                                          ? const Color(0xFF10B981)
                                          : (isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                                  border: Border.all(
                                    color: isActive
                                        ? const Color(0xFF00BFFF)
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: isCompleted
                                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                                      : Text(
                                          '$stepNum',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: isActive || isCompleted
                                                ? Colors.white
                                                : (isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                                          ),
                                        ),
                                ),
                              ),
                              if (index < 2)
                                Container(
                                  width: 32,
                                  height: 2,
                                  color: isCompleted
                                      ? const Color(0xFF10B981)
                                      : (isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                                ),
                            ],
                          );
                        }),
                      ),
                      const SizedBox(height: 32),

                      // Step 1: Name Field Flow
                      if (_currentStep == 1) ...[
                        _buildStepHeader(
                          title: isEn ? "What's your name?" : "ስምዎ ማን ነው?",
                          subtitle: isEn 
                              ? "Enter your full name to get personalized lessons" 
                              : "ለግል ብጁ የጥናት ማቴሪያሎች ሙሉ ስምዎን ያስገቡ",
                          icon: Icons.person_rounded,
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                        ),
                        const SizedBox(height: 24),
                        _buildTextField(
                          label: isEn ? "Full Name" : "ሙሉ ስም",
                          hintText: isEn ? "e.g., John Doe" : "ምሳሌ: አበበ በቀለ",
                          prefixIcon: Icons.badge_rounded,
                          controller: _nameController,
                          textColor: textColor,
                          inputFillColor: inputFillColor,
                          hintColor: subtitleColor,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return isEn ? 'Name is required' : 'እባክዎን ስምዎን ያስገቡ';
                            }
                            if (val.trim().length < 3) {
                              return isEn ? 'Name is too short' : 'የገቡት ስም በጣም አጭር ነው';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              setState(() {
                                _currentStep = 2;
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00BFFF),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isEn ? 'Next' : 'ቀጣይ',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                        ),
                      ],

                      // Step 2: Grade Selection Flow
                      if (_currentStep == 2) ...[
                        _buildStepHeader(
                          title: isEn ? "Select Grade" : "ክፍልዎን ይምረጡ",
                          subtitle: isEn
                              ? "Choose your current academic grade level"
                              : "የአሁኑን የትምህርት ክፍል ደረጃዎን ይምረጡ",
                          icon: Icons.school_rounded,
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [9, 10, 11, 12].map((g) {
                            final bool isSelected = _selectedGrade == g;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedGrade = g;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF00BFFF)
                                        : inputFillColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF00BFFF)
                                          : (isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      isEn ? '$g' : '$g ክፍል',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
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
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _currentStep = 1;
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textColor,
                                  minimumSize: const Size.fromHeight(52),
                                  side: BorderSide(
                                    color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  isEn ? 'Back' : 'ተመለስ',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _currentStep = 3;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00BFFF),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      isEn ? 'Next' : 'ቀጣይ',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.arrow_forward_rounded, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                        // Step 3: Phone Field Flow
                        if (_currentStep == 3) ...[
                          _buildStepHeader(
                            title: isEn ? "Phone Number" : "ስልክ ቁጥር",
                            subtitle: isEn
                                ? "Enter your 12-digit Ethiopian mobile number (+251 9... / +251 7...)"
                                : "ባለ 12 አሃዝ የኢትዮጵያ ስልክ ቁጥርዎን ያስገቡ (+251 9... / +251 7...)",
                            icon: Icons.phone_android_rounded,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                          ),
                          const SizedBox(height: 24),
                          _buildPhoneField(
                            label: isEn ? "Ethiopian Mobile Number" : "የኢትዮጵያ ሞባይል ስልክ ቁጥር",
                            hintText: "912 345 678",
                            controller: _phoneController,
                            textColor: textColor,
                            inputFillColor: inputFillColor,
                            hintColor: subtitleColor,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return isEn ? 'Phone number is required' : 'እባክዎን ስልክ ቁጥር ያስገቡ';
                              }
                              final formatted = _formatEthiopianPhone(val);
                              if (formatted == null) {
                                return isEn 
                                    ? 'Enter a valid 9-digit Ethiopian number (9... or 7...)' 
                                    : 'ትክክለኛ ባለ 9 አሃዝ ስልክ ቁጥር ያስገቡ (9... ወይም 7...)';
                              }
                              return null;
                            },
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _currentStep = 2;
                                        });
                                      },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textColor,
                                  minimumSize: const Size.fromHeight(52),
                                  side: BorderSide(
                                    color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  isEn ? 'Back' : 'ተመለስ',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00BFFF), Color(0xFF0E7896)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleRegister,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    minimumSize: const Size.fromHeight(52),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Text(
                                          isEn ? 'Register' : 'ይመዝገቡ',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _isLoading ? null : _handleSkip,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textColor,
                            minimumSize: const Size.fromHeight(52),
                            side: BorderSide(
                              color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            isEn ? 'Skip Registration' : 'ምዝገባውን ዝለል',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildStepHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF00BFFF), Color(0xFF0E7896)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00BFFF).withValues(alpha: 0.25),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 36,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            color: subtitleColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hintText,
    required IconData prefixIcon,
    required TextEditingController controller,
    required Color textColor,
    required Color inputFillColor,
    required Color hintColor,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.plusJakartaSans(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.plusJakartaSans(
              color: hintColor.withValues(alpha: 0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(prefixIcon, color: const Color(0xFF00BFFF), size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            filled: true,
            fillColor: inputFillColor,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFF00BFFF).withValues(alpha: 0.25),
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF00BFFF),
                width: 2.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 1.2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.5,
              ),
            ),
            errorStyle: GoogleFonts.plusJakartaSans(fontSize: 12),
          ),
          validator: validator,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPhoneField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required Color textColor,
    required Color inputFillColor,
    required Color hintColor,
    String? Function(String?)? validator,
  }) {
    final isLight = !widget.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.phone,
          style: GoogleFonts.plusJakartaSans(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.plusJakartaSans(
              color: hintColor.withValues(alpha: 0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.only(left: 8, right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '🇪🇹',
                    style: TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '+251',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isLight ? const Color(0xFF0F172A) : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 1.5,
                    height: 22,
                    color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  ),
                ],
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            filled: true,
            fillColor: inputFillColor,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFF00BFFF).withValues(alpha: 0.25),
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF00BFFF),
                width: 2.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 1.2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.5,
              ),
            ),
            errorStyle: GoogleFonts.plusJakartaSans(fontSize: 12),
          ),
          validator: validator,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
