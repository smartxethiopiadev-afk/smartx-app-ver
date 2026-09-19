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
  late AnimationController _entranceController;
  
  late Animation<double> _titleFadeAnimation;
  late Animation<Offset> _titleSlideAnimation;
  late Animation<double> _subtitleFadeAnimation;
  late Animation<double> _spinnerFadeAnimation;

  Timer? _autoNavigateTimer;

  @override
  void initState() {
    super.initState();
    logScreen('SplashScreen');

    // Smooth refined entrance animation for clean typography and spinner
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _titleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.20),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.70, curve: Curves.easeOutCubic),
      ),
    );

    _subtitleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _spinnerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.60, 1.0, curve: Curves.easeIn),
      ),
    );

    _entranceController.forward();

    // Start App Initialization Pipeline
    _evaluateAppLaunchFlow();
  }

  @override
  void dispose() {
    _autoNavigateTimer?.cancel();
    _entranceController.dispose();
    super.dispose();
  }

  /// Evaluates app launch flow in a non-blocking, offline-first manner.
  Future<void> _evaluateAppLaunchFlow() async {
    debugPrint('[Splash] Evaluating non-blocking offline-first app launch flow...');

    SharedPreferences? prefs;

    // 1. Read local preferences safely
    try {
      prefs = await SharedPreferences.getInstance();
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

    // 4. Navigate directly to HomeScreen - Open Exploration mode without mandatory registration barrier
    _autoNavigateTimer?.cancel();
    _autoNavigateTimer = Timer(const Duration(milliseconds: 2100), () {
      if (!mounted) return;
      debugPrint('[Splash] Direct entry -> HomeScreen (Immediate Learning Access)');
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
    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFF090D16),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 10),

                // Clean Minimalist Typography Header (NO IMAGE)
                SlideTransition(
                  position: _titleSlideAnimation,
                  child: FadeTransition(
                    opacity: _titleFadeAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top Subtle Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF38BDF8),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                'ETHIOPIAN CURRICULUM',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.0,
                                  color: const Color(0xFF38BDF8),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Main Typography: Smart Learn
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Smart ',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.0,
                                  color: Colors.white,
                                ),
                              ),
                              TextSpan(
                                text: 'Learn',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.0,
                                  color: const Color(0xFF38BDF8),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Secondary Clean Typography: Ethiopia
                        Text(
                          'ETHIOPIA',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 6.0,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // Clean Amharic Subtitle with Fade
                FadeTransition(
                  opacity: _subtitleFadeAnimation,
                  child: Text(
                    'የሁለተኛ ደረጃ ትምህርት እና የፈተና ዝግጅት መድረክ',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansEthiopic(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Smooth Minimalist Cyan Loading Indicator
                FadeTransition(
                  opacity: _spinnerFadeAnimation,
                  child: const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      strokeCap: StrokeCap.round,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
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

