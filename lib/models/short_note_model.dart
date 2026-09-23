class ShortNoteModel {
  final int grade;
  final String subject;
  final int unitNumber;
  final String pdfUrl;

  const ShortNoteModel({
    required this.grade,
    required this.subject,
    required this.unitNumber,
    required this.pdfUrl,
  });

  factory ShortNoteModel.fromJson(Map<String, dynamic> json) {
    int parseValToInt(dynamic val, int fallback) {
      if (val == null) return fallback;
      if (val is int) return val;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString().trim()) ?? fallback;
    }

    return ShortNoteModel(
      grade: parseValToInt(json['grade'], 0),
      subject: (json['subject'] ?? '').toString().trim(),
      unitNumber: parseValToInt(json['unit_number'] ?? json['unit'], 1),
      pdfUrl: (json['pdf_url'] ?? json['file_url'] ?? json['url'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'grade': grade,
      'subject': subject,
      'unit_number': unitNumber,
      'pdf_url': pdfUrl,
    };
  }
}
