import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
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
  static NavigatorObserver? _observerInstance;

  /// Safe access to [FirebaseAnalytics]. Returns `null` if Firebase is not initialized.
  static FirebaseAnalytics? get analytics {
    try {
      if (Firebase.apps.isNotEmpty) {
        _instance ??= FirebaseAnalytics.instance;
        return _instance;
      }
    } catch (e) {
      debugPrint('[AnalyticsService] Firebase Analytics unavailable: $e');
    }
    return null;
  }

  /// Safe Navigation observer for automatic named route tracking in [MaterialApp].
  /// Returns a dummy [NavigatorObserver] if Firebase Analytics is unavailable.
  static NavigatorObserver get observer {
    try {
      final fa = analytics;
      if (fa != null) {
        _observerInstance ??= FirebaseAnalyticsObserver(analytics: fa);
        return _observerInstance!;
      }
    } catch (e) {
      debugPrint('[AnalyticsService] Error creating observer: $e');
    }
    return NavigatorObserver(); // Safe fallback observer
  }

  /// Manually logs a screen view transition.
  static Future<void> logScreen(String screenName) async {
    try {
      final fa = analytics;
      if (fa == null) return;
      debugPrint('[FirebaseAnalytics] Tracking Screen View: $screenName');
      await fa.logScreenView(screenName: screenName);
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
      final fa = analytics;
      if (fa == null) return;
      debugPrint('[FirebaseAnalytics] Tracking Event: "$name" -> $parameters');
      await fa.logEvent(
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
