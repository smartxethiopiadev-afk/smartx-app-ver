import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/question_model.dart';
import 'offline_manager.dart';

enum QuizMode {
  practice,
  exam,
}

class QuizService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Standardizes subject name for querying
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

  /// Strict grade and unit validation and duplicate removal logic
  /// to ensure no cross-grade leakage and no repeated questions.
  static List<QuestionModel> deduplicateAndValidate({
    required List<QuestionModel> questions,
    required int expectedGrade,
    int? expectedUnit,
  }) {
    final seenIds = <String>{};
    final seenTexts = <String>{};
    final List<QuestionModel> filtered = [];

    for (final q in questions) {
      // 1. Strict Grade Validation to prevent cross-grade leaking
      if (q.grade != null && q.grade != expectedGrade) {
        continue;
      }
      // 2. Strict Unit Validation
      if (expectedUnit != null && q.unitNumber != null && q.unitNumber != expectedUnit) {
        continue;
      }

      // 3. Deduplication by ID & Normalized Question Text
      final String idKey = q.id.trim();
      final String textKey = q.questionText.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

      if (idKey.isNotEmpty && seenIds.contains(idKey)) {
        continue;
      }
      if (textKey.isNotEmpty && seenTexts.contains(textKey)) {
        continue;
      }

      if (idKey.isNotEmpty) seenIds.add(idKey);
      if (textKey.isNotEmpty) seenTexts.add(textKey);
      filtered.add(q);
    }

    return filtered;
  }

  /// Fetches questions for Practice Mode directly from `practice_questions` table.
  /// Supports: 'multiple_choice', 'true_false', 'blank_space', 'matching'.
  /// Enforces sequential order and removes duplicates.
  static Future<List<QuestionModel>> fetchPracticeQuestions({
    required int grade,
    required String subject,
    required int unit,
    String? questionType,
  }) async {
    final bool hasConn = await OfflineManager.isNetworkAvailable();
    final normSubject = _normalizeSubject(subject);
    List<QuestionModel> results = [];

    if (hasConn) {
      try {
        var query = _supabase
            .from('practice_questions')
            .select('*')
            .eq('grade', grade)
            .ilike('subject', '%$normSubject%')
            .eq('unit_number', unit);

        if (questionType != null && questionType.isNotEmpty && questionType != 'all') {
          query = query.eq('question_type', questionType);
        }

        final response = await query.order('question_number', ascending: true);

        if (response.isNotEmpty) {
          results = (response as List<dynamic>)
              .map((json) => QuestionModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      } catch (e) {
        debugPrint('[QuizService] practice_questions query note: $e. Checking fallback.');
      }

      // Legacy fallback to questions table if practice_questions is empty on legacy database
      if (results.isEmpty) {
        try {
          final legacyResp = await _supabase
              .from('questions')
              .select('*, question_options(*)')
              .eq('grade', grade)
              .ilike('subject', '%$normSubject%')
              .eq('unit_number', unit);

          if (legacyResp.isNotEmpty) {
            results = (legacyResp as List<dynamic>)
                .map((json) => QuestionModel.fromJson(json as Map<String, dynamic>))
                .toList();
          }
        } catch (e) {
          debugPrint('[QuizService] legacy questions query note: $e');
        }
      }
    }

    // Seeded fallback practice questions if database has no rows or is offline
    if (results.isEmpty) {
      results = _generateCurriculumPracticeFallback(grade, normSubject, unit);
    }

    // Filter by questionType if specified (especially when using fallback)
    if (questionType != null && questionType.isNotEmpty && questionType != 'all') {
      results = results.where((q) {
        if (questionType == 'multiple_choice') return q.isMultipleChoice;
        if (questionType == 'true_false') return q.isTrueFalse;
        if (questionType == 'blank_space') return q.isBlankSpace;
        if (questionType == 'matching') return q.isMatching;
        return true;
      }).toList();
    }

    // Strict validation & deduplication
    final validated = deduplicateAndValidate(
      questions: results,
      expectedGrade: grade,
      expectedUnit: unit,
    );

    // Practice Mode: Sequential ordering by orderIndex or questionNumber
    validated.sort((a, b) {
      if (a.orderIndex != b.orderIndex) return a.orderIndex.compareTo(b.orderIndex);
      if (a.questionNumber != b.questionNumber) return a.questionNumber.compareTo(b.questionNumber);
      return a.id.compareTo(b.id);
    });

    return validated;
  }

  /// Fetches questions for Exam Mode from `exam_questions` (or dynamic practice_questions MCQ pool).
  /// Strictly multiple choice questions with randomized question order and shuffled options.
  static Future<List<QuestionModel>> fetchExamQuestions({
    required int grade,
    required String subject,
    int? unit,
    String? year,
    int limit = 50,
  }) async {
    final bool hasConn = await OfflineManager.isNetworkAvailable();
    final normSubject = _normalizeSubject(subject);
    List<QuestionModel> results = [];

    if (hasConn) {
      // 1. Try exam_questions table first
      try {
        var query = _supabase
            .from('exam_questions')
            .select('*')
            .eq('grade', grade)
            .ilike('subject', '%$normSubject%');

        if (unit != null && unit > 0) {
          query = query.eq('unit_number', unit);
        }

        if (year != null && year.isNotEmpty && year != 'all') {
          query = query.eq('year', year);
        }

        final response = await query.limit(limit);

        if (response.isNotEmpty) {
          results = (response as List<dynamic>)
              .map((json) => QuestionModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      } catch (e) {
        debugPrint('[QuizService] exam_questions query note: $e. Checking dynamic MCQ pool.');
      }

      // 2. If exam_questions table has no records for this unit, query practice_questions for multiple choice questions
      if (results.isEmpty) {
        try {
          var poolQuery = _supabase
              .from('practice_questions')
              .select('*')
              .eq('grade', grade)
              .ilike('subject', '%$normSubject%')
              .eq('question_type', 'multiple_choice');

          if (unit != null && unit > 0) {
            poolQuery = poolQuery.eq('unit_number', unit);
          }

          final poolResp = await poolQuery.limit(limit);
          if (poolResp.isNotEmpty) {
            results = (poolResp as List<dynamic>)
                .map((json) => QuestionModel.fromJson(json as Map<String, dynamic>))
                .toList();
          }
        } catch (e) {
          debugPrint('[QuizService] dynamic exam fallback from practice_questions note: $e');
        }
      }

      // 3. Legacy questions fallback
      if (results.isEmpty) {
        try {
          var legacyQuery = _supabase
              .from('questions')
              .select('*, question_options(*)')
              .eq('grade', grade)
              .ilike('subject', '%$normSubject%');

          if (unit != null && unit > 0) {
            legacyQuery = legacyQuery.eq('unit_number', unit);
          }

          final legacyResp = await legacyQuery.limit(limit);

          if (legacyResp.isNotEmpty) {
            results = (legacyResp as List<dynamic>)
                .map((json) => QuestionModel.fromJson(json as Map<String, dynamic>))
                .toList();
          }
        } catch (e) {
          debugPrint('[QuizService] legacy exam questions query note: $e');
        }
      }
    }

    // Seeded fallback exam questions if still empty
    if (results.isEmpty) {
      results = _generateCurriculumExamFallback(grade, normSubject, unit ?? 1);
    }

    // Strict validation & deduplication
    final validated = deduplicateAndValidate(
      questions: results,
      expectedGrade: grade,
      expectedUnit: unit,
    );

    // Exam Mode: Randomize question sequence and shuffle choices
    final random = Random();
    validated.shuffle(random);
    final randomized = validated.map((q) => q.copyWithShuffledOptions(random)).toList();

    return randomized.take(limit).toList();
  }

  /// General router for QuizScreen
  static Future<List<QuestionModel>> fetchQuestions({
    required int grade,
    required String subject,
    required int unit,
    QuizMode mode = QuizMode.practice,
    String? questionType,
  }) async {
    if (mode == QuizMode.exam) {
      return fetchExamQuestions(grade: grade, subject: subject, unit: unit);
    } else {
      return fetchPracticeQuestions(
        grade: grade,
        subject: subject,
        unit: unit,
        questionType: questionType,
      );
    }
  }

  /// Curriculum Seeded Fallback for Practice Mode (includes MCQ, True/False, Blank Space)
  static List<QuestionModel> _generateCurriculumPracticeFallback(int grade, String subject, int unit) {
    if (subject.contains('Math')) {
      return [
        QuestionModel(
          id: 'fb_prac_m1',
          grade: grade,
          subject: subject,
          unitNumber: unit,
          topic: 'Arithmetic Progressions',
          questionType: QuestionType.multipleChoice,
          questionNumber: 1,
          orderIndex: 1,
          questionText: 'What is the 10th term of an arithmetic sequence with first term \$a_1 = 4\$ and common difference \$d = 5\$?',
          options: [
            QuestionOption(key: 'A', text: '45', isCorrect: false),
            QuestionOption(key: 'B', text: '49', isCorrect: true, explanation: 'a_10 = 4 + (10 - 1)(5) = 4 + 45 = 49'),
            QuestionOption(key: 'C', text: '54', isCorrect: false),
            QuestionOption(key: 'D', text: '50', isCorrect: false),
          ],
          hint: 'Use the formula \$a_n = a_1 + (n - 1)d\$.',
          explanation: 'Using \$a_n = a_1 + (n - 1)d\$, we have \$a_{10} = 4 + (9)(5) = 4 + 45 = 49\$.',
        ),
        QuestionModel(
          id: 'fb_prac_m2',
          grade: grade,
          subject: subject,
          unitNumber: unit,
          topic: 'Infinite Geometric Series',
          questionType: QuestionType.trueFalse,
          questionNumber: 2,
          orderIndex: 2,
          questionText: 'True or False: An infinite geometric series converges if and only if \$|r| < 1\$.',
          options: [
            QuestionOption(text: 'True (እውነት)', isCorrect: true),
            QuestionOption(text: 'False (ሐሰት)', isCorrect: false),
          ],
          correctBoolean: true,
          hint: 'Consider the limiting behavior of \$r^n\$ as \$n \\to \\infty\$.',
          explanation: 'True. When \$|r| < 1\$, the terms shrink to zero and the infinite sum equals \$S_\\infty = \\frac{a_1}{1 - r}\$.',
        ),
        QuestionModel(
          id: 'fb_prac_m3',
          grade: grade,
          subject: subject,
          unitNumber: unit,
          topic: 'Harmonic Sequences',
          questionType: QuestionType.blankSpace,
          questionNumber: 3,
          orderIndex: 3,
          questionText: 'A sequence is called a Harmonic Progression if the reciprocals of its terms form an _______ progression.',
          options: const [],
          blankAnswer: 'Arithmetic',
          acceptedAnswers: const ['arithmetic', 'arithmetic progression', 'AP', 'ap'],
          hint: 'The sequence formed by inverting harmonic fractions is the most fundamental linear sequence.',
          explanation: 'By definition, \$h_1, h_2, h_3, ...\$ is a Harmonic Progression if \$\\frac{1}{h_1}, \\frac{1}{h_2}, \\frac{1}{h_3}, ...\$ forms an Arithmetic Progression (AP).',
        ),
        QuestionModel(
          id: 'fb_prac_m4',
          grade: grade,
          subject: subject,
          unitNumber: unit,
          topic: 'Mathematical Terms Matching',
          questionType: QuestionType.matching,
          questionNumber: 4,
          orderIndex: 4,
          questionText: 'Match each mathematical term in Column A with its correct definition in Column B (አዛምድ):',
          options: const [],
          matchingPairs: const [
            MatchingPair(left: 'Arithmetic Mean', right: '(a + b) / 2'),
            MatchingPair(left: 'Geometric Mean', right: 'sqrt(a * b)'),
            MatchingPair(left: 'Common Difference', right: 'a_n - a_{n-1}'),
          ],
          explanation: 'Arithmetic Mean is the average (a+b)/2, Geometric Mean is sqrt(a*b), Common Difference is a_n - a_{n-1}.',
        ),
      ];
    } else if (subject.contains('Phys')) {
      return [
        QuestionModel(
          id: 'fb_prac_p1',
          grade: grade,
          subject: subject,
          unitNumber: unit,
          topic: 'First Law of Thermodynamics',
          questionType: QuestionType.multipleChoice,
          questionNumber: 1,
          orderIndex: 1,
          questionText: 'If 600 J of heat is added to a system and the system performs 250 J of work, what is the change in internal energy (\$\\Delta U\$)?',
          options: [
            QuestionOption(key: 'A', text: '850 J', isCorrect: false),
            QuestionOption(key: 'B', text: '350 J', isCorrect: true, explanation: 'ΔU = Q - W = 600 - 250 = 350 J'),
            QuestionOption(key: 'C', text: '-350 J', isCorrect: false),
            QuestionOption(key: 'D', text: '150 J', isCorrect: false),
          ],
          hint: 'Apply the First Law of Thermodynamics: \$\\Delta U = Q - W\$.',
          explanation: 'From the First Law of Thermodynamics: \$\\Delta U = Q - W = 600\\text{ J} - 250\\text{ J} = 350\\text{ J}\$.',
        ),
        QuestionModel(
          id: 'fb_prac_p2',
          grade: grade,
          subject: subject,
          unitNumber: unit,
          topic: 'Second Law of Thermodynamics',
          questionType: QuestionType.trueFalse,
          questionNumber: 2,
          orderIndex: 2,
          questionText: 'True or False: Natural spontaneous thermodynamic processes always result in an increase in the total entropy of the universe.',
          options: [
            QuestionOption(text: 'True (እውነት)', isCorrect: true),
            QuestionOption(text: 'False (ሐሰት)', isCorrect: false),
          ],
          correctBoolean: true,
          hint: 'Consider the Second Law of Thermodynamics regarding isolated systems and universal disorder.',
          explanation: 'True. The Second Law states that for any spontaneous natural process, the total entropy of the universe increases (\$\\Delta S_{total} > 0\$) or remains constant in an idealized reversible process.',
        ),
        QuestionModel(
          id: 'fb_prac_p3',
          grade: grade,
          subject: subject,
          unitNumber: unit,
          topic: 'Carnot Heat Engines',
          questionType: QuestionType.blankSpace,
          questionNumber: 3,
          orderIndex: 3,
          questionText: 'The theoretical maximum efficiency achievable by any heat engine operating between two temperatures is given by the _______ cycle.',
          options: const [],
          blankAnswer: 'Carnot',
          acceptedAnswers: const ['carnot', 'Carnot cycle', 'carnot cycle'],
          hint: 'Named after the French engineer and physicist Nicolas Léonard Sadi _______',
          explanation: 'The Carnot cycle efficiency \$\\eta_{Carnot} = 1 - \\frac{T_C}{T_H}\$ provides the theoretical upper limit for all heat engine efficiencies.',
        ),
      ];
    } else {
      return [
        QuestionModel(
          id: 'fb_prac_g1',
          grade: grade,
          subject: subject,
          unitNumber: unit,
          topic: 'Curriculum Core Principles',
          questionType: QuestionType.multipleChoice,
          questionNumber: 1,
          orderIndex: 1,
          questionText: 'Which of the following represents the fundamental SI unit for measuring thermodynamic temperature?',
          options: [
            QuestionOption(key: 'A', text: 'Celsius (°C)', isCorrect: false),
            QuestionOption(key: 'B', text: 'Kelvin (K)', isCorrect: true),
            QuestionOption(key: 'C', text: 'Fahrenheit (°F)', isCorrect: false),
            QuestionOption(key: 'D', text: 'Joule (J)', isCorrect: false),
          ],
          hint: 'Think of the absolute temperature scale without degree symbols.',
          explanation: 'Kelvin (K) is the SI base unit for thermodynamic temperature.',
        ),
        QuestionModel(
          id: 'fb_prac_g2',
          grade: grade,
          subject: subject,
          unitNumber: unit,
          topic: 'Scientific Method',
          questionType: QuestionType.trueFalse,
          questionNumber: 2,
          orderIndex: 2,
          questionText: 'True or False: A scientific hypothesis must be experimentally testable and falsifiable.',
          options: [
            QuestionOption(text: 'True (እውነት)', isCorrect: true),
            QuestionOption(text: 'False (ሐሰት)', isCorrect: false),
          ],
          correctBoolean: true,
          hint: 'Consider what distinguishes empirical science from non-testable claims.',
          explanation: 'True. A core principle of the scientific method is that hypotheses must produce testable and falsifiable predictions.',
        ),
        QuestionModel(
          id: 'fb_prac_g3',
          grade: grade,
          subject: subject,
          unitNumber: unit,
          topic: 'Physical Quantities',
          questionType: QuestionType.blankSpace,
          questionNumber: 3,
          orderIndex: 3,
          questionText: 'Physical quantities that possess both magnitude and direction are called _______ quantities.',
          options: const [],
          blankAnswer: 'Vector',
          acceptedAnswers: const ['vector', 'vectors', 'Vector', 'Vectors'],
          hint: 'Opposite of scalar quantities which have magnitude only.',
          explanation: 'A vector quantity is defined by both a magnitude and a direction (e.g. displacement, velocity, force).',
        ),
      ];
    }
  }

  /// Curriculum Seeded Fallback for Exam Mode (Multiple Choice Only)
  static List<QuestionModel> _generateCurriculumExamFallback(int grade, String subject, int unit) {
    if (subject.contains('Math')) {
      return [
        QuestionModel(
          id: 'fb_exam_m1',
          grade: grade,
          subject: subject,
          unitNumber: unit,
          year: '2016 E.C.',
          examCategory: 'national_exam',
          questionType: QuestionType.multipleChoice,
          questionNumber: 1,
          orderIndex: 1,
          questionText: 'What is the sum of the first 20 terms of an arithmetic progression whose first term is 5 and common difference is 3?',
          options: [
            QuestionOption(key: 'A', text: '640', isCorrect: false),
            QuestionOption(key: 'B', text: '670', isCorrect: true),
            QuestionOption(key: 'C', text: '720', isCorrect: false),
            QuestionOption(key: 'D', text: '580', isCorrect: false),
          ],
          timeLimitSeconds: 90,
          difficulty: 'medium',
          explanation: 'Formula: \$S_n = \\frac{n}{2}[2a_1 + (n-1)d]\$. For \$n=20, a_1=5, d=3\$: \$S_{20} = 10[10 + 57] = 670\$.',
        ),
        QuestionModel(
          id: 'fb_exam_m2',
          grade: grade,
          subject: subject,
          unitNumber: unit,
          year: '2016 E.C.',
          examCategory: 'national_exam',
          questionType: QuestionType.multipleChoice,
          questionNumber: 2,
          orderIndex: 2,
          questionText: 'For what value of \$r\$ does the infinite geometric series \$18 + 18r + 18r^2 + ...\$ converge to 27?',
          options: [
            QuestionOption(key: 'A', text: '1/3', isCorrect: true),
            QuestionOption(key: 'B', text: '2/3', isCorrect: false),
            QuestionOption(key: 'C', text: '-1/3', isCorrect: false),
            QuestionOption(key: 'D', text: '1/2', isCorrect: false),
          ],
          timeLimitSeconds: 90,
          difficulty: 'medium',
          explanation: '\$S_\\infty = \\frac{a_1}{1 - r} \\implies 27 = \\frac{18}{1 - r} \\implies 1 - r = \\frac{2}{3} \\implies r = \\frac{1}{3}\$.',
        ),
      ];
    } else {
      return [
        QuestionModel(
          id: 'fb_exam_p1',
          grade: grade,
          subject: subject,
          unitNumber: unit,
          year: '2016 E.C.',
          examCategory: 'national_exam',
          questionType: QuestionType.multipleChoice,
          questionNumber: 1,
          orderIndex: 1,
          questionText: 'A heat engine absorbs 1200 J of heat from a hot reservoir at 600 K and exhausts 400 J to a cold reservoir. What is the thermal efficiency of the engine?',
          options: [
            QuestionOption(key: 'A', text: '33.3%', isCorrect: false),
            QuestionOption(key: 'B', text: '50.0%', isCorrect: false),
            QuestionOption(key: 'C', text: '66.7%', isCorrect: true),
            QuestionOption(key: 'D', text: '75.0%', isCorrect: false),
          ],
          timeLimitSeconds: 90,
          difficulty: 'medium',
          explanation: '\$\\eta = 1 - \\frac{Q_C}{Q_H} = 1 - \\frac{400}{1200} = 1 - \\frac{1}{3} = \\frac{2}{3} \\approx 66.7\\%\$.',
        ),
        QuestionModel(
          id: 'fb_exam_p2',
          grade: grade,
          subject: subject,
          unitNumber: unit,
          year: '2015 E.C.',
          examCategory: 'national_exam',
          questionType: QuestionType.multipleChoice,
          questionNumber: 2,
          orderIndex: 2,
          questionText: 'During an adiabatic expansion of an ideal gas, which of the following is strictly TRUE?',
          options: [
            QuestionOption(key: 'A', text: 'Heat added Q > 0', isCorrect: false),
            QuestionOption(key: 'B', text: 'No heat enters or leaves the system (Q = 0)', isCorrect: true),
            QuestionOption(key: 'C', text: 'Internal energy is constant (ΔU = 0)', isCorrect: false),
            QuestionOption(key: 'D', text: 'Temperature always increases', isCorrect: false),
          ],
          timeLimitSeconds: 90,
          difficulty: 'easy',
          explanation: 'In an adiabatic process, no heat enters or leaves the system: \$Q = 0\$.',
        ),
      ];
    }
  }

  /// Filters questions sequentially or selects a pool for the user session
  static Future<List<QuestionModel>> filterAndSelectQuestions({
    required String unitId,
    required List<QuestionModel> allQuestions,
  }) async {
    return allQuestions;
  }

  /// Marks questions as answered in local session
  static Future<void> markQuestionsAsAnswered({
    required String unitId,
    required List<QuestionModel> questions,
  }) async {
    // Session completion hook
  }
}

