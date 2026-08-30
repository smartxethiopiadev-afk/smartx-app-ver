import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../models/subject_model.dart';
import '../models/question_model.dart';
import '../services/offline_service.dart';

class QuizScreen extends StatefulWidget {
  final UnitModel unit;
  final SubjectConfig subject;
  final int grade;

  const QuizScreen({
    super.key,
    required this.unit,
    required this.subject,
    required this.grade,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<QuestionModel> _questions;
  int _currentIndex = 0;
  String? _selectedOptionId;
  bool _isAnswered = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    final offline = Provider.of<OfflineService>(context, listen: false);
    _questions = offline.getQuestionsForUnit(widget.unit.unitId);
  }

  void _showReportQuestionDialog(BuildContext context, QuestionModel question, bool isAm) {
    final offline = Provider.of<OfflineService>(context, listen: false);
    final reasonController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: AppConfig.darkCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bug_report_rounded, color: Colors.redAccent, size: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  isAm ? 'ጥያቄውን / ስህተት ጠቁም' : 'Report Question Error',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.subject.code} G${widget.grade} U${widget.unit.unitNumber} • Q#${_currentIndex + 1}',
                          style: TextStyle(color: widget.subject.primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          question.questionText,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isAm ? 'የተመለከቱት ስህተት ምንድን ነው?' : 'Describe the Issue / Typo / Error:',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: reasonController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: isAm ? 'ለምሳሌ፡ ትክክለኛው መልስ B ሳይሆን C ነው...' : 'e.g., Typo in equation, option B is correct...',
                      hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                      filled: true,
                      fillColor: AppConfig.darkSurface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white12)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              // Telegram Share Option
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF29B6F6)),
                onPressed: () {
                  final reportText = '''
[Smart X Question Report]
Subject: ${widget.subject.code} (Grade ${widget.grade})
Unit: ${widget.unit.unitNumber} (${widget.unit.enTitle})
Question #${_currentIndex + 1}: ${question.questionText}
Report Reason: ${reasonController.text.trim().isEmpty ? "Error in question options/key" : reasonController.text.trim()}
Student: ${offline.profile.fullName} (${offline.profile.phoneNumber})
''';
                  Clipboard.setData(ClipboardData(text: reportText));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isAm
                            ? 'የጥያቄው መረጃ ተገልብጧል! ወደ ቴሌግራም (@smartx_ethiopia) መላክ ይችላሉ።'
                            : 'Report copied! You can now send it to Telegram @smartx_ethiopia',
                      ),
                      backgroundColor: const Color(0xFF0288D1),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Telegram', style: TextStyle(fontSize: 12)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppConfig.primaryGreen, foregroundColor: Colors.white),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        setModalState(() => isSubmitting = true);
                        await offline.reportQuestionError(
                          questionId: question.id,
                          unitId: widget.unit.unitId,
                          questionText: question.questionText,
                          reason: reasonController.text.trim().isEmpty ? 'Flagged by student' : reasonController.text.trim(),
                        );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(isAm ? 'ጥቆማዎ ለገምጋሚዎች ደርሷል!' : 'Question report submitted successfully!'),
                            backgroundColor: AppConfig.primaryGreen,
                          ),
                        );
                      },
                child: Text(isAm ? 'ላክ' : 'Submit'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final offline = context.watch<OfflineService>();
    final isAm = offline.language == LanguageCode.am;

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppConfig.darkBackground,
        appBar: AppBar(backgroundColor: AppConfig.darkCard, title: Text(widget.unit.enTitle)),
        body: Center(
          child: Text(
            isAm ? 'ምንም ጥያቄዎች አልተገኙም' : 'No questions found for this unit',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final question = _questions[_currentIndex];

    return Scaffold(
      backgroundColor: AppConfig.darkBackground,
      appBar: AppBar(
        backgroundColor: AppConfig.darkCard,
        elevation: 0,
        title: Text(
          '${widget.subject.code} • Unit ${widget.unit.unitNumber}',
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
        actions: [
          // Question Report Icon (Telegram / Bug Report)
          IconButton(
            icon: const Icon(Icons.bug_report_outlined, color: Colors.redAccent, size: 20),
            tooltip: isAm ? 'ስህተት ጠቁም / በቴሌግራም ላክ' : 'Report Error via Telegram',
            onPressed: () => _showReportQuestionDialog(context, question, isAm),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: widget.subject.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_currentIndex + 1} / ${_questions.length}',
                style: TextStyle(color: widget.subject.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Bar
              LinearProgressIndicator(
                value: (_currentIndex + 1) / _questions.length,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(widget.subject.primaryColor),
              ),
              const SizedBox(height: 16),

              // Question Card with Report Action
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConfig.darkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Question ${_currentIndex + 1}',
                          style: TextStyle(color: widget.subject.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        InkWell(
                          onTap: () => _showReportQuestionDialog(context, question, isAm),
                          child: Row(
                            children: [
                              const Icon(Icons.flag_outlined, size: 14, color: Colors.redAccent),
                              const SizedBox(width: 4),
                              Text(
                                isAm ? 'ስህተት ጠቁም' : 'Report',
                                style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      question.questionText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Options
              Expanded(
                child: ListView.separated(
                  itemCount: question.options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final option = question.options[index];
                    final isSelected = _selectedOptionId == option.id;

                    Color cardColor = AppConfig.darkCard;
                    BorderSide border = const BorderSide(color: Colors.white12);

                    if (_isAnswered) {
                      if (option.isCorrect) {
                        cardColor = AppConfig.primaryGreen.withValues(alpha: 0.2);
                        border = const BorderSide(color: AppConfig.primaryGreen, width: 2);
                      } else if (isSelected && !option.isCorrect) {
                        cardColor = Colors.redAccent.withValues(alpha: 0.2);
                        border = const BorderSide(color: Colors.redAccent, width: 2);
                      }
                    } else if (isSelected) {
                      cardColor = widget.subject.primaryColor.withValues(alpha: 0.2);
                      border = BorderSide(color: widget.subject.primaryColor, width: 2);
                    }

                    return GestureDetector(
                      onTap: _isAnswered
                          ? null
                          : () {
                              setState(() => _selectedOptionId = option.id);
                            },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.fromBorderSide(border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  option.id.toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                option.text,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Explanation Box if Answered
              if (_isAnswered && question.explanation != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppConfig.darkSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lightbulb_outline, color: AppConfig.accentAmber, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            isAm ? 'ማብራሪያ' : 'Explanation',
                            style: const TextStyle(color: AppConfig.accentAmber, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        question.explanation!,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),

              // Action Button
              ElevatedButton(
                onPressed: _selectedOptionId == null
                    ? null
                    : () {
                        if (!_isAnswered) {
                          final selected = question.options.firstWhere((o) => o.id == _selectedOptionId);
                          if (selected.isCorrect) _score++;
                          setState(() => _isAnswered = true);
                        } else {
                          if (_currentIndex < _questions.length - 1) {
                            setState(() {
                              _currentIndex++;
                              _selectedOptionId = null;
                              _isAnswered = false;
                            });
                          } else {
                            offline.recordAdMobEvent('Interstitial', 'Quiz Completed Ad Impression');
                            _showResultsDialog(context, isAm);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.subject.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  !_isAnswered
                      ? (isAm ? 'መልስ አረጋግጥ' : 'Check Answer')
                      : (_currentIndex < _questions.length - 1
                          ? (isAm ? 'ቀጣይ ጥያቄ' : 'Next Question')
                          : (isAm ? 'ውጤት እይ' : 'View Results')),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResultsDialog(BuildContext context, bool isAm) {
    final percentage = ((_score / _questions.length) * 100).round();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConfig.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isAm ? 'የፈተና ውጤት' : 'Quiz Completed',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$percentage%',
              style: TextStyle(
                color: percentage >= 60 ? AppConfig.primaryGreen : Colors.redAccent,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isAm
                  ? 'ከ ${_questions.length} ጥያቄዎች $_score በትክክል መልሰዋል!'
                  : 'You got $_score out of ${_questions.length} questions correct!',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(isAm ? 'ወደ ዋና ገጽ ተመለስ' : 'Return Home', style: const TextStyle(color: AppConfig.primaryGreen)),
          ),
        ],
      ),
    );
  }
}
