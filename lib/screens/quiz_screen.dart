import 'dart:async';
import 'dart:convert';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/question_model.dart';
import '../services/quiz_service.dart';
import '../services/offline_manager.dart';
import '../services/ad_helper.dart';
import '../main.dart';

enum QuizMode {
  practice,
  exam,
}

class QuizScreen extends StatefulWidget {
  final int grade;
  final String? subject;
  final int? unit;
  final bool isOffline;
  final String? offlineUnitId;
  final QuizMode mode;

  const QuizScreen({
    super.key,
    required this.grade,
    this.subject,
    this.unit,
    this.isOffline = false,
    this.offlineUnitId,
    this.mode = QuizMode.practice,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  bool _isLoading = true;
  bool _isSubmittingScore = false;
  bool _isAdLoading = false;
  String? _errorMessage;
  List<QuestionModel> _questions = [];
  
  int _currentIndex = 0;
  final Map<int, int> _selectedAnswers = {};
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

  RewardedAd? _rewardedAd;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoaded = false;

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  // Timer fields
  Timer? _quizTimer;
  int _timeLeftSeconds = 0;

  final ScrollController _scrollController = ScrollController();
  List<GlobalKey> _questionKeys = [];

  @override
  void initState() {
    super.initState();
    _loadRewardedAd();
    _loadInterstitialAd();
    _loadBannerAd();
    _checkAndRestoreProgress();
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    _bannerAd?.dispose();
    _quizTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Color _getSubjectThemeColor() {
    final sub = (widget.subject ?? '').toLowerCase();
    if (sub.contains('phys')) return const Color(0xFFF59E0B); // Amber
    if (sub.contains('chem')) return const Color(0xFF10B981); // Emerald
    if (sub.contains('bio')) return const Color(0xFFEC4899); // Pink
    if (sub.contains('math')) return const Color(0xFF3B82F6); // Blue
    return const Color(0xFF6366F1); // Indigo default
  }

  void _loadBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;

    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isBannerAdLoaded = true;
            });
          } else {
            ad.dispose();
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('QuizScreen BannerAd failed to load: $err. Code: ${err.code}');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isBannerAdLoaded = false;
              _bannerAd = null;
            });
          }
        },
      ),
    );
    _bannerAd!.load();
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (err) {
          debugPrint('Failed to load a rewarded ad: ${err.message}');
          _rewardedAd = null;
        },
      ),
    );
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;
        },
        onAdFailedToLoad: (err) {
          debugPrint('Failed to load an interstitial ad: ${err.message}');
          _isInterstitialAdLoaded = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedAnswers.clear();
      _submittedQuestions.clear();
      _showAnswersAndExplanations = false;
      _currentIndex = 0;
    });

    try {
      final List<QuestionModel> fetched;
      final String downloadKey = '${_getUnitId()}_quiz';
      final bool isQuizDownloaded = await OfflineManager.isDownloaded(downloadKey);

      if (isQuizDownloaded) {
        fetched = await OfflineManager.getOfflineQuestions(downloadKey);
      } else if (widget.isOffline && widget.offlineUnitId != null) {
        fetched = await OfflineManager.getOfflineQuestions(widget.offlineUnitId!);
      } else {
        fetched = await QuizService.fetchQuestions(
          grade: widget.grade,
          subject: widget.subject ?? 'unknown',
          unit: widget.unit ?? 1,
        );
      }

      if (fetched.isEmpty) {
        setState(() {
          _questions = [];
          _isLoading = false;
          _errorMessage = "No questions available.";
        });
        return;
      }

      // Select quiz questions and sort them sequentially (1, 2, 3...)
      final List<QuestionModel> selectedQuestions = await QuizService.filterAndSelectQuestions(
        unitId: _getUnitId(),
        allQuestions: fetched,
      );

      // Sort the questions sequentially based on order_index or question_number
      final List<QuestionModel> sequentialQuestions = List<QuestionModel>.from(selectedQuestions);
      sequentialQuestions.sort((a, b) {
        if (a.orderIndex != null && b.orderIndex != null) {
          return a.orderIndex!.compareTo(b.orderIndex!);
        }
        if (a.questionNumber != null && b.questionNumber != null) {
          return a.questionNumber!.compareTo(b.questionNumber!);
        }
        if (a.createdAt != null && b.createdAt != null) {
          return a.createdAt!.compareTo(b.createdAt!);
        }
        return a.id.compareTo(b.id);
      });

      final List<QuestionModel> processedQuestions = sequentialQuestions.map((q) {
        return QuestionModel(
          id: q.id,
          unitId: q.unitId,
          questionText: q.questionText,
          options: List<QuestionOption>.from(q.options),
          explanation: q.explanation,
          createdAt: q.createdAt,
          questionNumber: q.questionNumber,
          orderIndex: q.orderIndex,
        );
      }).toList();

      void startQuizTimerAndFinishLoading() {
        if (mounted) {
          setState(() {
            _questions = processedQuestions;
            _questionKeys = List.generate(processedQuestions.length, (_) => GlobalKey());
            _isLoading = false;
          });

          // Start exam mode countdown automatically
          if (widget.mode == QuizMode.exam) {
            _timeLeftSeconds = _questions.length * 60; // 1 minute per question
            _startTimer();
          }
        }
      }

      // Trigger AdMob Interstitial Ad before the quiz starts!
      if (_isInterstitialAdLoaded && _interstitialAd != null) {
        _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _loadInterstitialAd();
            startQuizTimerAndFinishLoading();
          },
          onAdFailedToShowFullScreenContent: (ad, err) {
            ad.dispose();
            _loadInterstitialAd();
            startQuizTimerAndFinishLoading();
          },
        );
        _interstitialAd!.show();
        _interstitialAd = null;
        _isInterstitialAdLoaded = false;
      } else {
        startQuizTimerAndFinishLoading();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
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

  void _onTimeExpired() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Time has expired! Submitting your quiz..."),
        backgroundColor: Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _showResults();
  }

  void _onOptionSelected(int optionIndex) {
    if (_questions.isEmpty || _currentIndex >= _questions.length || _currentIndex < 0) return;
    if (_showAnswersAndExplanations) return; // Prevent selection in post-exam review
    if (widget.mode == QuizMode.practice && _submittedQuestions.contains(_currentIndex)) return; // Already checked

    setState(() {
      _selectedAnswers[_currentIndex] = optionIndex;
    });

    _saveProgress();

    if (widget.mode == QuizMode.exam) {
      _scrollToShiftExamQuestionUp();
    }
  }

  void _submitPracticeAnswer() {
    final selectedIdx = _selectedAnswers[_currentIndex];
    if (selectedIdx == null) return;
    
    setState(() {
      _submittedQuestions.add(_currentIndex);
    });

    _saveProgress();
    _scrollToExplanation();
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
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
          alignment: 0.1, // Align near the top of the viewport
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
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
          alignment: 1.0, // Align to bottom of viewport to reveal explanation block
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
          alignment: 0.3, // Scroll slightly up so card and Next button are beautifully framed
        );
      }
    });
  }

  void _advanceToNext() {
    if (_currentIndex < _questions.length - 1) {
      final int nextIndex = _currentIndex + 1;
      if (nextIndex == 19) {
        _showBreakDialog();
        return;
      }
      setState(() {
        _currentIndex = nextIndex;
      });
      _saveProgress();
      _scrollToActiveQuestion();
    } else {
      // Reached the end, navigate to submit screen/trigger submit results
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

  Future<void> _submitScoreToLeaderboard(int score) async {
    debugPrint("QuizScreen: Score submission is disabled.");
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
        'submittedQuestions': _submittedQuestions.map((e) => e.toString()).toList(),
        'timeLeftSeconds': _timeLeftSeconds,
        'mode': widget.mode.toString(),
      };
      
      await prefs.setString(key, jsonEncode(data));
      debugPrint("QuizScreen: Progress saved for unit ${_getUnitId()}");
    } catch (e) {
      debugPrint("QuizScreen: Failed to save progress: $e");
    }
  }

  Future<void> _checkAndRestoreProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'quiz_session_progress_${_getUnitId()}';
      if (!prefs.containsKey(key)) {
        // No saved progress, load fresh questions
        await _loadQuestions();
        return;
      }
      
      final String? dataStr = prefs.getString(key);
      if (dataStr == null) {
        await _loadQuestions();
        return;
      }
      
      final Map<String, dynamic> data = jsonDecode(dataStr) as Map<String, dynamic>;
      
      // If widgets mount/state is active, show the restore dialog!
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
                  // Start New Session: clear progress and load questions fresh
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
                  // Resume: parse and restore progress
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
      final int savedTime = data['timeLeftSeconds'] as int? ?? (restoredQuestions.length * 60);
      
      final Map<String, dynamic> answersJson = data['selectedAnswers'] as Map<String, dynamic>? ?? {};
      final Map<int, int> restoredAnswers = {};
      answersJson.forEach((k, v) {
        final intIndex = int.tryParse(k);
        if (intIndex != null) {
          restoredAnswers[intIndex] = v as int;
        }
      });
      
      setState(() {
        _questions = restoredQuestions;
        _currentIndex = savedIndex;
        _timeLeftSeconds = savedTime;
        _selectedAnswers.clear();
        _selectedAnswers.addAll(restoredAnswers);
        _questionKeys = List.generate(restoredQuestions.length, (_) => GlobalKey());
        _isLoading = false;
        
        // Populate submitted questions for practice mode
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
        }
      });
      
      if (widget.mode == QuizMode.exam) {
        _startTimer();
      }
      
      debugPrint("QuizScreen: Session restored successfully!");
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
                "You have completed 20 questions! Outstanding effort. Take a deep breath, relax your shoulders, and rest your eyes before continuing.",
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

  Future<void> _checkNotificationPermissionOnFinish(VoidCallback onDone) async {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      if (!mounted) {
        onDone();
        return;
      }
      final isLight = Theme.of(context).brightness == Brightness.light;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              " Enable Notifications / ማሳወቂያዎችን ያግብሩ",
              style: TextStyle(
                color: isLight ? const Color(0xFF0F172A) : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            content: Text(
              "Get exam tips, unit updates, and study reminders / የፈተና ምክሮችን፣ የክፍል አፕዴት እና የማጠናከሪያ ማሳሰቢያዎችን ለማግኘት ማሳወቂያዎችን ይፍቀዱ።",
              style: TextStyle(
                color: isLight ? const Color(0xFF334155) : const Color(0xFF94A3B8),
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  onDone();
                },
                child: const Text("Cancel / ሰርዝ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BFFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  final reqStatus = await Permission.notification.request();
                  if (reqStatus.isPermanentlyDenied) {
                    await openAppSettings();
                  }
                  onDone();
                },
                child: const Text("Allow / አግብር", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
    } else {
      onDone();
    }
  }

  Future<void> _showResults() async {
    _quizTimer?.cancel();
    if (_questions.isEmpty) return;

    // Mark these questions as answered so consecutive sessions provide remaining unused questions
    await QuizService.markQuestionsAsAnswered(
      unitId: _getUnitId(),
      questions: _questions,
    );

    await _clearProgress(); // Clear saved progress upon successful quiz completion

    int score = 0;
    
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (_selectedAnswers.containsKey(i)) {
        final selectedIdx = _selectedAnswers[i]!;
        if (selectedIdx < q.options.length) {
          final isCorrect = q.options[selectedIdx].isCorrect;
          if (isCorrect) score++;
        }
      }
    }

    // Submit score in the background without showing any modal
    if (widget.mode == QuizMode.exam) {
      _submitScoreToLeaderboard(score).catchError((e) {
        debugPrint("Error submitting score: $e");
      });
    }

    if (!mounted) return;

    final percent = (score / _questions.length * 100).round();
    final bool isLight = Theme.of(context).brightness == Brightness.light;

    try {
      final prefs = await SharedPreferences.getInstance();
      final String scoreKey = 'best_score_${widget.grade}_${widget.subject ?? ""}_u${widget.unit ?? 1}';
      final int existingBest = prefs.getInt(scoreKey) ?? 0;
      if (percent > existingBest) {
        await prefs.setInt(scoreKey, percent);
      }
    } catch (_) {}

    // Show completed results dialog instantly
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        int selectRandomUnit() {
          final currentUnit = widget.unit ?? 1;
          final List<int> unitsPool = [1, 2, 3, 4, 5, 6, 7, 8].where((u) => u != currentUnit).toList();
          unitsPool.shuffle();
          return unitsPool.isNotEmpty ? unitsPool.first : currentUnit;
        }

        void startRandomQuiz() {
          final int randomUnit = selectRandomUnit();
          final targetGrade = widget.grade;
          final targetSubject = widget.subject;
          final targetMode = widget.mode;
          final targetIsOffline = widget.isOffline;
          final targetOfflineUnitId = widget.offlineUnitId;

          void performNavigation() {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => QuizScreen(
                  grade: targetGrade,
                  subject: targetSubject,
                  unit: randomUnit,
                  mode: targetMode,
                  isOffline: targetIsOffline,
                  offlineUnitId: targetOfflineUnitId,
                ),
              ),
            );
          }

          // Trigger AdMob interstitial or rewarded ad transition before pushing
          if (_isInterstitialAdLoaded && _interstitialAd != null) {
            _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _loadInterstitialAd();
                performNavigation();
              },
              onAdFailedToShowFullScreenContent: (ad, err) {
                ad.dispose();
                _loadInterstitialAd();
                performNavigation();
              },
            );
            _interstitialAd!.show();
            _interstitialAd = null;
            _isInterstitialAdLoaded = false;
          } else {
            performNavigation();
          }
        }

        return AlertDialog(
          elevation: 12,
          backgroundColor: isLight ? Colors.white : const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          titlePadding: const EdgeInsets.only(top: 16, left: 16, right: 16),
          title: Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBF24).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFFBBF24), size: 48),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.mode == QuizMode.exam ? "Exam Finished!" : "Quiz Finished!",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: isLight ? const Color(0xFF0F172A) : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  icon: Icon(Icons.close_rounded, color: isLight ? Colors.black54 : Colors.white70),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _checkNotificationPermissionOnFinish(() {
                      if (widget.mode == QuizMode.exam) {
                        setState(() {
                          _showAnswersAndExplanations = true;
                          _currentIndex = 0; // Return to first question for review
                        });
                        _scrollToActiveQuestion();
                      } else {
                        Navigator.of(context).pop();
                      }
                    });
                  },
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Here is your performance summary",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  decoration: BoxDecoration(
                    color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text("SCORE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey)),
                          const SizedBox(height: 6),
                          Text(
                            "$score / ${_questions.length}",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: isLight ? const Color(0xFF0F172A) : Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Container(width: 1.5, height: 36, color: Colors.grey.withValues(alpha: 0.2)),
                      Column(
                        children: [
                          const Text("ACCURACY", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey)),
                          const SizedBox(height: 6),
                          Text(
                            "$percent%",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: percent >= 70 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "You can now review all questions and explanations.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 20),
                // Encouraging Card: Ready to practice more?
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D2353), Color(0xFF1E3A8A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6D00).withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Ready to practice more?",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Keep up the momentum! Challenge yourself with a random unit from ${widget.subject ?? 'this subject'}.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          startRandomQuiz();
                        },
                        icon: const Icon(Icons.shuffle_rounded, size: 16),
                        label: const Text(
                          "Start Random Quiz",
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6D00),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  if (widget.mode == QuizMode.exam) {
                    setState(() {
                      _showAnswersAndExplanations = true;
                      _currentIndex = 0; // Return to first question for review
                    });
                    _scrollToActiveQuestion();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getSubjectThemeColor(),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: Text(
                  widget.mode == QuizMode.exam ? "Review Answers" : "Done",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            )
          ],
        );
      },
    );
  }

  Widget _buildMathText(String text, TextStyle baseStyle, {TextAlign align = TextAlign.center}) {
    if (!text.contains(r'$') && !text.contains(r'\(') && !text.contains(r'\[') && !text.contains(r'\\(') && !text.contains(r'\\[')) {
      return Text(
        text,
        style: baseStyle,
        textAlign: align,
      );
    }

    final List<InlineSpan> spans = [];
    final regex = RegExp(
      r'\$\$([\s\S]+?)\$\$|'
      r'\$([\s\S]+?)\$|'
      r'\\\[([\s\S]+?)\\\]|'
      r'\\\(([\s\S]+?)\\\)|'
      r'\\\\\[([\s\S]+?)\\\\\]|'
      r'\\\\\(([\s\S]+?)\\\\\)'
    );
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }

      final mathExpr = match.group(1) ??
          match.group(2) ??
          match.group(3) ??
          match.group(4) ??
          match.group(5) ??
          match.group(6) ??
          '';

      if (mathExpr.isNotEmpty) {
        String cleanedMath = mathExpr.trim()
            .replaceAll(r'\frac', '')
            .replaceAll(r'\times', '×')
            .replaceAll(r'\div', '÷')
            .replaceAll(r'\pm', '±')
            .replaceAll(r'\cdot', '·')
            .replaceAll(r'\le', '≤')
            .replaceAll(r'\ge', '≥')
            .replaceAll(r'\neq', '≠')
            .replaceAll(r'\approx', '≈')
            .replaceAll(r'\pi', 'π')
            .replaceAll(r'\theta', 'θ')
            .replaceAll(r'\alpha', 'α')
            .replaceAll(r'\beta', 'β')
            .replaceAll(r'\sqrt', '√')
            .replaceAll(r'\{', '{')
            .replaceAll(r'\}', '}');

        spans.add(TextSpan(
          text: ' $cleanedMath ',
          style: baseStyle.copyWith(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
          ),
        ));
      }
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: baseStyle,
      ));
    }

    return RichText(
      textAlign: align,
      text: TextSpan(children: spans),
    );
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
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
                      : (widget.mode == QuizMode.exam ? "EXAM MODE" : "PRACTICE MODE"),
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
        ),
        body: Stack(
          children: [
            _buildBody(),
            if (_isAdLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: Center(
                  child: Card(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E293B)
                        : Colors.white,
                    elevation: 12,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(24)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            strokeWidth: 4,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            AppStateProvider.of(context).languageCode == 'en'
                                ? "Loading ad..."
                                : "ማስታወቂያ በመጫን ላይ...",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppStateProvider.of(context).languageCode == 'en'
                                ? "Please wait a moment"
                                : "እባክዎ ትንሽ ይጠብቁ",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 11.5,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_isSubmittingScore)
              Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: const Center(
                  child: Card(
                    color: Colors.white,
                    elevation: 12,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(strokeWidth: 4),
                          SizedBox(height: 20),
                          Text(
                            "Syncing Leaderboard...",
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Please do not close this screen",
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: (_isBannerAdLoaded && _bannerAd != null)
            ? Container(
                color: backgroundColor,
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: _bannerAd!.size.height.toDouble(),
                    child: Center(
                      child: SizedBox(
                        width: _bannerAd!.size.width.toDouble(),
                        height: _bannerAd!.size.height.toDouble(),
                        child: AdWidget(ad: _bannerAd!),
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.blueAccent),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadQuestions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }
    if (_questions.isEmpty) {
      return const Center(
        child: Text(
          "No questions found.",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return _buildQuizActiveView();
  }

  Widget _buildCircularCheckbox({
    required bool isSelected,
    required bool showFeedback,
    required bool isCorrect,
    required Color subjectColor,
    required bool isLight,
  }) {
    Color borderCol;
    Color bgCol;
    Widget? icon;

    if (showFeedback) {
      if (isCorrect) {
        borderCol = const Color(0xFF10B981);
        bgCol = const Color(0xFF10B981);
        icon = const Icon(Icons.check, color: Colors.white, size: 12);
      } else if (isSelected) {
        borderCol = const Color(0xFFEF4444);
        bgCol = const Color(0xFFEF4444);
        icon = const Icon(Icons.close, color: Colors.white, size: 12);
      } else {
        borderCol = isLight ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
        bgCol = Colors.transparent;
      }
    } else {
      borderCol = isSelected ? subjectColor : (isLight ? const Color(0xFFCBD5E1) : const Color(0xFF475569));
      bgCol = isSelected ? subjectColor : Colors.transparent;
      if (isSelected) {
        icon = const Icon(Icons.check, color: Colors.white, size: 12);
      }
    }

    return Container(
      width: 22.0,
      height: 22.0,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgCol,
        border: Border.all(
          color: borderCol,
          width: 2.0,
        ),
        boxShadow: isSelected && !showFeedback
            ? [
                BoxShadow(
                  color: subjectColor.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: icon != null ? Center(child: icon) : null,
    );
  }

  Widget _buildQuestionBlock(int index, bool isLight, Color cardColor, Color descColor, Color titleTextColor) {
    final q = _questions[index];
    final optionsData = q.options;
    final qText = q.questionText;

    final bool isActive = index == _currentIndex;
    final bool isExamReview = widget.mode == QuizMode.exam && _showAnswersAndExplanations;
    final bool isVisible = isActive || isExamReview;
    final showFeedback = _shouldShowExplanation(index);
    final isSubmitted = widget.mode == QuizMode.practice && _submittedQuestions.contains(index);
    final hasSelected = _selectedAnswers.containsKey(index);

    return Container(
      key: _questionKeys[index],
      margin: const EdgeInsets.only(bottom: 40.0), // beautiful gap between question blocks
      child: IgnorePointer(
        ignoring: isExamReview ? true : !isActive,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 350),
          opacity: isVisible ? 1.0 : 0.2,
          child: ClipRect(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: isVisible ? 0.0 : 5.0,
                sigmaY: isVisible ? 0.0 : 5.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Question Header Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Question ${index + 1} of ${_questions.length}",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _getSubjectThemeColor(),
                        ),
                      ),
                      if (widget.mode == QuizMode.exam && isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.timer_rounded, size: 14, color: Color(0xFFEF4444)),
                              const SizedBox(width: 6),
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
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (index + 1) / _questions.length,
                      backgroundColor: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                      valueColor: AlwaysStoppedAnimation<Color>(_getSubjectThemeColor()),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Unified white card box containing both question text and options
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: isLight ? Colors.white : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(
                        color: isLight ? const Color(0xFFEDF2F7) : const Color(0xFF334155),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.16),
                          blurRadius: 16.0,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Question text (rendered with Georgia font & display math support)
                        _buildMathText(
                          qText,
                          TextStyle(
                            fontFamily: 'Georgia',
                            fontFamilyFallback: const ['Georgia', 'serif'],
                            fontSize: 17.5,
                            fontWeight: FontWeight.w700,
                            height: 1.5,
                            color: isLight ? const Color(0xFF0F172A) : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: isLight ? const Color(0xFFEDF2F7) : const Color(0xFF334155),
                        ),
                        const SizedBox(height: 20),

                        // Options
                        if (optionsData.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              "No options available.",
                              style: TextStyle(color: descColor, fontStyle: FontStyle.italic),
                            ),
                          )
                        else
                          ...optionsData.asMap().entries.map((entry) {
                            final optIdx = entry.key;
                            final optText = entry.value.text;
                            final isOptSelected = _selectedAnswers[index] == optIdx;

                            Color borderCol;
                            Color bgCol;
                            Color txtCol;

                            if (showFeedback) {
                              final isCorrect = q.options[optIdx].isCorrect;
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
                                bgCol = Colors.transparent;
                                txtCol = descColor.withValues(alpha: 0.6);
                              }
                            } else {
                              borderCol = isOptSelected
                                  ? _getSubjectThemeColor()
                                  : (isLight ? const Color(0xFFEDF2F7) : const Color(0xFF334155));
                              bgCol = isOptSelected
                                  ? _getSubjectThemeColor().withValues(alpha: isLight ? 0.08 : 0.15)
                                  : (isLight ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B));
                              txtCol = isOptSelected ? _getSubjectThemeColor() : (isLight ? const Color(0xFF0F172A) : Colors.white);
                            }

                            return GestureDetector(
                              onTap: () {
                                if (isActive && !showFeedback) {
                                  _onOptionSelected(optIdx);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.only(bottom: 16.0), // Generous spacing between boxes
                                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0), // Generous inner padding
                                decoration: BoxDecoration(
                                  color: bgCol,
                                  borderRadius: BorderRadius.circular(16.0),
                                  border: Border.all(
                                    color: borderCol,
                                    width: isOptSelected || (showFeedback && q.options[optIdx].isCorrect) ? 2.0 : 1.5,
                                  ),
                                  boxShadow: isOptSelected && !showFeedback
                                      ? [
                                          BoxShadow(
                                            color: _getSubjectThemeColor().withValues(alpha: 0.12),
                                            blurRadius: 10.0,
                                            offset: const Offset(0, 4),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    // Custom beautifully designed circular checkbox
                                    _buildCircularCheckbox(
                                      isSelected: isOptSelected,
                                      showFeedback: showFeedback,
                                      isCorrect: q.options[optIdx].isCorrect,
                                      subjectColor: _getSubjectThemeColor(),
                                      isLight: isLight,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: _buildMathText(
                                        optText,
                                        TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: txtCol,
                                        ),
                                        align: TextAlign.left, // Left align inside rows for premium bento style
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),

                  // Practice Mode check answer button (rendered below the unified card)
                  if (widget.mode == QuizMode.practice && !isSubmitted && isActive) ...[
                    const SizedBox(height: 28), // Ample spacing before button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: hasSelected ? _submitPracticeAnswer : null,
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                        label: const Text(
                          "Check Answer",
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getSubjectThemeColor(),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                          disabledForegroundColor: Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: hasSelected ? 4 : 0,
                          shadowColor: _getSubjectThemeColor().withValues(alpha: 0.35),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],

                  // Explanations Box
                  if (showFeedback && q.explanation != null && q.explanation!.trim().isNotEmpty && isActive) ...[
                    const SizedBox(height: 28), // Ample spacing before explanation
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
                                "Explanation",
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

                  // Next Question Button / Finish Quiz button (Freely navigable in Practice & Exam modes)
                  if (!isExamReview && isActive) ...[
                    const SizedBox(height: 24), // Ample spacing before button
                    Row(
                      children: [
                        if (index > 0) ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _advanceToPrevious,
                              icon: const Icon(Icons.arrow_back_rounded, size: 16),
                              label: const Text(
                                "Back",
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF334155),
                                foregroundColor: isLight ? const Color(0xFF0F172A) : Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF475569),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (index == _questions.length - 1) {
                                _showResults();
                              } else {
                                _advanceToNext();
                              }
                            },
                            icon: Icon(
                              index == _questions.length - 1
                                  ? Icons.assignment_turned_in_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 16,
                            ),
                            label: Text(
                              index == _questions.length - 1
                                  ? (_showAnswersAndExplanations ? "Finish Review" : "Finish Quiz")
                                  : "Next Question",
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _getSubjectThemeColor(),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 4,
                              shadowColor: _getSubjectThemeColor().withValues(alpha: 0.35),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuizActiveView() {
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final cardColor = isLight ? Colors.white : const Color(0xFF1E293B);
    final descColor = isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8);
    final titleTextColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final bool isExamReview = widget.mode == QuizMode.exam && _showAnswersAndExplanations;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Column(
          children: [
            // Question Palette / Quick Jump Bar
            if (_questions.length > 1 && !isExamReview)
              _buildQuestionPaletteStrip(isLight),

            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...List.generate(_questions.length, (index) {
                      return _buildQuestionBlock(index, isLight, cardColor, descColor, titleTextColor);
                    }),
                    
                    // End block when finished
                    if (_currentIndex == _questions.length || isExamReview) ...[
                      _buildFinishedSection(),
                    ] else ...[
                      // Generous vertical spacing at the bottom so we can center scroll the last question perfectly!
                      const SizedBox(height: 500),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionPaletteStrip(bool isLight) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
        border: Border(
          bottom: BorderSide(
            color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
            width: 1.0,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _questions.length,
        itemBuilder: (context, idx) {
          final isCurrent = idx == _currentIndex;
          final isAnswered = _selectedAnswers.containsKey(idx);
          final isSubmitted = _submittedQuestions.contains(idx);
          
          Color bgColor;
          Color textColor;
          Border? border;

          if (isCurrent) {
            bgColor = _getSubjectThemeColor();
            textColor = Colors.white;
            border = Border.all(color: _getSubjectThemeColor(), width: 1.5);
          } else if (widget.mode == QuizMode.practice && isSubmitted) {
            final isCorrect = _selectedAnswers[idx] == _questions[idx].correctAnswerIndex;
            if (isCorrect) {
              bgColor = isLight ? const Color(0xFFDCFCE7) : const Color(0xFF064E3B);
              textColor = isLight ? const Color(0xFF166534) : const Color(0xFF6EE7B7);
              border = Border.all(color: const Color(0xFF22C55E), width: 1.2);
            } else {
              bgColor = isLight ? const Color(0xFFFEE2E2) : const Color(0xFF7F1D1D);
              textColor = isLight ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5);
              border = Border.all(color: const Color(0xFFEF4444), width: 1.2);
            }
          } else if (isAnswered) {
            bgColor = isLight ? _getSubjectThemeColor().withValues(alpha: 0.12) : _getSubjectThemeColor().withValues(alpha: 0.25);
            textColor = _getSubjectThemeColor();
            border = Border.all(color: _getSubjectThemeColor().withValues(alpha: 0.5), width: 1.0);
          } else {
            bgColor = isLight ? Colors.white : const Color(0xFF1E293B);
            textColor = isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
            border = Border.all(color: isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155), width: 1.0);
          }

          return Padding(
            padding: const EdgeInsets.only(right: 6),
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

  Widget _buildFinishedSection() {
    if (_questions.isEmpty) return const SizedBox.shrink();
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final bool allAnswered = _selectedAnswers.length == _questions.length;
    
    if (_showAnswersAndExplanations) {
      final bool isExam = widget.mode == QuizMode.exam;
      final String languageCode = AppStateProvider.of(context).languageCode;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
        child: Column(
          children: [
            const Icon(Icons.check_circle_rounded, size: 64, color: Color(0xFF10B981)),
            const SizedBox(height: 16),
            Text(
              isExam
                  ? (languageCode == 'en' ? "Exam Review Complete" : "የፈተና ግምገማ ተጠናቋል")
                  : (languageCode == 'en' ? "Review Finished!" : "ግምገማው ተጠናቋል!"),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 24),
            if (isExam) ...[
              const SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getSubjectThemeColor(),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                languageCode == 'en' ? "Go Back" : "ተመለስ",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 64, color: Color(0xFF10B981)),
          const SizedBox(height: 16),
          const Text(
            "You've completed all questions!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: allAnswered ? _showResults : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _getSubjectThemeColor(),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              disabledBackgroundColor: (isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
            ),
            child: Text(
              widget.mode == QuizMode.exam ? "Submit Exam" : "View Results", 
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
