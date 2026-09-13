import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../models/worksheet_model.dart';
import '../services/worksheet_service.dart';
import '../services/offline_manager.dart';
import '../services/subscription_service.dart';
import '../widgets/upgrade_telegram_modal.dart';
import '../widgets/math_text.dart';

class WorksheetScreen extends StatefulWidget {
  final int grade;
  final String subject;
  final int unitNumber;
  final String unitTitle;
  final String languageCode;
  final Color? themeColor;

  const WorksheetScreen({
    super.key,
    required this.grade,
    required this.subject,
    required this.unitNumber,
    required this.unitTitle,
    this.languageCode = 'en',
    this.themeColor,
  });

  @override
  State<WorksheetScreen> createState() => _WorksheetScreenState();
}

class _WorksheetScreenState extends State<WorksheetScreen> {
  List<WorksheetModel> _worksheets = [];
  bool _isLoading = true;
  bool _isDownloading = false;
  bool _isDownloaded = false;
  bool _isLocked = false;
  final Set<int> _expandedSolutions = {};

  @override
  void initState() {
    super.initState();
    _checkAccessAndLoadData();
  }

  String get _unitKey =>
      '${widget.grade}_${widget.subject.toLowerCase()}_u${widget.unitNumber}';

  Future<void> _checkAccessAndLoadData() async {
    setState(() => _isLoading = true);

    // Business Rule: Unit 1 is always 100% Free!
    final bool accessible = await SubscriptionService.isUnitAccessible(
      widget.grade,
      widget.unitNumber,
    );

    final bool downloaded = await OfflineManager.hasOfflineWorksheets(_unitKey);

    if (!accessible && !downloaded) {
      if (mounted) {
        setState(() {
          _isLocked = true;
          _isLoading = false;
          _isDownloaded = downloaded;
        });
      }
      return;
    }

    _isLocked = false;
    _isDownloaded = downloaded;

    try {
      final list = await WorksheetService.fetchWorksheets(
        grade: widget.grade,
        subject: widget.subject,
        unit: widget.unitNumber,
      );

      if (mounted) {
        setState(() {
          _worksheets = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _downloadForOffline() async {
    if (_worksheets.isEmpty || _isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      await OfflineManager.saveOfflineWorksheets(
        _unitKey,
        _worksheets,
        grade: widget.grade,
        unit: widget.unitNumber,
      );

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _isDownloaded = true;
        });
        final isAm = widget.languageCode == 'am';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(isAm
                      ? 'የልምምድ ወረቀቱ ከመስመር ውጭ እንዲሰራ ተቀምጧል!'
                      : 'Worksheet saved for 100% offline study!'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  void _toggleSolution(int questionNumber) {
    setState(() {
      if (_expandedSolutions.contains(questionNumber)) {
        _expandedSolutions.remove(questionNumber);
      } else {
        _expandedSolutions.add(questionNumber);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAm = widget.languageCode == 'am';
    final Color primaryColor = widget.themeColor ?? const Color(0xFF0084FF);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.subject} • ${isAm ? "ክፍል" : "Grade"} ${widget.grade}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: primaryColor,
                letterSpacing: 0.2,
              ),
            ),
            Text(
              'Unit ${widget.unitNumber}: ${widget.unitTitle}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        actions: [
          if (!_isLocked && !_isLoading && _worksheets.isNotEmpty)
            IconButton(
              icon: _isDownloading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _isDownloaded
                          ? Icons.offline_pin_rounded
                          : Icons.download_rounded,
                      color: _isDownloaded
                          ? const Color(0xFF10B981)
                          : (isDark ? Colors.white70 : const Color(0xFF475569)),
                    ),
              tooltip: isAm
                  ? (_isDownloaded ? 'ከመስመር ውጭ ወርዷል' : 'ከመስመር ውጭ አውርድ')
                  : (_isDownloaded ? 'Saved Offline' : 'Download for Offline'),
              onPressed: _downloadForOffline,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(isDark, isAm, primaryColor),
    );
  }

  Widget _buildBody(bool isDark, bool isAm, Color primaryColor) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            const SizedBox(height: 16),
            Text(
              isAm ? 'የልምምድ ወረቀቶችን በማምጣት ላይ...' : 'Loading worksheets...',
              style: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (_isLocked) {
      return _buildLockedView(isDark, isAm, primaryColor);
    }

    if (_worksheets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 64,
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              ),
              const SizedBox(height: 16),
              Text(
                isAm
                    ? 'ለዚህ ክፍል የተዘጋጀ የልምምድ ወረቀት አልተገኘም።'
                    : 'No worksheets found for this unit.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _checkAccessAndLoadData,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(isAm ? 'እንደገና ሞክር' : 'Retry'),
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              ),
            ],
          ),
        ),
      );
    }

    // Collect all questions from the worksheets
    final allQuestions = <WorksheetQuestionItem>[];
    for (final ws in _worksheets) {
      allQuestions.addAll(ws.parsedQuestions);
    }

    return RefreshIndicator(
      onRefresh: _checkAccessAndLoadData,
      color: primaryColor,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Banner: Unit 1 Free or Offline Available
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: widget.unitNumber == 1
                  ? const Color(0xFF10B981).withValues(alpha: 0.12)
                  : primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.unitNumber == 1
                    ? const Color(0xFF10B981).withValues(alpha: 0.3)
                    : primaryColor.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  widget.unitNumber == 1
                      ? Icons.card_giftcard_rounded
                      : Icons.school_rounded,
                  color: widget.unitNumber == 1
                      ? const Color(0xFF10B981)
                      : primaryColor,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.unitNumber == 1
                            ? (isAm ? 'ክፍል 1 100% ነፃ ነው!' : 'Unit 1 is 100% FREE!')
                            : (isAm
                                ? 'ፕሪሚየም የፈተና ልምምድ ወረቀት'
                                : 'Premium Practice Worksheet'),
                        style: TextStyle(
                          color: widget.unitNumber == 1
                              ? const Color(0xFF10B981)
                              : primaryColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAm
                            ? 'በመጀመሪያ ራስዎን ይፈትሹ፤ ከዚያ መፍትሔውን በመጫን ደረጃ በደረጃ አሰራሩን ይመልከቱ።'
                            : 'Solve on your own first, then toggle "Show Solution" to review the step-by-step working.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Worksheet questions list
          ...allQuestions.map((q) => _buildQuestionCard(q, isDark, isAm, primaryColor)),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(
    WorksheetQuestionItem item,
    bool isDark,
    bool isAm,
    Color primaryColor,
  ) {
    final bool isExpanded = _expandedSolutions.contains(item.number);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Question Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF243248) : const Color(0xFFF1F5F9),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isAm ? 'ጥያቄ ${item.number}' : 'Question ${item.number}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ethiopian Curriculum',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.help_outline_rounded,
                  size: 18,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ],
            ),
          ),

          // Question Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _renderContent(item.questionHtml, isDark),
                const SizedBox(height: 14),

                // Show / Hide Solution Toggle Button
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () => _toggleSolution(item.number),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isExpanded
                            ? const Color(0xFF10B981).withValues(alpha: 0.12)
                            : (isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isExpanded
                              ? const Color(0xFF10B981)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isExpanded
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 16,
                            color: isExpanded
                                ? const Color(0xFF10B981)
                                : (isDark ? Colors.white70 : const Color(0xFF475569)),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isExpanded
                                ? (isAm ? 'መፍትሔውን ደብቅ' : 'Hide Solution')
                                : (isAm ? 'መፍትሔውን አሳይ' : 'Show Solution'),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: isExpanded
                                  ? const Color(0xFF10B981)
                                  : (isDark ? Colors.white : const Color(0xFF1E293B)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Solution Section (when expanded)
          if (isExpanded)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F291E) : const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Color(0xFF10B981),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isAm ? 'ደረጃ በደረጃ የተሰራ መፍትሔ:' : 'Step-by-Step Solution:',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFF10B981), height: 16, thickness: 0.5),
                  _renderContent(item.solutionHtml, isDark, isSolution: true),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _renderContent(String text, bool isDark, {bool isSolution = false}) {
    // If contains HTML tags like <p>, <h3>, <div>, use HtmlWidget
    final hasHtmlTags = RegExp(r'<[a-z][\s\S]*>', caseSensitive: false).hasMatch(text);

    if (hasHtmlTags) {
      return HtmlWidget(
        text,
        textStyle: TextStyle(
          fontSize: 14.5,
          height: 1.55,
          color: isSolution
              ? (isDark ? const Color(0xFFD1FAE5) : const Color(0xFF065F46))
              : (isDark ? Colors.white : const Color(0xFF1E293B)),
        ),
        customStylesBuilder: (element) {
          if (element.localName == 'h3' || element.localName == 'h4') {
            return {
              'font-weight': '800',
              'font-size': '15px',
              'margin': '4px 0',
              'color': isSolution
                  ? (isDark ? '#34D399' : '#047857')
                  : (isDark ? '#38BDF8' : '#0284C7'),
            };
          }
          if (element.localName == 'p') {
            return {'margin': '4px 0'};
          }
          return null;
        },
      );
    }

    // Otherwise render with formula MathText
    return MathText(
      text,
      style: TextStyle(
        fontSize: 14.5,
        height: 1.55,
        color: isSolution
            ? (isDark ? const Color(0xFFD1FAE5) : const Color(0xFF065F46))
            : (isDark ? Colors.white : const Color(0xFF1E293B)),
      ),
    );
  }

