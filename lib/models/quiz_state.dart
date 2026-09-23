import 'question_model.dart';
import '../services/quiz_service.dart';

/// Encapsulates the complete runtime state of a quiz or test session.
class QuizState {
  final QuizMode mode;
  final String questionTypeFilter; // 'all', 'multiple_choice', 'true_false', 'blank_space', 'matching'
  final int grade;
  final String subject;
  final int unit;
  final List<QuestionModel> questions;
  final int currentIndex;

  // Answers State
  final Map<int, int> selectedOptionIndices; // questionIndex -> optionIndex
  final Map<int, String> blankAnswers; // questionIndex -> userInput
  final Map<int, Map<int, String>> matchingAnswers; // questionIndex -> pairIndex -> chosenRight
  final Set<int> submittedQuestions; // For practice mode (questions already evaluated)
  final Set<int> revealedHints; // questionIndices where hint was revealed

  // Timing & Review State
  final int timeLeftSeconds;
  final int totalTimeSeconds;
  final bool isCompleted;
  final bool showReview;

  const QuizState({
    required this.mode,
    required this.questionTypeFilter,
    required this.grade,
    required this.subject,
    required this.unit,
    required this.questions,
    this.currentIndex = 0,
    this.selectedOptionIndices = const {},
    this.blankAnswers = const {},
    this.matchingAnswers = const {},
    this.submittedQuestions = const {},
    this.revealedHints = const {},
    this.timeLeftSeconds = 0,
    this.totalTimeSeconds = 0,
    this.isCompleted = false,
    this.showReview = false,
  });

  /// Factory for fresh quiz session
  factory QuizState.initial({
    required QuizMode mode,
    required String questionTypeFilter,
    required int grade,
    required String subject,
    required int unit,
    required List<QuestionModel> questions,
    int? customTimeLimitSeconds,
  }) {
    final int calculatedTime = customTimeLimitSeconds ?? (mode == QuizMode.exam ? questions.length * 90 : 0);
    return QuizState(
      mode: mode,
      questionTypeFilter: questionTypeFilter,
      grade: grade,
      subject: subject,
      unit: unit,
      questions: questions,
      currentIndex: 0,
      timeLeftSeconds: calculatedTime,
      totalTimeSeconds: calculatedTime,
    );
  }

  bool get isPracticeMode => mode == QuizMode.practice;
  bool get isExamMode => mode == QuizMode.exam;
  int get totalQuestions => questions.length;
  bool get hasQuestions => questions.isNotEmpty;
  QuestionModel? get currentQuestion => currentIndex < questions.length ? questions[currentIndex] : null;

  /// Check whether question at [index] has been answered
  bool isQuestionAnswered(int index) {
    if (index >= questions.length) return false;
    final q = questions[index];
    if (q.isBlankSpace) {
      final input = blankAnswers[index];
      return input != null && input.trim().isNotEmpty;
    }
    if (q.isMatching) {
      final map = matchingAnswers[index];
      return map != null && map.length == q.matchingPairs.length;
    }
    return selectedOptionIndices.containsKey(index);
  }

  /// Check whether question at [index] was answered correctly
  bool isQuestionCorrect(int index) {
    if (index >= questions.length) return false;
    final q = questions[index];

    if (q.isBlankSpace) {
      final input = blankAnswers[index] ?? '';
      return q.checkBlankAnswer(input);
    }

    if (q.isMatching) {
      final userPairs = matchingAnswers[index];
      if (userPairs == null || userPairs.isEmpty) return false;
      for (int i = 0; i < q.matchingPairs.length; i++) {
        final pair = q.matchingPairs[i];
        if (userPairs[i] != pair.right) return false;
      }
      return true;
    }

    final selected = selectedOptionIndices[index];
    if (selected == null || selected >= q.options.length) return false;

    if (q.isTrueFalse) {
      if (q.correctBoolean != null) {
        return (selected == 0 && q.correctBoolean == true) || (selected == 1 && q.correctBoolean == false);
      }
    }

    return q.options[selected].isCorrect;
  }

  /// Total count of answered questions
  int get answeredCount {
    int count = 0;
    for (int i = 0; i < questions.length; i++) {
      if (isQuestionAnswered(i)) count++;
    }
    return count;
  }

  /// Total count of correct answers
  int get correctCount {
    int count = 0;
    for (int i = 0; i < questions.length; i++) {
      if (isQuestionCorrect(i)) count++;
    }
    return count;
  }

  /// Total count of incorrect answers
  int get incorrectCount {
    int count = 0;
    for (int i = 0; i < questions.length; i++) {
      if (isQuestionAnswered(i) && !isQuestionCorrect(i)) count++;
    }
    return count;
  }

  /// Total unanswered questions count
  int get unansweredCount => totalQuestions - answeredCount;

  /// Percentage score (0.0 to 100.0)
  double get scorePercentage {
    if (totalQuestions == 0) return 0.0;
    return (correctCount / totalQuestions) * 100.0;
  }

  /// Standard educational letter grade
  String get letterGrade {
    final pct = scorePercentage;
    if (pct >= 90) return 'A';
    if (pct >= 80) return 'B';
    if (pct >= 70) return 'C';
    if (pct >= 60) return 'D';
    return 'F';
  }

  /// Passing criteria (>= 50%)
  bool get isPassed => scorePercentage >= 50.0;

  /// Copy with modifications
  QuizState copyWith({
    QuizMode? mode,
    String? questionTypeFilter,
    int? grade,
    String? subject,
    int? unit,
    List<QuestionModel>? questions,
    int? currentIndex,
    Map<int, int>? selectedOptionIndices,
    Map<int, String>? blankAnswers,
    Map<int, Map<int, String>>? matchingAnswers,
    Set<int>? submittedQuestions,
    Set<int>? revealedHints,
    int? timeLeftSeconds,
    int? totalTimeSeconds,
    bool? isCompleted,
    bool? showReview,
  }) {
    return QuizState(
      mode: mode ?? this.mode,
      questionTypeFilter: questionTypeFilter ?? this.questionTypeFilter,
      grade: grade ?? this.grade,
      subject: subject ?? this.subject,
      unit: unit ?? this.unit,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedOptionIndices: selectedOptionIndices ?? this.selectedOptionIndices,
      blankAnswers: blankAnswers ?? this.blankAnswers,
      matchingAnswers: matchingAnswers ?? this.matchingAnswers,
      submittedQuestions: submittedQuestions ?? this.submittedQuestions,
      revealedHints: revealedHints ?? this.revealedHints,
      timeLeftSeconds: timeLeftSeconds ?? this.timeLeftSeconds,
      totalTimeSeconds: totalTimeSeconds ?? this.totalTimeSeconds,
      isCompleted: isCompleted ?? this.isCompleted,
      showReview: showReview ?? this.showReview,
    );
  }
}
