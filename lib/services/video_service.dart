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

  /// Built-in curated 1 free sample masterclass preview video per grade
  static List<VideoModel> _getSampleVideosForGrade(int grade, String? subject) {
    final Map<int, VideoModel> sampleByGrade = {
      9: VideoModel(
        id: 'sample_g9_vid',
        grade: 9,
        subject: 'Mathematics',
        unitNumber: 1,
        title: 'Grade 9 Mathematics - Unit 1: The Number System [Sample Preview]',
        youtubeVideoId: 'dQw4w9WgXcQ',
        durationText: '24 mins',
        orderIndex: 1,
      ),
      10: VideoModel(
        id: 'sample_g10_vid',
        grade: 10,
        subject: 'Physics',
        unitNumber: 1,
        title: 'Grade 10 Physics - Unit 1: Vector Quantities & Motion [Sample Preview]',
        youtubeVideoId: 'dQw4w9WgXcQ',
        durationText: '28 mins',
        orderIndex: 1,
      ),
      11: VideoModel(
        id: 'sample_g11_vid',
        grade: 11,
        subject: 'Chemistry',
        unitNumber: 1,
        title: 'Grade 11 Chemistry - Unit 1: Atomic Structure & Bonding [Sample Preview]',
        youtubeVideoId: 'dQw4w9WgXcQ',
        durationText: '32 mins',
        orderIndex: 1,
      ),
      12: VideoModel(
        id: 'sample_g12_vid',
        grade: 12,
        subject: 'Mathematics',
        unitNumber: 1,
        title: 'Grade 12 Mathematics - Unit 1: Sequences & Series [Sample Preview]',
        youtubeVideoId: 'dQw4w9WgXcQ',
        durationText: '35 mins',
        orderIndex: 1,
      ),
    };

    final sample = sampleByGrade[grade];
    if (sample != null) {
      if (subject == null || subject.toLowerCase() == 'all' || subject.toLowerCase() == sample.subject.toLowerCase()) {
        return [sample];
      }
    }
    return [];
  }

  /// Fetches video lessons from database with fallback 1 sample video per grade.
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
        debugPrint('[VideoService] Database fetch notice: $e');
      }
    }

    // 1 Free Sample Video per Grade as requested by user
    return _getSampleVideosForGrade(grade, subject);
  }
}
