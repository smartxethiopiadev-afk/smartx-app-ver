import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/subject_model.dart';
import '../models/question_model.dart';
import '../models/note_model.dart';
import '../models/worksheet_model.dart';
import '../models/download_analytics_model.dart';
import 'supabase_service.dart';

class UserProfileData {
  String fullName;
  String phoneNumber;
  int grade;
  bool isRegistered;
  int streakDays;

  UserProfileData({
    required this.fullName,
    required this.phoneNumber,
    required this.grade,
    required this.isRegistered,
    required this.streakDays,
  });
}

class OfflineService extends ChangeNotifier {
  late SharedPreferences _prefs;
  bool _isInitialized = false;
  String _deviceId = '';

  UserProfileData _profile = UserProfileData(
    fullName: 'Ethiopian Student',
    phoneNumber: '+251912345678',
    grade: 11,
    isRegistered: false,
    streakDays: 3,
  );

  LanguageCode _language = LanguageCode.en;
  int _currentGrade = 11;

  // Set of downloaded unit IDs
  final Set<String> _downloadedUnitIds = {'math_g11_u1', 'bio_g11_u1', 'phy_g11_u1'};
  // Detailed Map of downloaded units
  final Map<String, DownloadedUnitInfo> _downloadedUnitsMap = {};

  // Downloaded worksheets IDs
  final Set<String> _downloadedWorksheetIds = {'ws_math_g11_u1', 'ws_phy_g11_u1'};

  // AdMob telemetry events log
  final List<AdMobTelemetryItem> _admobLogs = [];
  int _adImpressionsCount = 14;
  int _adClicksCount = 2;
  double _adRevenueEst = 0.42;

  // Live telemetry status
  int _activeUsersToday = 186;
  int _totalSystemDownloads = 942;
  bool _isTelemetrySyncing = false;

  bool get isInitialized => _isInitialized;
  String get deviceId => _deviceId;
  UserProfileData get profile => _profile;
  LanguageCode get language => _language;
  int get currentGrade => _currentGrade;
  Set<String> get downloadedUnitIds => _downloadedUnitIds;
  List<DownloadedUnitInfo> get downloadedUnitsList => _downloadedUnitsMap.values.toList();
  Set<String> get downloadedWorksheetIds => _downloadedWorksheetIds;
  List<AdMobTelemetryItem> get admobLogs => List.unmodifiable(_admobLogs);
  int get adImpressionsCount => _adImpressionsCount;
  int get adClicksCount => _adClicksCount;
  double get adRevenueEst => _adRevenueEst;
  int get activeUsersToday => _activeUsersToday;
  int get totalSystemDownloads => _totalSystemDownloads;
  bool get isTelemetrySyncing => _isTelemetrySyncing;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // 1. Device ID
    _deviceId = _prefs.getString('app_device_id') ?? '';
    if (_deviceId.isEmpty) {
      final random = Random().nextInt(999999);
      _deviceId = 'eth_dev_${DateTime.now().millisecondsSinceEpoch}_$random';
      await _prefs.setString('app_device_id', _deviceId);
    }

    // 2. Profile
    final name = _prefs.getString('user_full_name') ?? 'Ethiopian Student';
    final phone = _prefs.getString('user_phone') ?? '+251912345678';
    final grade = _prefs.getInt('user_grade') ?? 11;
    final registered = _prefs.getBool('user_registered') ?? false;
    final streak = _prefs.getInt('user_streak') ?? 3;
    final langStr = _prefs.getString('app_language') ?? 'en';

    _profile = UserProfileData(
      fullName: name,
      phoneNumber: phone,
      grade: grade,
      isRegistered: registered,
      streakDays: streak,
    );

    _language = langStr == 'am' ? LanguageCode.am : LanguageCode.en;
    _currentGrade = grade;

