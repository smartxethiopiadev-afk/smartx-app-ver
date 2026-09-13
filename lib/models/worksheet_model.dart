class WorksheetQuestionItem {
  final int number;
  final String questionHtml;
  final String solutionHtml;

  const WorksheetQuestionItem({
    required this.number,
    required this.questionHtml,
    required this.solutionHtml,
  });

  Map<String, dynamic> toJson() => {
    'number': number,
    'questionHtml': questionHtml,
    'solutionHtml': solutionHtml,
  };

  factory WorksheetQuestionItem.fromJson(Map<String, dynamic> json) =>
      WorksheetQuestionItem(
        number: (json['number'] as num?)?.toInt() ?? 1,
        questionHtml: json['questionHtml'] as String? ?? '',
        solutionHtml: json['solutionHtml'] as String? ?? '',
      );
}

class WorksheetModel {
  final String id;
  final int grade;
  final String subject;
  final int unitNumber;
  final String title;
  final String questionsHtml;
  final String solutionsHtml;
  final String? packageId;
  final DateTime? createdAt;
  final List<WorksheetQuestionItem>? cachedItems;

  const WorksheetModel({
    required this.id,
    required this.grade,
    required this.subject,
    required this.unitNumber,
    required this.title,
    required this.questionsHtml,
    required this.solutionsHtml,
    this.packageId,
    this.createdAt,
    this.cachedItems,
  });

  factory WorksheetModel.fromJson(Map<String, dynamic> json) {
    return WorksheetModel(
      id: json['id'] as String? ?? '',
      grade: (json['grade'] as num?)?.toInt() ?? 9,
      subject: json['subject'] as String? ?? '',
      unitNumber: (json['unit_number'] as num?)?.toInt() ??
          (json['unitNumber'] as num?)?.toInt() ??
          1,
      title: json['title'] as String? ?? '',
      questionsHtml: json['questions_html'] as String? ??
          json['questionsHtml'] as String? ??
          '',
      solutionsHtml: json['solutions_html'] as String? ??
          json['solutionsHtml'] as String? ??
          '',
      packageId: json['package_id'] as String? ?? json['packageId'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      cachedItems: json['items'] != null
          ? (json['items'] as List<dynamic>)
              .map((e) =>
                  WorksheetQuestionItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'grade': grade,
    'subject': subject,
    'unit_number': unitNumber,
    'title': title,
    'questions_html': questionsHtml,
    'solutions_html': solutionsHtml,
    'package_id': packageId,
    'created_at': createdAt?.toIso8601String(),
    'items': parsedQuestions.map((e) => e.toJson()).toList(),
  };

  /// Parses individual questions and solutions from HTML markup so students can
  /// toggle "Show / Hide Solution" per question.
  List<WorksheetQuestionItem> get parsedQuestions {
    if (cachedItems != null && cachedItems!.isNotEmpty) {
      return cachedItems!;
    }

    final List<WorksheetQuestionItem> items = [];

    // Check if questions are wrapped in <div class="question" ...>
    final questionMatches = RegExp(
      r'<div[^>]*class="question"[^>]*>([\s\S]*?)<\/div>',
      caseSensitive: false,
    ).allMatches(questionsHtml);

    final solutionMatches = RegExp(
      r'<div[^>]*class="solution"[^>]*>([\s\S]*?)<\/div>',
      caseSensitive: false,
    ).allMatches(solutionsHtml);

    if (questionMatches.isNotEmpty) {
      final solList = solutionMatches.map((m) => m.group(1) ?? '').toList();
      int index = 1;
      for (final qMatch in questionMatches) {
        final qContent = qMatch.group(1) ?? '';
        final sContent = (index - 1 < solList.length)
            ? solList[index - 1]
            : 'No solution available.';
        items.add(WorksheetQuestionItem(
          number: index,
          questionHtml: qContent,
          solutionHtml: sContent,
        ));
        index++;
      }
      return items;
    }

    // Fallback: If not formatted with div.question, split by <h3>Question or <hr>
    final questionParts = questionsHtml.split(RegExp(r'<hr\s*\/?>|<h3>Question\s*\d+<\/h3>', caseSensitive: false));
    final solutionParts = solutionsHtml.split(RegExp(r'<hr\s*\/?>|<h4>Solution\s*(?:for\s*Question\s*\d+)?:?<\/h4>', caseSensitive: false));

    final cleanQuestions = questionParts
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    final cleanSolutions = solutionParts
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (cleanQuestions.isNotEmpty) {
      for (int i = 0; i < cleanQuestions.length; i++) {
        final qContent = cleanQuestions[i];
        final sContent = (i < cleanSolutions.length)
            ? cleanSolutions[i]
            : (cleanSolutions.isNotEmpty
                ? cleanSolutions.last
                : solutionsHtml);
        items.add(WorksheetQuestionItem(
          number: i + 1,
          questionHtml: qContent,
          solutionHtml: sContent,
        ));
      }
      return items;
    }

    // Single item fallback
    if (questionsHtml.isNotEmpty) {
      items.add(WorksheetQuestionItem(
        number: 1,
        questionHtml: questionsHtml,
        solutionHtml: solutionsHtml.isNotEmpty
            ? solutionsHtml
            : 'No solution available.',
      ));
    }

    return items;
  }
}
