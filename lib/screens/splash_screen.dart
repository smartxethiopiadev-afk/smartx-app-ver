// ignore_for_file: overridden_fields
import 'dart:async';
import 'dart:math' as math;
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
  
  late Animation<double> _emblemScaleAnimation;
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

    // Gentle breathing pulse for the vector emblem
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // Entrance animation for emblem, typography, and spinner
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _emblemScaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _titleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.85, curve: Curves.easeOutCubic),
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

    // 4. Navigate to destination after smooth splash timing
    _autoNavigateTimer?.cancel();
    _autoNavigateTimer = Timer(const Duration(milliseconds: 2100), () {
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
      backgroundColor: const Color(0xFF080E1E), // Dark rich navy blue base
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFF080E1E),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1: Animated Abstract Geometric & Light Effects Canvas
            AnimatedBuilder(
              animation: _ambientController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _GeometricAbstractPainter(
                    animationProgress: _ambientController.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),

            // Layer 2: Subtle Ambient Center Glow Vignette
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.85,
                      colors: [
                        const Color(0xFF0EA5E9).withValues(alpha: 0.08),
                        Colors.transparent,
                        const Color(0xFF080E1E).withValues(alpha: 0.65),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Layer 3: Central Brand Identity & Modern Vector Emblem
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(flex: 12),

                    // Refined Brand Logo Image with luminous glowing frame
                    AnimatedBuilder(
                      animation: Listenable.merge([_entranceController, _pulseController]),
                      builder: (context, child) {
                        final double scale = _emblemScaleAnimation.value;
                        final double pulse = 1.0 + (_pulseController.value * 0.035);
                        final double opacity = _titleFadeAnimation.value;

                        return Opacity(
                          opacity: opacity,
                          child: Transform.scale(
                            scale: scale * pulse,
                            child: const _ModernBrandLogoImage(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 28),

                    // Central App Name: "Smart X Ethiopian"
                    SlideTransition(
                      position: _titleSlideAnimation,
                      child: FadeTransition(
                        opacity: _titleFadeAnimation,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Main Title with sleek modern typography
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  'Smart ',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.4,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: const Color(0xFF00BFFF).withValues(alpha: 0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [Color(0xFF00F0FF), Color(0xFF0099FF)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds),
                                  child: Text(
                                    'X',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: const Color(0xFF00D2FF).withValues(alpha: 0.6),
                                          blurRadius: 20,
                                          offset: const Offset(0, 0),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Text(
                                  ' Ethiopian',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: const Color(0xFF00BFFF).withValues(alpha: 0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Academic / Intelligent Learning Platform Tagline
                            Text(
                              'INTELLIGENT LEARNING PLATFORM',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 3.2,
                                color: const Color(0xFF94A3B8).withValues(alpha: 0.85),
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
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(2),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.2,
                          strokeCap: StrokeCap.round,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D2FF)),
                        ),
                      ),
                    ),

                    const Spacer(flex: 14),

                    // Minimal Footer Note
                    FadeTransition(
                      opacity: _spinnerFadeAnimation,
                      child: Text(
                        'ETHIOPIAN CURRICULUM EXCELLENCE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.4,
                          color: const Color(0xFF64748B).withValues(alpha: 0.65),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),
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

/// A modern, high-definition brand logo image component with luminous glow and clean transparent background.
class _ModernBrandLogoImage extends StatelessWidget {
  const _ModernBrandLogoImage();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft ambient glow directly behind the logo without hard circular boundaries
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D2FF).withValues(alpha: 0.35),
                  blurRadius: 36,
                  spreadRadius: 8,
                ),
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.20),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          Image.asset(
            'assets/images/smart_x_logo.png',
            width: 100,
            height: 100,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                'assets/images/app_icon.png',
                width: 100,
                height: 100,
                fit: BoxFit.contain,
                errorBuilder: (context, error2, stackTrace2) {
                  return const Icon(
                    Icons.auto_stories_rounded,
                    color: Color(0xFF00D2FF),
                    size: 56,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Custom painter that renders clean, sophisticated geometric patterns,
/// rotating orbital arcs, glowing constellation nodes, and soft light blooms.
class _GeometricAbstractPainter extends CustomPainter {
  final double animationProgress;

  _GeometricAbstractPainter({required this.animationProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Offset center = Offset(w / 2, h / 2);

    // 1. Rich Dark Navy Background Gradient
    final Rect backgroundRect = Rect.fromLTWH(0, 0, w, h);
    final Paint bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF050B18), // Deep obsidian navy
          Color(0xFF0A1428), // Rich sapphire navy
          Color(0xFF070E1F), // Dark navy footer
        ],
        stops: [0.0, 0.55, 1.0],
      ).createShader(backgroundRect);
    canvas.drawRect(backgroundRect, bgPaint);

    // 2. Soft Ambient Radial Light Blooms (Glow Effects)
    final double angle = animationProgress * 2 * math.pi;

    // Primary central teal glow
    final Paint centerGlowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.55,
        colors: [
          const Color(0xFF00D2FF).withValues(alpha: 0.09),
          const Color(0xFF0284C7).withValues(alpha: 0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: math.min(w, h) * 0.7));
    canvas.drawCircle(center, math.min(w, h) * 0.7, centerGlowPaint);

    // Floating subtle orb in the upper-right quadrant
    final Offset upperRightOrb = Offset(
      center.dx + math.cos(angle) * 70 + w * 0.22,
      center.dy + math.sin(angle) * 50 - h * 0.18,
    );
    final Paint orbPaint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF0D9488).withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: upperRightOrb, radius: 140));
    canvas.drawCircle(upperRightOrb, 140, orbPaint1);

    // Floating subtle orb in the lower-left quadrant
    final Offset lowerLeftOrb = Offset(
      center.dx - math.cos(angle) * 60 - w * 0.2,
      center.dy - math.sin(angle) * 45 + h * 0.18,
    );
    final Paint orbPaint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF0284C7).withValues(alpha: 0.07),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: lowerLeftOrb, radius: 160));
    canvas.drawCircle(lowerLeftOrb, 160, orbPaint2);

    // 3. Smooth Concentric Geometric Rings & Dashed Orbital Arcs
    _drawGeometricRing(
      canvas: canvas,
      center: center,
      radius: 105,
      rotation: angle * 0.8,
      dashCount: 4,
      dashRatio: 0.65,
      color: const Color(0xFF00D2FF).withValues(alpha: 0.22),
      strokeWidth: 1.2,
    );

    _drawGeometricRing(
      canvas: canvas,
      center: center,
      radius: 155,
      rotation: -angle * 0.5,
      dashCount: 6,
      dashRatio: 0.45,
      color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
      strokeWidth: 1.0,
    );

    _drawGeometricRing(
      canvas: canvas,
      center: center,
      radius: 235,
      rotation: angle * 0.3,
      dashCount: 8,
      dashRatio: 0.35,
      color: const Color(0xFF0284C7).withValues(alpha: 0.10),
      strokeWidth: 1.0,
    );

    _drawGeometricRing(
      canvas: canvas,
      center: center,
      radius: 320,
      rotation: -angle * 0.2,
      dashCount: 12,
      dashRatio: 0.25,
      color: const Color(0xFF64748B).withValues(alpha: 0.08),
      strokeWidth: 0.8,
    );

    // 4. Subtle Hexagonal / Orbital Nodes along rings
    _drawOrbitalNodes(canvas, center, 155, -angle * 0.5, 3, const Color(0xFF00D2FF));
    _drawOrbitalNodes(canvas, center, 235, angle * 0.3, 4, const Color(0xFF38BDF8));

    // 5. Fine Diagonal Architectural Light Rays (Geometric grid lines)
    final Paint gridLinePaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.25)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    // Cross subtle guide lines at 45 degrees
    final double rayLen = math.max(w, h) * 0.85;
    for (int i = -2; i <= 2; i++) {
      final double offsetVal = i * 90.0;
      final Offset p1 = Offset(center.dx - rayLen + offsetVal, center.dy - rayLen);
      final Offset p2 = Offset(center.dx + rayLen + offsetVal, center.dy + rayLen);
      canvas.drawLine(p1, p2, gridLinePaint);
    }
  }

  void _drawGeometricRing({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required double rotation,
    required int dashCount,
    required double dashRatio,
    required Color color,
    required double strokeWidth,
  }) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double totalArcPerSegment = (2 * math.pi) / dashCount;
    final double sweepAngle = totalArcPerSegment * dashRatio;

    for (int i = 0; i < dashCount; i++) {
      final double startAngle = rotation + (i * totalArcPerSegment);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  void _drawOrbitalNodes(
    Canvas canvas,
    Offset center,
    double radius,
    double rotation,
    int count,
    Color nodeColor,
  ) {
    final Paint nodePaint = Paint()
      ..color = nodeColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    final Paint glowPaint = Paint()
      ..color = nodeColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final double step = (2 * math.pi) / count;
    for (int i = 0; i < count; i++) {
      final double a = rotation + (i * step);
      final Offset pos = Offset(
        center.dx + radius * math.cos(a),
        center.dy + radius * math.sin(a),
      );

      // Glowing outer ring for node
      canvas.drawCircle(pos, 4.5, glowPaint);
      // Sharp core node
      canvas.drawCircle(pos, 2.0, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GeometricAbstractPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress;
  }
}
