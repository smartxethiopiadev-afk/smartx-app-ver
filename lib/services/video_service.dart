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

  /// Built-in curated video lessons per grade divided by units and parts
  static List<VideoModel> _getSampleVideosForGrade(int grade, String? subject, {int? unit, int? part}) {
    final List<VideoModel> allGradeVideos = [
      // ================= GRADE 9 =================
      // Grade 9 Math Unit 1 Parts
      VideoModel(
        id: 'g9_math_u1_p1',
        grade: 9,
        subject: 'Mathematics',
        unitNumber: 1,
        partNumber: 1,
        title: 'Grade 9 Mathematics - Unit 1 (Part 1): The Number System & Real Numbers',
        youtubeVideoId: 'b-4XYRX9dcU',
        durationText: '24 mins',
        orderIndex: 1,
      ),
      VideoModel(
        id: 'g9_math_u1_p2',
        grade: 9,
        subject: 'Mathematics',
        unitNumber: 1,
        partNumber: 2,
        title: 'Grade 9 Mathematics - Unit 1 (Part 2): Operations on Radicals & Indices',
        youtubeVideoId: 'b-4XYRX9dcU',
        durationText: '26 mins',
        orderIndex: 2,
      ),
      VideoModel(
        id: 'g9_math_u1_p3',
        grade: 9,
        subject: 'Mathematics',
        unitNumber: 1,
        partNumber: 3,
        title: 'Grade 9 Mathematics - Unit 1 (Part 3): Past Exam Solved Questions',
        youtubeVideoId: 'b-4XYRX9dcU',
        durationText: '22 mins',
        orderIndex: 3,
      ),
      // Grade 9 Math Unit 2 Parts
      VideoModel(
        id: 'g9_math_u2_p1',
        grade: 9,
        subject: 'Mathematics',
        unitNumber: 2,
        partNumber: 1,
        title: 'Grade 9 Mathematics - Unit 2 (Part 1): Equations & Inequalities',
        youtubeVideoId: 'b-4XYRX9dcU',
        durationText: '28 mins',
        orderIndex: 4,
      ),
      VideoModel(
        id: 'g9_math_u2_p2',
        grade: 9,
        subject: 'Mathematics',
        unitNumber: 2,
        partNumber: 2,
        title: 'Grade 9 Mathematics - Unit 2 (Part 2): Quadratic Equations & Graphs',
        youtubeVideoId: 'b-4XYRX9dcU',
        durationText: '30 mins',
        orderIndex: 5,
      ),
      // Grade 9 Physics Unit 1 Parts
      VideoModel(
        id: 'g9_phys_u1_p1',
        grade: 9,
        subject: 'Physics',
        unitNumber: 1,
        partNumber: 1,
        title: 'Grade 9 Physics - Unit 1 (Part 1): Physics & Human Society',
        youtubeVideoId: 'b-4XYRX9dcU',
        durationText: '22 mins',
        orderIndex: 6,
      ),
      VideoModel(
        id: 'g9_phys_u1_p2',
        grade: 9,
        subject: 'Physics',
        unitNumber: 1,
        partNumber: 2,
        title: 'Grade 9 Physics - Unit 1 (Part 2): Scientific Methods & Laboratory',
        youtubeVideoId: 'b-4XYRX9dcU',
        durationText: '19 mins',
        orderIndex: 7,
      ),
      // Grade 9 Chemistry Unit 1 Parts
      VideoModel(
        id: 'g9_chem_u1_p1',
        grade: 9,
        subject: 'Chemistry',
        unitNumber: 1,
        partNumber: 1,
        title: 'Grade 9 Chemistry - Unit 1 (Part 1): Structure of the Atom',
        youtubeVideoId: 'b-4XYRX9dcU',
        durationText: '25 mins',
        orderIndex: 8,
      ),
      VideoModel(
        id: 'g9_chem_u1_p2',
        grade: 9,
        subject: 'Chemistry',
        unitNumber: 1,
        partNumber: 2,
        title: 'Grade 9 Chemistry - Unit 1 (Part 2): Electronic Configuration & Periodic Table',
        youtubeVideoId: 'b-4XYRX9dcU',
        durationText: '27 mins',
        orderIndex: 9,
      ),
      // Grade 9 Biology Unit 1 Parts
      VideoModel(
        id: 'g9_bio_u1_p1',
        grade: 9,
        subject: 'Biology',
        unitNumber: 1,
        partNumber: 1,
        title: 'Grade 9 Biology - Unit 1 (Part 1): Introduction to Biology & Cell Theory',
        youtubeVideoId: 'b-4XYRX9dcU',
        durationText: '21 mins',
        orderIndex: 10,
      ),
      VideoModel(
        id: 'g9_bio_u1_p2',
        grade: 9,
        subject: 'Biology',
        unitNumber: 1,
        partNumber: 2,
        title: 'Grade 9 Biology - Unit 1 (Part 2): Microscope Skills & Organelles',
        youtubeVideoId: 'b-4XYRX9dcU',
        durationText: '23 mins',
        orderIndex: 11,
      ),

      // ================= GRADE 10 =================
      // Grade 10 Physics Unit 1 Parts
      VideoModel(
        id: 'g10_phys_u1_p1',
        grade: 10,
        subject: 'Physics',
        unitNumber: 1,
        partNumber: 1,
        title: 'Grade 10 Physics - Unit 1 (Part 1): Vector Quantities & Components',
        youtubeVideoId: 'b-4XYRX9dcU',
        durationText: '28 mins',
        orderIndex: 1,
      ),
      VideoModel(
        id: 'g10_phys_u1_p2',
        grade: 10,
        subject: 'Physics',
        unitNumber: 1,
        partNumber: 2,
        title: 'Grade 10 Physics - Unit 1 (Part 2): Motion in One & Two Dimensions',
        youtubeVideoId: 'b-4XYRX9dcU',
        durationText: '30 mins',
        orderIndex: 2,
      ),
      // Grade 10 Math Unit 1 Parts
      VideoModel(
        id: 'g10_math_u1_p1',
        grade: 10,
        subject: 'Mathematics',
        unitNumber: 1,
        partNumber: 1,
        title: 'Grade 10 Mathematics - Unit 1 (Part 1): Relations & Inverses',
        youtubeVideoId: 'b-4XYRX9dcU',
        durationText: '32 mins',
        orderIndex: 3,
      ),
      VideoModel(
        id: 'g10_math_u1_p2',
        grade: 10,
        subject: 'Mathematics',
        unitNumber: 1,
        partNumber: 2,
        title: 'Grade 10 Mathematics - Unit 1 (Part 2): Domain, Range & Graphs of Functions',
        youtubeVideoId: 'b-4XYRX9dcU',
        durationText: '29 mins',
        orderIndex: 4,
      ),
      // Grade 10 Chemistry Unit 1 Parts
      VideoModel(
        id: 'g10_chem_u1_p1',
        grade: 10,
        subject: 'Chemistry',
        unitNumber: 1,
        partNumber: 1,
        title: 'Grade 10 Chemistry - Unit 1 (Part 1): Chemical Reactions & Balancing Equations',
        youtubeVideoId: 'b-4XYRX9dcU',
        durationText: '31 mins',
        orderIndex: 5,
      ),
      VideoModel(
        id: 'g10_chem_u1_p2',
        grade: 10,
        subject: 'Chemistry',
        unitNumber: 1,
        partNumber: 2,
        title: 'Grade 10 Chemistry - Unit 1 (Part 2): Stoichiometry & Mole Calculations',
        youtubeVideoId: 'b-4XYRX9dcU',
        durationText: '33 mins',
        orderIndex: 6,
      ),

      // ================= GRADE 11 =================
      // Grade 11 Chemistry Unit 1 Parts
      VideoModel(
        id: 'g11_chem_u1_p1',
        grade: 11,
        subject: 'Chemistry',
        unitNumber: 1,
        partNumber: 1,
        title: 'Grade 11 Chemistry - Unit 1 (Part 1): Atomic Structure & Quantum Numbers',
        youtubeVideoId: 'yZ8Qtu6EfGQ',
        durationText: '35 mins',
        orderIndex: 1,
      ),
      VideoModel(
        id: 'g11_chem_u1_p2',
        grade: 11,
        subject: 'Chemistry',
        unitNumber: 1,
        partNumber: 2,
        title: 'Grade 11 Chemistry - Unit 1 (Part 2): Electromagnetic Radiation & Bohr Model',
        youtubeVideoId: 'yZ8Qtu6EfGQ',
        durationText: '38 mins',
        orderIndex: 2,
      ),
      // Grade 11 Math Unit 1 Parts
      VideoModel(
        id: 'g11_math_u1_p1',
        grade: 11,
        subject: 'Mathematics',
        unitNumber: 1,
        partNumber: 1,
        title: 'Grade 11 Mathematics - Unit 1 (Part 1): Further on Relations and Functions',
        youtubeVideoId: 'yZ8Qtu6EfGQ',
        durationText: '40 mins',
        orderIndex: 3,
      ),
      VideoModel(
        id: 'g11_math_u1_p2',
        grade: 11,
        subject: 'Mathematics',
        unitNumber: 1,
        partNumber: 2,
        title: 'Grade 11 Mathematics - Unit 1 (Part 2): Composition of Functions & Inverse Functions',
        youtubeVideoId: 'yZ8Qtu6EfGQ',
        durationText: '36 mins',
        orderIndex: 4,
      ),
      // Grade 11 Physics Unit 1 Parts
      VideoModel(
        id: 'g11_phys_u1_p1',
        grade: 11,
        subject: 'Physics',
        unitNumber: 1,
        partNumber: 1,
        title: 'Grade 11 Physics - Unit 1 (Part 1): Measurement & Practical Work',
        youtubeVideoId: 'yZ8Qtu6EfGQ',
        durationText: '30 mins',
        orderIndex: 5,
      ),
      VideoModel(
        id: 'g11_phys_u1_p2',
        grade: 11,
        subject: 'Physics',
        unitNumber: 1,
        partNumber: 2,
        title: 'Grade 11 Physics - Unit 1 (Part 2): Uncertainty & Vector Calculations',
        youtubeVideoId: 'yZ8Qtu6EfGQ',
        durationText: '34 mins',
        orderIndex: 6,
      ),

      // ================= GRADE 12 =================
      // Grade 12 Math Unit 1 Parts
      VideoModel(
        id: 'g12_math_u1_p1',
        grade: 12,
        subject: 'Mathematics',
        unitNumber: 1,
        partNumber: 1,
        title: 'Grade 12 Mathematics - Unit 1 (Part 1): Sequences & Arithmetic Progressions',
        youtubeVideoId: 'yZ8Qtu6EfGQ',
        durationText: '42 mins',
        orderIndex: 1,
      ),
      VideoModel(
        id: 'g12_math_u1_p2',
        grade: 12,
        subject: 'Mathematics',
        unitNumber: 1,
        partNumber: 2,
        title: 'Grade 12 Mathematics - Unit 1 (Part 2): Geometric Series & Sigma Notation',
        youtubeVideoId: 'yZ8Qtu6EfGQ',
        durationText: '45 mins',
        orderIndex: 2,
      ),
      VideoModel(
        id: 'g12_math_u1_p3',
        grade: 12,
        subject: 'Mathematics',
        unitNumber: 1,
        partNumber: 3,
        title: 'Grade 12 Mathematics - Unit 1 (Part 3): Matric Exam Solved Questions',
        youtubeVideoId: 'yZ8Qtu6EfGQ',
        durationText: '48 mins',
        orderIndex: 3,
      ),
      // Grade 12 Physics Unit 1 Parts
      VideoModel(
        id: 'g12_phys_u1_p1',
        grade: 12,
        subject: 'Physics',
        unitNumber: 1,
        partNumber: 1,
        title: 'Grade 12 Physics - Unit 1 (Part 1): Thermodynamics & Heat Capacity',
        youtubeVideoId: 'yZ8Qtu6EfGQ',
        durationText: '36 mins',
        orderIndex: 4,
      ),
      VideoModel(
        id: 'g12_phys_u1_p2',
        grade: 12,
        subject: 'Physics',
        unitNumber: 1,
        partNumber: 2,
        title: 'Grade 12 Physics - Unit 1 (Part 2): First & Second Laws of Thermodynamics',
        youtubeVideoId: 'yZ8Qtu6EfGQ',
        durationText: '39 mins',
        orderIndex: 5,
      ),
      // Grade 12 Chemistry Unit 1 Parts
      VideoModel(
        id: 'g12_chem_u1_p1',
        grade: 12,
        subject: 'Chemistry',
        unitNumber: 1,
        partNumber: 1,
        title: 'Grade 12 Chemistry - Unit 1 (Part 1): Acid-Base Equilibria & pH Calculations',
        youtubeVideoId: 'yZ8Qtu6EfGQ',
        durationText: '38 mins',
        orderIndex: 6,
      ),
      VideoModel(
        id: 'g12_chem_u1_p2',
        grade: 12,
        subject: 'Chemistry',
        unitNumber: 1,
        partNumber: 2,
        title: 'Grade 12 Chemistry - Unit 1 (Part 2): Buffer Solutions & Titration Curves',
        youtubeVideoId: 'yZ8Qtu6EfGQ',
        durationText: '41 mins',
        orderIndex: 7,
      ),
      // Grade 12 Biology Unit 1 Parts
      VideoModel(
        id: 'g12_bio_u1_p1',
        grade: 12,
        subject: 'Biology',
        unitNumber: 1,
        partNumber: 1,
        title: 'Grade 12 Biology - Unit 1 (Part 1): Genetics & DNA Replication Mechanisms',
        youtubeVideoId: 'yZ8Qtu6EfGQ',
        durationText: '33 mins',
        orderIndex: 8,
      ),
      VideoModel(
        id: 'g12_bio_u1_p2',
        grade: 12,
        subject: 'Biology',
        unitNumber: 1,
        partNumber: 2,
        title: 'Grade 12 Biology - Unit 1 (Part 2): Mendelian Genetics & Inheritance Patterns',
        youtubeVideoId: 'yZ8Qtu6EfGQ',
        durationText: '37 mins',
        orderIndex: 9,
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
      if (part != null && part > 0) {
        if (v.partNumber != part) return false;
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

  /// Fetches video lessons from database with fallback curated sample videos.
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

    // Curated Video Lessons organized by Unit & Part per Grade
    return _getSampleVideosForGrade(grade, subject, unit: unit, part: part);
  }
}
