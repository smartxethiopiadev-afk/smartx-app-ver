class QuestionOption {
  final String id;
  final String text;
  final bool isCorrect;
  final String? explanation;

  QuestionOption({
    required this.id,
    required this.text,
    required this.isCorrect,
    this.explanation,
  });

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return QuestionOption(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      isCorrect: json['is_correct'] == true || json['is_correct'] == 'true',
      explanation: json['explanation']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'is_correct': isCorrect,
      'explanation': explanation,
    };
  }
}

class QuestionModel {
  final String id;
  final String unitId;
  final String questionText;
  final List<QuestionOption> options;
  final String? explanation;
  final String? createdAt;
  final int? questionNumber;
  final int? orderIndex;

  QuestionModel({
    required this.id,
    required this.unitId,
    required this.questionText,
    required this.options,
    this.explanation,
    this.createdAt,
    this.questionNumber,
    this.orderIndex,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    List<QuestionOption> parsedOptions = [];
    final rawOptions = json['options'] ?? json['question_options'];
    if (rawOptions != null && rawOptions is List) {
      parsedOptions = rawOptions
          .map((item) {
            if (item is Map<String, dynamic>) {
              return QuestionOption.fromJson(item);
            } else if (item is Map) {
              return QuestionOption.fromJson(Map<String, dynamic>.from(item));
            }
            return null;
          })
          .whereType<QuestionOption>()
          .toList();
    }

    int? qNum = int.tryParse(json['question_number']?.toString() ?? '');
    int? oIdx = int.tryParse(json['order_index']?.toString() ?? '') ?? qNum;

    return QuestionModel(
      id: json['id']?.toString() ?? '',
      unitId: json['unit_id']?.toString() ?? json['unit_number']?.toString() ?? '',
      questionText: json['question_text']?.toString() ?? json['question']?.toString() ?? json['questionText']?.toString() ?? '',
      options: parsedOptions,
      explanation: json['explanation']?.toString(),
      createdAt: json['created_at']?.toString(),
      questionNumber: qNum,
      orderIndex: oIdx,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unit_id': unitId,
      'question_text': questionText,
      'question_options': options.map((e) => e.toJson()).toList(),
      'explanation': explanation,
      'created_at': createdAt,
      'question_number': questionNumber,
      'order_index': orderIndex,
    };
  }

  /// Returns the zero-based index of the correct option in [options], or -1 if none is marked correct.
  int get correctAnswerIndex => options.indexWhere((opt) => opt.isCorrect);
}
