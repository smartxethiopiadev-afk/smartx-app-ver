// ignore_for_file: overridden_fields
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../services/offline_manager.dart';
import 'home_screen.dart';
import '../services/analytics_service.dart';
import '../main.dart';

/// 100% Redesigned Splash Screen featuring pure Message Animations without any static logo.
/// Seamlessly animates through sequential Ethiopian curriculum educational messages
/// and a fluid progress indicator before transitioning to the Home Screen.
class SplashScreen extends StatefulWidget {
  final bool isDarkMode;
  final String languageCode;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLanguage;

  const SplashScreen({
    super.key,
    required this.isDarkMode,
    required this.languageCode,
    required this.onToggleTheme,
    required this.onToggleLanguage,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class SplashScreenWrapper extends SplashScreen {
  final SplashScreen actualWidget;

  @override
  final bool isDarkMode;
  @override
  final String languageCode;

  SplashScreenWrapper({
    required this.actualWidget,
    required this.isDarkMode,
    required this.languageCode,
  }) : super(
          isDarkMode: isDarkMode,
          languageCode: languageCode,
          onToggleTheme: actualWidget.onToggleTheme,
          onToggleLanguage: actualWidget.onToggleLanguage,
          key: actualWidget.key,
        );
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  @override
  SplashScreen get widget {
    try {
      final appState = AppStateProvider.of(context);
      return SplashScreenWrapper(
        actualWidget: super.widget,
        isDarkMode: appState.isDarkMode,
        languageCode: appState.languageCode,
      );
    } catch (_) {
      return super.widget;
    }
  }

  // Sequential message items for dynamic animation
  final List<Map<String, dynamic>> _educationalMessages = [
    {
      'badge': 'SMART LEARN ETHIOPIAN',
      'badgeAm': 'ስማርት ለርን ኢትዮጵያን',
      'title': 'Smart Learn Ethiopian',
      'titleAm': 'ስማርት ለርን ኢትዮጵያን',
      'subtitle': 'Comprehensive Ethiopian High School Curriculum Platform',
      'subtitleAm': 'የኢትዮጵያ ሁለተኛ ደረጃ ትምህርት እና የፈተና ዝግጅት መድረክ',
      'accent': const Color(0xFF38BDF8),
    },
    {
      'badge': 'CURRICULUM SHORT NOTES',
      'badgeAm': 'የካሪኩለም ማጠቃለያዎች',
      'title': 'Concise Unit Notes & Formulas',
      'titleAm': 'የአዲሱ ካሪኩለም ማጠቃለያ ማስታወሻዎች',
      'subtitle': 'Master key physics laws, math proofs, and chemistry reactions',
      'subtitleAm': 'ዋና ዋና ቀመሮች፣ ህጎች እና ማጠቃለያዎች በአጭሩ',
      'accent': const Color(0xFF0284C7),
    },
    {
      'badge': 'NATIONAL EXAM MASTERY',
      'badgeAm': 'የብሔራዊ ፈተና ዝግጅት',
      'title': 'National Exam Bank & Model Tests',
      'titleAm': 'የ9-12ኛ ክፍል የፈተና ጥያቄዎች እና ማብራሪያዎች',
      'subtitle': 'Timed practice quizzes with verified step-by-step solutions',
      'subtitleAm': 'የተረጋገጡ የፈተና ጥያቄዎች ከዝርዝር ማብራሪያ ጋር',
      'accent': const Color(0xFF10B981),
    },
    {
      'badge': '100% OFFLINE ACCESS',
      'badgeAm': 'ከመስመር ውጭ (100% OFFLINE)',
      'title': 'Study Anywhere Without Internet',
      'titleAm': 'ያለ ኢንተርኔት በየትኛውም ቦታና ሰዓት ማጥናት',
      'subtitle': 'Download units once and study completely offline',
      'subtitleAm': 'አንዴ ዳውንሎድ በማድረግ ያለ ዳታ ወይም ዋይፋይ ይጠቀሙ',
      'accent': const Color(0xFF8B5CF6),
    },
    {
      'badge': 'EXCELLENCE & SUCCESS',
      'badgeAm': 'የትምህርት ውጤታማነት',
      'title': 'Empowering Ethiopian Students',
      'titleAm': 'የትምህርት ጉዞዎን በብልሃት ይጀምሩ...',
      'subtitle': 'Learn • Practice • Succeed',
      'subtitleAm': 'ተማር • ተለማመድ • ከፍተኛ ውጤት አስመዘግብ!',
      'accent': const Color(0xFFF59E0B),
    },
  ];

  int _currentMessageIndex = 0;
  Timer? _messageTimer;
  Timer? _navigationTimer;

  // Controllers for animation
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    logScreen('SplashScreen');

    // Ambient background pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    // Progress bar controller from 0 to 100%
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2700),
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );

    _progressController.forward();

    // Start cycling through the message animation sequence every 550ms
    _messageTimer = Timer.periodic(const Duration(milliseconds: 540), (timer) {
      if (mounted) {
        setState(() {
          if (_currentMessageIndex < _educationalMessages.length - 1) {
            _currentMessageIndex++;
          }
        });
      }
    });

    // Start background app initialization
    _evaluateAppLaunchFlow();
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _navigationTimer?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  /// Evaluates app launch flow in a non-blocking, offline-first manner.
  Future<void> _evaluateAppLaunchFlow() async {
    SharedPreferences? prefs;

    try {
      prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('[Splash] SharedPreferences read notice: $e');
    }

    try {
      await OfflineManager.init();
    } catch (e) {
      debugPrint('[Splash] OfflineManager init notice: $e');
    }

    // Non-blocking network check
    try {
      final connectivityResult = await Connectivity().checkConnectivity().timeout(const Duration(seconds: 2));
      final bool isOnline = connectivityResult.isNotEmpty && !connectivityResult.contains(ConnectivityResult.none);

      if (isOnline) {
        if (!Supabase.instance.isInitialized) {
          await Supabase.initialize(
            url: AppConfig.supabaseUrl,
            publishableKey: AppConfig.supabaseAnonKey,
          ).timeout(const Duration(seconds: 3));
        }

        if (prefs != null) {
          await prefs.setBool('is_first_time_setup_completed', true);
          await prefs.setBool('has_completed_initial_sync', true);
        }
      }
    } catch (e) {
      debugPrint('[Splash] Non-blocking setup check notice: $e');
    }

    // Smooth navigation after message sequence plays
    _navigationTimer?.cancel();
    _navigationTimer = Timer(const Duration(milliseconds: 2800), () {
      if (!mounted) return;
      _navigateToHomeScreen();
    });
  }

  void _navigateToHomeScreen() {
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
    final bool isAmharic = widget.languageCode == 'am';
    final currentMsg = _educationalMessages[_currentMessageIndex];

    final String badgeText = isAmharic ? currentMsg['badgeAm'] : currentMsg['badge'];
    final String titleText = isAmharic ? currentMsg['titleAm'] : currentMsg['title'];
    final String subtitleText = isAmharic ? currentMsg['subtitleAm'] : currentMsg['subtitle'];
    final Color accentColor = currentMsg['accent'] as Color;

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFF070B14),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Stack(
          children: [
            // Ambient Animated Background Glow Orbs
            Positioned(
              top: -80,
              left: -80,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 260 + (_pulseController.value * 40),
                    height: 260 + (_pulseController.value * 40),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accentColor.withValues(alpha: 0.22),
                          accentColor.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: -60,
              right: -60,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 280 + ((1.0 - _pulseController.value) * 50),
                    height: 280 + ((1.0 - _pulseController.value) * 50),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF0284C7).withValues(alpha: 0.18),
                          const Color(0xFF0284C7).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Main Message Animation Content with Prominent +25% Enlarged App Icon
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),

                    // Prominent Circular Smart Learn Ethiopian Mobile Application Icon (+25% Enlarged)
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 175,
                          height: 175,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.8),
                              width: 3.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.45 + (_pulseController.value * 0.2)),
                                blurRadius: 36 + (_pulseController.value * 12),
                                spreadRadius: 4 + (_pulseController.value * 4),
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Graduation Cap & Learning Symbol
                                  Container(
                                    width: 62,
                                    height: 62,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.school_rounded,
                                      size: 38,
                                      color: Color(0xFF0284C7),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Smart Learn Title
                                  Text(
                                    'Smart Learn',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF0F2B5C),
                                      letterSpacing: -0.5,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  // Ethiopian Flag Tri-color Accent + Ethiopia Label
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(width: 8, height: 2.5, color: const Color(0xFF078930)), // Green
                                      const SizedBox(width: 2),
                                      Container(width: 8, height: 2.5, color: const Color(0xFFFCDD09)), // Yellow
                                      const SizedBox(width: 2),
                                      Container(width: 8, height: 2.5, color: const Color(0xFFDA121A)), // Red
                                      const SizedBox(width: 5),
                                      Text(
                                        'Ethiopia',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF0284C7),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Container(width: 8, height: 2.5, color: const Color(0xFF078930)),
                                      const SizedBox(width: 2),
                                      Container(width: 8, height: 2.5, color: const Color(0xFFFCDD09)),
                                      const SizedBox(width: 2),
                                      Container(width: 8, height: 2.5, color: const Color(0xFFDA121A)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const Spacer(flex: 2),

                    // Animated App Name Tag
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor,
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            badgeText,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Dynamic Animated Message Transition Switcher
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.0, 0.25),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        key: ValueKey<int>(_currentMessageIndex),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Main Animated Message Title
                            Text(
                              titleText,
                              textAlign: TextAlign.center,
                              style: isAmharic
                                  ? GoogleFonts.notoSansEthiopic(
                                      fontSize: 23,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      height: 1.35,
                                    )
                                  : GoogleFonts.plusJakartaSans(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                      height: 1.25,
                                    ),
                            ),
                            const SizedBox(height: 14),
                            // Subtitle description
                            Text(
                              subtitleText,
                              textAlign: TextAlign.center,
                              style: isAmharic
                                  ? GoogleFonts.notoSansEthiopic(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF94A3B8),
                                      height: 1.45,
                                    )
                                  : GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF94A3B8),
                                      height: 1.4,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Step Dots Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_educationalMessages.length, (index) {
                        final bool isCurrent = index == _currentMessageIndex;
                        final bool isDone = index < _currentMessageIndex;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 3.5),
                          width: isCurrent ? 24.0 : 6.0,
                          height: 6.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4.0),
                            color: isCurrent
                                ? accentColor
                                : (isDone
                                    ? Colors.white.withValues(alpha: 0.4)
                                    : Colors.white.withValues(alpha: 0.12)),
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: accentColor.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                        );
                      }),
                    ),

                    const Spacer(flex: 8),

                    // Smooth Bottom Loading Progress Bar & Percentage
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        final double val = _progressAnimation.value.clamp(0.0, 1.0);
                        final int percent = (val * 100).toInt();

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  height: 4,
                                  width: double.infinity,
                                  color: Colors.white.withValues(alpha: 0.08),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: val,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFF0284C7),
                                            accentColor,
                                            const Color(0xFF38BDF8),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isAmharic ? 'መተግበሪያውን በማዘጋጀት ላይ...' : 'Preparing learning modules...',
                                  style: GoogleFonts.notoSansEthiopic(
                                    fontSize: 11.5,
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '$percent%',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: accentColor,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
