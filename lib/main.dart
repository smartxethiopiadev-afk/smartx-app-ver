import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'config/app_config.dart';
import 'screens/splash_screen.dart';
import 'services/offline_manager.dart';
import 'services/analytics_service.dart';

void main() async {
  // Ensure widget bindings are safely initialized before calling native platforms/plugins
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase Core safely
  try {
    await Firebase.initializeApp();
    final analytics = FirebaseAnalytics.instance;
    debugPrint("[Firebase] Initialized successfully with analytics: $analytics");
  } catch (e) {
    debugPrint("[Firebase] Firebase.initializeApp notice: $e");
  }

  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 2));
  } catch (e) {
    debugPrint("Local SharedPreferences init notice: $e");
  }

  try {
    GoogleFonts.config.allowRuntimeFetching = false;
  } catch (e) {
    debugPrint("GoogleFonts config notice: $e");
  }

  // Launch app immediately to ensure smooth, unblocked UI presentation
  runApp(SmartXAcademyApp(prefs: prefs));

  // Non-blocking background initialization of remote and local cache services
  _initServicesBackground();
}

Future<void> _initServicesBackground() async {
  // Initialize offline manager locally
  try {
    await OfflineManager.init();
  } catch (e) {
    debugPrint("OfflineManager local init notice: $e");
  }
  
  // Initialize Mobile Ads SDK silently in background
  try {
    await MobileAds.instance.initialize().timeout(const Duration(seconds: 4));
  } catch (e) {
    debugPrint("MobileAds background init notice: $e");
  }

  // Initialize Supabase client silently in background
  try {
    if (!Supabase.instance.isInitialized) {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabaseAnonKey,
      ).timeout(const Duration(seconds: 4));
    }
  } catch (e) {
    debugPrint("Supabase background init notice: $e");
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
            primary: Color(0xFF00BFFF), // Elegant DeepSkyBlue (#00BFFF)
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
            primary: Color(0xFF00BFFF), // Elegant DeepSkyBlue (#00BFFF)
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
        
        // Launch the beautiful animated open-application process (Splash Screen)
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
