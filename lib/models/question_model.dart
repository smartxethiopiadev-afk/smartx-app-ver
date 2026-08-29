class QuestionOption {
  final String id;
  final String text;
  final bool isCorrect;
  final String? explanation;

  const QuestionOption({
    required this.id,
    required this.text,
    required this.isCorrect,
    this.explanation,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'is_correct': isCorrect,
    'explanation': explanation,
  };

  factory QuestionOption.fromJson(Map<String, dynamic> json) => QuestionOption(
    id: json['id'] as String? ?? '',
    text: json['text'] as String? ?? '',
    isCorrect: json['is_correct'] as bool? ?? false,
    explanation: json['explanation'] as String?,
  );
}

class QuestionModel {
  final String id;
  final String unitId;
  final String questionText;
  final int? questionNumber;
  final String? explanation;
  final List<QuestionOption> options;

  const QuestionModel({
    required this.id,
    required this.unitId,
    required this.questionText,
    this.questionNumber,
    this.explanation,
    required this.options,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'unit_id': unitId,
    'question_text': questionText,
    'question_number': questionNumber,
    'explanation': explanation,
    'question_options': options.map((e) => e.toJson()).toList(),
  };

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    var rawOptions = json['question_options'] as List<dynamic>? ?? [];
    List<QuestionOption> parsedOptions = rawOptions
        .map((e) => QuestionOption.fromJson(e as Map<String, dynamic>))
        .toList();

    return QuestionModel(
      id: json['id'] as String? ?? '',
      unitId: json['unit_id'] as String? ?? '',
      questionText: json['question_text'] as String? ?? '',
      questionNumber: json['question_number'] as int?,
      explanation: json['explanation'] as String?,
      options: parsedOptions,
    );
  }
}
