import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/subject_model.dart';
import '../models/question_model.dart';
import '../models/note_model.dart';

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

  UserProfileData _profile = UserProfileData(
    fullName: 'Ethiopian Student',
    phoneNumber: '+251912345678',
    grade: 11,
    isRegistered: false,
    streakDays: 3,
  );

  LanguageCode _language = LanguageCode.en;
  int _currentGrade = 11;
  final Set<String> _downloadedUnitIds = {'math_g11_u1', 'bio_g11_u1', 'phy_g11_u1'};

  bool get isInitialized => _isInitialized;
  UserProfileData get profile => _profile;
  LanguageCode get language => _language;
  int get currentGrade => _currentGrade;
  Set<String> get downloadedUnitIds => _downloadedUnitIds;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
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
    
    final savedDownloads = _prefs.getStringList('downloaded_units');
    if (savedDownloads != null) {
      _downloadedUnitIds.addAll(savedDownloads);
    }

    _isInitialized = true;
    notifyListeners();
  }

  void setGrade(int grade) {
    _currentGrade = grade;
    _profile.grade = grade;
    _prefs.setInt('user_grade', grade);
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
    notifyListeners();
  }

  bool isUnitDownloaded(String unitId) {
    return _downloadedUnitIds.contains(unitId);
  }

  Future<void> toggleUnitDownload(String unitId) async {
    if (_downloadedUnitIds.contains(unitId)) {
      _downloadedUnitIds.remove(unitId);
    } else {
      _downloadedUnitIds.add(unitId);
    }
    await _prefs.setStringList('downloaded_units', _downloadedUnitIds.toList());
    notifyListeners();
  }

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
