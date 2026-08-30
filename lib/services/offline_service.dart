import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/subject_model.dart';
import '../models/question_model.dart';
import '../models/note_model.dart';
import '../models/note_chunk_helper.dart';
import '../models/worksheet_model.dart';
import '../models/download_analytics_model.dart';
import 'google_analytics_service.dart';
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
  final Set<String> _downloadedWorksheetIds = {'ws_mathematics_g11_u1', 'ws_physics_g11_u1'};

  // AdMob telemetry events log
  final List<AdMobTelemetryItem> _admobLogs = [];
  int _adImpressionsCount = 18;
  int _adClicksCount = 3;
  double _adRevenueEst = 0.58;

  // Google Analytics Real-time Telemetry state
  int _activeUsersToday = 312;
  int _activeUsersNow = 48;
  int _totalSystemDownloads = 984;
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
  int get activeUsersNow => _activeUsersNow;
  int get totalSystemDownloads => _totalSystemDownloads;
  bool get isTelemetrySyncing => _isTelemetrySyncing;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // 1. Initialize Google Analytics Service
    GoogleAnalyticsService.init();

    // 2. Device ID
    _deviceId = _prefs.getString('app_device_id') ?? '';
    if (_deviceId.isEmpty) {
      final random = Random().nextInt(999999);
      _deviceId = 'eth_dev_${DateTime.now().millisecondsSinceEpoch}_$random';
      await _prefs.setString('app_device_id', _deviceId);
    }

    // 3. Profile
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

    // 4. Load downloaded units detailed records
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
      _seedDefaultDownloads();
    }

    // 5. Load downloaded worksheets
    final savedWs = _prefs.getStringList('downloaded_worksheets');
    if (savedWs != null) {
      _downloadedWorksheetIds.addAll(savedWs);
    }

    // 6. Initial AdMob Telemetry Seeds
    _seedAdMobLogs();

    _isInitialized = true;
    notifyListeners();

    // 7. Ping Active Session to Google Analytics
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
        enTitle: 'The Science of Biology & Cytology',
        amTitle: 'የሥነ-ሕይወት ሳይንስ እና ሴል',
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
        enTitle: 'Vectors & 2D Kinematics',
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

  /// Ping heartbeat directly to Google Analytics GA4
  Future<void> pingActiveSession() async {
    _isTelemetrySyncing = true;
    notifyListeners();

    try {
      await GoogleAnalyticsService.logActiveSessionPing(
        deviceId: _deviceId,
        userName: _profile.fullName,
        grade: _currentGrade,
        language: _language == LanguageCode.am ? 'am' : 'en',
      );

      _activeUsersNow = GoogleAnalyticsService.activeUsersNow;
      _activeUsersToday = GoogleAnalyticsService.activeUsersToday;
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

    GoogleAnalyticsService.logEvent(
      eventName: 'sign_up',
      deviceId: _deviceId,
      parameters: {'user_name': name, 'grade': grade},
      userId: phone,
    );

    pingActiveSession();
    notifyListeners();
  }

  bool isUnitDownloaded(String unitId) {
    return _downloadedUnitIds.contains(unitId);
  }

  /// Download a unit with full metadata and log to Google Analytics
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

    // Telemetry Sync to Google Analytics
    GoogleAnalyticsService.logEvent(
      eventName: 'unit_downloaded',
      deviceId: _deviceId,
      parameters: {
        'unit_id': unit.unitId,
        'subject': subjectId,
        'grade': grade,
        'unit_number': unit.unitNumber,
        'type': type,
      },
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
      
      // Log to Google Analytics
      GoogleAnalyticsService.logEvent(
        eventName: 'worksheet_cached',
        deviceId: _deviceId,
        parameters: {
          'worksheet_id': worksheet.id,
          'subject': worksheet.subject,
          'grade': worksheet.grade,
          'unit_number': worksheet.unitNumber,
        },
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
        amTitle: 'ምዕራፍ 1፡ መሠረታዊ ጥያቄዎችና የሞዴል ፈተና',
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
        amTitle: 'ምዕራፍ 2፡ የትንታኔና የማጠቃለያ ልምምድ',
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
        amTitle: 'ምዕራፍ 3፡ ሁሉን አቀፍ የሙከራ ፈተና',
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

    GoogleAnalyticsService.logAppError(
      errorType: 'Question_Report',
      errorMessage: reason,
      contextScreen: 'QuizScreen_$unitId',
      deviceId: _deviceId,
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
  // Curriculums, Units & Notes Database (All remaining core subjects)
  // ---------------------------------------------------------------------------
  List<UnitModel> getUnitsForSubject(String subjectId, int grade) {
    switch (subjectId) {
      case 'mathematics':
        return [
          UnitModel(
            unitNumber: 1,
            unitId: 'math_g${grade}_u1',
            enTitle: grade == 11 ? 'Relations and Functions' : 'Number Systems & Foundations',
            amTitle: grade == 11 ? 'ግንኙነቶችና ፈንክሽኖች' : 'የቁጥር ሥርዓቶችና መሠረቶች',
            description: 'Domain, range, inverse functions, and composition of functions in higher algebra.',
            questionCount: 15,
            hasNotes: true,
            estimatedMinutes: 25,
          ),
          UnitModel(
            unitNumber: 2,
            unitId: 'math_g${grade}_u2',
            enTitle: grade == 11 ? 'Rational Expressions & Functions' : 'Polynomial Expressions',
            amTitle: grade == 11 ? 'አመክንዮአዊ መግለጫዎችና ፈንክሽኖች' : 'ፖሊኖሚያል መግለጫዎች',
            description: 'Simplifying rational functions, asymptotes, and partial fraction decomposition.',
            questionCount: 12,
            hasNotes: true,
            estimatedMinutes: 20,
          ),
          UnitModel(
            unitNumber: 3,
            unitId: 'math_g${grade}_u3',
            enTitle: grade == 11 ? 'Coordinate Geometry & Conic Sections' : 'Exponential & Logarithmic Functions',
            amTitle: grade == 11 ? 'የመጋጠሚያ ጂኦሜትሪ እና ኮኒክስ' : 'ኤክስፖኔንሻል እና ሎጋሪዝም',
            description: 'Parabola, Ellipse, Hyperbola and locus problems.',
            questionCount: 18,
            hasNotes: true,
            estimatedMinutes: 30,
          ),
          UnitModel(
            unitNumber: 4,
            unitId: 'math_g${grade}_u4',
            enTitle: grade == 11 ? 'Matrices and Determinants' : 'Trigonometry & Analytic Geometry',
            amTitle: grade == 11 ? 'ማትሪክስ እና ዲተርሚናንትስ' : 'ትሪጎኖሜትሪ',
            description: 'Cramer rule, inverse matrix, transformations, and linear systems.',
            questionCount: 14,
            hasNotes: true,
            estimatedMinutes: 20,
          ),
        ];
      case 'biology':
        return [
          UnitModel(
            unitNumber: 1,
            unitId: 'bio_g${grade}_u1',
            enTitle: 'The Science of Biology & Cytology',
            amTitle: 'የሥነ-ሕይወት ሳይንስ እና ሴል',
            description: 'Biological tools, cell theory, scientific methods, and biochemical foundations.',
            questionCount: 15,
            hasNotes: true,
            estimatedMinutes: 20,
          ),
          UnitModel(
            unitNumber: 2,
            unitId: 'bio_g${grade}_u2',
            enTitle: 'Cell Biology and Molecular Genetics',
            amTitle: 'የሕዋስ ሥነ-ሕይወት እና ሞለኪውላር ጀነቲክስ',
            description: 'Cell organelle functions, DNA replication, and protein synthesis mechanisms.',
            questionCount: 20,
            hasNotes: true,
            estimatedMinutes: 30,
          ),
          UnitModel(
            unitNumber: 3,
            unitId: 'bio_g${grade}_u3',
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
          UnitModel(
            unitNumber: 1,
            unitId: 'phy_g${grade}_u1',
            enTitle: 'Vectors & Two-Dimensional Kinematics',
            amTitle: 'ፊዚክስና ቬክተሮች',
            description: 'Vector analysis, dot product, cross product, and relative motion.',
            questionCount: 15,
            hasNotes: true,
            estimatedMinutes: 25,
          ),
          UnitModel(
            unitNumber: 2,
            unitId: 'phy_g${grade}_u2',
            enTitle: 'Two-Dimensional Motion & Dynamics',
            amTitle: 'ባለሁለት አቅጣጫ እንቅስቃሴ',
            description: 'Projectile motion, circular dynamics, centripetal acceleration, and gravity.',
            questionCount: 18,
            hasNotes: true,
            estimatedMinutes: 30,
          ),
        ];
      case 'chemistry':
        return [
          UnitModel(
            unitNumber: 1,
            unitId: 'chem_g${grade}_u1',
            enTitle: 'Atomic Structure and Periodic Table',
            amTitle: 'የአተም መዋቅር እና ፔሪዮዲክ ሰንጠረዥ',
            description: 'Quantum numbers, orbital configurations, periodic trends, and bonding.',
            questionCount: 16,
            hasNotes: true,
            estimatedMinutes: 25,
          ),
          UnitModel(
            unitNumber: 2,
            unitId: 'chem_g${grade}_u2',
            enTitle: 'Chemical Bonding & Molecular Geometry',
            amTitle: 'ኬሚካላዊ ትስስርና የሞለኪውል ቅርጽ',
            description: 'Ionic, covalent, and metallic bonds, VSEPR theory, and hybridization.',
            questionCount: 18,
            hasNotes: true,
            estimatedMinutes: 28,
          ),
        ];
      case 'history':
        return [
          UnitModel(
            unitNumber: 1,
            unitId: 'hist_g${grade}_u1',
            enTitle: 'Historiography & Human Evolution',
            amTitle: 'ታሪክ አጻጻፍ እና የሰው ልጅ አመጣጥ',
            description: 'Primary/secondary sources, prehistoric discoveries, and ancient settlements.',
            questionCount: 14,
            hasNotes: true,
            estimatedMinutes: 20,
          ),
          UnitModel(
            unitNumber: 2,
            unitId: 'hist_g${grade}_u2',
            enTitle: 'Ancient Civilizations & Axumite Kingdom',
            amTitle: 'ጥንታዊ ስልጣኔዎችና የአክሱም መንግሥት',
            description: 'Yeha, Axum, Zagwe, and trade routes along the Red Sea.',
            questionCount: 16,
            hasNotes: true,
            estimatedMinutes: 25,
          ),
        ];
      case 'geography':
        return [
          UnitModel(
            unitNumber: 1,
            unitId: 'geo_g${grade}_u1',
            enTitle: 'Geology & Landforms of Ethiopia',
            amTitle: 'የኢትዮጵያ ጂኦሎጂ እና የመሬት ገጽታ',
            description: 'Geological eras, rock formations, Ethiopian Rift Valley, and highlands.',
            questionCount: 15,
            hasNotes: true,
            estimatedMinutes: 22,
          ),
          UnitModel(
            unitNumber: 2,
            unitId: 'geo_g${grade}_u2',
            enTitle: 'Drainage Systems & Water Resources',
            amTitle: 'የውሃ ፍሳሽ ሥርዓቶችና የተፈጥሮ ሀብት',
            description: 'Major river basins (Abay, Baro, Awash) and Ethiopian Rift Valley lakes.',
            questionCount: 14,
            hasNotes: true,
            estimatedMinutes: 20,
          ),
        ];
      case 'economics':
        return [
          UnitModel(
            unitNumber: 1,
            unitId: 'econ_g${grade}_u1',
            enTitle: 'Foundations of Economics & Market Theory',
            amTitle: 'የኢኮኖሚክስ መሠረቶችና የገበያ ንድፈ-ሀሳብ',
            description: 'Scarcity, opportunity cost, PPF curve, demand, supply, and elasticity.',
            questionCount: 15,
            hasNotes: true,
            estimatedMinutes: 25,
          ),
          UnitModel(
            unitNumber: 2,
            unitId: 'econ_g${grade}_u2',
            enTitle: 'National Income Accounting & Macroeconomics',
            amTitle: 'ብሔራዊ ገቢና ማክሮ ኢኮኖሚክስ',
            description: 'GDP, GNP, inflation, fiscal policy, and monetary stability.',
            questionCount: 16,
            hasNotes: true,
            estimatedMinutes: 25,
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
    final catalog = NoteChunkHelper.getSampleNotesCatalog();
    if (catalog.containsKey(unitId)) {
      return catalog[unitId]!;
    }

    // Dynamic fallback realistic short note data for any subject / unit
    return ShortNoteModel(
      id: '${unitId}_note',
      grade: grade,
      subject: subject,
      unitNumber: unitNumber,
      title: '$subject Unit $unitNumber Comprehensive Exam Note & Concept Breakdown',
      content: '''
# Smart X Ethiopia: Grade $grade $subject • Unit $unitNumber Summary

This comprehensive short note is specifically prepared according to the Ethiopian Ministry of Education national curriculum framework.

Section 1: Fundamental Principles and Definitions
Every student must thoroughly understand the foundational axioms of Unit $unitNumber. In national entrance examinations, approximately 15% to 20% of all section questions test conceptual clarity directly from these axioms.
- Key Axiom 1: Core foundational law and its standard mathematical or scientific formulation.
- Key Axiom 2: Conservation laws and boundary conditions governing this domain.
- Key Axiom 3: Applications in modern Ethiopian industrial, ecological, or economic contexts.

Section 2: Formulae, Methods, and Problem Solving Strategies
To maximize speed and accuracy during timed examinations:
1. Identify given variables and requested unknown quantities immediately.
2. Standardize all measurement units to SI metric units before calculating.
3. Check for special boundary conditions or undefined denominator singularities.

Section 3: Common Pitfalls and Trap Avoidance
- Trap A: Confusing sign conventions (+ vs -) in directional or algebraic vectors.
- Trap B: Neglecting domain restrictions when simplifying complex expressions.
- Trap C: Misinterpreting percentage changes in rate equations.

Study Tip: Practice the corresponding Smart X model quiz for Unit $unitNumber right after reading these notes to consolidate your memory!
''',
    );
  }
}
