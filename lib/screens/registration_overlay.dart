import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'dart:ui';

class RegistrationOverlay extends StatefulWidget {
  final bool isDarkMode;
  final String languageCode;
  final Color primaryColor;

  const RegistrationOverlay({
    super.key,
    required this.isDarkMode,
    required this.languageCode,
    required this.primaryColor,
  });

  @override
  State<RegistrationOverlay> createState() => _RegistrationOverlayState();
}

class _RegistrationOverlayState extends State<RegistrationOverlay> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  int _selectedGrade = 12; // Default grade level
  bool _isLoading = false;

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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final isEn = widget.languageCode == 'en';
    final fullName = _nameController.text.trim();
    final rawPhone = _phoneController.text.trim();

    // Strict Ethiopian Phone validation
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

      // Write to profiles table with fallback to student_profiles
      bool insertSuccess = false;
      dynamic lastDbError;

      try {
        await supabase.from('profiles').insert({
          'id': profileId,
          'full_name': fullName,
          'phone_number': formattedPhone,
          'grade': _selectedGrade,
          'created_at': nowIso,
        }).timeout(const Duration(seconds: 10));
        insertSuccess = true;
        debugPrint("Successfully registered in 'profiles' table.");
      } catch (e) {
        lastDbError = e;
        debugPrint("Failed 'profiles' table write, attempting fallback to 'student_profiles': $e");
        try {
          await supabase.from('student_profiles').insert({
            'id': profileId,
            'full_name': fullName,
            'phone_number': formattedPhone,
            'grade': _selectedGrade,
          }).timeout(const Duration(seconds: 10));
          insertSuccess = true;
          debugPrint("Successfully registered in fallback 'student_profiles' table.");
        } catch (e2) {
          lastDbError = e2;
          debugPrint("Database write failed for both tables: $e2");
        }
      }

      if (!insertSuccess) {
        throw lastDbError ?? Exception("Failed to connect to database");
      }

      // Registration is strictly verified & saved only upon successful database insert
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
            content: Text(
              isEn ? 'Successfully registered in database!' : 'በስኬት በመረጃ ቋቱ ውስጥ ተመዝግበዋል!',
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop('registered');
      }
    } catch (e) {
      debugPrint("Registration failed: $e");
      String errMsg = _getFriendlyDatabaseErrorMessage(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg),
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
          englishMsg = 'This phone number is already registered. Please use another number.';
          amharicMsg = 'ይህ ስልክ ቁጥር ቀድሞ ተመዝግቧል። እባክዎ ሌላ ስልክ ቁጥር ይጠቀሙ።';
        } else {
          englishMsg = 'A record with these details already exists in our database.';
          amharicMsg = 'እነዚህን ዝርዝሮች የያዘ ተማሪ ቀድሞ ተመዝግቧል።';
        }
      }
    }
    return isEn ? englishMsg : amharicMsg;
  }

  void _handleCancel() {
    Navigator.of(context).pop('cancelled');
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = !widget.isDarkMode;
    final bool isEn = widget.languageCode == 'en';

    final cardColor = isLight ? Colors.white.withValues(alpha: 0.95) : const Color(0xFF1E293B).withValues(alpha: 0.95);
    final textColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final subtitleColor = isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8);
    final inputFillColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.5),
      body: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isLight ? Colors.white : Colors.white.withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isLight ? 0.08 : 0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(28.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 12),
                              // Floating Card Header Icon
                              Center(
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [widget.primaryColor, widget.primaryColor.withValues(alpha: 0.7)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: widget.primaryColor.withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.school_rounded,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Text Header
                              Text(
                                isEn ? 'Create Your Account' : 'መለያ ይፍጠሩ',
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
                                isEn ? 'Register to unlock all units & features' : 'ሁሉንም ምዕራፎችና ፈተናዎች ለመክፈት ይመዝገቡ',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: subtitleColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Name Input
                              _buildTextField(
                                label: isEn ? "Full Name" : "ሙሉ ስም",
                                hintText: isEn ? "e.g., John Doe" : "ምሳሌ: አበበ በቀለ",
                                prefixIcon: Icons.person_rounded,
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

                              // Grade inputs
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEn ? 'Grade' : 'የክፍል ደረጃ',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
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
                                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? widget.primaryColor
                                                  : inputFillColor,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isSelected
                                                    ? widget.primaryColor
                                                    : (isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '$g',
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
                                  const SizedBox(height: 20),
                                ],
                              ),

                              // Phone Input with Ethiopian Flag and +251
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

                              // Register/Submit Button (Gradient)
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    colors: [widget.primaryColor, widget.primaryColor.withValues(alpha: 0.8)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.primaryColor.withValues(alpha: 0.25),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleSubmit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    minimumSize: const Size.fromHeight(50),
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
                              const SizedBox(height: 12),

                              // Cancel/Close Button
                              OutlinedButton(
                                onPressed: _isLoading ? null : _handleCancel,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textColor,
                                  minimumSize: const Size.fromHeight(50),
                                  side: BorderSide(
                                    color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  isEn ? 'Cancel' : 'ሰርዝ',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Top Right Close "X" Button
                      Positioned(
                        top: 12,
                        right: 12,
                        child: IconButton(
                          icon: Icon(Icons.close_rounded, color: subtitleColor, size: 22),
                          onPressed: _isLoading ? null : _handleCancel,
                          tooltip: isEn ? 'Close' : 'ዝጋ',
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
        const SizedBox(height: 6),
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
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(prefixIcon, color: widget.primaryColor, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: inputFillColor,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: widget.primaryColor.withValues(alpha: 0.25),
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: widget.primaryColor,
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
        const SizedBox(height: 20),
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
        const SizedBox(height: 6),
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
              fontSize: 13.5,
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: inputFillColor,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: widget.primaryColor.withValues(alpha: 0.25),
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: widget.primaryColor,
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
