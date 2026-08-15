import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/app_config.dart';
import 'screens/splash_screen.dart';
import 'services/offline_manager.dart';
import 'services/analytics_service.dart';

void main() async {
  // 1. Ensure widget bindings are safely initialized before any async/native plugin calls
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Global Error Handling to eliminate Grey Screen and capture uncaught errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] Caught framework error: ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('[PlatformDispatcher] Caught root error: $error\n$stack');
    return true; // Prevents app process termination
  };

  // 3. Fallback Error Widget: replace the default plain Grey Screen with a polished, readable error card
  ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
    return Material(
      color: const Color(0xFF0F172A),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(color: const Color(0xFF334155), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFEF4444),
                      size: 40.0,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  const Text(
                    'Application Notice',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    kReleaseMode
                        ? 'A temporary display issue occurred. Please restart or go back.'
                        : errorDetails.exceptionAsString(),
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  };

  // 4. Safe Firebase Core initialization with offline/network fault tolerance
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 3));
    debugPrint('[Firebase] Initialized successfully.');
  } catch (e) {
    debugPrint('[Firebase] Safe initialization notice (offline/skipped): $e');
  }

  // 5. Safe local SharedPreferences loading
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 2));
  } catch (e) {
    debugPrint('[Preferences] SharedPreferences init notice: $e');
  }

  // 6. Safe Google Fonts configuration
  try {
    GoogleFonts.config.allowRuntimeFetching = false;
  } catch (e) {
    debugPrint('[GoogleFonts] Config notice: $e');
  }

  // 7. Safe local offline database setup
  try {
    await OfflineManager.init().timeout(const Duration(seconds: 2));
    debugPrint('[OfflineManager] Local SQLite/cache storage ready.');
  } catch (e) {
    debugPrint('[OfflineManager] Safe local storage init notice: $e');
  }

  // 8. Launch UI immediately for instant rendering even when offline
  runApp(SmartXAcademyApp(prefs: prefs));

  // 9. Non-blocking asynchronous cloud services background initialization
  _initServicesBackground();
}

Future<void> _initServicesBackground() async {
  // Initialize Mobile Ads SDK silently in background with timeout
  try {
    await MobileAds.instance.initialize().timeout(const Duration(seconds: 4));
    debugPrint('[MobileAds] Initialized successfully in background.');
  } catch (e) {
    debugPrint('[MobileAds] Safe background init notice: $e');
  }

  // Initialize Supabase client silently in background with timeout & network safety
  try {
    if (!Supabase.instance.isInitialized) {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabaseAnonKey,
      ).timeout(const Duration(seconds: 4));
      debugPrint('[Supabase] Initialized successfully in background.');
    }
  } catch (e) {
    debugPrint('[Supabase] Safe background init notice: $e');
  }
}

class AppStateProvider extends InheritedWidget {
  final bool isDarkMode;
  final String languageCode;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLanguage;

  const AppStateProvider({
    super.key,
    required this.isDarkMode,
    required this.languageCode,
    required this.onToggleTheme,
    required this.onToggleLanguage,
    required super.child,
  });

  static AppStateProvider of(BuildContext context) {
    final AppStateProvider? result = context.dependOnInheritedWidgetOfExactType<AppStateProvider>();
    assert(result != null, 'No AppStateProvider found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(AppStateProvider oldWidget) {
    return oldWidget.isDarkMode != isDarkMode || oldWidget.languageCode != languageCode;
  }
}

class SmartXAcademyApp extends StatefulWidget {
  final SharedPreferences? prefs;
  const SmartXAcademyApp({super.key, this.prefs});

  @override
  State<SmartXAcademyApp> createState() => _SmartXAcademyAppState();
}

class _SmartXAcademyAppState extends State<SmartXAcademyApp> {
  late bool _isDarkMode;
  late String _languageCode; // 'en' or 'am' (Amharic)

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.prefs?.getBool('isDarkMode') ?? false;
    _languageCode = widget.prefs?.getString('languageCode') ?? 'en';
  }

  void toggleTheme() async {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    if (widget.prefs != null) {
      await widget.prefs!.setBool('isDarkMode', _isDarkMode);
    }
  }

  void toggleLanguage() async {
    setState(() {
      _languageCode = _languageCode == 'en' ? 'am' : 'en';
    });
    if (widget.prefs != null) {
      await widget.prefs!.setString('languageCode', _languageCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppStateProvider(
      isDarkMode: _isDarkMode,
      languageCode: _languageCode,
      onToggleTheme: toggleTheme,
      onToggleLanguage: toggleLanguage,
      child: MaterialApp(
        title: 'Smart X ET',
        debugShowCheckedModeBanner: false,
        
        // Sophisticated Light & Dark Themes matching the user's sleek palette
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF00BFFF), // DeepSkyBlue (#00BFFF)
            surface: Color(0xFFF1F5F9), // Soft slate background
            onPrimary: Colors.white,
            onSurface: Color(0xFF1E2843),
          ),
          textTheme: const TextTheme(
            titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00BFFF)),
            bodyLarge: TextStyle(color: Color(0xFF42526E)),
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00BFFF), // DeepSkyBlue (#00BFFF)
            surface: Color(0xFF0F172A), // Deep dark-slate background
            onPrimary: Color(0xFF0F172A),
            onSurface: Color(0xFFFAFAFA),
          ),
          textTheme: const TextTheme(
            titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            bodyLarge: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ),
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        
        // Automated Navigation Observer for Firebase Analytics
        navigatorObservers: [
          AnalyticsService.observer,
        ],
        
        // Launch the animated open-application process (Splash Screen)
        home: SplashScreen(
          isDarkMode: _isDarkMode,
          languageCode: _languageCode,
          onToggleTheme: toggleTheme,
          onToggleLanguage: toggleLanguage,
        ),
      ),
    );
  }
}

