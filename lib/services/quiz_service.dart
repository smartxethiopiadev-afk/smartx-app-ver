import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/question_model.dart';
import 'offline_manager.dart';

enum QuizMode {
  practice,
  exam,
}

class QuizService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Standardizes subject name for querying
  static String _normalizeSubject(String rawSubject) {
    final s = rawSubject.toLowerCase().trim();
    if (s.contains('math')) return 'Mathematics';
    if (s.contains('phys')) return 'Physics';
    if (s.contains('chem')) return 'Chemistry';
    if (s.contains('bio')) return 'Biology';
    if (s.contains('civ')) return 'Civics';
    if (s.contains('eng')) return 'English';
    if (s.contains('econ')) return 'Economics';
    if (s.contains('geog') || s.contains('geo')) return 'Geography';
    if (s.contains('hist')) return 'History';
    if (s.contains('agri') || s.contains('agr')) return 'Agriculture';
    if (s.contains('ict') || s.contains('it') || s.contains('info') || s.contains('comp')) {
      return 'ICT';
    }
    return rawSubject;
  }

  /// Strict grade and unit validation and duplicate removal logic
  /// to ensure no cross-grade leakage and no repeated questions.
  static List<QuestionModel> deduplicateAndValidate({
    required List<QuestionModel> questions,
    required int expectedGrade,
    int? expectedUnit,
  }) {
    final seenIds = <String>{};
    final seenTexts = <String>{};
    final List<QuestionModel> filtered = [];

    for (final q in questions) {
      // 1. Strict Grade Validation to prevent cross-grade leaking
      if (q.grade != null && q.grade != expectedGrade) {
        continue;
      }
      // 2. Strict Unit Validation
      if (expectedUnit != null && q.unitNumber != null && q.unitNumber != expectedUnit) {
        continue;
      }

      // 3. Deduplication by ID & Normalized Question Text
      final String idKey = q.id.trim();
      final String textKey = q.questionText.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

      if (idKey.isNotEmpty && seenIds.contains(idKey)) {
        continue;
      }
      if (textKey.isNotEmpty && seenTexts.contains(textKey)) {
        continue;
      }

      if (idKey.isNotEmpty) seenIds.add(idKey);
      if (textKey.isNotEmpty) seenTexts.add(textKey);
      filtered.add(q);
    }

    return filtered;
  }

  /// Fetches questions for Practice Mode directly from `practice_questions` table.
  /// Supports: 'multiple_choice', 'true_false', 'blank_space'.
  /// Enforces sequential order and removes duplicates.
  /// If database has no questions, returns empty list (no fake mock data).
  static Future<List<QuestionModel>> fetchPracticeQuestions({
    required int grade,
    required String subject,
    required int unit,
    String? questionType,
  }) async {
    final bool hasConn = await OfflineManager.isNetworkAvailable();
    final normSubject = _normalizeSubject(subject);
    List<QuestionModel> results = [];

    if (hasConn) {
      try {
        var query = _supabase
            .from('practice_questions')
            .select('*')
            .eq('grade', grade)
            .ilike('subject', '%$normSubject%')
            .eq('unit_number', unit);

        if (questionType != null && questionType.isNotEmpty && questionType != 'all') {
          query = query.eq('question_type', questionType);
        }

        final response = await query.order('question_number', ascending: true);

        if (response.isNotEmpty) {
          results = (response as List<dynamic>)
              .map((json) => QuestionModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      } catch (e) {
        debugPrint('[QuizService] practice_questions query note: $e');
      }

      // Legacy fallback to questions table only if practice_questions is empty on legacy database
      if (results.isEmpty) {
        try {
          final legacyResp = await _supabase
              .from('questions')
              .select('*, question_options(*)')
              .eq('grade', grade)
              .ilike('subject', '%$normSubject%')
              .eq('unit_number', unit);

          if (legacyResp.isNotEmpty) {
            results = (legacyResp as List<dynamic>)
                .map((json) => QuestionModel.fromJson(json as Map<String, dynamic>))
                .toList();
          }
        } catch (e) {
          debugPrint('[QuizService] legacy questions query note: $e');
        }
      }
    }

    // Filter by questionType if specified
    if (questionType != null && questionType.isNotEmpty && questionType != 'all') {
      results = results.where((q) {
        if (questionType == 'multiple_choice') return q.isMultipleChoice;
        if (questionType == 'true_false') return q.isTrueFalse;
        if (questionType == 'blank_space') return q.isBlankSpace;
        return true;
      }).toList();
    }

    // Strict validation & deduplication
    final validated = deduplicateAndValidate(
      questions: results,
      expectedGrade: grade,
      expectedUnit: unit,
    );

    // Practice Mode: Sequential ordering by orderIndex or questionNumber
    validated.sort((a, b) {
      if (a.orderIndex != b.orderIndex) return a.orderIndex.compareTo(b.orderIndex);
      if (a.questionNumber != b.questionNumber) return a.questionNumber.compareTo(b.questionNumber);
      return a.id.compareTo(b.id);
    });

    return validated;
  }

  /// Fetches questions for Exam Mode strictly from `exam_questions` table.
  /// Does NOT pull from practice_questions table or legacy questions table.
  /// Strictly multiple choice questions with clean deduplication.
  /// Sequential by default so QuizScreen can control randomization based on attempt count.
  /// If database has no exam questions, returns empty list (no fake mock data or cross-table fallback).
  static Future<List<QuestionModel>> fetchExamQuestions({
    required int grade,
    required String subject,
    int? unit,
    String? year,
    int limit = 50,
  }) async {
    final bool hasConn = await OfflineManager.isNetworkAvailable();
    final normSubject = _normalizeSubject(subject);
    List<QuestionModel> results = [];

    if (hasConn) {
      // 1. Strictly exam_questions table only
      try {
        var query = _supabase
            .from('exam_questions')
            .select('*')
            .eq('grade', grade)
            .ilike('subject', '%$normSubject%');

        if (unit != null && unit > 0) {
          query = query.eq('unit_number', unit);
        }

        if (year != null && year.isNotEmpty && year != 'all') {
          query = query.eq('year', year);
        }

        final response = await query.order('question_number', ascending: true).limit(limit);

        if (response.isNotEmpty) {
          results = (response as List<dynamic>)
              .map((json) => QuestionModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      } catch (e) {
        debugPrint('[QuizService] exam_questions query note: $e');
      }
    }

    // Strict validation & deduplication (guarantees no repeated questions)
    final validated = deduplicateAndValidate(
      questions: results,
      expectedGrade: grade,
      expectedUnit: unit,
    );

    // Sort sequentially by default
    validated.sort((a, b) {
      if (a.orderIndex != b.orderIndex) return a.orderIndex.compareTo(b.orderIndex);
      if (a.questionNumber != b.questionNumber) return a.questionNumber.compareTo(b.questionNumber);
      return a.id.compareTo(b.id);
    });

    return validated.take(limit).toList();
  }

  /// General router for QuizScreen
  static Future<List<QuestionModel>> fetchQuestions({
    required int grade,
    required String subject,
    required int unit,
    QuizMode mode = QuizMode.practice,
    String? questionType,
  }) async {
    if (mode == QuizMode.exam) {
      return fetchExamQuestions(grade: grade, subject: subject, unit: unit);
    } else {
      return fetchPracticeQuestions(
        grade: grade,
        subject: subject,
        unit: unit,
        questionType: questionType,
      );
    }
  }

  /// Gets the number of completed attempts for a unit quiz
  static Future<int> getQuizAttemptCount(String unitId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('quiz_attempt_count_$unitId') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Increments the completed attempts counter for a unit quiz
  static Future<int> incrementQuizAttemptCount(String unitId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt('quiz_attempt_count_$unitId') ?? 0;
      final next = current + 1;
      await prefs.setInt('quiz_attempt_count_$unitId', next);
      return next;
    } catch (_) {
      return 1;
    }
  }

  /// Filter and select active questions
  static Future<List<QuestionModel>> filterAndSelectQuestions({
    required String unitId,
    required List<QuestionModel> allQuestions,
  }) async {
    return allQuestions;
  }

  /// Mark questions as answered in SharedPreferences
  static Future<void> markQuestionsAsAnswered({
    required String unitId,
    required List<QuestionModel> questions,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final answeredIds = prefs.getStringList('answered_questions_$unitId') ?? [];
      final newIds = questions.map((q) => q.id).where((id) => !answeredIds.contains(id)).toList();
      if (newIds.isNotEmpty) {
        answeredIds.addAll(newIds);
        await prefs.setStringList('answered_questions_$unitId', answeredIds);
      }
    } catch (e) {
      debugPrint('[QuizService] markQuestionsAsAnswered error: $e');
    }
  }
}
