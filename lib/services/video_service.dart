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

  /// App Overview Tutorial Video
  static VideoModel getAppOverviewVideo() {
    return VideoModel(
      id: 'app_overview_video',
      grade: 0,
      subject: 'Tutorial',
      unitNumber: 1,
      partNumber: 1,
      title: 'Ethio Concept Center መተግበሪያ አጠቃቀም ሙሉ ገለፃ (App Overview & Master Tutorial)',
      youtubeVideoId: 'uYX1-IqlFzM',
      durationText: 'Full Tutorial',
      orderIndex: 0,
    );
  }

  /// Helper to get subjects available for a grade
  static List<String> getSubjectsForGrade(int grade) {
    switch (grade) {
      case 9:
      case 10:
        return ['Mathematics', 'Physics', 'Chemistry', 'Biology', 'Civics', 'English'];
      case 11:
      case 12:
      default:
        return ['Mathematics', 'Physics', 'Chemistry', 'Biology', 'Agriculture', 'Civics'];
    }
  }

  /// Fetches video lessons from database. Returns empty list if no videos published yet.
  static Future<List<VideoModel>> fetchVideos({
    required int grade,
    String? subject,
    int? unit,
    int? part,
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

        if (part != null && part > 0) {
          query = query.eq('part_number', part);
        }

        final response = await query.order('order_index', ascending: true);

        if (response.isNotEmpty) {
          return (response as List<dynamic>)
              .map((item) => VideoModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      } catch (e) {
        debugPrint('[VideoService] Database fetch notice: $e');
      }
    }

    return [];
  }
}
