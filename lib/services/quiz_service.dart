import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/question_model.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizService {
  static final SupabaseClient _supabase = Supabase.instance.client;

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

  /// Fetches questions from the unified 4-table 'questions' schema:
  /// query `supabase.from('questions').select().eq('grade', grade).ilike('subject', subject).eq('unit_number', unit).order('order_index', ascending: true)`.
  static Future<List<QuestionModel>> fetchQuestions({
    required int grade,
    required String subject,
    required int unit,
  }) async {
    try {
      debugPrint("QuizService: Fetching questions for grade = $grade, subject = $subject, unit_number = $unit");

      final String normalizedSubject = getNormalizedSubjectName(subject);

      final response = await _supabase
          .from('questions')
          .select()
          .eq('grade', grade)
          .ilike('subject', '%$normalizedSubject%')
          .eq('unit_number', unit)
          .order('order_index', ascending: true);

      if ((response as List).isEmpty) {
        // Try fallback with raw subject name
        final fallbackResponse = await _supabase
            .from('questions')
            .select()
            .eq('grade', grade)
            .ilike('subject', '%$subject%')
            .eq('unit_number', unit)
            .order('order_index', ascending: true);

        if ((fallbackResponse as List).isEmpty) {
          debugPrint("QuizService WARNING: No questions found for grade $grade, subject $subject, unit $unit");
          return [];
        }

        final List<dynamic> data = fallbackResponse as List<dynamic>;
        return data.map((json) => QuestionModel.fromJson(json as Map<String, dynamic>)).toList();
      }

      final List<dynamic> questionsData = response as List<dynamic>;
      final List<QuestionModel> questions = questionsData
          .map((json) => QuestionModel.fromJson(json as Map<String, dynamic>))
          .toList();

      // Ensure deterministic sorting by order_index ASC
      questions.sort((a, b) {
        final aIdx = a.orderIndex ?? a.questionNumber ?? 0;
        final bIdx = b.orderIndex ?? b.questionNumber ?? 0;
        return aIdx.compareTo(bIdx);
      });

      return questions;
    } catch (e) {
      debugPrint('QuizService fetchQuestions error: $e');
      rethrow;
    }
  }

  static Future<List<QuestionModel>> filterAndSelectQuestions({
    required String unitId,
    required List<QuestionModel> allQuestions,
  }) async {
    return allQuestions;
  }

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
    } catch (e) {
      debugPrint("QuizService: Failed to mark questions as answered: $e");
    }
  }
}
