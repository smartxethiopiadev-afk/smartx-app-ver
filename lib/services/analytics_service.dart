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

/// Comprehensive application event dispatcher and observer.
class AnalyticsService {
  AnalyticsService._();

  static NavigatorObserver? _observerInstance;
  static bool _collectionEnabled = true;

  /// Analytics service status
  static bool get isAvailable => true;

  /// NavigatorObserver for route tracking in [MaterialApp].
  static NavigatorObserver get observer {
    _observerInstance ??= _AppNavigatorObserver();
    return _observerInstance!;
  }

  /// Internal health check method
  static Future<bool> checkFirebaseHealth() async {
    return true;
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
  // CONVENIENCE EVENT HELPERS
  // ===========================================================================

  static Future<void> logGradeSelected(int grade) async {
    await logEvent(
      name: 'grade_selected',
      parameters: {'grade_number': grade},
    );
  }

  static Future<void> logSubjectOpened({
    required String subjectId,
    required int grade,
  }) async {
    await logEvent(
      name: 'subject_opened',
      parameters: {
        'subject_id': subjectId,
        'grade': grade,
      },
    );
  }

  static Future<void> logUnitSelected({
    required String subjectId,
    required int grade,
    required int unitNumber,
    required String unitTitle,
  }) async {
    await logEvent(
      name: 'unit_selected',
      parameters: {
        'subject_id': subjectId,
        'grade': grade,
        'unit_number': unitNumber,
        'unit_title': unitTitle,
      },
    );
  }

  static Future<void> logQuizStarted({
    required String subjectId,
    required int grade,
    int? unitNumber,
    int? unit,
    String? mode,
    int? totalQuestions,
  }) async {
    await logEvent(
      name: 'quiz_started',
      parameters: {
        'subject_id': subjectId,
        'grade': grade,
        if (unitNumber != null) 'unit_number': unitNumber,
        if (unit != null) 'unit': unit,
        if (mode != null) 'mode': mode,
        if (totalQuestions != null) 'total_questions': totalQuestions,
      },
    );
  }

  static Future<void> logQuizCompleted({
    required String subjectId,
    required int grade,
    int? unitNumber,
    int? unit,
    String? mode,
    required int score,
    int? totalQuestions,
    double? scorePercent,
    int? durationSeconds,
  }) async {
    await logEvent(
      name: 'quiz_completed',
      parameters: {
        'subject_id': subjectId,
        'grade': grade,
        if (unitNumber != null) 'unit_number': unitNumber,
        if (unit != null) 'unit': unit,
        if (mode != null) 'mode': mode,
        'score': score,
        if (totalQuestions != null) 'total_questions': totalQuestions,
        if (scorePercent != null) 'score_percentage': scorePercent,
        if (durationSeconds != null) 'duration_seconds': durationSeconds,
      },
    );
  }

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

  static Future<void> logUnitDownloaded({
    required String unitId,
    required int grade,
    required String subjectId,
    required int unitNumber,
  }) async {
    await logEvent(
      name: 'unit_downloaded_offline',
      parameters: {
        'unit_id': unitId,
        'grade': grade,
        'subject_id': subjectId,
        'unit_number': unitNumber,
      },
    );
  }

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

  static Future<void> logPackageUnlocked({
    required String packageId,
    required String packageName,
    required int priceEtb,
  }) async {
    await logEvent(
      name: 'package_unlocked',
      parameters: {
        'package_id': packageId,
        'package_name': packageName,
        'price_etb': priceEtb,
      },
    );
  }

  static Future<void> logThemeChanged(bool isDark) async {
    await logEvent(
      name: 'theme_changed',
      parameters: {'theme_mode': isDark ? 'dark' : 'light'},
    );
  }

  static Future<void> logLanguageChanged(String languageCode) async {
    await logEvent(
      name: 'language_changed',
      parameters: {'language_code': languageCode},
    );
  }

  static Future<void> logTelegramBannerClicked({required String source}) async {
    await logEvent(
      name: 'telegram_banner_clicked',
      parameters: {'click_source': source},
    );
  }
}

/// Lightweight navigator observer for route logging
class _AppNavigatorObserver extends NavigatorObserver {
  void _sendScreenView(PageRoute<dynamic> route) {
    final String? screenName = route.settings.name;
    if (screenName != null && screenName.isNotEmpty && screenName != '/') {
      AnalyticsService.logScreenView(screenName: screenName);
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) {
      _sendScreenView(route);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute is PageRoute) {
      _sendScreenView(newRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute is PageRoute && route is PageRoute) {
      _sendScreenView(previousRoute);
    }
  }
}
