class VideoModel {
  final String id;
  final int grade;
  final String subject;
  final int unitNumber;
  final int partNumber;
  final String title;
  final String youtubeVideoId;
  final String? durationText;
  final int orderIndex;
  final DateTime? createdAt;

  VideoModel({
    required this.id,
    required this.grade,
    required this.subject,
    required this.unitNumber,
    this.partNumber = 1,
    required this.title,
    required this.youtubeVideoId,
    this.durationText,
    this.orderIndex = 1,
    this.createdAt,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id']?.toString() ?? '',
      grade: json['grade'] is int
          ? json['grade']
          : int.tryParse(json['grade']?.toString() ?? '9') ?? 9,
      subject: json['subject']?.toString() ?? '',
      unitNumber: json['unit_number'] is int
          ? json['unit_number']
          : int.tryParse(json['unit_number']?.toString() ?? '1') ?? 1,
      partNumber: json['part_number'] is int
          ? json['part_number']
          : int.tryParse(json['part_number']?.toString() ?? '1') ?? 1,
      title: json['title']?.toString() ?? '',
      youtubeVideoId: json['youtube_video_id']?.toString() ?? '',
      durationText: json['duration_text']?.toString() ?? '15 mins',
      orderIndex: json['order_index'] is int
          ? json['order_index']
          : int.tryParse(json['order_index']?.toString() ?? '1') ?? 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'grade': grade,
      'subject': subject,
      'unit_number': unitNumber,
      'part_number': partNumber,
      'title': title,
      'youtube_video_id': youtubeVideoId,
      'duration_text': durationText,
      'order_index': orderIndex,
    };
  }

  String get thumbnailUrl =>
      'https://img.youtube.com/vi/$youtubeVideoId/hqdefault.jpg';
}
