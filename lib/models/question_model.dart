enum QuestionType {
  multipleChoice,
  trueFalse,
  blankSpace,
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
    return QuestionOption(
      text: json['text'] as String? ?? json['option_text'] as String? ?? '',
      isCorrect: json['is_correct'] as bool? ?? json['isCorrect'] as bool? ?? false,
      explanation: json['explanation'] as String?,
      key: json['key'] as String?,
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

  /// Validates a user's typed blank input against canonical `blankAnswer` and `acceptedAnswers`
  bool checkBlankAnswer(String userInput) {
    final cleanInput = userInput.trim();
    if (cleanInput.isEmpty) return false;

    if (caseSensitive) {
      if (blankAnswer != null && cleanInput == blankAnswer!.trim()) return true;
      for (final accepted in acceptedAnswers) {
        if (cleanInput == accepted.trim()) return true;
      }
    } else {
      final lowerInput = cleanInput.toLowerCase();
      if (blankAnswer != null && lowerInput == blankAnswer!.trim().toLowerCase()) return true;
      for (final accepted in acceptedAnswers) {
        if (lowerInput == accepted.trim().toLowerCase()) return true;
      }
    }
    return false;
  }

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    // 1. Resolve Question Type
    final rawType = (json['question_type'] ?? json['type'] ?? 'multiple_choice').toString().toLowerCase();
    QuestionType resolvedType = QuestionType.multipleChoice;
    if (rawType.contains('true') || rawType.contains('false') || rawType == 'tf') {
      resolvedType = QuestionType.trueFalse;
    } else if (rawType.contains('blank') || rawType.contains('fill') || rawType == 'space') {
      resolvedType = QuestionType.blankSpace;
    }

    // 2. Parse Options
    final rawOptions = json['options'];
    final List<QuestionOption> parsedOptions = [];

    if (rawOptions is List) {
      for (final item in rawOptions) {
        if (item is Map<String, dynamic>) {
          parsedOptions.add(QuestionOption.fromJson(item));
        } else if (item is String) {
          final correctAnswerStr = json['correct_answer']?.toString() ?? '';
          parsedOptions.add(QuestionOption(
            text: item,
            isCorrect: item.trim() == correctAnswerStr.trim(),
          ));
        }
      }
    } else if (rawOptions is Map<String, dynamic>) {
      rawOptions.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          parsedOptions.add(QuestionOption.fromJson(value));
        } else if (value is String) {
          final correctAnswerStr = json['correct_answer']?.toString() ?? json['correct_option']?.toString() ?? '';
          parsedOptions.add(QuestionOption(
            key: key,
            text: value,
            isCorrect: key.toUpperCase() == correctAnswerStr.toUpperCase() || value == correctAnswerStr,
          ));
        }
      });
    }

    // If options are still empty but option_a, option_b etc. exist (common in exam tables)
    if (parsedOptions.isEmpty && (json['option_a'] != null || json['option_b'] != null)) {
      final correctOpt = (json['correct_option'] ?? json['correct_answer'] ?? '').toString().toUpperCase();
      
      void addIfPresent(String optKey, dynamic val) {
        if (val != null && val.toString().isNotEmpty) {
          parsedOptions.add(QuestionOption(
            key: optKey,
            text: val.toString(),
            isCorrect: correctOpt == optKey || correctOpt == val.toString().toUpperCase(),
          ));
        }
      }

      addIfPresent('A', json['option_a']);
      addIfPresent('B', json['option_b']);
      addIfPresent('C', json['option_c']);
      addIfPresent('D', json['option_d']);
    }

    // 3. For True / False, populate default True/False options if none provided
    bool? boolVal;
    if (json['correct_boolean'] != null) {
      boolVal = json['correct_boolean'] is bool
          ? json['correct_boolean'] as bool
          : json['correct_boolean'].toString().toLowerCase() == 'true';
    } else if (resolvedType == QuestionType.trueFalse) {
      final ansStr = (json['correct_answer'] ?? '').toString().toLowerCase();
      boolVal = ansStr.contains('true') || ansStr.contains('እውነት');
    }

    if (resolvedType == QuestionType.trueFalse && parsedOptions.isEmpty) {
      parsedOptions.add(QuestionOption(
        text: 'True (እውነት)',
        isCorrect: boolVal == true,
      ));
      parsedOptions.add(QuestionOption(
        text: 'False (ሐሰት)',
        isCorrect: boolVal == false,
      ));
    }

    // 4. Accepted Answers List for Blank Space
    final List<String> accepted = [];
    final rawAccepted = json['accepted_answers'];
    if (rawAccepted is List) {
      for (final a in rawAccepted) {
        if (a != null && a.toString().isNotEmpty) {
          accepted.add(a.toString());
        }
      }
    }

    return QuestionModel(
      id: json['id']?.toString() ?? '',
      unitId: json['unit_id']?.toString(),
      grade: json['grade'] is int
          ? json['grade'] as int
          : int.tryParse(json['grade']?.toString() ?? ''),
      subject: json['subject']?.toString(),
      unitNumber: json['unit_number'] is int
          ? json['unit_number'] as int
          : int.tryParse(json['unit_number']?.toString() ?? ''),
      questionText: json['question_text'] as String? ?? json['text'] as String? ?? '',
      questionNumber: json['question_number'] is int
          ? json['question_number'] as int
          : int.tryParse(json['question_number']?.toString() ?? '1') ?? 1,
      orderIndex: json['order_index'] is int
          ? json['order_index'] as int
          : int.tryParse(json['order_index']?.toString() ?? '1') ?? 1,
      options: parsedOptions,
      explanation: json['explanation'] as String?,
      questionImageUrl: json['question_image_url'] as String? ?? json['image_url'] as String?,
      questionType: resolvedType,
      correctBoolean: boolVal,
      blankAnswer: json['blank_answer']?.toString() ?? (resolvedType == QuestionType.blankSpace ? json['correct_answer']?.toString() : null),
      acceptedAnswers: accepted,
      caseSensitive: json['case_sensitive'] is bool ? json['case_sensitive'] as bool : false,
      hint: json['hint'] as String?,
      year: json['year'] as String?,
      examCategory: json['exam_category'] as String?,
      timeLimitSeconds: json['time_limit_seconds'] is int
          ? json['time_limit_seconds'] as int
          : int.tryParse(json['time_limit_seconds']?.toString() ?? '90') ?? 90,
      difficulty: json['difficulty'] as String? ?? 'medium',
      topic: json['topic'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    String typeStr = 'multiple_choice';
    if (questionType == QuestionType.trueFalse) typeStr = 'true_false';
    if (questionType == QuestionType.blankSpace) typeStr = 'blank_space';

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
