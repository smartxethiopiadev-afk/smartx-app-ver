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
import 'onboarding_screen.dart';
import 'registration_screen.dart';
import 'login_activation_screen.dart';
import '../services/credential_auth_service.dart';
import '../services/analytics_service.dart';
import '../main.dart';

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

  // Animation Controllers
  late AnimationController _ambientController;
  late AnimationController _pulseController;
  late AnimationController _entranceController;
  
  late Animation<double> _titleFadeAnimation;
  late Animation<Offset> _titleSlideAnimation;
  late Animation<double> _spinnerFadeAnimation;

  Timer? _autoNavigateTimer;

  @override
  void initState() {
    super.initState();
    logScreen('SplashScreen');

    // Continuous smooth ambient rotation for geometric abstract background
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Gentle breathing pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // Entrance animation for typography and spinner
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.1, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _titleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.1, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _spinnerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    _entranceController.forward();

    // Start App Initialization Pipeline
    _evaluateAppLaunchFlow();
  }

  @override
  void dispose() {
    _autoNavigateTimer?.cancel();
    _ambientController.dispose();
    _pulseController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  /// Evaluates app launch flow in a non-blocking, offline-first manner.
  Future<void> _evaluateAppLaunchFlow() async {
    debugPrint('[Splash] Evaluating non-blocking offline-first app launch flow...');

    SharedPreferences? prefs;
    bool hasSeenOnboarding = false;

    // 1. Read local preferences safely
    try {
      prefs = await SharedPreferences.getInstance();
      hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    } catch (e) {
      debugPrint('[Splash] SharedPreferences read warning: $e');
    }

    // 2. Initialize OfflineManager safely
    try {
      await OfflineManager.init();
    } catch (e) {
      debugPrint('[Splash] OfflineManager init warning: $e');
    }

    // 3. Non-blocking Background Network Check & Sync
    bool isOnline = false;
    try {
      final connectivityResult = await Connectivity().checkConnectivity().timeout(const Duration(seconds: 2));
      isOnline = connectivityResult.isNotEmpty && !connectivityResult.contains(ConnectivityResult.none);

      if (isOnline) {
        debugPrint('[Splash] Online connectivity detected. Executing background syncs...');

        // Supabase Client initialization
        try {
          if (!Supabase.instance.isInitialized) {
            await Supabase.initialize(
              url: AppConfig.supabaseUrl,
              publishableKey: AppConfig.supabaseAnonKey,
            ).timeout(const Duration(seconds: 4));
          }
        } catch (sbErr) {
          debugPrint('[Splash] Supabase client init notice: $sbErr');
        }

        if (prefs != null) {
          await prefs.setBool('is_first_time_setup_completed', true);
          await prefs.setBool('has_completed_initial_sync', true);
        }
      } else {
        debugPrint('[Splash] Offline mode active. Skipping cloud network sync.');
      }
    } catch (netErr) {
      debugPrint('[Splash] Non-blocking network check/sync warning: $netErr');
    }

    final bool isAuth = await CredentialAuthService.isAuthenticated();
    final bool hasRegistered = prefs?.getBool('has_registered') ?? false;

    if (!mounted) return;

    // 4. Navigate to destination after smooth splash timing
    _autoNavigateTimer?.cancel();
    _autoNavigateTimer = Timer(const Duration(milliseconds: 2100), () {
      if (!mounted) return;
      if (isAuth) {
        debugPrint('[Splash] Authenticated session -> HomeScreen');
        _navigateToHomeScreen();
      } else if (!hasSeenOnboarding) {
        debugPrint('[Splash] First time user -> OnboardingScreen');
        _navigateToOnboarding();
      } else if (!isOnline) {
        debugPrint('[Splash] Offline launch -> LoginActivationScreen (Welcome Back)');
        _navigateToLogin(isOffline: true);
      } else if (!hasRegistered) {
        debugPrint('[Splash] Unregistered user -> RegistrationScreen');
        _navigateToRegistration();
      } else {
        debugPrint('[Splash] Registered user -> LoginActivationScreen');
        _navigateToLogin(isOffline: false);
      }
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

  void _navigateToRegistration() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        settings: const RouteSettings(name: '/registration'),
        pageBuilder: (context, animation, secondaryAnimation) => RegistrationScreen(
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

  void _navigateToLogin({bool isOffline = false}) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        settings: const RouteSettings(name: '/login'),
        pageBuilder: (context, animation, secondaryAnimation) => LoginActivationScreen(
          isDarkMode: widget.isDarkMode,
          languageCode: widget.languageCode,
          isOfflineWelcomeBack: isOffline,
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

  void _navigateToOnboarding() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        settings: const RouteSettings(name: '/onboarding'),
        pageBuilder: (context, animation, secondaryAnimation) => OnboardingScreen(
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 10),

                // Central App Logo & Title: "Ethio Concept Center"
                SlideTransition(
                  position: _titleSlideAnimation,
                  child: FadeTransition(
                    opacity: _titleFadeAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // App Icon Badge
                        Container(
                          width: 110,
                          height: 110,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/smart_x_logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.school_rounded,
                                    color: Colors.white,
                                    size: 54,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Main Title typography: Ethio Concept Center
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              'Ethio Concept ',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Center',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Platform Subtitle Message (Amharic & English)
                        Text(
                          'የኢትዮጵያ ሁለተኛ ደረጃ የትምህርት መድረክ',
                          style: GoogleFonts.notoSansEthiopic(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: const Color(0xFF0284C7),
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'GRADES 9 - 12 LEARNING PLATFORM',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.5,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 38),

                // Understated Minimal Teal Blue Loading Spinner
                FadeTransition(
                  opacity: _spinnerFadeAnimation,
                  child: Container(
                    width: 26,
                    height: 26,
                    padding: const EdgeInsets.all(2),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      strokeCap: StrokeCap.round,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                    ),
                  ),
                ),

                const Spacer(flex: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

