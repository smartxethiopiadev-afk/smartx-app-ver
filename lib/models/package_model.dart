class PackageModel {
  final String id;
  final String title;
  final int grade;
  final double priceEtb;
  final String description;
  final String? badgeText;
  final DateTime? createdAt;

  const PackageModel({
    required this.id,
    required this.title,
    required this.grade,
    required this.priceEtb,
    required this.description,
    this.badgeText,
    this.createdAt,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      grade: (json['grade'] as num?)?.toInt() ?? 9,
      priceEtb: (json['price_etb'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      badgeText: json['badge_text'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'grade': grade,
    'price_etb': priceEtb,
    'description': description,
    'badge_text': badgeText,
    'created_at': createdAt?.toIso8601String(),
  };

  /// Predefined default packages for offline / instant availability
  static List<PackageModel> get defaultPackages => [
    const PackageModel(
      id: 'pkg_grade_9',
      title: 'Grade 9 Ultimate Foundation & Exam Prep',
      grade: 9,
      priceEtb: 299.00,
      description: 'Complete access to all Grade 9 units (Units 1–9) across Mathematics, Physics, Chemistry, and Biology. Includes short notes, practice worksheets with step-by-step solutions, and chapter quizzes.',
      badgeText: 'MOST POPULAR',
    ),
    const PackageModel(
      id: 'pkg_grade_10',
      title: 'Grade 10 National Exam (EGSECE) Booster',
      grade: 10,
      priceEtb: 349.00,
      description: 'Comprehensive Ethiopian General Secondary Education Certificate Examination toolkit. Contains all unit worksheets, solved model exams, formula sheets, and offline mastery tests.',
      badgeText: 'EXAM ESSENTIAL',
    ),
    const PackageModel(
      id: 'pkg_grade_11',
      title: 'Grade 11 Natural & Social Sciences Mastery',
      grade: 11,
      priceEtb: 399.00,
      description: 'Full university-preparatory package for Grade 11 students. Advanced practice problems, calculus & trigonometry worksheets, chemistry reaction guides, and past regional tests.',
      badgeText: 'ADVANCED',
    ),
    const PackageModel(
      id: 'pkg_grade_12',
      title: 'Grade 12 University Entrance (EUEE) Master Package',
      grade: 12,
      priceEtb: 499.00,
      description: 'The ultimate Ethiopian University Entrance Examination preparation kit. Past 10 years matric exam questions solved step-by-step, all unit notes, formula flashcards, and priority Telegram tutor support.',
      badgeText: 'BEST VALUE',
    ),
  ];
}
