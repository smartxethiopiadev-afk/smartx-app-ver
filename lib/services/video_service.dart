import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/video_model.dart';
import 'offline_manager.dart';

class VideoService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Normalizes subject names for querying
  static String _normalizeSubject(String rawSubject) {
    final s = rawSubject.toLowerCase().trim();
    if (s.contains('math')) return 'Mathematics';
    if (s.contains('phys')) return 'Physics';
    if (s.contains('chem')) return 'Chemistry';
    if (s.contains('bio')) return 'Biology';
    if (s.contains('eng')) return 'English';
    if (s.contains('econ')) return 'Economics';
    if (s.contains('geog') || s.contains('geo')) return 'Geography';
    if (s.contains('hist')) return 'History';
    if (s.contains('agri') || s.contains('agr')) return 'Agriculture';
    if (s.contains('it') || s.contains('info') || s.contains('comp')) {
      return 'Information Technology';
    }
    return rawSubject;
  }

  /// Fetches video lessons STRICTLY from database.
  /// If database has no videos or is empty, returns empty list (shows "Coming Soon" in UI).
  static Future<List<VideoModel>> fetchVideos({
    required int grade,
    String? subject,
    int? unit,
  }) async {
    final bool hasConn = await OfflineManager.isNetworkAvailable();

    if (hasConn) {
      try {
        var query = _supabase.from('videos').select('*').eq('grade', grade);

        if (subject != null && subject.trim().isNotEmpty && subject.toLowerCase() != 'all') {
          final normSubject = _normalizeSubject(subject);
          query = query.ilike('subject', '%$normSubject%');
        }

        if (unit != null && unit > 0) {
          query = query.eq('unit_number', unit);
        }

        final response = await query.order('order_index', ascending: true);

        if (response.isNotEmpty) {
          return (response as List<dynamic>)
              .map((item) => VideoModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      } catch (e) {
        debugPrint('[VideoService] Database fetch error: $e');
      }
    }

    // Strict user mandate: Videos come ONLY from database.
    // If no database link or records exist, return empty list so the UI displays "Coming Soon".
    return [];
  }
}
