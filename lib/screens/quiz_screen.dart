// ignore_for_file: prefer_final_fields, prefer_const_constructors, prefer_const_literals_to_create_immutables, use_build_context_synchronously
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question_model.dart';
import '../services/quiz_service.dart';
import '../services/offline_manager.dart';
import '../main.dart';
import '../widgets/quiz_result_dialog.dart';
import '../widgets/math_text.dart';
import '../services/analytics_service.dart';

class QuizScreen extends StatefulWidget {
  final int grade;
  final String? subject;
  final int? unit;
  final bool isOffline;
  final String? offlineUnitId;
  final QuizMode mode;
  final String initialQuestionType;

  const QuizScreen({
    super.key,
    required this.grade,
    this.subject,
    this.unit,
    this.isOffline = false,
    this.offlineUnitId,
    this.mode = QuizMode.practice,
    this.initialQuestionType = 'all',
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<QuestionModel> _questions = [];
  late String _selectedTypeFilter;
  
  int _currentIndex = 0;
  final Map<int, int> _selectedAnswers = {}; // For MCQ and True/False (option index)
  final Map<int, String> _blankInputAnswers = {}; // For Blank Space (typed string)
  final Map<int, Map<int, String>> _matchingAnswers = {}; // For Matching (question index -> pair index -> chosen right item)
  final Map<int, TextEditingController> _blankControllers = {};
  final Set<int> _revealedHints = {};
  final Set<int> _submittedQuestions = {}; // Only for practice mode (already checked)
  bool _showAnswersAndExplanations = false; // Set to true after exam is finished/submitted

  String _getUnitId() {
    if (widget.offlineUnitId != null && widget.offlineUnitId!.isNotEmpty) {
      return widget.offlineUnitId!;
    }
    String sub = (widget.subject ?? 'Physics').toLowerCase();
    String prefix = 'phys_u';
    if (sub.contains('math')) {
      prefix = 'math_u';
    } else if (sub.contains('biol')) {
      prefix = 'bio_u';
    } else if (sub.contains('phys')) {
      prefix = 'phys_u';
    } else if (sub.contains('chem')) {
      prefix = 'chem_u';
    } else if (sub.contains('geog')) {
      prefix = 'geo_u';
    } else if (sub.contains('hist')) {
      prefix = 'hist_u';
    } else if (sub.contains('civ')) {
      prefix = 'civ_u';
    } else if (sub.contains('agri')) {
      prefix = 'agri_u';
    }
    return 'g${widget.grade}_$prefix${widget.unit ?? 1}';
  }

  // Timer fields
  Timer? _quizTimer;
  int _timeLeftSeconds = 0;

  final ScrollController _scrollController = ScrollController();
  List<GlobalKey> _questionKeys = [];

  @override
  void initState() {
    super.initState();
    _selectedTypeFilter = widget.initialQuestionType;
    logScreen('QuizScreen');
    _checkAndRestoreProgress();
  }

  @override
  void dispose() {
    _quizTimer?.cancel();
    _scrollController.dispose();
    for (final controller in _blankControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _getBlankController(int index) {
    if (!_blankControllers.containsKey(index)) {
      final initialText = _blankInputAnswers[index] ?? '';
      final controller = TextEditingController(text: initialText);
      controller.addListener(() {
        _blankInputAnswers[index] = controller.text;
      });
      _blankControllers[index] = controller;
    }
    return _blankControllers[index]!;
  }

  Color _getSubjectThemeColor() {
    final sub = (widget.subject ?? '').toLowerCase();
    if (sub.contains('phys')) return const Color(0xFFF59E0B); // Amber
    if (sub.contains('chem')) return const Color(0xFF10B981); // Emerald
    if (sub.contains('bio')) return const Color(0xFFEC4899); // Pink
    if (sub.contains('math')) return const Color(0xFF3B82F6); // Blue
    return const Color(0xFF6366F1); // Indigo default
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedAnswers.clear();
      _blankInputAnswers.clear();
      _revealedHints.clear();
      _submittedQuestions.clear();
      _showAnswersAndExplanations = false;
      _currentIndex = 0;
    });

    try {
      final List<QuestionModel> fetched;
      final String unitId = _getUnitId();
      final String modeStr = widget.mode == QuizMode.exam ? 'exam' : 'practice';

      // 1. Check if questions for this specific mode and type are downloaded offline
      final offlineModeQuestions = await OfflineManager.getOfflineQuestionsByMode(
        unitId: unitId,
        mode: modeStr,
        questionType: widget.mode == QuizMode.practice ? _selectedTypeFilter : null,
      );

      final String downloadKey = '${unitId}_quiz';
      final bool isQuizDownloaded = await OfflineManager.isDownloaded(downloadKey);

      if (offlineModeQuestions.isNotEmpty) {
        fetched = offlineModeQuestions;
      } else if (isQuizDownloaded) {
        fetched = await OfflineManager.getOfflineQuestions(downloadKey);
      } else if (widget.isOffline && widget.offlineUnitId != null) {
        fetched = await OfflineManager.getOfflineQuestions(widget.offlineUnitId!);
      } else {
        fetched = await QuizService.fetchQuestions(
          grade: widget.grade,
          subject: widget.subject ?? 'unknown',
          unit: widget.unit ?? 1,
          mode: widget.mode,
          questionType: _selectedTypeFilter,
        );
      }

      // Local type filtering if needed
      List<QuestionModel> typeFiltered = fetched;
      if (_selectedTypeFilter != 'all' && widget.mode == QuizMode.practice) {
        typeFiltered = fetched.where((q) {
          if (_selectedTypeFilter == 'multiple_choice') return q.isMultipleChoice;
          if (_selectedTypeFilter == 'true_false') return q.isTrueFalse;
          if (_selectedTypeFilter == 'blank_space') return q.isBlankSpace;
          if (_selectedTypeFilter == 'matching') return q.questionType == QuestionType.matching;
          return true;
        }).toList();
      }

      if (typeFiltered.isEmpty) {
        setState(() {
          _questions = [];
          _isLoading = false;
          _errorMessage = "No questions found for this selected question type.";
        });
        return;
      }

      final List<QuestionModel> selectedQuestions = await QuizService.filterAndSelectQuestions(
        unitId: _getUnitId(),
        allQuestions: typeFiltered,
      );

      final List<QuestionModel> sequentialQuestions = List<QuestionModel>.from(selectedQuestions);
      sequentialQuestions.sort((a, b) {
        if (a.orderIndex != b.orderIndex) {
          return a.orderIndex.compareTo(b.orderIndex);
        }
        if (a.questionNumber != b.questionNumber) {
          return a.questionNumber.compareTo(b.questionNumber);
        }
        return a.id.compareTo(b.id);
      });

      if (mounted) {
        setState(() {
          _questions = sequentialQuestions;
          _questionKeys = List.generate(sequentialQuestions.length, (_) => GlobalKey());
          _isLoading = false;
        });

        // Initialize blank controllers
        for (int i = 0; i < sequentialQuestions.length; i++) {
          if (sequentialQuestions[i].isBlankSpace) {
            _getBlankController(i);
          }
        }

        // Start countdown timer for Exam Mode
        if (widget.mode == QuizMode.exam) {
          _timeLeftSeconds = _questions.length * 90; // 90 seconds per question in exam mode
          _startTimer();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
      debugPrint("Error loading questions: $e");
    }
  }

  void _startTimer() {
    _quizTimer?.cancel();
    _quizTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_timeLeftSeconds > 0) {
        setState(() {
          _timeLeftSeconds--;
        });
      } else {
        timer.cancel();
        _onTimeExpired();
      }
    });
  }

  Future<void> _downloadCurrentModeQuestions() async {
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ጥያቄዎች ገና አልተጫኑም (Questions still loading)',
            style: GoogleFonts.notoSansEthiopic(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final unitId = _getUnitId();
    final modeStr = widget.mode == QuizMode.exam ? 'exam' : 'practice';
    final type = widget.mode == QuizMode.practice ? _selectedTypeFilter : null;

    await OfflineManager.saveOfflineQuestionsByMode(
      unitId: unitId,
      mode: modeStr,
      questionType: type,
      questions: _questions,
      grade: widget.grade,
      unit: widget.unit,
    );

    if (mounted) {
      final isAm = AppStateProvider.of(context).languageCode == 'am';
      final typeLabel = widget.mode == QuizMode.exam
          ? (isAm ? "የፈተና ጥያቄዎች (Exam Mode)" : "Exam Questions")
          : (isAm ? "የልምምድ ጥያቄዎች (${_selectedTypeFilter.toUpperCase()})" : "Practice Questions (${_selectedTypeFilter.toUpperCase()})");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$typeLabel ከመስመር ውጭ ተቀምጠዋል! (Downloaded for Offline)',
            style: GoogleFonts.notoSansEthiopic(),
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onTimeExpired() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Time has expired! Submitting your exam..."),
        backgroundColor: Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _showResults();
  }

  void _onOptionSelected(int optionIndex) {
    if (_questions.isEmpty || _currentIndex >= _questions.length || _currentIndex < 0) return;
    if (_showAnswersAndExplanations) return;
    if (widget.mode == QuizMode.practice && _submittedQuestions.contains(_currentIndex)) return;

    setState(() {
      _selectedAnswers[_currentIndex] = optionIndex;
    });

    _saveProgress();

    if (widget.mode == QuizMode.exam) {
      _scrollToShiftExamQuestionUp();
    }
  }

  void _submitPracticeAnswer() {
    if (_questions.isEmpty || _currentIndex >= _questions.length) return;
    final q = _questions[_currentIndex];

    if (q.isBlankSpace) {
      final text = _blankInputAnswers[_currentIndex]?.trim() ?? '';
      if (text.isEmpty) return;
    } else if (q.questionType == QuestionType.matching) {
      final userPairs = _matchingAnswers[_currentIndex];
      if (userPairs == null || userPairs.length < q.matchingPairs.length) return;
    } else {
      final selectedIdx = _selectedAnswers[_currentIndex];
      if (selectedIdx == null) return;
    }
    
    setState(() {
      _submittedQuestions.add(_currentIndex);
    });

    _saveProgress();
    _scrollToExplanation();
  }

  bool _hasUserAnswered(int index) {
    if (index >= _questions.length || index < 0) return false;
    final q = _questions[index];
    if (q.isBlankSpace) {
      return (_blankInputAnswers[index]?.trim().isNotEmpty ?? false);
    }
    if (q.questionType == QuestionType.matching) {
      final userPairs = _matchingAnswers[index];
      if (userPairs == null || userPairs.isEmpty) return false;
      return userPairs.length >= q.matchingPairs.length;
    }
    return _selectedAnswers.containsKey(index);
  }

  void _jumpToQuestion(int targetIndex) {
    if (targetIndex >= 0 && targetIndex < _questions.length) {
      setState(() {
        _currentIndex = targetIndex;
      });
      _saveProgress();
      _scrollToActiveQuestion();
    }
  }

  void _scrollToActiveQuestion() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_currentIndex < _questionKeys.length && _questionKeys[_currentIndex].currentContext != null) {
        Scrollable.ensureVisible(
          _questionKeys[_currentIndex].currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
          alignment: 0.08,
        );
      }
    });
  }

  void _scrollToExplanation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_currentIndex < _questionKeys.length && _questionKeys[_currentIndex].currentContext != null) {
        Scrollable.ensureVisible(
          _questionKeys[_currentIndex].currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
          alignment: 0.5,
        );
      }
    });
  }

  void _scrollToShiftExamQuestionUp() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_currentIndex < _questionKeys.length && _questionKeys[_currentIndex].currentContext != null) {
        Scrollable.ensureVisible(
          _questionKeys[_currentIndex].currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          alignment: 0.25,
        );
      }
    });
  }

  void _advanceToNext() {
    if (_currentIndex < _questions.length - 1) {
      final int nextIndex = _currentIndex + 1;
      if (nextIndex == 20) {
        _showBreakDialog();
        return;
      }
      setState(() {
        _currentIndex = nextIndex;
      });
      _saveProgress();
      _scrollToActiveQuestion();
    } else {
      _showResults();
    }
  }

  void _advanceToPrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _saveProgress();
      _scrollToActiveQuestion();
    }
  }

  bool _shouldShowExplanation(int index) {
    if (widget.mode == QuizMode.practice) {
      return _submittedQuestions.contains(index);
    } else {
      return _showAnswersAndExplanations;
    }
  }

  void _showExitConfirmationDialog() {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final isExam = widget.mode == QuizMode.exam;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isLight ? Colors.white : const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isExam ? "Exit Exam?" : "Exit Quiz?",
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          isExam
              ? "Are you sure you want to quit this exam? Your progress will be lost and your score won't be saved."
              : "Are you sure you want to quit this practice session? Your progress will be lost.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text("Exit", style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _clearProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('quiz_session_progress_${_getUnitId()}');
    } catch (e) {
      debugPrint("QuizScreen: Failed to clear progress: $e");
    }
  }

  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'quiz_session_progress_${_getUnitId()}';
      
      final Map<String, dynamic> data = {
        'questions': _questions.map((q) => q.toJson()).toList(),
        'currentIndex': _currentIndex,
        'selectedAnswers': _selectedAnswers.map((k, v) => MapEntry(k.toString(), v)),
        'blankInputAnswers': _blankInputAnswers.map((k, v) => MapEntry(k.toString(), v)),
        'submittedQuestions': _submittedQuestions.map((e) => e.toString()).toList(),
        'revealedHints': _revealedHints.map((e) => e.toString()).toList(),
        'timeLeftSeconds': _timeLeftSeconds,
        'mode': widget.mode.toString(),
      };
      
      await prefs.setString(key, jsonEncode(data));
    } catch (e) {
      debugPrint("QuizScreen: Failed to save progress: $e");
    }
  }

  Future<void> _checkAndRestoreProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'quiz_session_progress_${_getUnitId()}';
      if (!prefs.containsKey(key)) {
        await _loadQuestions();
        return;
      }
      
      final String? dataStr = prefs.getString(key);
      if (dataStr == null) {
        await _loadQuestions();
        return;
      }
      
      final Map<String, dynamic> data = jsonDecode(dataStr) as Map<String, dynamic>;
      
      if (!mounted) return;
      
      final bool isLight = Theme.of(context).brightness == Brightness.light;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
            title: Row(
              children: [
                const Icon(Icons.restore_rounded, color: Color(0xFFFF6D00), size: 28),
                const SizedBox(width: 10),
                const Text(
                  "Resume Quiz?",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                ),
              ],
            ),
            content: const Text(
              "We found a saved quiz session for this unit. Would you like to resume where you left off or start a new session?",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await _clearProgress();
                  await _loadQuestions();
                },
                child: Text(
                  "Start New Session",
                  style: TextStyle(color: isLight ? Colors.black54 : Colors.white70, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _restoreSessionFromData(data);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6D00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  "Resume",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint("QuizScreen: Error checking progress: $e");
      await _loadQuestions();
    }
  }

  void _restoreSessionFromData(Map<String, dynamic> data) {
    try {
      final List<dynamic> questionsJson = data['questions'] as List<dynamic>;
      final List<QuestionModel> restoredQuestions = questionsJson
          .map((item) => QuestionModel.fromJson(item as Map<String, dynamic>))
          .toList();
          
      final int savedIndex = data['currentIndex'] as int? ?? 0;
      final int savedTime = data['timeLeftSeconds'] as int? ?? (restoredQuestions.length * 90);
      
      final Map<String, dynamic> answersJson = data['selectedAnswers'] as Map<String, dynamic>? ?? {};
      final Map<int, int> restoredAnswers = {};
      answersJson.forEach((k, v) {
        final intIndex = int.tryParse(k);
        if (intIndex != null) {
          restoredAnswers[intIndex] = v as int;
        }
      });

      final Map<String, dynamic> blankJson = data['blankInputAnswers'] as Map<String, dynamic>? ?? {};
      final Map<int, String> restoredBlankAnswers = {};
      blankJson.forEach((k, v) {
        final intIndex = int.tryParse(k);
        if (intIndex != null) {
          restoredBlankAnswers[intIndex] = v.toString();
        }
      });
      
      setState(() {
        _questions = restoredQuestions;
        _currentIndex = savedIndex;
        _timeLeftSeconds = savedTime;
        _selectedAnswers.clear();
        _selectedAnswers.addAll(restoredAnswers);
        _blankInputAnswers.clear();
        _blankInputAnswers.addAll(restoredBlankAnswers);
        _questionKeys = List.generate(restoredQuestions.length, (_) => GlobalKey());
        _isLoading = false;
        
        _submittedQuestions.clear();
        if (data.containsKey('submittedQuestions') && data['submittedQuestions'] is List) {
          final List<dynamic> subList = data['submittedQuestions'] as List<dynamic>;
          for (final item in subList) {
            final parsedIdx = int.tryParse(item.toString());
            if (parsedIdx != null) {
              _submittedQuestions.add(parsedIdx);
            }
          }
        } else if (widget.mode == QuizMode.practice) {
          _submittedQuestions.addAll(restoredAnswers.keys);
          _submittedQuestions.addAll(restoredBlankAnswers.keys);
        }

        _revealedHints.clear();
        if (data.containsKey('revealedHints') && data['revealedHints'] is List) {
          final List<dynamic> hintList = data['revealedHints'] as List<dynamic>;
          for (final item in hintList) {
            final parsedIdx = int.tryParse(item.toString());
            if (parsedIdx != null) {
              _revealedHints.add(parsedIdx);
            }
          }
        }
      });

      // Synchronize controllers
      for (int i = 0; i < restoredQuestions.length; i++) {
        if (restoredQuestions[i].isBlankSpace) {
          final controller = _getBlankController(i);
          if (restoredBlankAnswers.containsKey(i)) {
            controller.text = restoredBlankAnswers[i]!;
          }
        }
      }
      
      if (widget.mode == QuizMode.exam) {
        _startTimer();
      }
    } catch (e) {
      debugPrint("QuizScreen: Failed to restore session data: $e. Loading fresh instead.");
      _loadQuestions();
    }
  }

  bool _hasShownBreakDialog = false;

  void _showBreakDialog() {
    if (_hasShownBreakDialog) {
      setState(() {
        _currentIndex = 19;
      });
      _scrollToActiveQuestion();
      return;
    }
    _hasShownBreakDialog = true;
    _quizTimer?.cancel();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final bool isLight = Theme.of(context).brightness == Brightness.light;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
          title: Row(
            children: [
              const Icon(Icons.coffee_rounded, color: Color(0xFFFF6D00), size: 28),
              const SizedBox(width: 10),
              Text(
                "Take a Quick Rest!",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: isLight ? const Color(0xFF0F172A) : Colors.white,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "You have completed 20 questions! Outstanding effort. Take a deep breath and rest your eyes before continuing.",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                  color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Your progress has been automatically saved.",
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: isLight ? Colors.grey[600] : Colors.grey[400],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _saveProgress();
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                }
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text(
                "Rest/Pause",
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                if (widget.mode == QuizMode.exam) {
                  _startTimer();
                }
                setState(() {
                  _currentIndex = 19;
                });
                _scrollToActiveQuestion();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6D00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                "Continue",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showResults() async {
    _quizTimer?.cancel();
    if (_questions.isEmpty) return;

    await QuizService.markQuestionsAsAnswered(
      unitId: _getUnitId(),
      questions: _questions,
    );

    await _clearProgress();

    int score = 0;
    
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.isBlankSpace) {
        final userInput = _blankInputAnswers[i] ?? '';
        if (q.checkBlankAnswer(userInput)) {
          score++;
        }
      } else if (q.questionType == QuestionType.matching) {
        final userPairs = _matchingAnswers[i] ?? {};
        int correctCount = 0;
        for (int pIdx = 0; pIdx < q.matchingPairs.length; pIdx++) {
          if (userPairs[pIdx] == q.matchingPairs[pIdx].right) {
            correctCount++;
          }
        }
        if (q.matchingPairs.isNotEmpty && correctCount == q.matchingPairs.length) {
          score++;
        }
      } else {
        if (_selectedAnswers.containsKey(i)) {
          final selectedIdx = _selectedAnswers[i]!;
          if (selectedIdx < q.options.length) {
            final isCorrect = q.options[selectedIdx].isCorrect;
            if (isCorrect) score++;
          }
        }
      }
    }

    if (!mounted) return;

    final percent = (score / _questions.length * 100).round();

    logEvent(
      name: 'quiz_completed',
      parameters: {
        'subject': widget.subject ?? 'General',
        'score': score,
        'total_questions': _questions.length,
        'percent': percent,
        'grade': widget.grade,
        'unit': widget.unit ?? 1,
        'mode': widget.mode == QuizMode.exam ? 'exam' : 'practice',
      },
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final String scoreKey = 'best_score_${widget.grade}_${widget.subject ?? ""}_u${widget.unit ?? 1}';
      final int existingBest = prefs.getInt(scoreKey) ?? 0;
      if (percent > existingBest) {
        await prefs.setInt(scoreKey, percent);
      }
    } catch (_) {}

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String langCode = AppStateProvider.of(context).languageCode;

    QuizResultDialog.show(
      context,
      score: score,
      totalQuestions: _questions.length,
      isExam: widget.mode == QuizMode.exam,
      grade: widget.grade,
      unit: widget.unit,
      subject: widget.subject,
      languageCode: langCode,
      isDark: isDark,
      onReview: () {
        Navigator.of(context).pop();
        setState(() {
          _showAnswersAndExplanations = true;
          _currentIndex = 0;
        });
        _scrollToActiveQuestion();
      },
      onDone: () {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      },
    );
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final backgroundColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final titleTextColor = isLight ? const Color(0xFF0F172A) : Colors.white;

    return PopScope(
      canPop: _showAnswersAndExplanations || widget.mode == QuizMode.practice || _questions.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitConfirmationDialog();
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            tooltip: "Exit",
            onPressed: () {
              if (_showAnswersAndExplanations || widget.mode == QuizMode.practice || _questions.isEmpty) {
                Navigator.of(context).pop();
              } else {
                _showExitConfirmationDialog();
              }
            },
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.subject != null ? "${widget.subject!.toUpperCase()} QUIZ" : "QUIZ",
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2.5),
                decoration: BoxDecoration(
                  color: _showAnswersAndExplanations 
                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                      : (widget.mode == QuizMode.exam 
                          ? const Color(0xFFEF4444).withValues(alpha: 0.12) 
                          : const Color(0xFF3B82F6).withValues(alpha: 0.12)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _showAnswersAndExplanations 
                      ? "REVIEW MODE" 
                      : (widget.mode == QuizMode.exam ? "EXAM MODE (MCQ ONLY)" : "PRACTICE MODE"),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: _showAnswersAndExplanations 
                        ? const Color(0xFF10B981)
                        : (widget.mode == QuizMode.exam 
                            ? const Color(0xFFEF4444) 
                            : const Color(0xFF3B82F6)),
                  ),
                ),
              ),
            ],
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: titleTextColor,
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.download_for_offline_rounded,
                color: Color(0xFF2563EB),
                size: 22,
              ),
              tooltip: "Download Current Mode Questions Offline",
              onPressed: _downloadCurrentModeQuestions,
            ),
            IconButton(
              icon: Icon(
                isLight ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                color: isLight ? const Color(0xFF0F172A) : const Color(0xFFFBBF24),
                size: 22,
              ),
              tooltip: isLight ? "Dark Mode" : "Light Mode",
              onPressed: () {
                try {
                  AppStateProvider.of(context).onToggleTheme();
                } catch (_) {}
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3.5,
                valueColor: AlwaysStoppedAnimation<Color>(_getSubjectThemeColor()),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppStateProvider.of(context).languageCode == 'am'
                  ? "ጥያቄዎችን በመጫን ላይ..."
                  : "Loading quiz questions...",
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null || _questions.isEmpty) {
      final bool isLight = Theme.of(context).brightness == Brightness.light;
      final bool isAm = AppStateProvider.of(context).languageCode == 'am';
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: isLight ? Colors.white : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.quiz_outlined, size: 56, color: _getSubjectThemeColor()),
                const SizedBox(height: 16),
                Text(
                  isAm ? "ጥያቄዎች አልተገኙም" : "No Questions Available",
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const SizedBox(height: 10),
                Text(
                  _errorMessage ?? (isAm ? "ለዚህ ዩኒት እስካሁን የተጫነ የጥያቄ ባንክ የለም።" : "No questions have been published for this unit yet."),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: isLight ? Colors.black54 : Colors.white60),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadQuestions,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(isAm ? "እንደገና ሞክር" : "Retry"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getSubjectThemeColor(),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildQuestionTypeFilterBar(),
        _buildQuestionNumberStrip(),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            itemCount: _questions.length + 1,
            itemBuilder: (context, index) {
              if (index == _questions.length) {
                return _buildFinishedSection();
              }
              return _buildQuestionItem(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionNumberStrip() {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isLight ? Colors.white : const Color(0xFF1E293B),
        border: Border(
          bottom: BorderSide(
            color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
            width: 1,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _questions.length,
        itemBuilder: (context, idx) {
          final isCurrent = idx == _currentIndex;
          final isAnswered = _hasUserAnswered(idx);
          final q = _questions[idx];

          Color bgColor;
          Color textColor;
          Border? border;

          if (isCurrent) {
            bgColor = _getSubjectThemeColor();
            textColor = Colors.white;
          } else if (_shouldShowExplanation(idx)) {
            bool isCorrect = false;
            if (q.isBlankSpace) {
              isCorrect = q.checkBlankAnswer(_blankInputAnswers[idx] ?? '');
            } else if (_selectedAnswers.containsKey(idx)) {
              final sel = _selectedAnswers[idx]!;
              if (sel < q.options.length) {
                isCorrect = q.options[sel].isCorrect;
              }
            }
            bgColor = isCorrect
                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                : const Color(0xFFEF4444).withValues(alpha: 0.15);
            textColor = isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444);
            border = Border.all(
              color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              width: 1.5,
            );
          } else if (isAnswered) {
            bgColor = isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155);
            textColor = isLight ? const Color(0xFF0F172A) : Colors.white;
          } else {
            bgColor = Colors.transparent;
            textColor = isLight ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => _jumpToQuestion(idx),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: border,
                ),
                child: Text(
                  "${idx + 1}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuestionItem(int index) {
    final q = _questions[index];
    final bool isActive = index == _currentIndex;
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final bool showFeedback = _shouldShowExplanation(index);
    final bool isSubmitted = _submittedQuestions.contains(index);
    final bool isExamReview = _showAnswersAndExplanations && widget.mode == QuizMode.exam;
    final bool isAm = AppStateProvider.of(context).languageCode == 'am';

    return Container(
      key: _questionKeys[index],
      margin: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar with Question Number & Type Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    "Question ${index + 1} of ${_questions.length}",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _getSubjectThemeColor(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Question Type Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getTypeColor(q.questionType).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getTypeLabel(q.questionType, isAm),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: _getTypeColor(q.questionType),
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.mode == QuizMode.exam && isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_rounded, size: 14, color: Color(0xFFEF4444)),
                      const SizedBox(width: 5),
                      Text(
                        _formatTime(_timeLeftSeconds),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (index + 1) / _questions.length,
              backgroundColor: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
              valueColor: AlwaysStoppedAnimation<Color>(_getSubjectThemeColor()),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 16),

          // Question Card Box
          Container(
            padding: const EdgeInsets.all(18.0),
            decoration: BoxDecoration(
              color: isLight ? Colors.white : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(
                color: isLight ? const Color(0xFFEDF2F7) : const Color(0xFF334155),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.16),
                  blurRadius: 14.0,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Question text
                _buildMathText(
                  q.questionText,
                  GoogleFonts.inter(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                    color: isLight ? const Color(0xFF0F172A) : Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isLight ? const Color(0xFFEDF2F7) : const Color(0xFF334155),
                ),
                const SizedBox(height: 14),

                // Render based on Question Type
                if (q.questionType == QuestionType.multipleChoice)
                  _buildMultipleChoiceContent(q, index, isActive, showFeedback, isLight)
                else if (q.questionType == QuestionType.trueFalse)
                  _buildTrueFalseContent(q, index, isActive, showFeedback, isLight, isAm)
                else if (q.questionType == QuestionType.blankSpace)
                  _buildBlankSpaceContent(q, index, isActive, showFeedback, isLight, isAm)
                else if (q.questionType == QuestionType.matching)
                  _buildMatchingContent(q, index, isActive, showFeedback, isLight, isAm),
              ],
            ),
          ),

          // Practice Mode Check Answer Button
          if (widget.mode == QuizMode.practice && !isSubmitted && isActive) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _hasUserAnswered(index) ? _submitPracticeAnswer : null,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: Text(
                  isAm ? "መልስ አረጋግጥ (Check Answer)" : "Check Answer",
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getSubjectThemeColor(),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                  disabledForegroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],

          // Explanations Box
          if (showFeedback && q.explanation != null && q.explanation!.trim().isNotEmpty && isActive) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isLight ? const Color(0xFFF0F7FF) : const Color(0xFF1E293B).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left: BorderSide(color: _getSubjectThemeColor(), width: 4.0),
                  top: BorderSide(color: isLight ? const Color(0xFFDBEAFE) : const Color(0xFF334155), width: 1.0),
                  right: BorderSide(color: isLight ? const Color(0xFFDBEAFE) : const Color(0xFF334155), width: 1.0),
                  bottom: BorderSide(color: isLight ? const Color(0xFFDBEAFE) : const Color(0xFF334155), width: 1.0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline_rounded, size: 18, color: _getSubjectThemeColor()),
                      const SizedBox(width: 8),
                      Text(
                        isAm ? "ማብራሪያ (Explanation)" : "Explanation",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: _getSubjectThemeColor(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildMathText(
                    q.explanation!.trim(),
                    TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                      color: isLight ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    ),
                    align: TextAlign.left,
                  ),
                ],
              ),
            ),
          ],

          // Navigation Back / Next Buttons
          if (!isExamReview && isActive) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                if (index > 0) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _advanceToPrevious,
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: Text(
                        isAm ? "ወደ ኋላ" : "Back",
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF334155),
                        foregroundColor: isLight ? const Color(0xFF0F172A) : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _advanceToNext,
                    icon: Icon(
                      index == _questions.length - 1 ? Icons.check_rounded : Icons.arrow_forward_rounded,
                      size: 16,
                    ),
                    label: Text(
                      index == _questions.length - 1 
                          ? (isAm ? "ፈተናውን ጨርስ" : "Finish") 
                          : (isAm ? "ቀጣይ ጥያቄ" : "Next"),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getSubjectThemeColor(),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getTypeColor(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return const Color(0xFF3B82F6); // Blue
      case QuestionType.trueFalse:
        return const Color(0xFF10B981); // Emerald
      case QuestionType.blankSpace:
        return const Color(0xFF8B5CF6); // Purple
      case QuestionType.matching:
        return const Color(0xFFF59E0B); // Amber
    }
  }

  String _getTypeLabel(QuestionType type, bool isAm) {
    switch (type) {
      case QuestionType.multipleChoice:
        return isAm ? "ምርጫ (MCQ)" : "Multiple Choice";
      case QuestionType.trueFalse:
        return isAm ? "እውነት / ሐሰት" : "True / False";
      case QuestionType.blankSpace:
        return isAm ? "ባዶ ቦታ ሙላ" : "Fill in the Blank";
      case QuestionType.matching:
        return isAm ? "ማዛመድ" : "Matching";
    }
  }

  // 1. Multiple Choice Option List
  Widget _buildMultipleChoiceContent(
    QuestionModel q,
    int index,
    bool isActive,
    bool showFeedback,
    bool isLight,
  ) {
    if (q.options.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text("No options provided for this question.", style: TextStyle(color: isLight ? Colors.black54 : Colors.white60)),
      );
    }

    return Column(
      children: q.options.asMap().entries.map((entry) {
        final optIdx = entry.key;
        final opt = entry.value;
        final isOptSelected = _selectedAnswers[index] == optIdx;

        Color borderCol;
        Color bgCol;
        Color txtCol;

        if (showFeedback) {
          final isCorrect = opt.isCorrect;
          if (isCorrect) {
            borderCol = const Color(0xFF10B981);
            bgCol = isLight ? const Color(0xFFD1FAE5) : const Color(0xFF064E3B).withValues(alpha: 0.5);
            txtCol = isLight ? const Color(0xFF065F46) : const Color(0xFFA7F3D0);
          } else if (isOptSelected) {
            borderCol = const Color(0xFFEF4444);
            bgCol = isLight ? const Color(0xFFFEE2E2) : const Color(0xFF7F1D1D).withValues(alpha: 0.5);
            txtCol = isLight ? const Color(0xFF991B1B) : const Color(0xFFFECACA);
          } else {
            borderCol = isLight ? const Color(0xFFEDF2F7) : const Color(0xFF334155);
            bgCol = isLight ? const Color(0xFFF8FAFC).withValues(alpha: 0.5) : const Color(0xFF0F172A).withValues(alpha: 0.5);
            txtCol = isLight ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
          }
        } else {
          const selectedAmber = Color(0xFFF59E0B);
          borderCol = isOptSelected
              ? selectedAmber
              : (isLight ? const Color(0xFFEDF2F7) : const Color(0xFF334155));
          bgCol = isOptSelected
              ? selectedAmber.withValues(alpha: isLight ? 0.10 : 0.18)
              : (isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A));
          txtCol = isOptSelected 
              ? (isLight ? const Color(0xFFB45309) : const Color(0xFFFDE68A))
              : (isLight ? const Color(0xFF334155) : const Color(0xFFE2E8F0));
        }

        final optLetter = opt.key ?? String.fromCharCode(65 + optIdx);

        return GestureDetector(
          onTap: () {
            if (isActive && !showFeedback) {
              _onOptionSelected(optIdx);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(bottom: 12.0),
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: bgCol,
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(
                color: borderCol,
                width: isOptSelected || (showFeedback && opt.isCorrect) ? 2.0 : 1.5,
              ),
            ),
            child: Row(
              children: [
                // Option key pill (A, B, C, D)
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isOptSelected ? _getSubjectThemeColor() : (isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    optLetter,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: isOptSelected ? Colors.white : (isLight ? const Color(0xFF475569) : Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMathText(
                    opt.text,
                    GoogleFonts.inter(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                      color: txtCol,
                    ),
                    align: TextAlign.left,
                  ),
                ),
                if (showFeedback && opt.isCorrect)
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20)
                else if (showFeedback && isOptSelected && !opt.isCorrect)
                  const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // 2. True / False Split Option Cards
  Widget _buildTrueFalseContent(
    QuestionModel q,
    int index,
    bool isActive,
    bool showFeedback,
    bool isLight,
    bool isAm,
  ) {
    final isTrueSelected = _selectedAnswers[index] == 0;
    final isFalseSelected = _selectedAnswers[index] == 1;

    final isCorrectTrue = q.correctBoolean == true || (q.options.isNotEmpty && q.options[0].isCorrect);
    final isCorrectFalse = q.correctBoolean == false || (q.options.length > 1 && q.options[1].isCorrect);

    Widget buildTFButton({
      required bool isTrue,
      required bool isSelected,
      required bool isCorrectOption,
      required VoidCallback onTap,
    }) {
      Color borderCol;
      Color bgCol;
      Color txtCol;
      Color iconCol;

      if (showFeedback) {
        if (isCorrectOption) {
          borderCol = const Color(0xFF10B981);
          bgCol = isLight ? const Color(0xFFD1FAE5) : const Color(0xFF064E3B).withValues(alpha: 0.5);
          txtCol = isLight ? const Color(0xFF065F46) : const Color(0xFFA7F3D0);
          iconCol = const Color(0xFF10B981);
        } else if (isSelected) {
          borderCol = const Color(0xFFEF4444);
          bgCol = isLight ? const Color(0xFFFEE2E2) : const Color(0xFF7F1D1D).withValues(alpha: 0.5);
          txtCol = isLight ? const Color(0xFF991B1B) : const Color(0xFFFECACA);
          iconCol = const Color(0xFFEF4444);
        } else {
          borderCol = isLight ? const Color(0xFFEDF2F7) : const Color(0xFF334155);
          bgCol = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
          txtCol = isLight ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
          iconCol = txtCol;
        }
      } else {
        if (isSelected) {
          final themeColor = isTrue ? const Color(0xFF10B981) : const Color(0xFFEF4444);
          borderCol = themeColor;
          bgCol = themeColor.withValues(alpha: isLight ? 0.12 : 0.22);
          txtCol = isLight ? (isTrue ? const Color(0xFF065F46) : const Color(0xFF991B1B)) : Colors.white;
          iconCol = themeColor;
        } else {
          borderCol = isLight ? const Color(0xFFEDF2F7) : const Color(0xFF334155);
          bgCol = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
          txtCol = isLight ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
          iconCol = isTrue ? const Color(0xFF10B981) : const Color(0xFFEF4444);
        }
      }

      return Expanded(
        child: GestureDetector(
          onTap: () {
            if (isActive && !showFeedback) {
              onTap();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 12.0),
            decoration: BoxDecoration(
              color: bgCol,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: borderCol,
                width: isSelected || (showFeedback && isCorrectOption) ? 2.5 : 1.5,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  isTrue ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: iconCol,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  isTrue 
                      ? (isAm ? "እውነት (True)" : "TRUE") 
                      : (isAm ? "ሐሰት (False)" : "FALSE"),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: txtCol,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          buildTFButton(
            isTrue: true,
            isSelected: isTrueSelected,
            isCorrectOption: isCorrectTrue,
            onTap: () => _onOptionSelected(0),
          ),
          const SizedBox(width: 14),
          buildTFButton(
            isTrue: false,
            isSelected: isFalseSelected,
            isCorrectOption: isCorrectFalse,
            onTap: () => _onOptionSelected(1),
          ),
        ],
      ),
    );
  }

  // 3. Blank Space (Fill in the Blank / ባዶ ቦታ ሙላ) Input Component
  Widget _buildBlankSpaceContent(
    QuestionModel q,
    int index,
    bool isActive,
    bool showFeedback,
    bool isLight,
    bool isAm,
  ) {
    final controller = _getBlankController(index);
    final isHintRevealed = _revealedHints.contains(index);
    final userInput = _blankInputAnswers[index] ?? '';
    final isCorrect = q.checkBlankAnswer(userInput);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Input text field with clear action
        TextField(
          controller: controller,
          enabled: isActive && !showFeedback,
          onChanged: (val) {
            setState(() {
              _blankInputAnswers[index] = val;
            });
            _saveProgress();
          },
          decoration: InputDecoration(
            hintText: isAm ? "መልስዎን እዚህ ይጻፉ..." : "Type your answer here...",
            hintStyle: TextStyle(
              color: isLight ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              fontSize: 14,
            ),
            filled: true,
            fillColor: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
            prefixIcon: const Icon(Icons.edit_note_rounded, color: Color(0xFF8B5CF6)),
            suffixIcon: (userInput.isNotEmpty && isActive && !showFeedback)
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      controller.clear();
                      setState(() {
                        _blankInputAnswers[index] = '';
                      });
                      _saveProgress();
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF8B5CF6),
                width: 2.0,
              ),
            ),
          ),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isLight ? const Color(0xFF0F172A) : Colors.white,
          ),
        ),

        // Hint button & display
        if (q.hint != null && q.hint!.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    if (isHintRevealed) {
                      _revealedHints.remove(index);
                    } else {
                      _revealedHints.add(index);
                    }
                  });
                  _saveProgress();
                },
                icon: Icon(
                  isHintRevealed ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded,
                  color: const Color(0xFFF59E0B),
                  size: 16,
                ),
                label: Text(
                  isHintRevealed 
                      ? (isAm ? "ፍንጭ ደብቅ" : "Hide Hint") 
                      : (isAm ? "ፍንጭ አሳይ (Show Hint)" : "Show Hint"),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
          ),
          if (isHintRevealed)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: isLight ? 0.10 : 0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      q.hint!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isLight ? const Color(0xFFB45309) : const Color(0xFFFDE68A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],

        // Feedback Banner in Practice mode or post-review
        if (showFeedback) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isCorrect
                  ? (isLight ? const Color(0xFFD1FAE5) : const Color(0xFF064E3B).withValues(alpha: 0.4))
                  : (isLight ? const Color(0xFFFEE2E2) : const Color(0xFF7F1D1D).withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isCorrect 
                          ? (isAm ? "ትክክል ነው! (Correct)" : "Correct Answer!") 
                          : (isAm ? "ትክክል አይደለም (Incorrect)" : "Incorrect Answer"),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: isCorrect
                            ? (isLight ? const Color(0xFF065F46) : const Color(0xFFA7F3D0))
                            : (isLight ? const Color(0xFF991B1B) : const Color(0xFFFECACA)),
                      ),
                    ),
                  ],
                ),
                if (!isCorrect && q.blankAnswer != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    isAm 
                        ? "ትክክለኛው መልስ፡ ${q.blankAnswer}" 
                        : "Expected Answer: ${q.blankAnswer}",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isLight ? const Color(0xFF0F172A) : Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFinishedSection() {
    if (_questions.isEmpty) return const SizedBox.shrink();
    final bool isAm = AppStateProvider.of(context).languageCode == 'am';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 64, color: Color(0xFF10B981)),
          const SizedBox(height: 16),
          Text(
            isAm ? "ሁሉንም ጥያቄዎች አጠናቀዋል!" : "You've completed all questions!",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _showResults,
            style: ElevatedButton.styleFrom(
              backgroundColor: _getSubjectThemeColor(),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              widget.mode == QuizMode.exam 
                  ? (isAm ? "ፈተናውን አስገባ (Submit Exam)" : "Submit Exam") 
                  : (isAm ? "ውጤት ተመልከት (View Results)" : "View Results"),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMathText(String text, TextStyle baseStyle, {TextAlign align = TextAlign.left}) {
    return MathText(
      text,
      style: baseStyle,
      textAlign: align,
    );
  }

  Widget _buildQuestionTypeFilterBar() {
    if (widget.mode != QuizMode.practice) return const SizedBox.shrink();

    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final isAm = AppStateProvider.of(context).languageCode == 'am';

    final filters = [
      {'key': 'all', 'label': isAm ? 'ሁሉም (All)' : 'All Types'},
      {'key': 'multiple_choice', 'label': isAm ? 'ምርጫ' : 'Multiple Choice'},
      {'key': 'true_false', 'label': isAm ? 'እውነት/ሐሰት' : 'True/False'},
      {'key': 'blank_space', 'label': isAm ? 'ባዶ ቦታ' : 'Fill Blank'},
      {'key': 'matching', 'label': isAm ? 'አዛምድ' : 'Matching'},
    ];

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (ctx, i) => const SizedBox(width: 8),
        itemBuilder: (ctx, idx) {
          final f = filters[idx];
          final key = f['key']!;
          final label = f['label']!;
          final isSelected = _selectedTypeFilter == key;

          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (selected) {
              if (selected && _selectedTypeFilter != key) {
                setState(() {
                  _selectedTypeFilter = key;
                });
                _loadQuestions();
              }
            },
            selectedColor: _getSubjectThemeColor(),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isSelected
                  ? Colors.white
                  : (isLight ? const Color(0xFF334155) : const Color(0xFF94A3B8)),
            ),
            backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
            elevation: 0,
            pressElevation: 0,
            side: BorderSide(
              color: isSelected
                  ? _getSubjectThemeColor()
                  : (isLight ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMatchingContent(
    QuestionModel q,
    int index,
    bool isActive,
    bool showFeedback,
    bool isLight,
    bool isAm,
  ) {
    if (q.matchingPairs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(
          isAm ? "ማዛመጃ አልተዘጋጀም" : "No matching pairs provided.",
          style: TextStyle(color: isLight ? Colors.black54 : Colors.white60),
        ),
      );
    }

    final userAnswers = _matchingAnswers[index] ?? {};
    final List<String> rightOptions = q.matchingPairs.map((p) => p.right).toSet().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            isAm ? "እባክዎ በምድብ ሀ (Column A) ያሉትን ከምድብ ለ (Column B) ጋር ያዛምዱ:" : "Match Column A with Column B:",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
            ),
          ),
        ),
        ...q.matchingPairs.asMap().entries.map((entry) {
          final pairIdx = entry.key;
          final pair = entry.value;
          final selectedRight = userAnswers[pairIdx];
          final isCorrect = selectedRight == pair.right;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: showFeedback
                    ? (isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                    : (selectedRight != null
                        ? _getSubjectThemeColor()
                        : (isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155))),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _getSubjectThemeColor().withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${pairIdx + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: _getSubjectThemeColor(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        pair.left,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isLight ? const Color(0xFF0F172A) : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: isLight ? Colors.white : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: Text(
                        isAm ? "-- ከምድብ ለ ይምረጡ --" : "-- Select Match from Column B --",
                        style: TextStyle(
                          fontSize: 12,
                          color: isLight ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      value: rightOptions.contains(selectedRight) ? selectedRight : null,
                      onChanged: (isActive && !showFeedback)
                          ? (val) {
                              if (val == null) return;
                              setState(() {
                                if (!_matchingAnswers.containsKey(index)) {
                                  _matchingAnswers[index] = {};
                                }
                                _matchingAnswers[index]![pairIdx] = val;
                              });
                              _saveProgress();
                            }
                          : null,
                      items: rightOptions.map((opt) {
                        return DropdownMenuItem<String>(
                          value: opt,
                          child: Text(
                            opt,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isLight ? const Color(0xFF0F172A) : Colors.white,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                if (showFeedback) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        size: 16,
                        color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          isCorrect
                              ? (isAm ? "ትክክለኛ ማዛመጃ!" : "Correct match!")
                              : (isAm ? "ትክክለኛው መልስ: ${pair.right}" : "Correct match: ${pair.right}"),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}
