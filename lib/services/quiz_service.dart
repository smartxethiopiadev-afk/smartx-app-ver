import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/question_model.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static String mapSubjectToPrefix(String subject) {
    final sub = subject.toLowerCase().trim();
    switch (sub) {
      case 'mathematics':
      case 'math':
        return 'math';
      case 'biology':
      case 'bio':
        return 'bio';
      case 'physics':
      case 'phys':
        return 'phys';
      case 'chemistry':
      case 'chem':
        return 'chem';
      case 'geography':
      case 'geo':
        return 'geo';
      case 'history':
      case 'hist':
        return 'hist';
      case 'civics':
      case 'civ':
        return 'civ';
      case 'agriculture':
      case 'agri':
        return 'agri';
      default:
        return sub.length > 4 ? sub.substring(0, 4) : sub;
    }
  }

  static String getNormalizedSubjectName(String rawSubject) {
    final sub = rawSubject.toLowerCase().trim();
    if (sub.contains('math')) return 'mathematics';
    if (sub.contains('biol') || sub.contains('bio')) return 'biology';
    if (sub.contains('phys')) return 'physics';
    if (sub.contains('chem')) return 'chemistry';
    if (sub.contains('geog') || sub.contains('geo')) return 'geography';
    if (sub.contains('hist')) return 'history';
    if (sub.contains('civ')) return 'civics';
    if (sub.contains('agri') || sub.contains('agr')) return 'agriculture';
    if (sub.contains('econ') || sub.contains('eco')) return 'economics';
    if (sub.contains('eng')) return 'english';
    return sub;
  }

  /// Fetches filtered questions from Supabase.
  /// If [grade] is supplied, filters by grade.
  /// If [subject] is supplied, filters by subject (case-insensitive).
  /// If [unit] is supplied, filters by unit.
  static Future<List<QuestionModel>> fetchQuestions({
    required int grade,
    required String subject,
    required int unit,
  }) async {
    try {
      debugPrint("QuizService: Fetching questions for grade = $grade, subject = $subject, unit = $unit");

      final String normalizedSubject = getNormalizedSubjectName(subject);
      final String expectedSubjectId = '${grade}_$normalizedSubject';

      final response = await _supabase
          .from('units')
          .select('''
            id,
            subject_id,
            unit_number,
            subjects!inner(
              id,
              name,
              grade
            ),
            questions (
              id,
              unit_id,
              question_text,
              question_number,
              order_index,
              explanation,
              created_at,
              question_options (
                id,
                text,
                is_correct,
                explanation
              )
            )
          ''')
          .eq('unit_number', unit)
          .eq('subjects.grade', grade)
          .or('subject_id.eq.$expectedSubjectId,subject_id.ilike.%$normalizedSubject%,subject_id.ilike.%$subject%')
          .maybeSingle();

      if (response == null || response['questions'] == null) {
        debugPrint("QuizService WARNING: No questions found or response is null for $subject grade $grade unit $unit. Raw: $response");
        return [];
      }

      final List<dynamic> questionsData = response['questions'] as List<dynamic>;
      return questionsData.map((json) => QuestionModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Supabase query failed: $e');
      rethrow;
    }
  }

  /// Filters a list of questions to randomly select up to 25 questions if 40 are available,
  /// tracking already answered questions using SharedPreferences.
  static Future<List<QuestionModel>> filterAndSelectQuestions({
    required String unitId,
    required List<QuestionModel> allQuestions,
  }) async {
    return allQuestions;
  }

  /// Marks the given questions as answered/used in SharedPreferences.
  static Future<void> markQuestionsAsAnswered({
    required String unitId,
    required List<QuestionModel> questions,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final answeredKey = 'answered_questions_$unitId';
      final List<String> answeredIds = prefs.getStringList(answeredKey) ?? [];

      for (final q in questions) {
        final String idStr = q.id.toString();
        if (!answeredIds.contains(idStr)) {
          answeredIds.add(idStr);
        }
      }
      await prefs.setStringList(answeredKey, answeredIds);
      debugPrint("QuizService: Marked ${questions.length} questions as answered. Total answered: ${answeredIds.length}");
    } catch (e) {
      debugPrint("QuizService: Failed to mark questions as answered: $e");
    }
  }

  /// Submits the student's quiz score to the user_progress table. Disabled.
  static Future<void> submitLeaderboardScore({
    required String fullName,
    required String phoneNumber,
    required String subjectId,
    required String unitId,
    required int score,
    required int totalQuestions,
  }) async {
    debugPrint("QuizService: submitLeaderboardScore is disabled.");
    return;
  }
}
