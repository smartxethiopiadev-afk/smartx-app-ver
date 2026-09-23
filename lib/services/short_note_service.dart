import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/short_note_model.dart';
import 'offline_manager.dart';

class ShortNoteService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static String _normalizeSubject(String rawSubject) {
    final s = rawSubject.toLowerCase().trim();
    if (s.contains('math')) return 'mathematics';
    if (s.contains('phys')) return 'physics';
    if (s.contains('chem')) return 'chemistry';
    if (s.contains('bio')) return 'biology';
    if (s.contains('civ')) return 'civics';
    if (s.contains('eng')) return 'english';
    if (s.contains('econ')) return 'economics';
    if (s.contains('geog') || s.contains('geo')) return 'geography';
    if (s.contains('hist')) return 'history';
    if (s.contains('agri') || s.contains('agr')) return 'agriculture';
    if (s.contains('ict') || s.contains('it') || s.contains('info') || s.contains('comp')) {
      return 'ict';
    }
    return s;
  }

  /// Fetch short notes for a specific grade, subject, and unit from Supabase.
  static Future<List<ShortNoteModel>> fetchShortNotes({
    required int grade,
    required String subject,
    int? unitNumber,
  }) async {
    final bool hasConn = await OfflineManager.isNetworkAvailable();
    final normalizedSubject = _normalizeSubject(subject);

    if (hasConn) {
      try {
        var query = _supabase
            .from('short_notes')
            .select('*')
            .eq('grade', grade)
            .ilike('subject', '%$normalizedSubject%');

        if (unitNumber != null && unitNumber > 0) {
          query = query.eq('unit_number', unitNumber);
        }

        final List<dynamic> res = await query.order('unit_number', ascending: true);
        return res.map((json) => ShortNoteModel.fromJson(json as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('[ShortNoteService] Supabase query note: $e');
      }
    }

    return [];
  }

  /// Get single short note for unit or return default model
  static Future<ShortNoteModel?> fetchSingleNote({
    required int grade,
    required String subject,
    required int unitNumber,
  }) async {
    final notes = await fetchShortNotes(
      grade: grade,
      subject: subject,
      unitNumber: unitNumber,
    );
    if (notes.isNotEmpty) {
      return notes.first;
    }
    return null;
  }
}
