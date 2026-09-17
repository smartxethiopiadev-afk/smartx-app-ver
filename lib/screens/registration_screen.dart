import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/device_service.dart';
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

  int _selectedGrade = 12; // Default Grade 12
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
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

    final fullName = _nameController.text.trim();
    final rawPhone = _phoneController.text.trim();

    final formattedPhone = _formatEthiopianPhone(rawPhone);
    if (formattedPhone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('እባክዎ ትክክለኛ የኢትዮጵያ ስልክ ቁጥር ያስገቡ (ምሳሌ፡ 09... ወይም 07...)'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentDeviceId = await DeviceService.getDeviceId();
      final supabase = Supabase.instance.client;
      final String nowIso = DateTime.now().toUtc().toIso8601String();

      // Silently insert into Supabase student_profiles
      try {
        await supabase.from('student_profiles').upsert({
          'full_name': fullName,
          'phone_number': formattedPhone,
          'grade': _selectedGrade,
          'device_id': currentDeviceId,
          'updated_at': nowIso,
        }, onConflict: 'phone_number').timeout(const Duration(seconds: 8));
      } catch (err) {
        debugPrint('[Registration] student_profiles upsert note: $err');
        try {
          await supabase.from('student_profiles').insert({
            'full_name': fullName,
            'phone_number': formattedPhone,
            'grade': _selectedGrade,
            'device_id': currentDeviceId,
          });
        } catch (_) {}
      }

      // Also attempt sync in student_registrations and profiles
      try {
        await supabase.from('student_registrations').upsert({
          'full_name': fullName,
          'phone_number': formattedPhone,
          'grade': _selectedGrade,
          'device_id': currentDeviceId,
        }, onConflict: 'phone_number');
      } catch (_) {}

      try {
        await supabase.from('profiles').upsert({
          'full_name': fullName,
          'phone_number': formattedPhone,
          'grade': _selectedGrade,
          'device_id': currentDeviceId,
        }, onConflict: 'phone_number');
      } catch (_) {}

      // Save locally in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_registered', true);
      await prefs.setBool('is_authenticated', true);
      await prefs.setString('user_fullName', fullName);
      await prefs.setString('user_phoneNumber', formattedPhone);
      await prefs.setString('user_grade', 'Grade $_selectedGrade');
      await prefs.setInt('selected_grade', _selectedGrade);
      await prefs.setString('user_device_id', currentDeviceId);
      await prefs.setString('smartx_verified_device_binding', currentDeviceId);

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        _navigateToHome();
      }
    } catch (e) {
      debugPrint('[Registration] Error or offline mode: $e');

      // Offline fallback: Save locally so user can enter the app
      final currentDeviceId = await DeviceService.getDeviceId();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_registered', true);
      await prefs.setBool('is_authenticated', true);
      await prefs.setString('user_fullName', fullName);
      await prefs.setString('user_phoneNumber', formattedPhone);
      await prefs.setString('user_grade', 'Grade $_selectedGrade');
      await prefs.setInt('selected_grade', _selectedGrade);
      await prefs.setString('user_device_id', currentDeviceId);

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        _navigateToHome();
      }
    }
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        settings: const RouteSettings(name: '/home'),
        pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(
          isDarkMode: widget.isDarkMode,
          languageCode: widget.languageCode,
          onToggleTheme: widget.onToggleTheme,
          onToggleLanguage: widget.onToggleLanguage,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation.drive(CurveTween(curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = !widget.isDarkMode;

    final Color cardColor = isLight ? Colors.white : const Color(0xFF1E293B);
    final Color textColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final Color subtitleColor = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final Color inputFillColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color borderColor = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0B132B),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isLight ? 0.08 : 0.5),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(26.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Branding
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF0284C7), width: 1.5),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/smart_x_logo.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.school_rounded,
                                    color: Color(0xFF0284C7),
                                    size: 26,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Smart Learn Ethiopian',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: textColor,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'የተማሪዎች ምዝገባ መግቢያ',
                                    style: GoogleFonts.notoSansEthiopic(
                                      fontSize: 12,
                                      color: const Color(0xFF0284C7),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),
                        Divider(height: 1, color: borderColor),
                        const SizedBox(height: 22),

                        Text(
                          'እንኳን ደህና መጡ! ለመጀመር እባክዎ መረጃዎን ይሙሉ:',
                          style: GoogleFonts.notoSansEthiopic(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 1. Full Name (ሙሉ ስም)
                        Text(
                          'የተማሪው ሙሉ ስም (Full Name)',
                          style: GoogleFonts.notoSansEthiopic(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: textColor),
                          decoration: InputDecoration(
                            hintText: 'ምሳሌ፡ አበበ ከበደ',
                            hintStyle: TextStyle(fontSize: 13, color: subtitleColor),
                            filled: true,
                            fillColor: inputFillColor,
                            prefixIcon: const Icon(Icons.person_outline_rounded, size: 22, color: Color(0xFF0284C7)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 2)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'እባክዎ ሙሉ ስምዎን ያስገቡ';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        // 2. Phone Number (ስልክ ቁጥር)
                        Text(
                          'የስልክ ቁጥር (Phone Number)',
                          style: GoogleFonts.notoSansEthiopic(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: textColor),
                          decoration: InputDecoration(
                            hintText: '09xxxxxxxx / 07xxxxxxxx',
                            hintStyle: TextStyle(fontSize: 13, color: subtitleColor),
                            filled: true,
                            fillColor: inputFillColor,
                            prefixIcon: const Icon(Icons.phone_outlined, size: 22, color: Color(0xFF0284C7)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 2)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'እባክዎ ስልክ ቁጥር ያስገቡ';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        // 3. Grade Level (9, 10, 11, 12)
                        Text(
                          'የክፍል ደረጃ (Grade Level)',
                          style: GoogleFonts.notoSansEthiopic(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 10),
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
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF0284C7)
                                        : inputFillColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF0284C7) : borderColor,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Grade $g',
                                      style: TextStyle(
                                        fontSize: 13,
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

                        const SizedBox(height: 28),

                        // Submit Button
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                  )
                                : Text(
                                    'ምዝገባውን አጠናቅቅና ጀምር',
                                    style: GoogleFonts.notoSansEthiopic(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                    ),
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
      ),
    );
  }
}
