import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../models/question_model.dart';
import '../models/note_model.dart';

class SupabaseService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    try {
      // ignore: deprecated_member_use
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: AppConfig.supabaseAnonKey,
      );
      _initialized = true;
    } catch (e) {
      _initialized = false;
    }
  }

  static bool get isReady => _initialized;

  static Future<List<QuestionModel>?> fetchQuestions(String unitId) async {
    if (!_initialized) return null;
    try {
      final response = await Supabase.instance.client
          .from('questions')
          .select('id, unit_id, question_text, question_number, explanation, question_options(id, text, is_correct, explanation)')
          .eq('unit_id', unitId)
          .order('question_number');

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => QuestionModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return null;
    }
  }

  static Future<ShortNoteModel?> fetchShortNote(int grade, String subject, int unitNumber) async {
    if (!_initialized) return null;
    try {
      final response = await Supabase.instance.client
          .from('short_notes')
          .select('id, grade, subject, unit_number, title, html_content')
          .eq('grade', grade)
          .ilike('subject', subject)
          .eq('unit_number', unitNumber)
          .maybeSingle();

      if (response != null) {
        return ShortNoteModel.fromJson(response);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
