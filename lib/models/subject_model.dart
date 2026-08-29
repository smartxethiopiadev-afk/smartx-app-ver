class UnitModel {
  final int unitNumber;
  final String unitId;
  final String enTitle;
  final String amTitle;
  final String description;
  final int questionCount;
  final bool hasNotes;
  final int estimatedMinutes;

  const UnitModel({
    required this.unitNumber,
    required this.unitId,
    required this.enTitle,
    required this.amTitle,
    required this.description,
    required this.questionCount,
    required this.hasNotes,
    required this.estimatedMinutes,
  });

  Map<String, dynamic> toJson() => {
    'unitNumber': unitNumber,
    'unitId': unitId,
    'enTitle': enTitle,
    'amTitle': amTitle,
    'description': description,
    'questionCount': questionCount,
    'hasNotes': hasNotes,
    'estimatedMinutes': estimatedMinutes,
  };

  factory UnitModel.fromJson(Map<String, dynamic> json) => UnitModel(
    unitNumber: json['unitNumber'] as int,
    unitId: json['unitId'] as String,
    enTitle: json['enTitle'] as String,
    amTitle: json['amTitle'] as String,
    description: json['description'] as String,
    questionCount: json['questionCount'] as int,
    hasNotes: json['hasNotes'] as bool,
    estimatedMinutes: json['estimatedMinutes'] as int,
  );
}
