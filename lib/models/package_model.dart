enum PackageTier {
  singleSubject,
  streamOrGrade,
  allInclusiveMatric,
}

class PackageModel {
  final String id;
  final String title;
  final int grade;
  final double priceEtb;
  final String description;
  final String? badgeText;
  final PackageTier tier;
  final String? subject;
  final List<String> features;
  final DateTime? createdAt;

  const PackageModel({
    required this.id,
    required this.title,
    required this.grade,
    required this.priceEtb,
    required this.description,
    this.badgeText,
    this.tier = PackageTier.streamOrGrade,
    this.subject,
    this.features = const [],
    this.createdAt,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    PackageTier parsedTier = PackageTier.streamOrGrade;
    final String? tierStr = json['tier'] as String?;
    if (tierStr == 'single_subject') {
      parsedTier = PackageTier.singleSubject;
    } else if (tierStr == 'all_inclusive') {
      parsedTier = PackageTier.allInclusiveMatric;
    }

    return PackageModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      grade: (json['grade'] as num?)?.toInt() ?? 9,
      priceEtb: (json['price_etb'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      badgeText: json['badge_text'] as String?,
      tier: parsedTier,
      subject: json['subject'] as String?,
      features: (json['features'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
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
    'tier': tier.name,
    'subject': subject,
    'features': features,
    'created_at': createdAt?.toIso8601String(),
  };

  /// Generates the 3 package tiers for a given Grade and optional Subject
  static List<PackageModel> getPackagesForGrade(int grade, {String? subject}) {
    final String subjectName = (subject != null && subject.trim().isNotEmpty) ? subject.trim() : 'Mathematics';
    final String subjectSlug = subjectName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');

    return [
      // 1. Single Subject Pack (150 ETB)
      PackageModel(
        id: 'pkg_g${grade}_$subjectSlug',
        title: 'Grade $grade $subjectName Only',
        grade: grade,
        priceEtb: 150.00,
        description: 'Complete Units 1–10 access for $subjectName. Includes full chapter short notes, quizzes, and unit worksheets with solutions.',
        badgeText: 'FOCUSED',
        tier: PackageTier.singleSubject,
        subject: subjectName,
        features: [
          'Full Units (1–10) of $subjectName',
          'Curriculum Short Notes & Formulas',
          'Interactive Chapter Quizzes',
          'Offline Downloads on 1 Phone',
        ],
      ),

      // 2. Full Stream / Grade Pack (400 ETB)
      PackageModel(
        id: 'pkg_grade_$grade',
        title: 'Grade $grade Complete All-Subjects Pack',
        grade: grade,
        priceEtb: 400.00,
        description: 'Unlocks ALL curriculum subjects for Grade $grade (Math, Physics, Chemistry, Biology, English, etc.) with offline access.',
        badgeText: 'MOST POPULAR',
        tier: PackageTier.streamOrGrade,
        features: [
          'All Grade $grade Subjects & Units Unlocked',
          'Every Chapter Short Notes & Summary',
          'All Model Worksheets with Step-by-Step Solutions',
          '100% Offline Access for 1 Device',
        ],
      ),

      // 3. All-Inclusive Matric Prep / Master Pack (600 ETB)
      PackageModel(
        id: 'pkg_all_inclusive_g$grade',
        title: 'Grade $grade All-Inclusive Matric & Exam Prep Kit',
        grade: grade,
        priceEtb: 600.00,
        description: 'Ultimate comprehensive bundle: All Grade $grade subjects + National Exam past papers + Formula Cheat Sheets + Priority Telegram tutor support.',
        badgeText: 'BEST VALUE',
        tier: PackageTier.allInclusiveMatric,
        features: [
          'Everything in All-Subjects Pack',
          '10+ Years Past EUEE / National Matric Questions',
          'Formula Flashcards & Quick Reference Sheets',
          'Priority VIP Telegram Admin & Tutor Support',
          'Single-Device Anti-Loss Cloud Sync',
        ],
      ),
    ];
  }

  /// Predefined default packages for offline / instant availability
  static List<PackageModel> get defaultPackages => [
    const PackageModel(
      id: 'pkg_grade_9',
      title: 'Grade 9 Foundation & Exam Prep',
      grade: 9,
      priceEtb: 400.00,
      description: 'Complete access to all Grade 9 units across Mathematics, Physics, Chemistry, and Biology. Includes short notes, worksheets, and quizzes.',
      badgeText: 'POPULAR',
      tier: PackageTier.streamOrGrade,
      features: [
        'All Grade 9 Subjects Unlocked',
        'Curriculum Summaries & Quizzes',
        'Offline Study on 1 Device',
      ],
    ),
    const PackageModel(
      id: 'pkg_grade_10',
      title: 'Grade 10 National Exam (EGSECE) Booster',
      grade: 10,
      priceEtb: 400.00,
      description: 'Comprehensive EGSECE toolkit with all unit worksheets, solved model exams, formula sheets, and offline mastery tests.',
      badgeText: 'EXAM READY',
      tier: PackageTier.streamOrGrade,
      features: [
        'All Grade 10 Subjects Unlocked',
        'Solved Model Exams & Quizzes',
        'EGSECE Question Bank',
      ],
    ),
    const PackageModel(
      id: 'pkg_grade_11',
      title: 'Grade 11 Natural & Social Sciences Mastery',
      grade: 11,
      priceEtb: 400.00,
      description: 'Full university-preparatory package for Grade 11. Advanced practice problems, calculus & trigonometry worksheets, chemistry reaction guides.',
      badgeText: 'PREP PACK',
      tier: PackageTier.streamOrGrade,
      features: [
        'All Grade 11 Natural & Social Sciences',
        'Advanced Topic Worksheets',
        'Step-by-step Model Solutions',
      ],
    ),
    const PackageModel(
      id: 'pkg_grade_12',
      title: 'Grade 12 University Entrance (EUEE) Master Package',
      grade: 12,
      priceEtb: 600.00,
      description: 'The ultimate Ethiopian University Entrance Examination kit. Past 10 years matric questions solved step-by-step, formula flashcards, and tutor support.',
      badgeText: 'BEST VALUE',
      tier: PackageTier.allInclusiveMatric,
      features: [
        'All Grade 12 Subjects & Units Unlocked',
        '10+ Years Past EUEE Matric Questions Solved',
        'Formula Flashcards & Quick Reference',
        'Priority Telegram Support',
      ],
    ),
  ];
}
