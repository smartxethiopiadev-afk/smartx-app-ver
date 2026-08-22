import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'home_screen.dart';
import 'registration_screen.dart';
import '../services/analytics_service.dart';

class OnboardingScreen extends StatefulWidget {
  final bool isDarkMode;
  final String languageCode;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLanguage;

  const OnboardingScreen({
    super.key,
    required this.isDarkMode,
    required this.languageCode,
    required this.onToggleTheme,
    required this.onToggleLanguage,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoPlayTimer;

  final List<Map<String, dynamic>> _slides = [
    {
      'image': 'assets/images/student_laptop.png',
      'color': const Color(0xFF00BFFF), // Deep Sky Blue
      'titleEn': 'Interactive Quizzes',
      'titleAm': 'አሳታፊ ጥያቄዎች',
      'descEn': 'Sharpen your skills with real-time feedback, detailed explanations, and performance analytics after every quiz.',
      'descAm': 'ከእያንዳንዱ ጥያቄ በኋላ በቅጽበት በሚሰጥ ግብረ-መልስ፣ ዝርዝር ማብራሪያዎች እና የክንውን ትንተናዎች ብቃትዎን ያሳድጉ።',
    },
    {
      'image': 'assets/images/student_tablet.png',
      'color': const Color(0xFF10B981), // Emerald Green
      'titleEn': 'Smart Short Notes',
      'titleAm': 'ስማርት አጫጭር ማስታወሻዎች',
      'descEn': 'Access comprehensive, summarized study materials organized chapter-by-chapter for rapid review and exam preparation.',
      'descAm': 'ፈጣን ክለሳ ለማድረግ እና ለፈተና ለመዘጋጀት እንዲረዳዎት በየምዕራፉ የተደራጁ አጠቃላይና አጫጭር የጥናት ጽሑፎችን ያግኙ።',
    },
    {
      'image': 'assets/images/student_phone.png',
      'color': const Color(0xFFF59E0B), // Warm Amber
      'titleEn': 'Realistic Exams & Offline Study',
      'titleAm': 'ትክክለኛ ፈተናዎችና የባለሙሉ ማህደር ጥናት',
      'descEn': 'Simulate national exams with timed tests and access all study resources fully offline anywhere, anytime.',
      'descAm': 'ፍጥነትን እና በራስ መተማመንን ለመገንባት በጊዜ ገደብ ከተቀመጡ ፈተናዎች ጋር ይለማመዱ፤ እንዲሁም ያሉበት ቦታ ሆነው ያለ ኢንተርኔት ያጥኑ።',
    },
  ];

  @override
  void initState() {
    super.initState();
    logScreen('OnboardingScreen');
    _startAutoPlay();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentPage < _slides.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
        );
      } else {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
  }

  Future<void> _completeOnboarding() async {
    _stopAutoPlay();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    if (!mounted) return;

    bool isOffline = false;
    try {
      final connectivity = await Connectivity().checkConnectivity().timeout(const Duration(seconds: 2));
      if (connectivity.contains(ConnectivityResult.none) || connectivity.isEmpty) {
        isOffline = true;
      }
    } catch (e) {
      debugPrint('[Offline Auth Check] Onboarding completion connectivity check: $e');
    }

    final Widget targetScreen = isOffline
        ? HomeScreen(
            isDarkMode: widget.isDarkMode,
            languageCode: widget.languageCode,
            onToggleTheme: widget.onToggleTheme,
            onToggleLanguage: widget.onToggleLanguage,
          )
        : RegistrationScreen(
            isDarkMode: widget.isDarkMode,
            languageCode: widget.languageCode,
            onToggleTheme: widget.onToggleTheme,
            onToggleLanguage: widget.onToggleLanguage,
          );

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const curve = Curves.fastOutSlowIn;
          var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));
          return FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAm = widget.languageCode == 'am';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFF0F172A),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full-Screen Cover Image PageView Carousel
            PageView.builder(
              controller: _pageController,
              itemCount: _slides.length,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemBuilder: (context, index) {
                final slide = _slides[index];
                final String primaryImg = slide['image']!;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Immersive Full-Screen Cover Background Image
                    Image.asset(
                      primaryImg,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),

                    // Atmospheric gradient overlay ensuring top header & bottom panel contrast
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF0F172A).withValues(alpha: 0.65),
                            const Color(0xFF0F172A).withValues(alpha: 0.30),
                            const Color(0xFF0F172A).withValues(alpha: 0.85),
                            const Color(0xFF0F172A),
                          ],
                          stops: const [0.0, 0.35, 0.70, 1.0],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // Top Header Bar Overlay (App Badge & Controls)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Miniature Glassmorphic Logo Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.60),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Smart X ET',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),

                      // Controls: Language Toggle & Skip Action
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Theme Toggle
                          IconButton(
                            icon: Icon(
                              widget.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: widget.onToggleTheme,
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.60),
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Language Toggle
                          InkWell(
                            onTap: widget.onToggleLanguage,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00BFFF).withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isAm ? 'English' : 'አማርኛ',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Semi-Transparent Dark Glassmorphic Bottom Panel
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  border: Border.all(
                    color: (_slides[_currentPage]['color'] as Color).withValues(alpha: 0.25),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_slides[_currentPage]['color'] as Color).withValues(alpha: 0.15),
                      blurRadius: 36,
                      offset: const Offset(0, -8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 28,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Slide Counter Badge & Theme Accent Line
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: (_slides[_currentPage]['color'] as Color).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: (_slides[_currentPage]['color'] as Color).withValues(alpha: 0.6),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _slides[_currentPage]['color'] as Color,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'FEATURE 0${_currentPage + 1} OF 0${_slides.length}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: _slides[_currentPage]['color'] as Color,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Title Text
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Align(
                            key: ValueKey<int>(_currentPage),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              isAm
                                  ? _slides[_currentPage]['titleAm']!
                                  : _slides[_currentPage]['titleEn']!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.4,
                                height: 1.25,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Description Text
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Align(
                            key: ValueKey<int>(_currentPage + 10),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              isAm
                                  ? _slides[_currentPage]['descAm']!
                                  : _slides[_currentPage]['descEn']!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.0,
                                height: 1.55,
                                color: const Color(0xFFCBD5E1),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Bottom Actions Row: Indicator Dots, Skip & Next Button
                        Row(
                          children: [
                            // Page Indicator Dots
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(_slides.length, (index) {
                                final bool isActive = _currentPage == index;
                                final Color accentColor = _slides[_currentPage]['color'] as Color;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: isActive ? 26.0 : 8.0,
                                  height: 8.0,
                                  margin: const EdgeInsets.only(right: 6.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100),
                                    color: isActive
                                        ? accentColor
                                        : Colors.white.withValues(alpha: 0.2),
                                    boxShadow: isActive
                                        ? [
                                            BoxShadow(
                                              color: accentColor.withValues(alpha: 0.5),
                                              blurRadius: 6,
                                              offset: const Offset(0, 1),
                                            ),
                                          ]
                                        : null,
                                  ),
                                );
                              }),
                            ),

                            const Spacer(),

                            // Skip Button
                            TextButton(
                              onPressed: _completeOnboarding,
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF94A3B8),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              child: Text(
                                isAm ? 'ዝለል' : 'Skip',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Next / Get Started Action Button
                            ElevatedButton(
                              onPressed: () {
                                if (_currentPage < _slides.length - 1) {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 450),
                                    curve: Curves.easeInOutCubic,
                                  );
                                } else {
                                  _completeOnboarding();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _slides[_currentPage]['color'] as Color,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: (_slides[_currentPage]['color'] as Color).withValues(alpha: 0.5),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _currentPage == _slides.length - 1
                                        ? (isAm ? 'ይጀምሩ' : 'Get Started')
                                        : (isAm ? 'ቀጣይ' : 'Next'),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
