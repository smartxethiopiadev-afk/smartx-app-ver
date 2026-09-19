import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/device_service.dart';
import '../services/subscription_service.dart';
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
  String? _validationErrorBanner;

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
    setState(() {
      _validationErrorBanner = null;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _validationErrorBanner = "Please correct the highlighted input errors below before proceeding.";
      });
      return;
    }

    final fullName = _nameController.text.trim();
    final rawPhone = _phoneController.text.trim();

    if (fullName.length < 3) {
      setState(() {
        _validationErrorBanner = "Full Name must be at least 3 characters long.";
      });
      return;
    }

    final formattedPhone = _formatEthiopianPhone(rawPhone);
    if (formattedPhone == null) {
      setState(() {
        _validationErrorBanner = "Invalid Phone Number! Enter a valid Ethiopian phone number (e.g. 0911234567 or 0712345678).";
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentDeviceId = await DeviceService.getDeviceId();
      final supabase = Supabase.instance.client;
      final String nowIso = DateTime.now().toUtc().toIso8601String();

      // Check if student already exists in 'students' table
      List<String> unlockedPackages = [];
      try {
        final existing = await supabase
            .from('students')
            .select('unlocked_packages, device_id')
            .eq('phone_number', formattedPhone)
            .maybeSingle()
            .timeout(const Duration(seconds: 5));

        if (existing != null) {
          final existingDev = (existing['device_id'] as String?)?.trim();
          if (existingDev != null && existingDev.isNotEmpty && existingDev != currentDeviceId) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(widget.languageCode == 'am'
                      ? 'ይህ ስልክ ቁጥር አስቀድሞ በሌላ ስልክ ላይ ተመዝግቧል። መለያ ማጋራት በጥብቅ የተከለከለ ነው።'
                      : 'This phone number is already registered on another device. Account sharing is strictly prohibited.'),
                  backgroundColor: const Color(0xFFEF4444),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            setState(() => _isLoading = false);
            return;
          }
          final raw = existing['unlocked_packages'] as List<dynamic>?;
          if (raw != null) {
            unlockedPackages = raw.map((e) => e.toString()).toList();
          }
        }

        // Upsert into unified 'students' table without giving away free packages
        await supabase.from('students').upsert({
          'full_name': fullName,
          'phone_number': formattedPhone,
          'grade': _selectedGrade,
          'device_id': currentDeviceId,
          'is_active': true,
          'unlocked_packages': unlockedPackages,
          'updated_at': nowIso,
        }, onConflict: 'phone_number').timeout(const Duration(seconds: 8));

        await SubscriptionService.setUnlockedPackages(unlockedPackages);
      } catch (err) {
        debugPrint('[Registration] students upsert notice: $err');
      }

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

    final Color bgColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color cardColor = isLight ? Colors.white : const Color(0xFF1E293B);
    final Color textColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final Color subtitleColor = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final Color inputFillColor = isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final Color borderColor = isLight ? const Color(0xFFCBD5E1) : const Color(0xFF334155);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 520),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isLight ? 0.06 : 0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
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
                          // Header Branding in 100% Full English
                          Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF0284C7), width: 1.8),
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/app_logo.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.school_rounded,
                                      color: Color(0xFF0284C7),
                                      size: 28,
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
                                      'Smart Learn Ethiopia',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: textColor,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Student Registration & Hardware Lock',
                                      style: GoogleFonts.plusJakartaSans(
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
                          const SizedBox(height: 20),

                          // Error Banner Display for User Stage Validation
                          if (_validationErrorBanner != null) ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 22),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _validationErrorBanner!,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFEF4444),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                          ],

                          Text(
                            'Welcome! Please enter your details to initialize your single-device account:',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: subtitleColor,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 1. Full Name Input
                          Text(
                            'Student Full Name',
                            style: GoogleFonts.plusJakartaSans(
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
                              hintText: 'e.g. Abebe Kebede',
                              hintStyle: TextStyle(fontSize: 13, color: subtitleColor),
                              filled: true,
                              fillColor: inputFillColor,
                              prefixIcon: const Icon(Icons.person_outline_rounded, size: 22, color: Color(0xFF0284C7)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 2)),
                              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5)),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Full Name is required';
                              }
                              if (val.trim().length < 3) {
                                return 'Full Name must be at least 3 characters';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 18),

                          // 2. Phone Number Input
                          Text(
                            'Phone Number',
                            style: GoogleFonts.plusJakartaSans(
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
                              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5)),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Phone Number is required';
                              }
                              if (_formatEthiopianPhone(val.trim()) == null) {
                                return 'Enter a valid Ethiopian phone number (e.g. 0911234567)';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 18),

                          // 3. Grade Selection
                          Text(
                            'Grade Level',
                            style: GoogleFonts.plusJakartaSans(
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
                                      color: isSelected ? const Color(0xFF0284C7) : inputFillColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFF0284C7) : borderColor,
                                        width: isSelected ? 2 : 1,
                                      ),
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

                          const SizedBox(height: 22),

                          // Package System Detailed Explanation Box
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.info_outline_rounded, color: Color(0xFF0284C7), size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Smart Learn Package Architecture',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '• Unit 1 for all subjects & grades is 100% FREE forever for trial.\n'
                                  '• Full Grade Packages unlock Unit 2+ across all curriculum subjects.\n'
                                  '• Single Device Hardware Lock: Your account is securely tied to this device upon registration to prevent unauthorized account sharing.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    height: 1.45,
                                    fontWeight: FontWeight.w500,
                                    color: subtitleColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 26),

                          // Submit Action Button
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
                                      'Complete Registration & Get Started',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14.5,
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
      ),
    );
  }
}
