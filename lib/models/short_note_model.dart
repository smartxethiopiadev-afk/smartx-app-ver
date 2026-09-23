class ShortNoteModel {
  final String id;
  final int grade;
  final String subject;
  final int unitNumber;
  final String title;
  final String pdfUrl;
  final String summary;
  final double fileSizeMb;
  final DateTime? createdAt;

  ShortNoteModel({
    required this.id,
    required this.grade,
    required this.subject,
    required this.unitNumber,
    required this.title,
    required this.pdfUrl,
    required this.summary,
    this.fileSizeMb = 2.5,
    this.createdAt,
  });

  factory ShortNoteModel.fromJson(Map<String, dynamic> json) {
    return ShortNoteModel(
      id: json['id']?.toString() ?? '',
      grade: json['grade'] is int ? json['grade'] : int.tryParse(json['grade']?.toString() ?? '0') ?? 0,
      subject: json['subject']?.toString() ?? '',
      unitNumber: json['unit_number'] is int ? json['unit_number'] : int.tryParse(json['unit_number']?.toString() ?? '1') ?? 1,
      title: json['title']?.toString() ?? '',
      pdfUrl: json['pdf_url']?.toString() ?? json['file_url']?.toString() ?? json['url']?.toString() ?? '',
      summary: json['summary']?.toString() ?? json['content']?.toString() ?? json['description']?.toString() ?? '',
      fileSizeMb: json['file_size_mb'] != null
          ? (json['file_size_mb'] is num ? (json['file_size_mb'] as num).toDouble() : double.tryParse(json['file_size_mb'].toString()) ?? 2.5)
          : 2.5,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'grade': grade,
      'subject': subject,
      'unit_number': unitNumber,
      'title': title,
      'pdf_url': pdfUrl,
      'summary': summary,
      'file_size_mb': fileSizeMb,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
