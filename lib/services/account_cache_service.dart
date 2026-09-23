import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'device_service.dart';
import 'offline_manager.dart';

/// Subject Mastery Performance Model
class SubjectMasteryData {
  final String id;
  final String nameEn;
  final String nameAm;
  final int averageScore;
  final int completedUnits;
  final int totalQuestions;
  final int correctCount;

  const SubjectMasteryData({
    required this.id,
    required this.nameEn,
    required this.nameAm,
    required this.averageScore,
    required this.completedUnits,
    this.totalQuestions = 0,
    this.correctCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nameEn': nameEn,
        'nameAm': nameAm,
        'averageScore': averageScore,
        'completedUnits': completedUnits,
        'totalQuestions': totalQuestions,
        'correctCount': correctCount,
      };

  factory SubjectMasteryData.fromJson(Map<String, dynamic> json) => SubjectMasteryData(
        id: json['id']?.toString() ?? '',
        nameEn: json['nameEn']?.toString() ?? '',
        nameAm: json['nameAm']?.toString() ?? '',
        averageScore: json['averageScore'] is int
            ? json['averageScore']
            : int.tryParse(json['averageScore']?.toString() ?? '0') ?? 0,
        completedUnits: json['completedUnits'] is int
            ? json['completedUnits']
            : int.tryParse(json['completedUnits']?.toString() ?? '0') ?? 0,
        totalQuestions: json['totalQuestions'] is int
            ? json['totalQuestions']
            : int.tryParse(json['totalQuestions']?.toString() ?? '0') ?? 0,
        correctCount: json['correctCount'] is int
            ? json['correctCount']
            : int.tryParse(json['correctCount']?.toString() ?? '0') ?? 0,
      );
}

/// Snapshot of User Account and Analytics
class AccountSnapshotModel {
  final String studentName;
  final String phoneNumber;
  final int grade;
  final String stream;
  final String deviceId;
  final String subscriptionStatus;
  final Set<String> unlockedPackages;
  final int totalQuizzesTaken;
  final int totalQuestionsSolved;
  final int correctAnswersCount;
  final int highestScore;
  final int totalStudyMinutes;
  final int streakDays;
  final DateTime lastActiveDate;
  final List<double> weeklyStudyHours;
  final List<SubjectMasteryData> subjectMastery;
  final DateTime? lastSyncTime;

  const AccountSnapshotModel({
    required this.studentName,
    required this.phoneNumber,
    required this.grade,
    required this.stream,
    required this.deviceId,
    required this.subscriptionStatus,
    required this.unlockedPackages,
    required this.totalQuizzesTaken,
    required this.totalQuestionsSolved,
    required this.correctAnswersCount,
    required this.highestScore,
    required this.totalStudyMinutes,
    required this.streakDays,
    required this.lastActiveDate,
    required this.weeklyStudyHours,
    required this.subjectMastery,
    this.lastSyncTime,
  });

  /// Accuracy percentage calculation (0 to 100)
  double get accuracyPercentage {
    if (totalQuestionsSolved == 0) return 0.0;
    return ((correctAnswersCount / totalQuestionsSolved) * 100).clamp(0.0, 100.0);
  }

  /// Total study hours formatted
  double get totalStudyHours => (totalStudyMinutes / 60.0);

  bool get isSubscribed =>
      subscriptionStatus.toLowerCase() == 'active' || unlockedPackages.isNotEmpty;
}

/// High-Performance Local Caching & Sync Service for User Profile & Academic Analytics
class AccountCacheService {
  static SharedPreferences? _prefs;
  static AccountSnapshotModel? _inMemorySnapshot;

  /// Ensures SharedPreferences is initialized
  static Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Synchronous retrieval of cached account snapshot (0ms latency, instant UI load)
  static AccountSnapshotModel getAccountSnapshotSync({
    String defaultName = 'Student',
    String defaultPhone = '',
    int defaultGrade = 12,
  }) {
    if (_inMemorySnapshot != null) {
      return _inMemorySnapshot!;
    }

    if (_prefs != null) {
      return _buildSnapshotFromPrefs(_prefs!, defaultName, defaultPhone, defaultGrade);
    }

    // Fallback default snapshot
    return AccountSnapshotModel(
      studentName: defaultName,
      phoneNumber: defaultPhone,
      grade: defaultGrade,
      stream: 'Natural',
      deviceId: '',
      subscriptionStatus: 'free',
      unlockedPackages: {},
      totalQuizzesTaken: 0,
      totalQuestionsSolved: 0,
      correctAnswersCount: 0,
      highestScore: 0,
      totalStudyMinutes: 0,
      streakDays: 1,
      lastActiveDate: DateTime.now(),
      weeklyStudyHours: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
      subjectMastery: _getDefaultSubjectMastery(),
      lastSyncTime: null,
    );
  }

