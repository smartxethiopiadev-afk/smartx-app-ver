class ShortNoteModel {
  final String id;
  final int grade;
  final String subject;
  final int unitNumber;
  final String title;
  final String content;

  const ShortNoteModel({
    required this.id,
    required this.grade,
    required this.subject,
    required this.unitNumber,
    required this.title,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'grade': grade,
    'subject': subject,
    'unit_number': unitNumber,
    'title': title,
    'html_content': content,
  };

  factory ShortNoteModel.fromJson(Map<String, dynamic> json) => ShortNoteModel(
    id: json['id'] as String? ?? '',
    grade: (json['grade'] as num?)?.toInt() ?? 11,
    subject: json['subject'] as String? ?? '',
    unitNumber: (json['unit_number'] as num?)?.toInt() ?? 1,
    title: json['title'] as String? ?? '',
    content: json['html_content'] as String? ?? json['content'] as String? ?? '',
  );
}
