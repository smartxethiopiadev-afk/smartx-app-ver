class DownloadedUnitInfo {
  final String unitId;
  final String subjectId;
  final int grade;
  final int unitNumber;
  final String enTitle;
  final String amTitle;
  final DateTime downloadedAt;
  final String type; // 'short_note', 'worksheet', 'quiz', 'full_bundle'
  final int sizeKb;
  final int questionCount;

  DownloadedUnitInfo({
    required this.unitId,
    required this.subjectId,
    required this.grade,
    required this.unitNumber,
    required this.enTitle,
    required this.amTitle,
    required this.downloadedAt,
    required this.type,
    this.sizeKb = 120,
    this.questionCount = 15,
  });

  Map<String, dynamic> toJson() => {
    'unitId': unitId,
    'subjectId': subjectId,
    'grade': grade,
    'unitNumber': unitNumber,
    'enTitle': enTitle,
    'amTitle': amTitle,
    'downloadedAt': downloadedAt.toIso8601String(),
    'type': type,
    'sizeKb': sizeKb,
    'questionCount': questionCount,
  };

  factory DownloadedUnitInfo.fromJson(Map<String, dynamic> json) => DownloadedUnitInfo(
    unitId: json['unitId'] as String,
    subjectId: json['subjectId'] as String? ?? 'general',
    grade: (json['grade'] as num?)?.toInt() ?? 11,
    unitNumber: (json['unitNumber'] as num?)?.toInt() ?? 1,
    enTitle: json['enTitle'] as String? ?? '',
    amTitle: json['amTitle'] as String? ?? '',
    downloadedAt: DateTime.tryParse(json['downloadedAt'] as String? ?? '') ?? DateTime.now(),
    type: json['type'] as String? ?? 'full_bundle',
    sizeKb: (json['sizeKb'] as num?)?.toInt() ?? 120,
    questionCount: (json['questionCount'] as num?)?.toInt() ?? 15,
  );
}

class AdMobTelemetryItem {
  final String id;
  final String adType; // 'Banner', 'Interstitial', 'Rewarded Video', 'Native'
  final String status; // 'Active & Serving', 'Impression Logged', 'Ad Clicked', 'Cached Offline'
  final DateTime timestamp;
  final String network;
  final double estimatedEcpm;

  AdMobTelemetryItem({
    required this.id,
    required this.adType,
    required this.status,
    required this.timestamp,
    this.network = 'Google AdMob v23.0',
    this.estimatedEcpm = 1.45,
  });
}

class QuestionReportModel {
  final String? id;
  final String questionId;
  final String unitId;
  final String questionText;
  final String reason;
  final String studentPhone;
  final String studentName;
  final DateTime createdAt;

  QuestionReportModel({
    this.id,
    required this.questionId,
    required this.unitId,
    required this.questionText,
    required this.reason,
    required this.studentPhone,
    required this.studentName,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'question_id': questionId,
    'unit_id': unitId,
    'question_text': questionText,
    'reason': reason,
    'student_phone': studentPhone,
    'student_name': studentName,
    'created_at': createdAt.toIso8601String(),
  };
}

class FeedbackReportModel {
  final String? id;
  final String userName;
  final String phoneNumber;
  final int rating;
  final String category;
  final String message;
  final DateTime createdAt;

  FeedbackReportModel({
    this.id,
    required this.userName,
    required this.phoneNumber,
    required this.rating,
    required this.category,
    required this.message,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'user_name': userName,
    'phone_number': phoneNumber,
    'rating': rating,
    'category': category,
    'message': message,
    'created_at': createdAt.toIso8601String(),
  };
}
