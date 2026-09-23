class OfflineQuestionPackage {
  final String unitId; // Normalized unit ID e.g. "g9_mathematics_u1"
  final String title;
  final String subject;
  final int grade;
  final int unit;
  final int totalQuestions;
  final int mcqCount;
  final int trueFalseCount;
  final int blankCount;
  final int matchingCount;
  final int examCount;
  final int downloadedAt;
  final int payloadSizeBytes;

  OfflineQuestionPackage({
    required this.unitId,
    required this.title,
    required this.subject,
    required this.grade,
    required this.unit,
    required this.totalQuestions,
    required this.mcqCount,
    required this.trueFalseCount,
    required this.blankCount,
    required this.matchingCount,
    required this.examCount,
    required this.downloadedAt,
    required this.payloadSizeBytes,
  });

  Map<String, dynamic> toJson() => {
    'unitId': unitId,
    'title': title,
    'subject': subject,
    'grade': grade,
    'unit': unit,
    'totalQuestions': totalQuestions,
    'mcqCount': mcqCount,
    'trueFalseCount': trueFalseCount,
    'blankCount': blankCount,
    'matchingCount': matchingCount,
    'examCount': examCount,
    'downloadedAt': downloadedAt,
    'payloadSizeBytes': payloadSizeBytes,
  };

  factory OfflineQuestionPackage.fromJson(Map<String, dynamic> json) => OfflineQuestionPackage(
    unitId: json['unitId'] as String? ?? '',
    title: json['title'] as String? ?? 'Unit Practice & Exam Package',
    subject: json['subject'] as String? ?? 'General',
    grade: json['grade'] as int? ?? 9,
    unit: json['unit'] as int? ?? 1,
    totalQuestions: json['totalQuestions'] as int? ?? 0,
    mcqCount: json['mcqCount'] as int? ?? 0,
    trueFalseCount: json['trueFalseCount'] as int? ?? 0,
    blankCount: json['blankCount'] as int? ?? 0,
    matchingCount: json['matchingCount'] as int? ?? 0,
    examCount: json['examCount'] as int? ?? 0,
    downloadedAt: json['downloadedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    payloadSizeBytes: json['payloadSizeBytes'] as int? ?? 0,
  );

  String get formattedSize {
    if (payloadSizeBytes <= 0) return '24 KB';
    if (payloadSizeBytes < 1024 * 1024) {
      return '${(payloadSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(payloadSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get breakdownText {
    final List<String> parts = [];
    if (mcqCount > 0) parts.add('$mcqCount MCQs');
    if (trueFalseCount > 0) parts.add('$trueFalseCount T/F');
    if (blankCount > 0) parts.add('$blankCount Blanks');
    if (matchingCount > 0) parts.add('$matchingCount Matching');
    if (parts.isEmpty && totalQuestions > 0) parts.add('$totalQuestions Questions');
    return parts.join(' • ');
  }
}
