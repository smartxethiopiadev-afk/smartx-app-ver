import 'package:flutter/material.dart';
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

              // Question Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConfig.darkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  question.questionText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
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
                  ? 'ከ $_questions.length ጥያቄዎች $_score በትክክል መልሰዋል!'
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
