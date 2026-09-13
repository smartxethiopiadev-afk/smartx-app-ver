import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

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

/// Standalone, privacy-focused application event dispatcher and observer.
/// Completely decoupled from external telemetry/Firebase services.
class AnalyticsService {
  AnalyticsService._();

  static NavigatorObserver? _observerInstance;
  static bool _collectionEnabled = true;

  /// Analytics service status
  static bool get isAvailable => true;

  /// Lightweight [NavigatorObserver] for route tracking in [MaterialApp].
  static NavigatorObserver get observer {
    _observerInstance ??= _AppNavigatorObserver();
    return _observerInstance!;
  }

  /// Sanitizes an event or screen name
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

  /// Sanitizes parameter map
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
    if (!_collectionEnabled) return;
    final sanitizedScreenName = _sanitizeName(screenName);
    if (kDebugMode) {
      debugPrint('[AnalyticsService] 📱 Screen View: "$sanitizedScreenName" (Class: $screenClass)');
    }
  }

  /// Logs a custom application event with optional payload parameters.
  static Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (!_collectionEnabled) return;
    final sanitizedEventName = _sanitizeName(name);
    final sanitizedParams = _sanitizeParameters(parameters);
    if (kDebugMode) {
      debugPrint('[AnalyticsService] 📊 Event: "$sanitizedEventName" -> $sanitizedParams');
    }
  }

  /// Sets the user ID for user-scoped sessions.
  static Future<void> setUserId(String? userId) async {
    if (kDebugMode) {
      debugPrint('[AnalyticsService] 👤 User ID: $userId');
    }
  }

  /// Sets a user property (e.g. `preferred_grade`, `preferred_lang`).
  static Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    if (kDebugMode) {
      debugPrint('[AnalyticsService] 🏷️ User Property: $name = $value');
    }
  }

  /// Enables or disables analytics data collection.
  static Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    _collectionEnabled = enabled;
    if (kDebugMode) {
      debugPrint('[AnalyticsService] Analytics collection enabled: $enabled');
    }
  }

  /// Resets analytics data for the current app instance.
  static Future<void> resetAnalyticsData() async {
    if (kDebugMode) {
      debugPrint('[AnalyticsService] Analytics data reset.');
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

/// Safe [NavigatorObserver] used for navigation monitoring.
class _AppNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final name = route.settings.name;
    if (name != null && name.isNotEmpty && name != '/') {
      AnalyticsService.logScreenView(screenName: name);
    }
  }
}