  Widget _buildLockedView(bool isDark, bool isAm, Color primaryColor) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.lock_rounded,
                size: 40,
                color: Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isAm ? 'ይህ ክፍል ተቆልፏል' : 'This Worksheet is Locked',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isAm
                    ? 'ክፍል 1 100% ነፃ ነው! ክፍል 2 እና ከዚያ በላይ የፕሪሚየም ጥቅል ይፈልጋሉ።'
                    : 'Unit 1 is 100% FREE! Units 2+ require Premium Package.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isAm
                  ? 'የክፍል ${widget.grade} ሙሉ የትምህርት ማጠቃለያዎችን፣ የቀመር ካርዶችን እና የፈተና ጥያቄዎችን በቴሌግራም ያግኙ።'
                  : 'Get full access to all Grade ${widget.grade} unit summaries, formula sheets, and matric worksheets via Telegram.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () {
                UpgradeTelegramModal.show(
                  context,
                  grade: widget.grade,
                  packageName: 'Grade ${widget.grade} Premium Package',
                  unitNumber: widget.unitNumber,
                  unitTitle: widget.unitTitle,
                  languageCode: widget.languageCode,
                  isDarkMode: isDark,
                  onPackageUnlocked: () {
                    _checkAccessAndLoadData();
                  },
                );
              },
              icon: const Icon(Icons.telegram_rounded, size: 22),
              label: Text(
                isAm ? 'በቴሌግራም ክፈት (Upgrade)' : 'Unlock via Telegram',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0084FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
