import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/app_config.dart';
import 'screens/splash_screen.dart';
import 'services/offline_manager.dart';
import 'services/analytics_service.dart';

void main() {
  runZonedGuarded<Future<void>>(() async {
    // 1. Ensure widget bindings are safely initialized at the very beginning inside the zone
    WidgetsFlutterBinding.ensureInitialized();

    // 2. Override ErrorWidget.builder to show a dark theme Scaffold error UI with exact exception & stack trace
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return GlobalCustomErrorWidget(details: details);
    };

    // 3. Catch Flutter framework errors globally
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('[FlutterError] Uncaught Flutter Framework Error: ${details.exception}');
    };

    // Initialize Firebase Core safely
    try {
      await Firebase.initializeApp();
      debugPrint("[Firebase] Initialized successfully.");
    } catch (e) {
      debugPrint("[Firebase] Firebase.initializeApp notice: $e");
    }

    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 2));
    } catch (e, stack) {
      debugPrint("Local SharedPreferences init notice: $e\n$stack");
    }

    try {
      GoogleFonts.config.allowRuntimeFetching = true;
    } catch (e) {
      debugPrint("GoogleFonts config notice: $e");
    }

    // Launch app immediately to ensure smooth, unblocked UI presentation
    runApp(SmartXAcademyApp(prefs: prefs));

    // Non-blocking background initialization of remote and local cache services
    _initServicesBackground();
  }, (Object error, StackTrace stack) {
    // Catch uncaught asynchronous errors globally
    debugPrint('[runZonedGuarded] Uncaught Async Exception: $error');
    debugPrint(stack.toString());
  });
}

/// A developer-friendly fallback UI displayed whenever a rendering crash or unhandled UI error occurs.
class GlobalCustomErrorWidget extends StatefulWidget {
  final FlutterErrorDetails details;
  const GlobalCustomErrorWidget({super.key, required this.details});

  @override
  State<GlobalCustomErrorWidget> createState() => _GlobalCustomErrorWidgetState();
}

class _GlobalCustomErrorWidgetState extends State<GlobalCustomErrorWidget> {
  bool _copied = false;

  void _copyToClipboard(BuildContext context) {
    final String errorLog = "EXCEPTION:\n${widget.details.exceptionAsString()}\n\nSTACK TRACE:\n${widget.details.stack.toString()}";
    Clipboard.setData(ClipboardData(text: errorLog));
    setState(() {
      _copied = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text("Error details copied to clipboard"),
          ],
        ),
        duration: Duration(seconds: 3),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String exceptionString = widget.details.exceptionAsString();
    final String stackTraceString = widget.details.stack?.toString() ?? 'No stack trace available.';

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          elevation: 0,
          leading: const Padding(
            padding: EdgeInsets.all(12.0),
            child: Icon(Icons.bug_report_rounded, color: Color(0xFFEF4444)),
          ),
          title: const Text(
            "Application Error Encountered",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
          ),
          actions: [
            Builder(
              builder: (ctx) => IconButton(
                icon: Icon(
                  _copied ? Icons.check_circle_rounded : Icons.copy_rounded,
                  color: _copied ? const Color(0xFF10B981) : Colors.white70,
                ),
                tooltip: "Copy Error",
                onPressed: () => _copyToClipboard(ctx),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAlignment.start,
              children: [
                // Warning Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAlignment.start,
                          children: [
                            Text(
                              "UI Rendering Exception Caught",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "The exact details below describe what went wrong during runtime.",
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "EXCEPTION MESSAGE",
                  style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 120),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF020617),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      exceptionString,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Color(0xFFF87171),
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "STACK TRACE",
                  style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF020617),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        stackTraceString,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Color(0xFFCBD5E1),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (ctx) => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _copyToClipboard(ctx),
                      icon: Icon(_copied ? Icons.check_circle_rounded : Icons.copy_rounded, size: 18),
                      label: Text(_copied ? "Copied to Clipboard" : "Copy Error Details"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BFFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
