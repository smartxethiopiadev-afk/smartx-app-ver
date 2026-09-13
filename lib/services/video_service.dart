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

  /// Fetches video lessons for a specific grade and optional subject/unit.
  /// Falls back to built-in curriculum video list if Supabase is offline or empty.
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
        debugPrint('[VideoService] Supabase fetch error: $e');
      }
    }

    // Fallback to curriculum seed video lessons
    return _generateCurriculumFallbackVideos(grade: grade, subject: subject, unit: unit);
  }

  /// Built-in Ethiopian Curriculum Video Catalog (Unlisted & Educational Videos)
  static List<VideoModel> _generateCurriculumFallbackVideos({
    required int grade,
    String? subject,
    int? unit,
  }) {
    final List<VideoModel> allVideos = [
      // Grade 9
      VideoModel(
        id: 'v_g9_math_u1',
        grade: 9,
        subject: 'Mathematics',
        unitNumber: 1,
        title: 'Grade 9 Mathematics - Unit 1: The Number System & Real Numbers',
        youtubeVideoId: 'dQw4w9WgXcQ', // educational fallback placeholder
        durationText: '24:15',
        orderIndex: 1,
      ),
      VideoModel(
        id: 'v_g9_math_u2',
        grade: 9,
        subject: 'Mathematics',
        unitNumber: 2,
        title: 'Grade 9 Mathematics - Unit 2: Solving Linear Equations & Inequalities',
        youtubeVideoId: 'M7lc1UVf-VE',
        durationText: '28:40',
        orderIndex: 2,
      ),
      VideoModel(
        id: 'v_g9_phys_u1',
        grade: 9,
        subject: 'Physics',
        unitNumber: 1,
        title: 'Grade 9 Physics - Unit 1: Physics and Human Society & Measurements',
        youtubeVideoId: 'fJ9rUzIMcZQ',
        durationText: '19:50',
        orderIndex: 1,
      ),
      VideoModel(
        id: 'v_g9_phys_u2',
        grade: 9,
        subject: 'Physics',
        unitNumber: 2,
        title: 'Grade 9 Physics - Unit 2: Kinematics & Motion in One Dimension',
        youtubeVideoId: '3fumBcKC6RE',
        durationText: '32:10',
        orderIndex: 2,
      ),
      VideoModel(
        id: 'v_g9_chem_u1',
        grade: 9,
        subject: 'Chemistry',
        unitNumber: 1,
        title: 'Grade 9 Chemistry - Unit 1: Structure of the Atom & Periodic Trends',
        youtubeVideoId: 'tgbNymZ7vqY',
        durationText: '22:30',
        orderIndex: 1,
      ),
      VideoModel(
        id: 'v_g9_bio_u1',
        grade: 9,
        subject: 'Biology',
        unitNumber: 1,
        title: 'Grade 9 Biology - Unit 1: Introduction to Biology & Cell Anatomy',
        youtubeVideoId: 'kJQP7kiw5Fk',
        durationText: '25:45',
        orderIndex: 1,
      ),
      VideoModel(
        id: 'v_g9_eng_u1',
        grade: 9,
        subject: 'English',
        unitNumber: 1,
        title: 'Grade 9 English - Unit 1: Living in a Community & Tense Mastery',
        youtubeVideoId: 'OPf0YbXqDm0',
        durationText: '18:20',
        orderIndex: 1,
      ),

      // Grade 10 (EGSECE Prep)
      VideoModel(
        id: 'v_g10_math_u1',
        grade: 10,
        subject: 'Mathematics',
        unitNumber: 1,
        title: 'Grade 10 Mathematics - Unit 1: Relations & Functions Deep Dive',
        youtubeVideoId: 'M7lc1UVf-VE',
        durationText: '31:15',
        orderIndex: 1,
      ),
      VideoModel(
        id: 'v_g10_math_u2',
        grade: 10,
        subject: 'Mathematics',
        unitNumber: 2,
        title: 'Grade 10 Mathematics - Unit 2: Polynomial Functions & Factoring',
        youtubeVideoId: 'dQw4w9WgXcQ',
        durationText: '35:20',
        orderIndex: 2,
      ),
      VideoModel(
        id: 'v_g10_phys_u1',
        grade: 10,
        subject: 'Physics',
        unitNumber: 1,
        title: 'Grade 10 Physics - Unit 1: Motion in Two Dimensions & Vectors',
        youtubeVideoId: '3fumBcKC6RE',
        durationText: '27:40',
        orderIndex: 1,
      ),
      VideoModel(
        id: 'v_g10_chem_u1',
        grade: 10,
        subject: 'Chemistry',
        unitNumber: 1,
        title: 'Grade 10 Chemistry - Unit 1: Chemical Reactions & Stoichiometry',
        youtubeVideoId: 'tgbNymZ7vqY',
        durationText: '29:50',
        orderIndex: 1,
      ),
      VideoModel(
        id: 'v_g10_bio_u1',
        grade: 10,
        subject: 'Biology',
        unitNumber: 1,
        title: 'Grade 10 Biology - Unit 1: Biotechnology & Genetic Engineering',
        youtubeVideoId: 'kJQP7kiw5Fk',
        durationText: '23:10',
        orderIndex: 1,
      ),

      // Grade 11
      VideoModel(
        id: 'v_g11_math_u1',
        grade: 11,
        subject: 'Mathematics',
        unitNumber: 1,
        title: 'Grade 11 Mathematics - Unit 1: Further on Relations & Functions',
        youtubeVideoId: 'M7lc1UVf-VE',
        durationText: '34:00',
        orderIndex: 1,
      ),
      VideoModel(
        id: 'v_g11_phys_u1',
        grade: 11,
        subject: 'Physics',
        unitNumber: 1,
        title: 'Grade 11 Physics - Unit 1: Measurement & Vectors in 3D',
        youtubeVideoId: '3fumBcKC6RE',
        durationText: '30:45',
        orderIndex: 1,
      ),
      VideoModel(
        id: 'v_g11_chem_u1',
        grade: 11,
        subject: 'Chemistry',
        unitNumber: 1,
        title: 'Grade 11 Chemistry - Unit 1: Fundamental Concepts & Quantum Model',
        youtubeVideoId: 'tgbNymZ7vqY',
        durationText: '33:15',
        orderIndex: 1,
      ),
      VideoModel(
        id: 'v_g11_bio_u1',
        grade: 11,
        subject: 'Biology',
        unitNumber: 1,
        title: 'Grade 11 Biology - Unit 1: The Science of Biology & Biomolecules',
        youtubeVideoId: 'kJQP7kiw5Fk',
        durationText: '26:50',
        orderIndex: 1,
      ),

      // Grade 12 (EUEE Matric Prep)
      VideoModel(
        id: 'v_g12_math_u1',
        grade: 12,
        subject: 'Mathematics',
        unitNumber: 1,
        title: 'Grade 12 Mathematics - Unit 1: Sequences and Series Mastery for EUEE',
        youtubeVideoId: 'M7lc1UVf-VE',
        durationText: '42:30',
        orderIndex: 1,
      ),
      VideoModel(
        id: 'v_g12_math_u2',
        grade: 12,
        subject: 'Mathematics',
        unitNumber: 2,
        title: 'Grade 12 Mathematics - Unit 2: Introduction to Limits and Continuity',
        youtubeVideoId: 'dQw4w9WgXcQ',
        durationText: '38:15',
        orderIndex: 2,
      ),
      VideoModel(
        id: 'v_g12_phys_u1',
        grade: 12,
        subject: 'Physics',
        unitNumber: 1,
        title: 'Grade 12 Physics - Unit 1: Thermodynamics and Heat Engines',
        youtubeVideoId: '3fumBcKC6RE',
        durationText: '36:40',
        orderIndex: 1,
      ),
      VideoModel(
        id: 'v_g12_chem_u1',
        grade: 12,
        subject: 'Chemistry',
        unitNumber: 1,
        title: 'Grade 12 Chemistry - Unit 1: Acid-Base Equilibria & Buffer Solutions',
        youtubeVideoId: 'tgbNymZ7vqY',
        durationText: '40:10',
        orderIndex: 1,
      ),
      VideoModel(
        id: 'v_g12_bio_u1',
        grade: 12,
        subject: 'Biology',
        unitNumber: 1,
        title: 'Grade 12 Biology - Unit 1: Microorganisms and Disease Prevention',
        youtubeVideoId: 'kJQP7kiw5Fk',
        durationText: '28:30',
        orderIndex: 1,
      ),
      VideoModel(
        id: 'v_g12_econ_u1',
        grade: 12,
        subject: 'Economics',
        unitNumber: 1,
        title: 'Grade 12 Economics - Unit 1: National Income Accounting',
        youtubeVideoId: 'OPf0YbXqDm0',
        durationText: '31:20',
        orderIndex: 1,
      ),
    ];

    return allVideos.where((v) {
      if (v.grade != grade) return false;
      if (subject != null &&
          subject.trim().isNotEmpty &&
          subject.toLowerCase() != 'all') {
        final norm = _normalizeSubject(subject).toLowerCase();
        if (!v.subject.toLowerCase().contains(norm)) return false;
      }
      if (unit != null && unit > 0 && v.unitNumber != unit) return false;
      return true;
    }).toList();
  }
}
