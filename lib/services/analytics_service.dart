import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

/// Top-level convenience function to log screen views manually across the app.
Future<void> logScreen(String screenName, {String? screenClass}) async {
  await AnalyticsService.logScreenView(
    screenName: screenName,
    screenClass: screenClass,
  );
}

/// Top-level convenience function to log custom analytics events.
Future<void> logEvent({
  required String name,
  Map<String, Object>? parameters,
}) async {
  await AnalyticsService.logEvent(name: name, parameters: parameters);
}

/// Production-ready service for Google Analytics (Firebase Analytics).
/// Enforces resilient error handling, parameter sanitation according to GA4 specs,
/// safe route navigation observing, and offline-safe execution.
class AnalyticsService {
  AnalyticsService._();

  static FirebaseAnalytics? _analyticsInstance;
  static NavigatorObserver? _observerInstance;
  static bool _hasLoggedInitNotice = false;

  /// Checks if Firebase Core is initialized and available.
  static bool get isAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Safe singleton accessor for [FirebaseAnalytics].
  /// Returns `null` if Firebase is uninitialized or unconfigured.
  static FirebaseAnalytics? get analytics {
    if (!isAvailable) {
      if (!_hasLoggedInitNotice && kDebugMode) {
        debugPrint('[AnalyticsService] Notice: Firebase is not initialized. Analytics events will be silently skipped.');
        _hasLoggedInitNotice = true;
      }
      return null;
    }
    try {
      _analyticsInstance ??= FirebaseAnalytics.instance;
      return _analyticsInstance;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AnalyticsService] Error accessing FirebaseAnalytics instance: $e');
      }
      return null;
    }
  }

  /// Production-ready [NavigatorObserver] for automatic screen view tracking in [MaterialApp].
  /// Uses a custom name extractor for clean route names and guarantees zero runtime crashes.
  static NavigatorObserver get observer {
    if (_observerInstance != null) {
      return _observerInstance!;
    }

    try {
      final fa = analytics;
      if (fa != null) {
        _observerInstance = _SafeFirebaseAnalyticsObserver(
          analytics: fa,
          nameExtractor: _defaultRouteNameExtractor,
        );
        return _observerInstance!;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AnalyticsService] Error creating FirebaseAnalyticsObserver: $e');
      }
    }

    // Fallback safe observer when Firebase is not active
    _observerInstance = _FallbackNavigatorObserver();
    return _observerInstance!;
  }

  /// Intelligently extracts readable screen names from [RouteSettings].
  static String? _defaultRouteNameExtractor(RouteSettings settings) {
    final name = settings.name;
    if (name != null && name.isNotEmpty && name != '/') {
      return _sanitizeName(name.replaceAll('/', '_'));
    }
    return null;
  }

  /// Sanitizes an event or screen name to match Google Analytics 4 (GA4) specifications:
  /// - Max 40 characters
  /// - Alphanumeric and underscores only
  /// - Must start with an alphabetic character
  static String _sanitizeName(String raw) {
    String clean = raw.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    while (clean.startsWith('_')) {
      clean = clean.substring(1);
    }
    if (clean.isEmpty) return 'unnamed';
    if (clean.length > 40) {
      clean = clean.substring(0, 40);
    }
    return clean;
  }

  /// Sanitizes parameter map according to GA4 constraints:
  /// - Parameter names: max 40 characters, alphanumeric and underscores only
  /// - String values: max 100 characters
  static Map<String, Object>? _sanitizeParameters(Map<String, Object>? rawParams) {
    if (rawParams == null || rawParams.isEmpty) return null;

    final Map<String, Object> sanitized = {};
    for (final entry in rawParams.entries) {
      final key = _sanitizeName(entry.key);
      final value = entry.value;

      if (value is String) {
        sanitized[key] = value.length > 100 ? value.substring(0, 100) : value;
      } else if (value is num || value is bool) {
        sanitized[key] = value;
      } else {
        final str = value.toString();
        sanitized[key] = str.length > 100 ? str.substring(0, 100) : str;
      }
    }
    return sanitized;
  }

  // ===========================================================================
  // CORE TRACKING METHODS
  // ===========================================================================

  /// Manually logs a screen view transition.
  static Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      final fa = analytics;
      if (fa == null) return;

      final sanitizedScreenName = _sanitizeName(screenName);
      if (kDebugMode) {
        debugPrint('[AnalyticsService] 📱 Screen View: "$sanitizedScreenName" (Class: $screenClass)');
      }

      await fa.logScreenView(
        screenName: sanitizedScreenName,
        screenClass: screenClass ?? screenName,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AnalyticsService] Error logging screen "$screenName": $e');
      }
    }
  }

  /// Logs a custom GA4 event with optional payload parameters.
  static Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      final fa = analytics;
      if (fa == null) return;

      final sanitizedEventName = _sanitizeName(name);
      final sanitizedParams = _sanitizeParameters(parameters);

      if (kDebugMode) {
        debugPrint('[AnalyticsService] 📊 Event: "$sanitizedEventName" -> $sanitizedParams');
      }

      await fa.logEvent(
        name: sanitizedEventName,
        parameters: sanitizedParams,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AnalyticsService] Error logging event "$name": $e');
      }
    }
  }

  /// Sets the user ID for cross-device tracking and user-scoped analytics.
  static Future<void> setUserId(String? userId) async {
    try {
      final fa = analytics;
      if (fa == null) return;
      await fa.setUserId(id: userId);
      if (kDebugMode) {
        debugPrint('[AnalyticsService] 👤 User ID set: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AnalyticsService] Error setting user ID: $e');
      }
    }
  }

  /// Sets a user property for audience segmentation (e.g. `preferred_grade`, `preferred_lang`).
  static Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    try {
      final fa = analytics;
      if (fa == null) return;

      final sanitizedName = _sanitizeName(name);
      final sanitizedValue = value.length > 36 ? value.substring(0, 36) : value;

      await fa.setUserProperty(
        name: sanitizedName,
        value: sanitizedValue,
      );
      if (kDebugMode) {
        debugPrint('[AnalyticsService] 🏷️ User Property set: $sanitizedName = $sanitizedValue');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AnalyticsService] Error setting user property "$name": $e');
      }
    }
  }

  /// Enables or disables analytics data collection (useful for user privacy / GDPR toggles).
  static Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    try {
      final fa = analytics;
      if (fa == null) return;
      await fa.setAnalyticsCollectionEnabled(enabled);
      if (kDebugMode) {
        debugPrint('[AnalyticsService] Analytics collection enabled: $enabled');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AnalyticsService] Error setting analytics collection enabled: $e');
      }
    }
  }

  /// Resets all analytics data for the current app instance (e.g. on user logout).
  static Future<void> resetAnalyticsData() async {
    try {
      final fa = analytics;
      if (fa == null) return;
      await fa.resetAnalyticsData();
      if (kDebugMode) {
        debugPrint('[AnalyticsService] Analytics data reset successfully.');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AnalyticsService] Error resetting analytics data: $e');
      }
    }
  }

  // ===========================================================================
  // DOMAIN-SPECIFIC HIGH-LEVEL EVENT HELPERS
  // ===========================================================================

  /// Logged when a student starts a quiz.
  static Future<void> logQuizStarted({
    required String subject,
    required int grade,
    int? unit,
    String? mode,
  }) async {
    await logEvent(
      name: 'quiz_started',
      parameters: {
        'subject': subject,
        'grade': grade,
        if (unit != null) 'unit': unit,
        if (mode != null) 'mode': mode,
      },
    );
  }

  /// Logged when a student completes a quiz session.
  static Future<void> logQuizCompleted({
    required String subject,
    required int score,
    int? totalQuestions,
    int? percent,
    int? grade,
    int? unit,
    String? mode,
  }) async {
    await logEvent(
      name: 'quiz_completed',
      parameters: {
        'subject': subject,
        'score': score,
        if (totalQuestions != null) 'total_questions': totalQuestions,
        if (percent != null) 'percent': percent,
        if (grade != null) 'grade': grade,
        if (unit != null) 'unit': unit,
        if (mode != null) 'mode': mode,
      },
    );
  }

  /// Logged when a student opens a short note or unit summary.
  static Future<void> logShortNoteOpened({
    required String unit,
    String? subject,
    int? grade,
  }) async {
    await logEvent(
      name: 'short_note_opened',
      parameters: {
        'unit': unit,
        if (subject != null) 'subject': subject,
        if (grade != null) 'grade': grade,
      },
    );
  }

  /// Logged when a student downloads a unit for offline study.
  static Future<void> logOfflineDownload({
    required String unitTitle,
    required String subject,
    required int grade,
  }) async {
    await logEvent(
      name: 'offline_unit_downloaded',
      parameters: {
        'unit_title': unitTitle,
        'subject': subject,
        'grade': grade,
      },
    );
  }

  /// Logged when a student selects or switches a grade level.
  static Future<void> logGradeSelected(int grade) async {
    await logEvent(
      name: 'grade_selected',
      parameters: {'grade': grade},
    );
    await setUserProperty(name: 'selected_grade', value: 'Grade $grade');
  }

  /// Logged when a student selects a subject.
  static Future<void> logSubjectSelected({
    required String subject,
    required int grade,
  }) async {
    await logEvent(
      name: 'subject_selected',
      parameters: {
        'subject': subject,
        'grade': grade,
      },
    );
  }

  /// Logged when user taps the Telegram study community banner.
  static Future<void> logTelegramBannerClicked({String? source}) async {
    await logEvent(
      name: 'telegram_banner_clicked',
      parameters: {
        if (source != null) 'source': source,
      },
    );
  }

  /// Logged when user toggles theme (dark/light).
  static Future<void> logThemeChanged(bool isDark) async {
    await logEvent(
      name: 'theme_changed',
      parameters: {'mode': isDark ? 'dark' : 'light'},
    );
    await setUserProperty(name: 'theme_preference', value: isDark ? 'dark' : 'light');
  }

  /// Logged when user changes app language.
  static Future<void> logLanguageChanged(String languageCode) async {
    await logEvent(
      name: 'language_changed',
      parameters: {'language': languageCode},
    );
    await setUserProperty(name: 'app_language', value: languageCode);
  }
}

// =============================================================================
// SAFE OBSERVER IMPLEMENTATIONS
// =============================================================================

/// A wrapper around [FirebaseAnalyticsObserver] that guarantees runtime exceptions
/// inside navigation callbacks never bubble up or disrupt the Flutter Navigator.
class _SafeFirebaseAnalyticsObserver extends FirebaseAnalyticsObserver {
  _SafeFirebaseAnalyticsObserver({
    required super.analytics,
    super.nameExtractor,
  });

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    try {
      super.didPush(route, previousRoute);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[_SafeFirebaseAnalyticsObserver] didPush notice: $e');
      }
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    try {
      super.didPop(route, previousRoute);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[_SafeFirebaseAnalyticsObserver] didPop notice: $e');
      }
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    try {
      super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[_SafeFirebaseAnalyticsObserver] didReplace notice: $e');
      }
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    try {
      super.didRemove(route, previousRoute);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[_SafeFirebaseAnalyticsObserver] didRemove notice: $e');
      }
    }
  }
}

/// Fallback [NavigatorObserver] used when Firebase is uninitialized or disabled.
class _FallbackNavigatorObserver extends NavigatorObserver {}