  /// Loads account snapshot asynchronously from SharedPreferences and primes memory cache
  static Future<AccountSnapshotModel> loadAccountSnapshot({
    String defaultName = 'Student',
    String defaultPhone = '',
    int defaultGrade = 12,
  }) async {
    final prefs = await _getPrefs();
    _inMemorySnapshot = _buildSnapshotFromPrefs(prefs, defaultName, defaultPhone, defaultGrade);
    return _inMemorySnapshot!;
  }

  static AccountSnapshotModel _buildSnapshotFromPrefs(
    SharedPreferences prefs,
    String defaultName,
    String defaultPhone,
    int defaultGrade,
  ) {
    final name = prefs.getString('user_fullName') ??
        prefs.getString('user_name') ??
        prefs.getString('cached_student_name') ??
        defaultName;

    final phone = prefs.getString('user_phoneNumber') ??
        prefs.getString('phone_number') ??
        prefs.getString('cached_student_phone') ??
        defaultPhone;

    final grade = prefs.getInt('selected_grade_preference') ??
        prefs.getInt('user_grade') ??
        prefs.getInt('cached_student_grade') ??
        defaultGrade;

    final stream = prefs.getString('user_stream') ?? prefs.getString('cached_student_stream') ?? 'Natural';
    final devId = prefs.getString('device_hardware_id') ?? '';
    final subStatus = prefs.getString('subscription_status') ?? 'free';

    // Unlocked packages
    final List<String> pkgList = prefs.getStringList('unlocked_packages_list') ??
        prefs.getStringList('unlocked_packages') ??
        [];
    final Set<String> unlockedPkgs = pkgList.toSet();

    // Stats
    int totalQuizzes = prefs.getInt('stat_total_quizzes_taken') ?? 0;
    int totalQuestions = prefs.getInt('stat_total_questions_solved') ?? 0;
    int correctCount = prefs.getInt('stat_correct_answers_count') ?? 0;
    int highestScore = prefs.getInt('stat_highest_score') ?? 0;
    int totalMinutes = prefs.getInt('stat_total_study_minutes') ?? 0;
    int streakDays = prefs.getInt('stat_streak_days') ?? 1;

    final lastActiveStr = prefs.getString('stat_last_active_date');
    final DateTime lastActive = lastActiveStr != null
        ? (DateTime.tryParse(lastActiveStr) ?? DateTime.now())
        : DateTime.now();

    // Reconstruct stats from best_score_ and quiz_score_ if primary counter is zero
    if (totalQuizzes == 0) {
      final keys = prefs.getKeys();
      for (final k in keys) {
        if (k.startsWith('best_score_') || k.startsWith('quiz_score_')) {
          final s = prefs.getInt(k) ?? 0;
          if (s > 0) {
            totalQuizzes++;
            totalQuestions += 10;
            correctCount += ((s / 100.0) * 10).round();
            if (s > highestScore) highestScore = s;
          }
        }
      }
      if (totalMinutes == 0 && totalQuizzes > 0) {
        totalMinutes = totalQuizzes * 12;
      }
    }

    // Weekly study hours (7 days: Mon-Sun)
    List<double> weeklyHours = [];
    for (int i = 0; i < 7; i++) {
      weeklyHours.add(prefs.getDouble('study_hours_day_$i') ?? 0.0);
    }
    // If all zeroes but has quizzes, distribute proportionally
    if (weeklyHours.every((h) => h == 0.0) && totalMinutes > 0) {
      final todayIndex = (DateTime.now().weekday - 1).clamp(0, 6);
      weeklyHours[todayIndex] = (totalMinutes / 60.0).clamp(0.5, 4.0);
    }

    // Subject mastery
    List<SubjectMasteryData> masteryList = [];
    final masteryJson = prefs.getString('cached_subject_mastery_json');
    if (masteryJson != null && masteryJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(masteryJson);
        masteryList = decoded.map((e) => SubjectMasteryData.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    if (masteryList.isEmpty) {
      masteryList = _computeSubjectMasteryFromScores(prefs);
    }

    final syncStr = prefs.getString('cached_last_sync_time');
    final DateTime? lastSync = syncStr != null ? DateTime.tryParse(syncStr) : null;

    final snapshot = AccountSnapshotModel(
      studentName: name,
      phoneNumber: phone,
      grade: grade,
      stream: stream,
      deviceId: devId,
      subscriptionStatus: subStatus,
      unlockedPackages: unlockedPkgs,
      totalQuizzesTaken: totalQuizzes,
      totalQuestionsSolved: totalQuestions,
      correctAnswersCount: correctCount,
      highestScore: highestScore,
      totalStudyMinutes: totalMinutes,
      streakDays: streakDays,
      lastActiveDate: lastActive,
      weeklyStudyHours: weeklyHours,
      subjectMastery: masteryList,
      lastSyncTime: lastSync,
    );

    _inMemorySnapshot = snapshot;
    return snapshot;
  }

  static List<SubjectMasteryData> _getDefaultSubjectMastery() {
    return const [
      SubjectMasteryData(id: 'Mathematics', nameEn: 'Mathematics', nameAm: 'ሂሳብ', averageScore: 0, completedUnits: 0),
      SubjectMasteryData(id: 'Physics', nameEn: 'Physics', nameAm: 'ፊዚክስ', averageScore: 0, completedUnits: 0),
      SubjectMasteryData(id: 'Chemistry', nameEn: 'Chemistry', nameAm: 'ኬሚስትሪ', averageScore: 0, completedUnits: 0),
      SubjectMasteryData(id: 'Biology', nameEn: 'Biology', nameAm: 'ስነ-ህይወት', averageScore: 0, completedUnits: 0),
      SubjectMasteryData(id: 'English', nameEn: 'English', nameAm: 'እንግሊዝኛ', averageScore: 0, completedUnits: 0),
      SubjectMasteryData(id: 'Civics', nameEn: 'Civics', nameAm: 'ስነ-ዜጋ', averageScore: 0, completedUnits: 0),
      SubjectMasteryData(id: 'Agriculture', nameEn: 'Agriculture', nameAm: 'ግብርና', averageScore: 0, completedUnits: 0),
    ];
  }

  static List<SubjectMasteryData> _computeSubjectMasteryFromScores(SharedPreferences prefs) {
    final Map<String, List<int>> subjectScores = {
      'Mathematics': [],
      'Physics': [],
      'Chemistry': [],
      'Biology': [],
      'English': [],
      'Civics': [],
      'Agriculture': [],
    };

    final Map<String, String> amNames = {
      'Mathematics': 'ሂሳብ',
      'Physics': 'ፊዚክስ',
      'Chemistry': 'ኬሚስትሪ',
      'Biology': 'ስነ-ህይወት',
      'English': 'እንግሊዝኛ',
      'Civics': 'ስነ-ዜጋ',
      'Agriculture': 'ግብርና',
    };

    final keys = prefs.getKeys();
    for (final k in keys) {
      if (k.startsWith('best_score_') || k.startsWith('quiz_score_')) {
        final val = prefs.getInt(k) ?? 0;
        if (val > 0) {
          for (final sub in subjectScores.keys) {
            if (k.toLowerCase().contains(sub.toLowerCase())) {
              subjectScores[sub]!.add(val);
              break;
            }
          }
        }
      }
    }

    final List<SubjectMasteryData> results = [];
    for (final entry in subjectScores.entries) {
      final scores = entry.value;
      final avg = scores.isNotEmpty ? (scores.reduce((a, b) => a + b) / scores.length).round() : 0;
      results.add(
        SubjectMasteryData(
          id: entry.key,
          nameEn: entry.key,
          nameAm: amNames[entry.key] ?? entry.key,
          averageScore: avg,
          completedUnits: scores.length,
          totalQuestions: scores.length * 10,
          correctCount: scores.isNotEmpty ? ((avg / 100.0) * scores.length * 10).round() : 0,
        ),
      );
    }

    return results;
  }

  /// Records a newly completed quiz session instantly into cache & analytics
  static Future<void> recordQuizCompletion({
    required String subject,
    required int grade,
    required int unit,
    required int score,
    required int totalQuestions,
    required int correctCount,
    int durationMinutes = 10,
  }) async {
    final prefs = await _getPrefs();

    // 1. Update overall counters
    int totalQuizzes = (prefs.getInt('stat_total_quizzes_taken') ?? 0) + 1;
    int totalQuestionsSolved = (prefs.getInt('stat_total_questions_solved') ?? 0) + totalQuestions;
    int totalCorrect = (prefs.getInt('stat_correct_answers_count') ?? 0) + correctCount;
    int currentHighest = prefs.getInt('stat_highest_score') ?? 0;
    if (score > currentHighest) {
      currentHighest = score;
    }
    int totalMinutes = (prefs.getInt('stat_total_study_minutes') ?? 0) + durationMinutes;

    // 2. Update streak
    final now = DateTime.now();
    final lastActiveStr = prefs.getString('stat_last_active_date');
    int streak = prefs.getInt('stat_streak_days') ?? 1;
    if (lastActiveStr != null) {
      final lastActive = DateTime.tryParse(lastActiveStr);
      if (lastActive != null) {
        final diffDays = now.difference(lastActive).inDays;
        if (diffDays == 1) {
          streak += 1;
        } else if (diffDays > 1) {
          streak = 1;
        }
      }
    }

    // 3. Update day's study hours
    final int todayIdx = (now.weekday - 1).clamp(0, 6);
    final double currentDayHours = prefs.getDouble('study_hours_day_$todayIdx') ?? 0.0;
    final double newDayHours = currentDayHours + (durationMinutes / 60.0);

    // Write to SharedPreferences
    await prefs.setInt('stat_total_quizzes_taken', totalQuizzes);
    await prefs.setInt('stat_total_questions_solved', totalQuestionsSolved);
    await prefs.setInt('stat_correct_answers_count', totalCorrect);
    await prefs.setInt('stat_highest_score', currentHighest);
    await prefs.setInt('stat_total_study_minutes', totalMinutes);
    await prefs.setInt('stat_streak_days', streak);
    await prefs.setString('stat_last_active_date', now.toIso8601String());
    await prefs.setDouble('study_hours_day_$todayIdx', newDayHours);

    // Save individual unit score key
    final cleanSubject = subject.replaceAll(' ', '_').toLowerCase();
    final unitKey = 'best_score_${grade}_${cleanSubject}_u$unit';
    final existingUnitScore = prefs.getInt(unitKey) ?? 0;
    if (score > existingUnitScore) {
      await prefs.setInt(unitKey, score);
    }

    // 4. Recompute and cache subject mastery
    final mastery = _computeSubjectMasteryFromScores(prefs);
    final masteryJson = jsonEncode(mastery.map((m) => m.toJson()).toList());
    await prefs.setString('cached_subject_mastery_json', masteryJson);

    // 5. Update in-memory snapshot
    _inMemorySnapshot = _buildSnapshotFromPrefs(prefs, 'Student', '', grade);

    if (kDebugMode) {
      debugPrint('[AccountCacheService] Quiz recorded: $subject Unit $unit (Score: $score%). Total quizzes: $totalQuizzes');
    }
  }

  /// Syncs cached student data with Supabase in the background
  static Future<AccountSnapshotModel> syncWithServer() async {
    final prefs = await _getPrefs();
    final bool hasNet = await OfflineManager.isNetworkAvailable();

    if (hasNet) {
      try {
        final String? phone = prefs.getString('user_phoneNumber') ?? prefs.getString('phone_number');
        if (phone != null && phone.isNotEmpty) {
          final devId = await DeviceService.getDeviceId();
          final client = Supabase.instance.client;

          final studentData = await client
              .from('students')
              .select('*')
              .eq('phone_number', phone)
              .maybeSingle();

          if (studentData != null) {
            final name = studentData['full_name']?.toString() ?? '';
            final subStatus = studentData['subscription_status']?.toString() ?? 'free';
            final grade = studentData['grade'] is int
                ? studentData['grade']
                : int.tryParse(studentData['grade']?.toString() ?? '12') ?? 12;
            final stream = studentData['stream']?.toString() ?? 'Natural';

            final rawPkgs = studentData['unlocked_packages'];
            final List<String> pkgs = [];
            if (rawPkgs is List) {
              pkgs.addAll(rawPkgs.map((e) => e.toString()));
            }

            // Update local cache
            if (name.isNotEmpty) await prefs.setString('user_fullName', name);
            await prefs.setString('subscription_status', subStatus);
            await prefs.setInt('user_grade', grade);
            await prefs.setString('user_stream', stream);
            await prefs.setStringList('unlocked_packages_list', pkgs);
            await prefs.setString('device_hardware_id', devId);
            await prefs.setString('cached_last_sync_time', DateTime.now().toIso8601String());
          }
        }
      } catch (e) {
        debugPrint('[AccountCacheService] Background sync note: $e');
      }
    }

    return await loadAccountSnapshot();
  }

  /// Clears local user profile and cached stats
  static Future<void> clearUserCache() async {
    final prefs = await _getPrefs();
    await prefs.remove('user_fullName');
    await prefs.remove('user_name');
    await prefs.remove('user_phoneNumber');
    await prefs.remove('phone_number');
    await prefs.remove('is_authenticated');
    await prefs.remove('unlocked_packages_list');
    await prefs.remove('subscription_status');
    await prefs.remove('cached_subject_mastery_json');
    await prefs.remove('cached_last_sync_time');
    _inMemorySnapshot = null;
  }
}
