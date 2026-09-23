import 'dart:convert';
import 'dart:math';

enum QuestionType {
  multipleChoice,
  trueFalse,
  blankSpace,
  matching,
}

class MatchingPair {
  final String left;
  final String right;

  const MatchingPair({required this.left, required this.right});

  factory MatchingPair.fromJson(Map<String, dynamic> json) {
    return MatchingPair(
      left: (json['left'] ?? json['premise'] ?? json['column_a'] ?? json['term'] ?? json['k'] ?? '').toString().trim(),
      right: (json['right'] ?? json['response'] ?? json['column_b'] ?? json['definition'] ?? json['v'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toJson() => {
    'left': left,
    'right': right,
  };
}

class QuestionOption {
  final String text;
  final bool isCorrect;
  final String? explanation;
  final String? key; // e.g. "A", "B", "C", "D"

  QuestionOption({
    required this.text,
    required this.isCorrect,
    this.explanation,
    this.key,
  });

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    bool correct = false;
    if (json['is_correct'] != null) {
      final raw = json['is_correct'];
      if (raw is bool) {
        correct = raw;
      } else {
        final s = raw.toString().trim().toLowerCase();
        correct = s == 'true' || s == '1' || s == 'yes' || s == 't';
      }
    } else if (json['isCorrect'] != null) {
      final raw = json['isCorrect'];
      if (raw is bool) {
        correct = raw;
      } else {
        final s = raw.toString().trim().toLowerCase();
        correct = s == 'true' || s == '1' || s == 'yes' || s == 't';
      }
    }

    return QuestionOption(
      text: (json['text'] ?? json['option_text'] ?? json['label'] ?? json['value'] ?? '').toString().trim(),
      isCorrect: correct,
      explanation: json['explanation']?.toString().trim(),
      key: json['key']?.toString().trim().toUpperCase(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'is_correct': isCorrect,
      'explanation': explanation,
      'key': key,
    };
  }
}

class QuestionModel {
  final String id;
  final String? unitId;
  final int? grade;
  final String? subject;
  final int? unitNumber;
  final String questionText;
  final int questionNumber;
  final int orderIndex;
  final List<QuestionOption> options;
  final String? explanation;
  final String? questionImageUrl;

  // Question Format Classification
  final QuestionType questionType;

  // True / False support
  final bool? correctBoolean;

  // Blank Space (Fill in the blank / ባዶ ቦታ ሙላ) support
  final String? blankAnswer;
  final List<String> acceptedAnswers;
  final bool caseSensitive;
  final String? hint;

  // Matching (አዛምድ) support
  final List<MatchingPair> matchingPairs;

  // Exam Mode Metadata
  final String? year;
  final String? examCategory;
  final int timeLimitSeconds;
  final String? difficulty;
  final String? topic;

  QuestionModel({
    required this.id,
    this.unitId,
    this.grade,
    this.subject,
    this.unitNumber,
    required this.questionText,
    required this.questionNumber,
    required this.orderIndex,
    required this.options,
    this.explanation,
    this.questionImageUrl,
    this.questionType = QuestionType.multipleChoice,
    this.correctBoolean,
    this.blankAnswer,
    this.acceptedAnswers = const [],
    this.matchingPairs = const [],
    this.caseSensitive = false,
    this.hint,
    this.year,
    this.examCategory,
    this.timeLimitSeconds = 90,
    this.difficulty = 'medium',
    this.topic,
  });

  bool get isMultipleChoice => questionType == QuestionType.multipleChoice;
  bool get isTrueFalse => questionType == QuestionType.trueFalse;
  bool get isBlankSpace => questionType == QuestionType.blankSpace;
  bool get isMatching => questionType == QuestionType.matching;

  static String _normalizeAnswerString(String str) {
    return str
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[.,!?]+$'), '')
        .trim();
  }

  /// Validates a user's typed blank input against canonical `blankAnswer` and `acceptedAnswers`
  bool checkBlankAnswer(String userInput) {
    final cleanInput = _normalizeAnswerString(userInput);
    if (cleanInput.isEmpty) return false;

    if (caseSensitive) {
      if (blankAnswer != null && cleanInput == _normalizeAnswerString(blankAnswer!)) return true;
      for (final accepted in acceptedAnswers) {
        if (cleanInput == _normalizeAnswerString(accepted)) return true;
      }
    } else {
      final lowerInput = cleanInput.toLowerCase();
      if (blankAnswer != null && lowerInput == _normalizeAnswerString(blankAnswer!).toLowerCase()) return true;
      for (final accepted in acceptedAnswers) {
        if (lowerInput == _normalizeAnswerString(accepted).toLowerCase()) return true;
      }
    }
    return false;
  }

  /// Unique identifier key for deduplication and caching
  String get uniqueKey => id.isNotEmpty
      ? id
      : '$grade-$subject-$unitNumber-$questionNumber-${questionText.trim().toLowerCase()}';

  /// Returns a copy of this question with its multiple choice options randomly shuffled.
  /// Keys ('A', 'B', 'C', 'D') are re-assigned cleanly while preserving correctness.
  QuestionModel copyWithShuffledOptions(Random random) {
    if (options.length <= 1) return this;
    final shuffled = List<QuestionOption>.from(options)..shuffle(random);
    final reKeyed = <QuestionOption>[];
    for (int i = 0; i < shuffled.length; i++) {
      final key = String.fromCharCode(65 + i);
      reKeyed.add(QuestionOption(
        key: key,
        text: shuffled[i].text,
        isCorrect: shuffled[i].isCorrect,
        explanation: shuffled[i].explanation,
      ));
    }
    return QuestionModel(
      id: id,
      unitId: unitId,
      grade: grade,
      subject: subject,
      unitNumber: unitNumber,
      questionText: questionText,
      questionNumber: questionNumber,
      orderIndex: orderIndex,
      options: reKeyed,
      explanation: explanation,
      questionImageUrl: questionImageUrl,
      questionType: questionType,
      correctBoolean: correctBoolean,
      blankAnswer: blankAnswer,
      acceptedAnswers: acceptedAnswers,
      matchingPairs: matchingPairs,
      caseSensitive: caseSensitive,
      hint: hint,
      year: year,
      examCategory: examCategory,
      timeLimitSeconds: timeLimitSeconds,
      difficulty: difficulty,
      topic: topic,
    );
  }

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    // Helpers for safe type parsing
    int? parseNullableInt(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      if (val is double) return val.toInt();
      if (val is num) return val.toInt();
      return int.tryParse(val.toString().trim());
    }

    int parseInt(dynamic val, {int defaultValue = 1}) {
      return parseNullableInt(val) ?? defaultValue;
    }

    bool parseBool(dynamic val, {bool defaultValue = false}) {
      if (val == null) return defaultValue;
      if (val is bool) return val;
      final str = val.toString().trim().toLowerCase();
      if (str == 'true' || str == '1' || str == 'yes' || str == 't' || str == 'እውነት') return true;
      if (str == 'false' || str == '0' || str == 'no' || str == 'f' || str == 'ሐሰት') return false;
      return defaultValue;
    }

    // 1. Resolve Question Type
    final rawType = (json['question_type'] ?? json['type'] ?? json['format'] ?? 'multiple_choice')
        .toString()
        .toLowerCase()
        .trim();
    QuestionType resolvedType = QuestionType.multipleChoice;
    if (rawType.contains('true') || rawType.contains('false') || rawType == 'tf' || rawType.contains('እውነት')) {
      resolvedType = QuestionType.trueFalse;
    } else if (rawType.contains('blank') || rawType.contains('fill') || rawType == 'space' || rawType.contains('ባዶ')) {
      resolvedType = QuestionType.blankSpace;
    } else if (rawType.contains('match') || rawType.contains('pair') || rawType.contains('አዛምድ')) {
      resolvedType = QuestionType.matching;
    }

    // 2. Parse Options safely
    dynamic rawOptions = json['options'] ?? json['question_options'] ?? json['choices'];
    if (rawOptions is String && rawOptions.trim().startsWith('[')) {
      try {
        rawOptions = jsonDecode(rawOptions);
      } catch (_) {}
    } else if (rawOptions is String && rawOptions.trim().startsWith('{')) {
      try {
        rawOptions = jsonDecode(rawOptions);
      } catch (_) {}
    }

    final List<QuestionOption> parsedOptions = [];
    final String correctAnswerStr = (json['correct_answer'] ?? json['correct_option'] ?? json['answer'] ?? '')
        .toString()
        .trim();

    if (rawOptions is List) {
      for (final item in rawOptions) {
        if (item is Map<String, dynamic>) {
          parsedOptions.add(QuestionOption.fromJson(item));
        } else if (item is Map) {
          parsedOptions.add(QuestionOption.fromJson(Map<String, dynamic>.from(item)));
        } else if (item != null) {
          final itemStr = item.toString().trim();
          final isCorr = itemStr.toLowerCase() == correctAnswerStr.toLowerCase() ||
              (correctAnswerStr.isNotEmpty && itemStr.toUpperCase() == correctAnswerStr.toUpperCase());
          parsedOptions.add(QuestionOption(
            text: itemStr,
            isCorrect: isCorr,
          ));
        }
      }
    } else if (rawOptions is Map) {
      rawOptions.forEach((key, value) {
        final optKey = key.toString().trim().toUpperCase();
        if (value is Map<String, dynamic>) {
          parsedOptions.add(QuestionOption.fromJson(value));
        } else if (value is Map) {
          parsedOptions.add(QuestionOption.fromJson(Map<String, dynamic>.from(value)));
        } else if (value != null) {
          final valStr = value.toString().trim();
          final isCorr = optKey == correctAnswerStr.toUpperCase() ||
              valStr.toLowerCase() == correctAnswerStr.toLowerCase();
          parsedOptions.add(QuestionOption(
            key: optKey,
            text: valStr,
            isCorrect: isCorr,
          ));
        }
      });
    }

    // Fallback: check option_a, option_b, option_c, option_d columns
    if (parsedOptions.isEmpty && (json['option_a'] != null || json['option_b'] != null)) {
      final correctOpt = correctAnswerStr.toUpperCase();
      
      void addIfPresent(String optKey, dynamic val) {
        if (val != null) {
          final valStr = val.toString().trim();
          if (valStr.isNotEmpty) {
            parsedOptions.add(QuestionOption(
              key: optKey,
              text: valStr,
              isCorrect: correctOpt == optKey || correctOpt == valStr.toUpperCase(),
            ));
          }
        }
      }

      addIfPresent('A', json['option_a']);
      addIfPresent('B', json['option_b']);
      addIfPresent('C', json['option_c']);
      addIfPresent('D', json['option_d']);
    }

    // Match options with correctAnswerStr if none has been marked isCorrect
    if (correctAnswerStr.isNotEmpty && !parsedOptions.any((o) => o.isCorrect)) {
      for (int i = 0; i < parsedOptions.length; i++) {
        final opt = parsedOptions[i];
        final bool keyMatches = opt.key != null && opt.key!.toUpperCase() == correctAnswerStr.toUpperCase();
        final bool textMatches = opt.text.trim().toLowerCase() == correctAnswerStr.toLowerCase();
        if (keyMatches || textMatches) {
          parsedOptions[i] = QuestionOption(
            key: opt.key,
            text: opt.text,
            isCorrect: true,
            explanation: opt.explanation,
          );
        }
      }
    }

    // 3. For True / False, populate default True/False options if none provided
    bool? boolVal;
    if (json['correct_boolean'] != null) {
      boolVal = parseBool(json['correct_boolean']);
    } else if (resolvedType == QuestionType.trueFalse) {
      final ansStr = correctAnswerStr.toLowerCase();
      boolVal = ansStr.contains('true') || ansStr.contains('እውነት') || ansStr == 't' || ansStr == '1';
    }

    if (resolvedType == QuestionType.trueFalse && parsedOptions.isEmpty) {
      parsedOptions.add(QuestionOption(
        text: 'True (እውነት)',
        isCorrect: boolVal == true,
        key: 'A',
      ));
      parsedOptions.add(QuestionOption(
        text: 'False (ሐሰት)',
        isCorrect: boolVal == false,
        key: 'B',
      ));
    }

    // 4. Accepted Answers List for Blank Space
    final List<String> accepted = [];
    dynamic rawAccepted = json['accepted_answers'] ?? json['valid_answers'];
    if (rawAccepted is String && rawAccepted.trim().startsWith('[')) {
      try {
        rawAccepted = jsonDecode(rawAccepted);
      } catch (_) {}
    }
    if (rawAccepted is List) {
      for (final a in rawAccepted) {
        if (a != null && a.toString().trim().isNotEmpty) {
          accepted.add(a.toString().trim());
        }
      }
    }

    // 5. Matching Pairs List for Matching Questions (አዛምድ)
    final List<MatchingPair> parsedMatchingPairs = [];
    dynamic rawPairs = json['matching_pairs'] ?? json['pairs'] ?? json['matching_options'];
    if (rawPairs is String && rawPairs.trim().startsWith('[')) {
      try {
        rawPairs = jsonDecode(rawPairs);
      } catch (_) {}
    } else if (rawPairs is String && rawPairs.trim().startsWith('{')) {
      try {
        rawPairs = jsonDecode(rawPairs);
      } catch (_) {}
    }

    if (rawPairs is List) {
      for (final p in rawPairs) {
        if (p is Map<String, dynamic>) {
          parsedMatchingPairs.add(MatchingPair.fromJson(p));
        } else if (p is Map) {
          parsedMatchingPairs.add(MatchingPair.fromJson(Map<String, dynamic>.from(p)));
        }
      }
    } else if (rawPairs is Map) {
      rawPairs.forEach((k, v) {
        parsedMatchingPairs.add(MatchingPair(
          left: k.toString().trim(),
          right: v?.toString().trim() ?? '',
        ));
      });
    }

    return QuestionModel(
      id: (json['id'] ?? json['question_id'] ?? DateTime.now().millisecondsSinceEpoch.toString()).toString(),
      unitId: json['unit_id']?.toString(),
      grade: parseNullableInt(json['grade']),
      subject: json['subject']?.toString(),
      unitNumber: parseNullableInt(json['unit_number']),
      questionText: (json['question_text'] ?? json['text'] ?? json['question'] ?? '').toString().trim(),
      questionNumber: parseInt(json['question_number'], defaultValue: 1),
      orderIndex: parseInt(json['order_index'], defaultValue: 1),
      options: parsedOptions,
      explanation: json['explanation']?.toString().trim() ?? json['rationale']?.toString().trim(),
      questionImageUrl: (json['question_image_url'] ?? json['image_url'] ?? json['image'])?.toString().trim(),
      questionType: resolvedType,
      correctBoolean: boolVal,
      blankAnswer: json['blank_answer']?.toString().trim() ??
          (resolvedType == QuestionType.blankSpace ? (correctAnswerStr.isNotEmpty ? correctAnswerStr : null) : null),
      acceptedAnswers: accepted,
      matchingPairs: parsedMatchingPairs,
      caseSensitive: parseBool(json['case_sensitive']),
      hint: json['hint']?.toString().trim(),
      year: json['year']?.toString(),
      examCategory: json['exam_category']?.toString(),
      timeLimitSeconds: parseInt(json['time_limit_seconds'], defaultValue: 90),
      difficulty: json['difficulty']?.toString() ?? 'medium',
      topic: json['topic']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    String typeStr = 'multiple_choice';
    if (questionType == QuestionType.trueFalse) typeStr = 'true_false';
    if (questionType == QuestionType.blankSpace) typeStr = 'blank_space';
    if (questionType == QuestionType.matching) typeStr = 'matching';

    return {
      'id': id,
      'unit_id': unitId,
      'grade': grade,
      'subject': subject,
      'unit_number': unitNumber,
      'question_text': questionText,
      'question_number': questionNumber,
      'order_index': orderIndex,
      'options': options.map((e) => e.toJson()).toList(),
      'explanation': explanation,
      'question_image_url': questionImageUrl,
      'question_type': typeStr,
      'correct_boolean': correctBoolean,
      'blank_answer': blankAnswer,
      'accepted_answers': acceptedAnswers,
      'matching_pairs': matchingPairs.map((e) => e.toJson()).toList(),
      'case_sensitive': caseSensitive,
      'hint': hint,
      'year': year,
      'exam_category': examCategory,
      'time_limit_seconds': timeLimitSeconds,
      'difficulty': difficulty,
      'topic': topic,
    };
  }
}
