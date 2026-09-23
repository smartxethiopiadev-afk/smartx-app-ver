import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/short_note_model.dart';

class ShortNoteService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static String _normalizeSubject(String raw) {
    final s = raw.toLowerCase().trim();
    if (s.contains('econ')) return 'economics';
    if (s.contains('math')) return 'mathematics';
    if (s.contains('phys')) return 'physics';
    if (s.contains('chem')) return 'chemistry';
    if (s.contains('bio')) return 'biology';
    if (s.contains('civ')) return 'civics';
    if (s.contains('eng')) return 'english';
    if (s.contains('geog') || s.contains('geo')) return 'geography';
    if (s.contains('hist')) return 'history';
    if (s.contains('agri') || s.contains('agr')) return 'agriculture';
    if (s.contains('ict') || s.contains('info')) return 'ict';
    return s;
  }

  /// Retrieves the pdf_url for a given grade, subject (case-insensitive), and unit_number.
  static Future<String?> getPdfUrl({
    required int grade,
    required String subject,
    required int unitNumber,
  }) async {
    try {
      final cleanSubject = subject.trim();
      final normalized = _normalizeSubject(cleanSubject);

      // 1. Direct case-insensitive match (ilike)
      var response = await _supabase
          .from('short_notes')
          .select('pdf_url')
          .eq('grade', grade)
          .ilike('subject', cleanSubject)
          .eq('unit_number', unitNumber)
          .limit(1);

      // 2. Normalized subject match if different
      if (response.isEmpty && normalized != cleanSubject.toLowerCase()) {
        response = await _supabase
            .from('short_notes')
            .select('pdf_url')
            .eq('grade', grade)
            .ilike('subject', normalized)
            .eq('unit_number', unitNumber)
            .limit(1);
      }

      // 3. Wildcard ilike match
      if (response.isEmpty) {
        response = await _supabase
            .from('short_notes')
            .select('pdf_url')
            .eq('grade', grade)
            .ilike('subject', '%$cleanSubject%')
            .eq('unit_number', unitNumber)
            .limit(1);
      }

      if (response.isNotEmpty) {
        final rawUrl = (response.first['pdf_url'] ?? '').toString().trim();
        if (rawUrl.isNotEmpty) {
          return rawUrl;
        }
      }
    } catch (e) {
      debugPrint('[ShortNoteService] Error fetching pdf_url: $e');
    }
    return null;
  }

  /// Fetches short notes matching grade, subject, and optional unit_number.
  static Future<List<ShortNoteModel>> fetchShortNotes({
    required int grade,
    required String subject,
    int? unitNumber,
  }) async {
    try {
      final cleanSubject = subject.trim();
      var query = _supabase
          .from('short_notes')
          .select('grade, subject, unit_number, pdf_url')
          .eq('grade', grade)
          .ilike('subject', cleanSubject);

      if (unitNumber != null && unitNumber > 0) {
        query = query.eq('unit_number', unitNumber);
      }

      final List<dynamic> res = await query.order('unit_number', ascending: true);
      return res.map((json) => ShortNoteModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[ShortNoteService] Error in fetchShortNotes: $e');
      return [];
    }
  }

  /// Fetches a single ShortNoteModel for a specific unit.
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
