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
  late AnimationController _iconController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  late AnimationController _subtextController;
  late Animation<Offset> _subtextSlideAnimation;
  late Animation<double> _subtextFadeAnimation;

  // Flow State
  bool _isReturningUser = false;
  Timer? _autoNavigateTimer;

  @override
  void initState() {
    super.initState();

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeIn),
    );

    _subtextController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _subtextSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _subtextController, curve: Curves.easeOutCubic),
    );

    _subtextFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _subtextController, curve: Curves.easeIn),
    );

    _iconController.forward();

    // Start Non-Blocking App Boot Evaluation Pipeline
    _evaluateAppLaunchFlow();
  }

  @override
  void dispose() {
    _autoNavigateTimer?.cancel();
    _iconController.dispose();
    _subtextController.dispose();
    super.dispose();
  }

  /// Evaluates app launch flow in a non-blocking, offline-first manner.
  /// Always resolves navigation after splash delay regardless of network state.
  Future<void> _evaluateAppLaunchFlow() async {
    debugPrint('[Splash] Evaluating non-blocking offline-first app launch flow...');

    _subtextController.forward();

    SharedPreferences? prefs;
    bool hasSeenOnboarding = false;

    // 1. Read local preferences safely
    try {
      prefs = await SharedPreferences.getInstance();
      hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
      if (mounted) {
        setState(() {
          _isReturningUser = hasSeenOnboarding;
        });
      }
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
    try {
      final connectivityResult = await Connectivity().checkConnectivity().timeout(const Duration(seconds: 2));
      final bool isOnline = connectivityResult.isNotEmpty && !connectivityResult.contains(ConnectivityResult.none);

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

    if (!mounted) return;

    // 4. Always resolve flow & navigate to destination after splash duration
    _autoNavigateTimer?.cancel();
    _autoNavigateTimer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      if (hasSeenOnboarding) {
        debugPrint('[Splash] Direct offline-first route -> HomeScreen');
        _navigateToHomeScreen();
      } else {
        debugPrint('[Splash] Direct route -> OnboardingScreen');
        _navigateToOnboarding();
      }
    });
  }

  void _navigateToHomeScreen() {
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
          return FadeTransition(
            opacity: animation.drive(CurveTween(curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _navigateToOnboarding() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
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
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAmharic = widget.languageCode == 'am';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFF0F172A),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Central App Icon with scale & fade animation
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00BFFF).withValues(alpha: 0.35),
                            blurRadius: 36,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.school_rounded,
                                size: 64,
                                color: Color(0xFF00BFFF),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // App Name
                Text(
                  'Smart X ET',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),

                // Subtext Animation
                SlideTransition(
                  position: _subtextSlideAnimation,
                  child: FadeTransition(
                    opacity: _subtextFadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BFFF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFF00BFFF).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        isAmharic
                            ? (_isReturningUser ? 'እንኳን በደህና ተመለሱ!' : 'እንኳን ወደ Smart X ET በደህና መጡ!')
                            : (_isReturningUser ? 'Welcome Back!' : 'Welcome to Smart X ET'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF00BFFF),
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFFF)),
                  ),
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