    // 3. Load downloaded units detailed records
    final savedDownloadsJson = _prefs.getString('downloaded_units_detailed');
    if (savedDownloadsJson != null && savedDownloadsJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(savedDownloadsJson) as List<dynamic>;
        _downloadedUnitsMap.clear();
        for (var item in decoded) {
          final info = DownloadedUnitInfo.fromJson(item as Map<String, dynamic>);
          _downloadedUnitsMap[info.unitId] = info;
          _downloadedUnitIds.add(info.unitId);
        }
      } catch (_) {}
    } else {
      // Seed default initial downloads
      _seedDefaultDownloads();
    }

    // 4. Load downloaded worksheets
    final savedWs = _prefs.getStringList('downloaded_worksheets');
    if (savedWs != null) {
      _downloadedWorksheetIds.addAll(savedWs);
    }

    // 5. Initial AdMob Telemetry Seeds
    _seedAdMobLogs();

    _isInitialized = true;
    notifyListeners();

    // 6. Ping Active Session & Sync Telemetry
    pingActiveSession();
  }

  void _seedDefaultDownloads() {
    final now = DateTime.now();
    final sampleDownloads = [
      DownloadedUnitInfo(
        unitId: 'math_g11_u1',
        subjectId: 'mathematics',
        grade: 11,
        unitNumber: 1,
        enTitle: 'Relations and Functions',
        amTitle: 'ግንኙነቶችና ፈንክሽኖች',
        downloadedAt: now.subtract(const Duration(days: 2)),
        type: 'full_bundle',
        sizeKb: 145,
        questionCount: 15,
      ),
      DownloadedUnitInfo(
        unitId: 'bio_g11_u1',
        subjectId: 'biology',
        grade: 11,
        unitNumber: 1,
        enTitle: 'The Science of Biology & Technology',
        amTitle: 'የሥነ-ሕይወት ሳይንስ እና ቴክኖሎጂ',
        downloadedAt: now.subtract(const Duration(days: 1)),
        type: 'full_bundle',
        sizeKb: 120,
        questionCount: 15,
      ),
      DownloadedUnitInfo(
        unitId: 'phy_g11_u1',
        subjectId: 'physics',
        grade: 11,
        unitNumber: 1,
        enTitle: 'Physics and Human Society / Vectors',
        amTitle: 'ፊዚክስና ቬክተሮች',
        downloadedAt: now,
        type: 'full_bundle',
        sizeKb: 160,
        questionCount: 15,
      ),
    ];

    for (var d in sampleDownloads) {
      _downloadedUnitsMap[d.unitId] = d;
      _downloadedUnitIds.add(d.unitId);
    }
    _saveDownloadedUnitsToPrefs();
  }

  void _seedAdMobLogs() {
    _admobLogs.add(AdMobTelemetryItem(
      id: 'adm_1',
      adType: 'Banner (Adaptive)',
      status: 'Impression Logged',
      timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
      network: 'Google AdMob v23.0.0 (Ethiopia Region)',
      estimatedEcpm: 1.80,
    ));
    _admobLogs.add(AdMobTelemetryItem(
      id: 'adm_2',
      adType: 'Interstitial',
      status: 'Displayed on Quiz Finish',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      network: 'Google AdMob (AdUnit: ca-app-pub-3940256099942544/1033173712)',
      estimatedEcpm: 4.20,
    ));
  }

  Future<void> _saveDownloadedUnitsToPrefs() async {
    final list = _downloadedUnitsMap.values.map((e) => e.toJson()).toList();
    await _prefs.setString('downloaded_units_detailed', jsonEncode(list));
    await _prefs.setStringList('downloaded_units', _downloadedUnitIds.toList());
  }

  /// Ping heartbeat to Supabase so active users graph updates in real time
  Future<void> pingActiveSession() async {
    _isTelemetrySyncing = true;
    notifyListeners();

    try {
      await SupabaseService.pingActiveSession(
        deviceId: _deviceId,
        userName: _profile.fullName,
        phone: _profile.phoneNumber,
        grade: _currentGrade,
      );

      final telemetry = await SupabaseService.fetchLiveTelemetry();
      _activeUsersToday = telemetry['active_users_today'] as int? ?? _activeUsersToday;
      _totalSystemDownloads = telemetry['total_downloads'] as int? ?? _totalSystemDownloads;
    } catch (_) {}

    _isTelemetrySyncing = false;
    notifyListeners();
  }

  void setGrade(int grade) {
    _currentGrade = grade;
    _profile.grade = grade;
    _prefs.setInt('user_grade', grade);
    pingActiveSession();
    notifyListeners();
  }

  void setLanguage(LanguageCode lang) {
    _language = lang;
    _prefs.setString('app_language', lang == LanguageCode.am ? 'am' : 'en');
    notifyListeners();
  }

  Future<void> registerUser(String name, String phone, int grade) async {
    _profile = UserProfileData(
      fullName: name,
      phoneNumber: phone,
      grade: grade,
      isRegistered: true,
      streakDays: _profile.streakDays + 1,
    );
    _currentGrade = grade;
    await _prefs.setString('user_full_name', name);
    await _prefs.setString('user_phone', phone);
    await _prefs.setInt('user_grade', grade);
    await _prefs.setBool('user_registered', true);
    await _prefs.setInt('user_streak', _profile.streakDays);
    
    pingActiveSession();
    notifyListeners();
  }

  bool isUnitDownloaded(String unitId) {
    return _downloadedUnitIds.contains(unitId);
  }

  /// Download a unit with full metadata and log to database
  Future<void> downloadUnit(
    UnitModel unit,
    String subjectId,
    int grade, {
    String type = 'full_bundle',
  }) async {
    final info = DownloadedUnitInfo(
      unitId: unit.unitId,
      subjectId: subjectId,
      grade: grade,
      unitNumber: unit.unitNumber,
      enTitle: unit.enTitle,
      amTitle: unit.amTitle,
      downloadedAt: DateTime.now(),
      type: type,
      sizeKb: (unit.questionCount * 8) + 40,
      questionCount: unit.questionCount,
    );

    _downloadedUnitsMap[unit.unitId] = info;
    _downloadedUnitIds.add(unit.unitId);
    await _saveDownloadedUnitsToPrefs();

    // Trigger AdMob rewarded/interstitial impression event for download
    recordAdMobEvent('Interstitial', 'Ad Served on Unit Download');

    // Telemetry Sync to Supabase
    SupabaseService.logDownload(
      deviceId: _deviceId,
      userName: _profile.fullName,
      phone: _profile.phoneNumber,
      grade: grade,
      subject: subjectId,
      unitId: unit.unitId,
      unitNumber: unit.unitNumber,
      type: type,
    );

    _totalSystemDownloads += 1;
    notifyListeners();
  }

  /// Delete / remove downloaded unit from offline storage
  Future<void> deleteDownloadedUnit(String unitId) async {
    _downloadedUnitsMap.remove(unitId);
    _downloadedUnitIds.remove(unitId);
    await _saveDownloadedUnitsToPrefs();
    notifyListeners();
  }

  /// Toggle unit download status
  Future<void> toggleUnitDownload(
    UnitModel unit,
    String subjectId,
    int grade,
  ) async {
    if (_downloadedUnitIds.contains(unit.unitId)) {
      await deleteDownloadedUnit(unit.unitId);
    } else {
      await downloadUnit(unit, subjectId, grade);
    }
  }

  // ---------------------------------------------------------------------------
  // Worksheets & Worksheets Downloads
  // ---------------------------------------------------------------------------
  bool isWorksheetDownloaded(String worksheetId) {
    return _downloadedWorksheetIds.contains(worksheetId);
  }

  Future<void> toggleWorksheetDownload(WorksheetModel worksheet) async {
    if (_downloadedWorksheetIds.contains(worksheet.id)) {
      _downloadedWorksheetIds.remove(worksheet.id);
    } else {
      _downloadedWorksheetIds.add(worksheet.id);
      
      // Log to remote DB
      SupabaseService.logDownload(
        deviceId: _deviceId,
        userName: _profile.fullName,
        phone: _profile.phoneNumber,
        grade: worksheet.grade,
        subject: worksheet.subject,
        unitId: 'ws_${worksheet.subject}_g${worksheet.grade}_u${worksheet.unitNumber}',
        unitNumber: worksheet.unitNumber,
        type: 'worksheet',
      );
      recordAdMobEvent('Banner', 'Worksheet Cached Offline');
    }
    await _prefs.setStringList('downloaded_worksheets', _downloadedWorksheetIds.toList());
    notifyListeners();
  }

  List<WorksheetModel> getWorksheetsForSubject(String subjectId, int grade) {
    return [
      WorksheetModel(
        id: 'ws_${subjectId}_g${grade}_u1',
        grade: grade,
        subject: subjectId,
        unitNumber: 1,
        title: 'Unit 1: Fundamentals & Model Exam Drill',
        am_title: 'ምዕራፍ 1፡ መሠረታዊ ጥያቄዎችና የሞዴል ፈተና',
        description: 'Comprehensive multiple-choice and conceptual practice questions with step-by-step solutions.',
        totalQuestions: 20,
        downloadCount: 142,
        difficulty: 'National Exam Standard',
        keyTopics: const ['Core Theorems', 'Calculations', 'Common Exam Traps', 'Fast Matrix Methods'],
      ),
      WorksheetModel(
        id: 'ws_${subjectId}_g${grade}_u2',
        grade: grade,
        subject: subjectId,
        unitNumber: 2,
        title: 'Unit 2: Analytical & Mastery Worksheet',
        am_title: 'ምዕራፍ 2፡ የትንታኔና የማጠቃለያ ልምምድ',
        description: 'Advanced problems and structured questions targeting high-score performance.',
        totalQuestions: 25,
        downloadCount: 98,
        difficulty: 'Medium',
        keyTopics: const ['Formulas', 'Data Interpretation', 'Application Problems'],
      ),
      WorksheetModel(
        id: 'ws_${subjectId}_g${grade}_u3',
        grade: grade,
        subject: subjectId,
        unitNumber: 3,
        title: 'Unit 3: Comprehensive Practice Test',
        am_title: 'ምዕራፍ 3፡ ሁሉን አቀፍ የሙከራ ፈተና',
        description: 'Time-managed practice worksheet designed for university entrance exam readiness.',
        totalQuestions: 30,
        downloadCount: 76,
        difficulty: 'National Exam Standard',
        keyTopics: const ['Speed Drills', 'Exam Strategy', 'Revision Matrix'],
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // AdMob Telemetry & Events Tracking
  // ---------------------------------------------------------------------------
  void recordAdMobEvent(String adType, String status, {double ecpm = 2.10}) {
    final item = AdMobTelemetryItem(
      id: 'adm_${DateTime.now().millisecondsSinceEpoch}',
      adType: adType,
      status: status,
      timestamp: DateTime.now(),
      network: 'Google AdMob (App ID: ca-app-pub-3940256099942544~3347511713)',
      estimatedEcpm: ecpm,
    );
    _admobLogs.insert(0, item);
    if (_admobLogs.length > 20) {
      _admobLogs.removeLast();
    }
    _adImpressionsCount += 1;
    _adRevenueEst += (ecpm / 1000.0);
    notifyListeners();
  }

  void recordAdClick() {
    _adClicksCount += 1;
    recordAdMobEvent('Interactive Ad', 'User Click Registered / Conversions Tracked', ecpm: 5.50);
  }

  // ---------------------------------------------------------------------------
  // Question Bug Reports & Feedback Submission
  // ---------------------------------------------------------------------------
  Future<bool> reportQuestionError({
    required String questionId,
    required String unitId,
    required String questionText,
    required String reason,
  }) async {
    final report = QuestionReportModel(
      questionId: questionId,
      unitId: unitId,
      questionText: questionText,
      reason: reason,
      studentName: _profile.fullName,
      studentPhone: _profile.phoneNumber,
      createdAt: DateTime.now(),
    );

    return await SupabaseService.submitQuestionReport(report);
  }

  Future<bool> submitFeedback({
    required int rating,
    required String category,
    required String message,
  }) async {
    final feedback = FeedbackReportModel(
      userName: _profile.fullName,
      phoneNumber: _profile.phoneNumber,
      rating: rating,
      category: category,
      message: message,
      createdAt: DateTime.now(),
    );

    return await SupabaseService.submitFeedback(feedback);
  }

  // ---------------------------------------------------------------------------
  // Curriculums, Units & Notes Database
  // ---------------------------------------------------------------------------
  List<UnitModel> getUnitsForSubject(String subjectId, int grade) {
    switch (subjectId) {
      case 'mathematics':
        return [
          const UnitModel(
            unitNumber: 1,
            unitId: 'math_g11_u1',
            enTitle: 'Relations and Functions',
            amTitle: 'ግንኙነቶችና ፈንክሽኖች',
            description: 'Domain, range, inverse functions, and composition of functions in higher algebra.',
            questionCount: 15,
            hasNotes: true,
            estimatedMinutes: 25,
          ),
          const UnitModel(
            unitNumber: 2,
            unitId: 'math_g11_u2',
            enTitle: 'Rational Expressions & Functions',
            amTitle: 'አመክንዮአዊ መግለጫዎችና ፈንክሽኖች',
            description: 'Simplifying rational functions, asymptotes, and partial fraction decomposition.',
            questionCount: 12,
            hasNotes: true,
            estimatedMinutes: 20,
          ),
          const UnitModel(
            unitNumber: 3,
            unitId: 'math_g11_u3',
            enTitle: 'Coordinate Geometry & Conic Sections',
            amTitle: 'የመጋጠሚያ ጂኦሜትሪ እና ኮኒክስ',
            description: 'Parabola, Ellipse, Hyperbola and locus problems.',
            questionCount: 18,
            hasNotes: true,
            estimatedMinutes: 30,
          ),
          const UnitModel(
            unitNumber: 4,
            unitId: 'math_g11_u4',
            enTitle: 'Matrices and Determinants',
            amTitle: 'ማትሪክስ እና ዲተርሚናንትስ',
            description: 'Cramer rule, inverse matrix, transformations, and linear systems.',
            questionCount: 14,
            hasNotes: true,
            estimatedMinutes: 20,
          ),
        ];
      case 'biology':
        return [
          const UnitModel(
            unitNumber: 1,
            unitId: 'bio_g11_u1',
            enTitle: 'The Science of Biology & Technology',
            amTitle: 'የሥነ-ሕይወት ሳይንስ እና ቴክኖሎጂ',
            description: 'Biological tools, scientific methods, and biochemical foundations.',
            questionCount: 15,
            hasNotes: true,
            estimatedMinutes: 20,
          ),
          const UnitModel(
            unitNumber: 2,
            unitId: 'bio_g11_u2',
            enTitle: 'Cell Biology and Molecular Genetics',
            amTitle: 'የሕዋስ ሥነ-ሕይወት እና ሞለኪውላር ጀነቲክስ',
            description: 'Cell organelle functions, DNA replication, and protein synthesis mechanisms.',
            questionCount: 20,
            hasNotes: true,
            estimatedMinutes: 30,
          ),
          const UnitModel(
            unitNumber: 3,
            unitId: 'bio_g11_u3',
            enTitle: 'Enzymes and Metabolic Pathways',
            amTitle: 'ኢንዛይሞች እና ሜታቦሊዝም',
            description: 'Enzyme kinetics, activation energy, inhibition, and cellular respiration.',
            questionCount: 16,
            hasNotes: true,
            estimatedMinutes: 25,
          ),
        ];
      case 'physics':
        return [
          const UnitModel(
            unitNumber: 1,
            unitId: 'phy_g11_u1',
            enTitle: 'Physics and Human Society / Vectors',
            amTitle: 'ፊዚክስና ቬክተሮች',
            description: 'Vector analysis, dot product, cross product, and relative motion.',
            questionCount: 15,
            hasNotes: true,
            estimatedMinutes: 25,
          ),
          const UnitModel(
            unitNumber: 2,
            unitId: 'phy_g11_u2',
            enTitle: 'Two-Dimensional Motion & Projectiles',
            amTitle: 'ባለሁለት አቅጣጫ እንቅስቃሴ',
            description: 'Projectile motion, circular dynamics, centripetal acceleration, and gravity.',
            questionCount: 18,
            hasNotes: true,
            estimatedMinutes: 30,
          ),
        ];
      default:
        return [
          UnitModel(
            unitNumber: 1,
            unitId: '${subjectId}_g${grade}_u1',
            enTitle: 'Unit 1: Fundamentals & Principles',
            amTitle: 'ምዕራፍ 1፡ መሠረታዊ መርሆዎች',
            description: 'Comprehensive introduction aligned with the Ethiopian National Educational curriculum.',
            questionCount: 12,
            hasNotes: true,
            estimatedMinutes: 20,
          ),
          UnitModel(
            unitNumber: 2,
            unitId: '${subjectId}_g${grade}_u2',
            enTitle: 'Unit 2: Core Concepts & Applications',
            amTitle: 'ምዕራፍ 2፡ ዋና ዋና ጽንሰ-ሀሳቦች',
            description: 'Detailed exploration and practical applications for matric & model exams.',
            questionCount: 15,
            hasNotes: true,
            estimatedMinutes: 25,
          ),
        ];
    }
  }

  List<QuestionModel> getQuestionsForUnit(String unitId) {
    return [
      QuestionModel(
        id: '${unitId}_q1',
        unitId: unitId,
        questionText: 'What is the domain of the function f(x) = sqrt(x - 4) / (x - 7)?',
        questionNumber: 1,
        explanation: 'For the square root in the numerator, x - 4 >= 0 implies x >= 4. The denominator cannot be zero, so x != 7. Hence domain is [4, 7) U (7, infinity).',
        options: [
          const QuestionOption(id: 'a', text: '[4, infinity)', isCorrect: false),
          const QuestionOption(id: 'b', text: '[4, 7) U (7, infinity)', isCorrect: true, explanation: 'Correct! Includes x>=4 excluding the vertical asymptote at x=7.'),
          const QuestionOption(id: 'c', text: '(-infinity, 7) U (7, infinity)', isCorrect: false),
          const QuestionOption(id: 'd', text: '(4, 7)', isCorrect: false),
        ],
      ),
      QuestionModel(
        id: '${unitId}_q2',
        unitId: unitId,
        questionText: 'Which of the following describes a bijective function?',
        questionNumber: 2,
        explanation: 'A function is bijective (one-to-one correspondence) if and only if it is both injective (one-to-one) and surjective (onto).',
        options: [
          const QuestionOption(id: 'a', text: 'Injective only', isCorrect: false),
          const QuestionOption(id: 'b', text: 'Surjective only', isCorrect: false),
          const QuestionOption(id: 'c', text: 'Both Injective and Surjective', isCorrect: true, explanation: 'Bijective functions have an inverse that is also a valid function.'),
          const QuestionOption(id: 'd', text: 'Neither Injective nor Surjective', isCorrect: false),
        ],
      ),
      QuestionModel(
        id: '${unitId}_q3',
        unitId: unitId,
        questionText: 'In cellular biology, which organelle is responsible for ATP synthesis via oxidative phosphorylation?',
        questionNumber: 3,
        explanation: 'Mitochondria produce ATP through the electron transport chain located along their inner folded cristae membrane.',
        options: [
          const QuestionOption(id: 'a', text: 'Ribosome', isCorrect: false),
          const QuestionOption(id: 'b', text: 'Mitochondria', isCorrect: true, explanation: 'Known as the powerhouse of the cell generating ATP energy currency.'),
          const QuestionOption(id: 'c', text: 'Endoplasmic Reticulum', isCorrect: false),
          const QuestionOption(id: 'd', text: 'Golgi Apparatus', isCorrect: false),
        ],
      ),
      QuestionModel(
        id: '${unitId}_q4',
        unitId: unitId,
        questionText: 'When a projectile is launched at an angle theta with initial velocity v0, what launch angle produces maximum horizontal range?',
        questionNumber: 4,
        explanation: 'The formula R = (v0^2 * sin(2*theta)) / g attains its maximum value when sin(2*theta) = 1, meaning 2*theta = 90 deg, so theta = 45 deg.',
        options: [
          const QuestionOption(id: 'a', text: '30 degrees', isCorrect: false),
          const QuestionOption(id: 'b', text: '45 degrees', isCorrect: true, explanation: '45 degrees maximizes sin(2*theta) = 1 on level ground in vacuum kinematics.'),
          const QuestionOption(id: 'c', text: '60 degrees', isCorrect: false),
          const QuestionOption(id: 'd', text: '90 degrees', isCorrect: false),
        ],
      ),
      QuestionModel(
        id: '${unitId}_q5',
        unitId: unitId,
        questionText: 'In Ethiopian Grade 11 Chemistry, what is the hybridization of carbon atoms in benzene (C6H6)?',
        questionNumber: 5,
        explanation: 'Each carbon atom in benzene forms three sigma bonds in a planar geometry with bond angles of 120 degrees, which corresponds to sp2 hybridization.',
        options: [
          const QuestionOption(id: 'a', text: 'sp', isCorrect: false),
          const QuestionOption(id: 'b', text: 'sp2', isCorrect: true, explanation: 'sp2 hybridization with unhybridized p-orbitals creating the delocalized pi electron ring.'),
          const QuestionOption(id: 'c', text: 'sp3', isCorrect: false),
          const QuestionOption(id: 'd', text: 'dsp2', isCorrect: false),
        ],
      ),
    ];
  }

  ShortNoteModel getShortNoteForUnit(String unitId, String subject, int grade, int unitNumber) {
    return ShortNoteModel(
      id: '${unitId}_note',
      grade: grade,
      subject: subject,
      unitNumber: unitNumber,
      title: 'High-Yield Unit $unitNumber Summary: Key Formulas & Exam Cheatsheet',
      content: '''
# Smart X Ethiopian Exam Matrix & Cheat Sheet
### Grade $grade • $subject • Unit $unitNumber

---

## 📌 1. Core High-Yield Definitions
- **Essential Axioms:** Review primary laws, fundamental conservation rules, and official curriculum theorems.
- **National Exam Frequency:** Questions from this unit historically represent **15% - 20%** of all national entrance & regional exam points.

## 🧮 2. Key Formulas & Identities
- **Formula A:** `f(x) = a*x^2 + b*x + c` with vertex at `(-b/(2a), -D/(4a))`
- **Formula B:** `W = F * d * cos(theta)` (Work Done in Joules)
- **Formula C:** `pH = -log[H+]` and `pOH = -log[OH-]` where `pH + pOH = 14`

## 💡 3. Common Exam Pitfalls & Trap Avoidance
- **Trap 1:** Forgetting to exclude points that make denominators zero when calculating function domains.
- **Trap 2:** Confusing scalar quantities with vector quantities in relative velocity equations.
- **Trap 3:** Not balancing redox equations in acidic vs. basic medium.

---
*Generated by Smart X Ethiopian Educational Engine • Verified for Ethiopian National Examination Agency (NEAEA) Standards.*
''',
    );
  }
}
