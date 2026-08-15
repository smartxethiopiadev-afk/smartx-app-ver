import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

/// Top-level helper function to log screen views manually across the application.
Future<void> logScreen(String screenName) async {
  await AnalyticsService.logScreen(screenName);
}

/// Top-level helper function to log custom analytics events.
Future<void> logEvent({
  required String name,
  Map<String, Object>? parameters,
}) async {
  await AnalyticsService.logEvent(name: name, parameters: parameters);
}

class AnalyticsService {
  static FirebaseAnalytics? _instance;
  static FirebaseAnalyticsObserver? _observerInstance;

  /// Singleton access to [FirebaseAnalytics].
  static FirebaseAnalytics get analytics {
    _instance ??= FirebaseAnalytics.instance;
    return _instance!;
  }

  /// Navigation observer for automatic named route tracking in [MaterialApp].
  static FirebaseAnalyticsObserver get observer {
    _observerInstance ??= FirebaseAnalyticsObserver(analytics: analytics);
    return _observerInstance!;
  }

  /// Manually logs a screen view transition.
  static Future<void> logScreen(String screenName) async {
    try {
      debugPrint('[FirebaseAnalytics] Tracking Screen View: $screenName');
      await analytics.logScreenView(screenName: screenName);
    } catch (e) {
      debugPrint('[FirebaseAnalytics] Error logging screen "$screenName": $e');
    }
  }

  /// Logs a custom analytics event with optional payload parameters.
  static Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      debugPrint('[FirebaseAnalytics] Tracking Event: "$name" -> $parameters');
      await analytics.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      debugPrint('[FirebaseAnalytics] Error logging event "$name": $e');
    }
  }

  /// Custom event helper: When a student finishes a quiz session.
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

  /// Custom event helper: When a student opens a short note or unit summary.
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

  /// Custom event helper: When a student downloads a unit for offline use.
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
}
