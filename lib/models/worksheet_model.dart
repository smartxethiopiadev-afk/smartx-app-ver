class WorksheetModel {
  final String id;
  final int grade;
  final String subject;
  final int unitNumber;
  final String title;
  final String amTitle;
  final String description;
  final int totalQuestions;
  final int downloadCount;
  final String difficulty;
  final List<String> keyTopics;
  final String? fileUrl;

  const WorksheetModel({
    required this.id,
    required this.grade,
    required this.subject,
    required this.unitNumber,
    required this.title,
    required this.amTitle,
    required this.description,
    required this.totalQuestions,
    this.downloadCount = 0,
    this.difficulty = 'Medium',
    this.keyTopics = const [],
    this.fileUrl,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'grade': grade,
    'subject': subject,
    'unit_number': unitNumber,
    'title': title,
    'am_title': amTitle,
    'description': description,
    'total_questions': totalQuestions,
    'download_count': downloadCount,
    'difficulty': difficulty,
    'key_topics': keyTopics,
    'file_url': fileUrl,
  };

  factory WorksheetModel.fromJson(Map<String, dynamic> json) => WorksheetModel(
    id: json['id'] as String? ?? '',
    grade: (json['grade'] as num?)?.toInt() ?? 11,
    subject: json['subject'] as String? ?? '',
    unitNumber: (json['unit_number'] as num?)?.toInt() ?? 1,
    title: json['title'] as String? ?? '',
    amTitle: json['am_title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    totalQuestions: (json['total_questions'] as num?)?.toInt() ?? 10,
    downloadCount: (json['download_count'] as num?)?.toInt() ?? 0,
    difficulty: json['difficulty'] as String? ?? 'Medium',
    keyTopics: (json['key_topics'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    fileUrl: json['file_url'] as String?,
  );
}
