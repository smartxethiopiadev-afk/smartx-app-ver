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

  /// Built-in curated video lessons per grade divided by units
  static List<VideoModel> _getSampleVideosForGrade(int grade, String? subject, {int? unit}) {
    final List<VideoModel> allGradeVideos = [
      // Grade 9
      VideoModel(
        id: 'g9_math_u1',
        grade: 9,
        subject: 'Mathematics',
        unitNumber: 1,
        title: 'Grade 9 Mathematics - Unit 1: The Number System Full Lesson',
        youtubeVideoId: 'b-4XYRX9dcU',
        durationText: '24 mins',
        orderIndex: 1,
      ),
      VideoModel(
        id: 'g9_math_u2',
        grade: 9,
        subject: 'Mathematics',
        unitNumber: 2,
        title: 'Grade 9 Mathematics - Unit 2: Equations & Inequalities',
        youtubeVideoId: 'b-4XYRX9dcU',
        durationText: '28 mins',
        orderIndex: 2,
      ),
      VideoModel(
        id: 'g9_phys_u1',
        grade: 9,
        subject: 'Physics',
        unitNumber: 1,
        title: 'Grade 9 Physics - Unit 1: Physics & Human Society',
        youtubeVideoId: 'b-4XYRX9dcU',
        durationText: '22 mins',
        orderIndex: 3,
      ),
      VideoModel(
        id: 'g9_phys_u2',
        grade: 9,
        subject: 'Physics',
        unitNumber: 2,
        title: 'Grade 9 Physics - Unit 2: Physical Quantities & Measurement',
        youtubeVideoId: 'b-4XYRX9dcU',
        durationText: '26 mins',
        orderIndex: 4,
      ),
      VideoModel(
        id: 'g9_chem_u1',
        grade: 9,
        subject: 'Chemistry',
        unitNumber: 1,
        title: 'Grade 9 Chemistry - Unit 1: Structure of the Atom',
        youtubeVideoId: 'b-4XYRX9dcU',
        durationText: '25 mins',
        orderIndex: 5,
      ),
      VideoModel(
        id: 'g9_bio_u1',
        grade: 9,
        subject: 'Biology',
        unitNumber: 1,
        title: 'Grade 9 Biology - Unit 1: Introduction to Biology & Ecology',
        youtubeVideoId: 'b-4XYRX9dcU',
        durationText: '21 mins',
        orderIndex: 6,
      ),
      VideoModel(
        id: 'g9_civ_u1',
        grade: 9,
        subject: 'Civics',
        unitNumber: 1,
        title: 'Grade 9 Civics - Unit 1: Democratic System & Human Rights',
        youtubeVideoId: 'b-4XYRX9dcU',
        durationText: '18 mins',
        orderIndex: 7,
      ),

      // Grade 10
      VideoModel(
        id: 'g10_phys_u1',
        grade: 10,
        subject: 'Physics',
        unitNumber: 1,
        title: 'Grade 10 Physics - Unit 1: Vector Quantities & Motion in 1D',
        youtubeVideoId: 'b-4XYRX9dcU',
        durationText: '28 mins',
        orderIndex: 1,
      ),
      VideoModel(
        id: 'g10_phys_u2',
        grade: 10,
        subject: 'Physics',
        unitNumber: 2,
        title: 'Grade 10 Physics - Unit 2: Dynamics & Newton\'s Laws',
        youtubeVideoId: 'b-4XYRX9dcU',
        durationText: '30 mins',
        orderIndex: 2,
      ),
      VideoModel(
        id: 'g10_math_u1',
        grade: 10,
        subject: 'Mathematics',
        unitNumber: 1,
        title: 'Grade 10 Mathematics - Unit 1: Relations and Functions',
        youtubeVideoId: 'b-4XYRX9dcU',
        durationText: '32 mins',
        orderIndex: 3,
      ),
      VideoModel(
        id: 'g10_math_u2',
        grade: 10,
        subject: 'Mathematics',
        unitNumber: 2,
        title: 'Grade 10 Mathematics - Unit 2: Polynomial Functions',
        youtubeVideoId: 'b-4XYRX9dcU',
        durationText: '27 mins',
        orderIndex: 4,
      ),
      VideoModel(
        id: 'g10_chem_u1',
        grade: 10,
        subject: 'Chemistry',
        unitNumber: 1,
        title: 'Grade 10 Chemistry - Unit 1: Chemical Reactions & Stoichiometry',
        youtubeVideoId: 'b-4XYRX9dcU',
        durationText: '31 mins',
        orderIndex: 5,
      ),
      VideoModel(
        id: 'g10_bio_u1',
        grade: 10,
        subject: 'Biology',
        unitNumber: 1,
        title: 'Grade 10 Biology - Unit 1: Sub-fields of Biology & Cells',
        youtubeVideoId: 'b-4XYRX9dcU',
        durationText: '20 mins',
        orderIndex: 6,
      ),

      // Grade 11
      VideoModel(
        id: 'g11_chem_u1',
        grade: 11,
        subject: 'Chemistry',
        unitNumber: 1,
        title: 'Grade 11 Chemistry - Unit 1: Atomic Structure & Quantum Mechanics',
        youtubeVideoId: 'yZ8Qtu6EfGQ',
        durationText: '35 mins',
        orderIndex: 1,
      ),
      VideoModel(
        id: 'g11_chem_u2',
        grade: 11,
        subject: 'Chemistry',
        unitNumber: 2,
        title: 'Grade 11 Chemistry - Unit 2: Chemical Bonding & Intermolecular Forces',
        youtubeVideoId: 'yZ8Qtu6EfGQ',
        durationText: '38 mins',
        orderIndex: 2,
      ),
      VideoModel(
        id: 'g11_math_u1',
        grade: 11,
        subject: 'Mathematics',
        unitNumber: 1,
        title: 'Grade 11 Mathematics - Unit 1: Further on Relations and Functions',
        youtubeVideoId: 'yZ8Qtu6EfGQ',
        durationText: '40 mins',
        orderIndex: 3,
      ),
      VideoModel(
        id: 'g11_math_u2',
        grade: 11,
        subject: 'Mathematics',
        unitNumber: 2,
        title: 'Grade 11 Mathematics - Unit 2: Rational Expressions & Functions',
        youtubeVideoId: 'yZ8Qtu6EfGQ',
        durationText: '34 mins',
        orderIndex: 4,
      ),
      VideoModel(
        id: 'g11_phys_u1',
        grade: 11,
        subject: 'Physics',
        unitNumber: 1,
        title: 'Grade 11 Physics - Unit 1: Measurement & Practical Work',
        youtubeVideoId: 'yZ8Qtu6EfGQ',
        durationText: '30 mins',
        orderIndex: 5,
      ),
      VideoModel(
        id: 'g11_bio_u1',
        grade: 11,
        subject: 'Biology',
        unitNumber: 1,
        title: 'Grade 11 Biology - Unit 1: The Science of Biology & Biomolecules',
        youtubeVideoId: 'yZ8Qtu6EfGQ',
        durationText: '29 mins',
        orderIndex: 6,
      ),
      VideoModel(
        id: 'g11_agri_u1',
        grade: 11,
        subject: 'Agriculture',
        unitNumber: 1,
        title: 'Grade 11 Agriculture - Unit 1: General Agriculture & Soil Science',
        youtubeVideoId: 'yZ8Qtu6EfGQ',
        durationText: '24 mins',
        orderIndex: 7,
      ),

      // Grade 12
      VideoModel(
        id: 'g12_math_u1',
        grade: 12,
        subject: 'Mathematics',
        unitNumber: 1,
        title: 'Grade 12 Mathematics - Unit 1: Sequences and Series Comprehensive Review',
        youtubeVideoId: 'yZ8Qtu6EfGQ',
        durationText: '42 mins',
        orderIndex: 1,
      ),
      VideoModel(
        id: 'g12_math_u2',
        grade: 12,
        subject: 'Mathematics',
        unitNumber: 2,
        title: 'Grade 12 Mathematics - Unit 2: Introduction to Calculus & Limits',
        youtubeVideoId: 'yZ8Qtu6EfGQ',
        durationText: '45 mins',
        orderIndex: 2,
      ),
      VideoModel(
        id: 'g12_phys_u1',
        grade: 12,
        subject: 'Physics',
        unitNumber: 1,
        title: 'Grade 12 Physics - Unit 1: Thermodynamics & Gas Laws',
        youtubeVideoId: 'yZ8Qtu6EfGQ',
        durationText: '36 mins',
        orderIndex: 3,
      ),
      VideoModel(
        id: 'g12_chem_u1',
        grade: 12,
        subject: 'Chemistry',
        unitNumber: 1,
        title: 'Grade 12 Chemistry - Unit 1: Acid-Base Equilibria & pH Calculation',
        youtubeVideoId: 'yZ8Qtu6EfGQ',
        durationText: '38 mins',
        orderIndex: 4,
      ),
      VideoModel(
        id: 'g12_bio_u1',
        grade: 12,
        subject: 'Biology',
        unitNumber: 1,
        title: 'Grade 12 Biology - Unit 1: Genetics, DNA Replication & Heredity',
        youtubeVideoId: 'yZ8Qtu6EfGQ',
        durationText: '33 mins',
        orderIndex: 5,
      ),
      VideoModel(
        id: 'g12_agri_u1',
        grade: 12,
        subject: 'Agriculture',
        unitNumber: 1,
        title: 'Grade 12 Agriculture - Unit 1: Crop Production & Agricultural Economics',
        youtubeVideoId: 'yZ8Qtu6EfGQ',
        durationText: '26 mins',
        orderIndex: 6,
      ),
    ];

    return allGradeVideos.where((v) {
      if (v.grade != grade) return false;
      if (subject != null && subject.trim().isNotEmpty && subject.toLowerCase() != 'all') {
        final norm = _normalizeSubject(subject);
        if (!v.subject.toLowerCase().contains(norm.toLowerCase()) &&
            !norm.toLowerCase().contains(v.subject.toLowerCase())) {
          return false;
        }
      }
      if (unit != null && unit > 0) {
        if (v.unitNumber != unit) return false;
      }
      return true;
    }).toList();
  }

  /// App Overview Tutorial Video
  static VideoModel getAppOverviewVideo() {
    return VideoModel(
      id: 'app_overview_video',
      grade: 0,
      subject: 'Tutorial',
      unitNumber: 1,
      title: 'Ethio Concept Center መተግበሪያ አጠቃቀም ሙሉ ገለፃ (App Overview & Master Tutorial)',
      youtubeVideoId: 'uYX1-IqlFzM',
      durationText: 'Full Tutorial',
      orderIndex: 0,
    );
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

    // Curated Video Lessons organized by Unit per Grade
    return _getSampleVideosForGrade(grade, subject, unit: unit);
  }
}
