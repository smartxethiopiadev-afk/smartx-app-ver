// ignore_for_file: prefer_function_declarations_over_variables, use_build_context_synchronously, unnecessary_brace_in_string_interps
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pdf_viewer_screen.dart';
import 'downloads_screen.dart';
import '../services/short_note_service.dart';
import '../services/offline_manager.dart';
import '../services/quiz_service.dart';
import '../main.dart';
import 'quiz_screen.dart';
import '../services/analytics_service.dart';
import '../services/subscription_service.dart';
import '../widgets/locked_unit_dialog.dart';
import '../widgets/quiz_selection_dialogs.dart';
import '../data/curriculum_units.dart';

class UnitSelectionScreen extends StatefulWidget {
  final int grade;
  final String subjectId;
  final String enTitle;
  final String amTitle;
  final Color color;
  final Widget icon;
  final bool isDarkMode;
  final String languageCode;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLanguage;
  final bool isShortNotesMode;

  const UnitSelectionScreen({
    super.key,
    required this.grade,
    required this.subjectId,
    required this.enTitle,
    required this.amTitle,
    required this.color,
    required this.icon,
    required this.isDarkMode,
    required this.languageCode,
    required this.onToggleTheme,
    required this.onToggleLanguage,
    this.isShortNotesMode = false,
  });

  @override
  State<UnitSelectionScreen> createState() => _UnitSelectionScreenState();
}

class _UnitSelectionScreenState extends State<UnitSelectionScreen> {
  // Simple in-memory tracker for downloaded units & download progress states
  final Set<String> _downloadedUnits = {};
  final Set<String> _expiredUnits = {};
  final Map<String, double> _downloadProgress = {}; // unitId -> 0.0 to 1.0

  bool _isPackageUnlocked = false;
  final Map<int, int> _unitBestScores = {};

  bool _showOfflineTipBanner = true;

  @override
  void initState() {
    super.initState();
    SubscriptionService.addListener(_onSubscriptionChanged);
    logScreen(widget.isShortNotesMode ? 'ShortNotesUnitScreen' : 'UnitSelectionScreen');
    _loadOfflineDownloads();
    _loadBestScores();
    _checkRegistrationStatus();
    _checkOfflineTipBanner();
  }

  @override
  void dispose() {
    SubscriptionService.removeListener(_onSubscriptionChanged);
    super.dispose();
  }

  void _onSubscriptionChanged() {
    _checkRegistrationStatus();
  }

  void _checkOfflineTipBanner() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('seen_offline_info_tip') ?? false;
    if (mounted) {
      setState(() {
        _showOfflineTipBanner = !seen;
      });
    }
  }

  void _dismissOfflineTipBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_offline_info_tip', true);
    if (mounted) {
      setState(() {
        _showOfflineTipBanner = false;
      });
    }
  }

  void _checkRegistrationStatus() async {
    final bool isUnlocked = await SubscriptionService.isGradeUnlocked(widget.grade, subject: widget.enTitle);
    if (mounted) {
       setState(() {
         _isPackageUnlocked = isUnlocked;
       });
    }
  }

  Future<void> _checkRegistrationAndProceed(int index, int activeUnitNum, {required VoidCallback onSuccess}) async {
    // Unit 1 is always unlocked and 100% FREE for all subjects and grades
    if (activeUnitNum <= 1) {
      onSuccess();
      return;
    }

    // If package is already unlocked for this grade, proceed
    if (_isPackageUnlocked) {
      onSuccess();
      return;
    }

    // Query active subscription from Supabase students table with device binding and expiry verification
    final bool isAllowed = await SubscriptionService.checkSubscriptionAccess(
      grade: widget.grade,
      subject: widget.enTitle,
      unitNumber: activeUnitNum,
    );
    if (isAllowed) {
      _checkRegistrationStatus();
      onSuccess();
      return;
    }

    // Unit 2+ locked: Show the Telegram pop-up
    LockedUnitDialog.show(
      context,
      grade: widget.grade,
      subject: widget.enTitle,
      unitNumber: activeUnitNum,
      unitTitle: 'Unit $activeUnitNum',
      languageCode: widget.languageCode,
      isDarkMode: AppStateProvider.of(context).isDarkMode,
      onUnlocked: () {
        _checkRegistrationStatus();
        onSuccess();
      },
    );
  }

  Future<void> _openShortNotePdf(int unitNumber) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();

    // Enforce subscription check: Unit 1 is free trial; Unit 2+ requires active subscription
    final bool isAccessible = await SubscriptionService.isUnitAccessible(
      widget.grade,
      unitNumber,
      subject: widget.enTitle.isNotEmpty ? widget.enTitle : widget.subjectId,
    );

    if (!isAccessible) {
      if (!mounted) return;
      LockedUnitDialog.show(
        context,
        grade: widget.grade,
        subject: widget.enTitle.isNotEmpty ? widget.enTitle : widget.subjectId,
        unitNumber: unitNumber,
        unitTitle: 'Unit $unitNumber Short Note',
        languageCode: widget.languageCode,
        isDarkMode: AppStateProvider.of(context).isDarkMode,
        onUnlocked: () {
          _checkRegistrationStatus();
          _openShortNotePdf(unitNumber);
        },
      );
      return;
    }

    String? pdfUrl;
    try {
      // Query short_notes by grade, subject (case-insensitive), and unit_number to get pdf_url
      pdfUrl = await ShortNoteService.getPdfUrl(
        grade: widget.grade,
        subject: widget.subjectId,
        unitNumber: unitNumber,
      );

      // If not found with subjectId, fallback to enTitle
      if ((pdfUrl == null || pdfUrl.trim().isEmpty) && widget.enTitle.isNotEmpty) {
        pdfUrl = await ShortNoteService.getPdfUrl(
          grade: widget.grade,
          subject: widget.enTitle,
          unitNumber: unitNumber,
        );
      }
    } catch (e) {
      debugPrint('[UnitSelectionScreen] Error querying short_notes pdf_url: $e');
    }

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          pdfUrl: pdfUrl?.trim() ?? '',
          title: 'Unit $unitNumber Short Note',
          subject: widget.enTitle.isNotEmpty ? widget.enTitle : widget.subjectId,
          grade: widget.grade,
          unitNumber: unitNumber,
        ),
      ),
    );
  }

  void _showUnitOptionsSheet(BuildContext context, int unitNumber, String unitId, String unitTitle, bool isDownloaded) {
    QuizSelectionDialogs.showModeSelectionModal(
      context: context,
      grade: widget.grade,
      subject: widget.languageCode == 'am' ? widget.amTitle : widget.enTitle,
      unitNumber: unitNumber,
      unitTitle: unitTitle,
      onModeChosen: (mode) {
        if (mode == QuizMode.practice) {
          // Trigger second pop-up modal: Choose Question Type (MCQs, True/False, Blank Space, Matching)
          QuizSelectionDialogs.showQuestionTypeModal(
            context: context,
            grade: widget.grade,
            subject: widget.languageCode == 'am' ? widget.amTitle : widget.enTitle,
            unitNumber: unitNumber,
            onTypeSelected: (selectedQuestionType) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => QuizScreen(
                    grade: widget.grade,
                    subject: widget.subjectId,
                    unit: unitNumber,
                    mode: QuizMode.practice,
                    initialQuestionType: selectedQuestionType,
                    isOffline: isDownloaded,
                    offlineUnitId: isDownloaded ? 'g${widget.grade}_${unitId}_quiz' : null,
                  ),
                ),
              ).then((_) {
                _loadBestScores();
              });
            },
          );
        } else {
          // Exam Mode: Show confirmation modal with exam rules & start trigger
          QuizSelectionDialogs.showExamConfirmationModal(
            context: context,
            grade: widget.grade,
            subject: widget.languageCode == 'am' ? widget.amTitle : widget.enTitle,
            unitNumber: unitNumber,
            onStartExam: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => QuizScreen(
                    grade: widget.grade,
                    subject: widget.subjectId,
                    unit: unitNumber,
                    mode: QuizMode.exam,
                    isOffline: isDownloaded,
                    offlineUnitId: isDownloaded ? 'g${widget.grade}_${unitId}_quiz' : null,
                  ),
                ),
              ).then((_) {
                _loadBestScores();
              });
            },
          );
        }
      },
    );
  }

  void _showQuizStartDialog({
    required QuizMode mode,
    required int unitNumber,
    required VoidCallback onStart,
  }) {
    final bool isDark = AppStateProvider.of(context).isDarkMode;
    final bool isAmharic = widget.languageCode == 'am';

    final String title = isAmharic ? 'ምዕራፍ $unitNumber ለመጀመር ተዘጋጅተዋል?' : 'Ready to Start Unit $unitNumber?';
    
    final String description = mode == QuizMode.exam
        ? (isAmharic
            ? 'ይህ በጊዜ የተገደበ ፈተና ነው። በሚሰሩበት ጊዜ ፈጣን ምላሽ ወይም ማብራሪያ አያገኙም።'
            : 'This is a timed test. You will not get instant answers or explanations during the exam.')
        : (isAmharic
            ? 'በዚህ የልምምድ ዓይነት ፈጣን ምላሾችን፣ ማብራሪያዎችን እና ዝርዝር መረጃዎችን ያገኛሉ።'
            : 'In Practice Mode, you will get instant feedback, correct answers, and detailed explanations.');

    final String startText = isAmharic ? 'ጀምር' : 'Start Quiz';
    final String cancelText = isAmharic ? 'ተመለስ' : 'Cancel';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (mode == QuizMode.exam ? const Color(0xFFEF4444) : const Color(0xFF3B82F6)).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      mode == QuizMode.exam ? Icons.timer_rounded : Icons.school_rounded,
                      color: mode == QuizMode.exam ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        cancelText,
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        onStart();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        startText,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _hasInternet() async {
    if (kIsWeb) return true;
    try {
      final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _loadOfflineDownloads() async {
    final downloaded = await OfflineManager.getDownloadedUnitIds();
    final Set<String> expired = {};
    for (final id in downloaded) {
      if (await OfflineManager.isExpired(id)) {
        expired.add(id);
      }
    }
    if (mounted) {
      setState(() {
        _downloadedUnits.clear();
        _downloadedUnits.addAll(downloaded);
        _expiredUnits.clear();
        _expiredUnits.addAll(expired);
      });
    }
  }

  void _loadBestScores() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allUnits = _getUnits();
      final Map<int, int> loadedScores = {};
      for (int i = 0; i < allUnits.length; i++) {
        final int unitNum = i + 1;
        final String scoreKey = 'best_score_${widget.grade}_${widget.subjectId}_u$unitNum';
        final int? score = prefs.getInt(scoreKey);
        if (score != null) {
          loadedScores[unitNum] = score;
        }
      }
      if (mounted) {
        setState(() {
          _unitBestScores.clear();
          _unitBestScores.addAll(loadedScores);
        });
      }
    } catch (_) {}
  }

  // Bilingual translation helper
  String _local(String key) {
    // Dynamic retrieval from AppStateProvider context
    final String languageCode = AppStateProvider.of(context).languageCode;
    final Map<String, Map<String, String>> localized = {
      'en': {
        'back': 'Back',
        'units_title': 'Unit Explorer',
        'download': 'Download Questions',
        'downloading': 'Downloading Questions...',
        'downloaded': 'Questions Saved',
        'start_quiz': 'Start Practice',
        'completed': 'Completed',
        'units_count': 'Units Available',
        'progress_label': 'My Learning Progress',
        'bytes_info': 'Size: ~100 KB • Complete offline questions database',
        'info_sheet': 'Unit Questions Package',
        'info_desc': 'Downloading saves unit-specific exam questions directly to your device for complete offline practice.',
      },
      'am': {
        'back': 'ተመለስ',
        'units_title': 'የትምህርት ክፍሎች',
        'download': 'ጥያቄዎችን አውርድ',
        'downloading': 'ጥያቄዎችን በማውረድ ላይ...',
        'downloaded': 'ጥያቄዎች ወርደዋል',
        'start_quiz': 'መጠይቅ ጀምር',
        'completed': 'የተጠናቀቀ',
      }
    };
    return localized[languageCode]?[key] ?? key;
  }

  List<Map<String, dynamic>> _getUnits() {
    return CurriculumUnits.getUnits(
      subjectId: widget.subjectId,
      grade: widget.grade,
    );
  }

  int _selectedUnitIndex = 0;

  Future<void> _showDownloadOptionsModal({
    required String unitId,
    required int activeUnitNum,
    required String unitTitle,
  }) async {
    final isDark = AppStateProvider.of(context).isDarkMode;
    final cleanUnitId = 'g${widget.grade}_$unitId';

    // State trackers for this unit
    bool hasPdf = await OfflineManager.hasOfflinePdf(cleanUnitId);
    bool hasExam = await OfflineManager.hasOfflineQuestionsByMode(unitId: cleanUnitId, mode: 'exam');
    bool hasPracticeMcq = await OfflineManager.hasOfflineQuestionsByMode(unitId: cleanUnitId, mode: 'practice', questionType: 'multiple_choice');
    bool hasPracticeTf = await OfflineManager.hasOfflineQuestionsByMode(unitId: cleanUnitId, mode: 'practice', questionType: 'true_false');
    bool hasPracticeBlank = await OfflineManager.hasOfflineQuestionsByMode(unitId: cleanUnitId, mode: 'practice', questionType: 'blank_space');

    if (!mounted) return;

    // Download progress trackers for each independent item
    double? pdfProgress;
    double? examProgress;
    double? mcqProgress;
    double? tfProgress;
    double? blankProgress;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
            final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
            final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.download_rounded, color: Color(0xFF2563EB), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'የማውረጃ ማዕከል (Download Hub)',
                                style: GoogleFonts.notoSansEthiopic(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                'Unit $activeUnitNum: $unitTitle • ለየብቻ አውርድ (Independent)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: subColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Options List - Each item downloads independently
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      children: [
                        // 1. Short Note PDF (Independent)
                        _buildDownloadOptionTile(
                          title: 'አጭር ማስታወሻ ፒዲኤፍ (Short Note PDF)',
                          subtitle: 'ኦፊሴላዊ የኢትዮጵያ ስርዓተ-ትምህርት ፒዲኤፍ',
                          icon: Icons.picture_as_pdf_rounded,
                          iconColor: const Color(0xFFEF4444),
                          isDownloaded: hasPdf,
                          isDownloading: pdfProgress != null,
                          progress: pdfProgress,
                          onDownload: () async {
                            setModalState(() => pdfProgress = 0.1);
                            await _downloadUnitPdf(
                              cleanUnitId: cleanUnitId,
                              activeUnitNum: activeUnitNum,
                              unitTitle: unitTitle,
                              onProgress: (p) => setModalState(() => pdfProgress = p),
                            );
                            final updated = await OfflineManager.hasOfflinePdf(cleanUnitId);
                            setModalState(() {
                              pdfProgress = null;
                              hasPdf = updated;
                            });
                            _loadOfflineDownloads();
                          },
                          cardBg: cardBg,
                          textColor: textColor,
                          subColor: subColor,
                        ),
                        const SizedBox(height: 12),

                        // 2. Exam Mode Questions (Independent)
                        _buildDownloadOptionTile(
                          title: 'የፈተና ጥያቄዎች (Exam Mode Questions)',
                          subtitle: 'የተቆጠረ የብሔራዊ ፈተና ጥያቄዎች (Timed Exam)',
                          icon: Icons.timer_outlined,
                          iconColor: const Color(0xFFF59E0B),
                          isDownloaded: hasExam,
                          isDownloading: examProgress != null,
                          progress: examProgress,
                          onDownload: () async {
                            setModalState(() => examProgress = 0.1);
                            await _downloadUnitQuestionsSeparately(
                              cleanUnitId: cleanUnitId,
                              activeUnitNum: activeUnitNum,
                              mode: 'exam',
                              type: null,
                              onProgress: (p) => setModalState(() => examProgress = p),
                            );
                            final updated = await OfflineManager.hasOfflineQuestionsByMode(unitId: cleanUnitId, mode: 'exam');
                            setModalState(() {
                              examProgress = null;
                              hasExam = updated;
                            });
                            _loadOfflineDownloads();
                          },
                          cardBg: cardBg,
                          textColor: textColor,
                          subColor: subColor,
                        ),
                        const SizedBox(height: 14),

                        // Section Header: Practice Mode by Type
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: Text(
                            'የልምምድ ጥያቄዎች በየዓይነቱ (Practice Questions by Type)',
                            style: GoogleFonts.notoSansEthiopic(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ),

                        // 3a. Multiple Choice (Independent)
                        _buildDownloadOptionTile(
                          title: 'ምርጫ ጥያቄዎች (Multiple Choice - MCQ)',
                          subtitle: 'የተሟሉ 4 አማራጭ ያላቸው ጥያቄዎች',
                          icon: Icons.checklist_rounded,
                          iconColor: const Color(0xFF3B82F6),
                          isDownloaded: hasPracticeMcq,
                          isDownloading: mcqProgress != null,
                          progress: mcqProgress,
                          onDownload: () async {
                            setModalState(() => mcqProgress = 0.1);
                            await _downloadUnitQuestionsSeparately(
                              cleanUnitId: cleanUnitId,
                              activeUnitNum: activeUnitNum,
                              mode: 'practice',
                              type: 'multiple_choice',
                              onProgress: (p) => setModalState(() => mcqProgress = p),
                            );
                            final updated = await OfflineManager.hasOfflineQuestionsByMode(unitId: cleanUnitId, mode: 'practice', questionType: 'multiple_choice');
                            setModalState(() {
                              mcqProgress = null;
                              hasPracticeMcq = updated;
                            });
                            _loadOfflineDownloads();
                          },
                          cardBg: cardBg,
                          textColor: textColor,
                          subColor: subColor,
                        ),
                        const SizedBox(height: 10),

                        // 3b. True / False (Independent)
                        _buildDownloadOptionTile(
                          title: 'እውነት / ሐሰት (True or False)',
                          subtitle: 'ጽንሰ-ሀሳብን የሚፈትሹ ጥያቄዎች',
                          icon: Icons.rule_rounded,
                          iconColor: const Color(0xFF10B981),
                          isDownloaded: hasPracticeTf,
                          isDownloading: tfProgress != null,
                          progress: tfProgress,
                          onDownload: () async {
                            setModalState(() => tfProgress = 0.1);
                            await _downloadUnitQuestionsSeparately(
                              cleanUnitId: cleanUnitId,
                              activeUnitNum: activeUnitNum,
                              mode: 'practice',
                              type: 'true_false',
                              onProgress: (p) => setModalState(() => tfProgress = p),
                            );
                            final updated = await OfflineManager.hasOfflineQuestionsByMode(unitId: cleanUnitId, mode: 'practice', questionType: 'true_false');
                            setModalState(() {
                              tfProgress = null;
                              hasPracticeTf = updated;
                            });
                            _loadOfflineDownloads();
                          },
                          cardBg: cardBg,
                          textColor: textColor,
                          subColor: subColor,
                        ),
                        const SizedBox(height: 10),

                        // 3c. Fill in the blank (Independent)
                        _buildDownloadOptionTile(
                          title: 'ክፍት ቦታ ሙላ (Blank Space)',
                          subtitle: 'ቀመሮችንና ቁልፍ ቃላትን የሚጠይቁ',
                          icon: Icons.edit_note_rounded,
                          iconColor: const Color(0xFF8B5CF6),
                          isDownloaded: hasPracticeBlank,
                          isDownloading: blankProgress != null,
                          progress: blankProgress,
                          onDownload: () async {
                            setModalState(() => blankProgress = 0.1);
                            await _downloadUnitQuestionsSeparately(
                              cleanUnitId: cleanUnitId,
                              activeUnitNum: activeUnitNum,
                              mode: 'practice',
                              type: 'blank_space',
                              onProgress: (p) => setModalState(() => blankProgress = p),
                            );
                            final updated = await OfflineManager.hasOfflineQuestionsByMode(unitId: cleanUnitId, mode: 'practice', questionType: 'blank_space');
                            setModalState(() {
                              blankProgress = null;
                              hasPracticeBlank = updated;
                            });
                            _loadOfflineDownloads();
                          },
                          cardBg: cardBg,
                          textColor: textColor,
                          subColor: subColor,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _downloadUnitPdf({
    required String cleanUnitId,
    required int activeUnitNum,
    required String unitTitle,
    Function(double)? onProgress,
  }) async {
    final String cardKey = 'g${widget.grade}_${cleanUnitId.replaceAll("g${widget.grade}_", "")}_notes';
    try {
      final normalizedSubject = widget.subjectId.toLowerCase();
      String pdfUrl = '';
      String summary = '';

      setState(() => _downloadProgress[cardKey] = 0.15);
      onProgress?.call(0.15);

      try {
        final res = await Supabase.instance.client
            .from('short_notes')
            .select()
            .eq('grade', widget.grade)
            .eq('unit_number', activeUnitNum)
            .ilike('subject', '%$normalizedSubject%')
            .maybeSingle();

        if (res != null) {
          pdfUrl = res['pdf_url']?.toString() ?? '';
          summary = res['summary']?.toString() ?? res['content']?.toString() ?? '';
        }
      } catch (e) {
        debugPrint('[Download PDF] query note: $e');
      }

      onProgress?.call(0.55);
      if (mounted) setState(() => _downloadProgress[cardKey] = 0.55);

      if (pdfUrl.isEmpty) {
        pdfUrl = 'https://smartlearn.et/curriculum/grade_${widget.grade}/${normalizedSubject}_u$activeUnitNum.pdf';
      }

      await OfflineManager.saveOfflinePdf(
        unitId: cleanUnitId,
        pdfUrl: pdfUrl,
        title: 'Unit $activeUnitNum: $unitTitle',
        summary: summary,
        grade: widget.grade,
        unit: activeUnitNum,
      );

      onProgress?.call(1.0);
      if (mounted) setState(() => _downloadProgress[cardKey] = 1.0);
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        setState(() {
          _downloadProgress.remove(cardKey);
          _downloadedUnits.add(cardKey);
          _downloadedUnits.add(cleanUnitId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.languageCode == 'am'
                        ? 'የ Unit $activeUnitNum ፒዲኤፍ ማስታወሻ በተሟላ ሁኔታ ወርዷል (Completed)!'
                        : 'Unit $activeUnitNum Short Note downloaded completely (Completed)!',
                    style: GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.bold),
                  ),
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
        setState(() => _downloadProgress.remove(cardKey));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ማውረድ አልተሳካም፡ $e', style: GoogleFonts.notoSansEthiopic()),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _downloadUnitQuestionsSeparately({
    required String cleanUnitId,
    required int activeUnitNum,
    required String mode,
    String? type,
    Function(double)? onProgress,
  }) async {
    final String cardKey = 'g${widget.grade}_${cleanUnitId.replaceAll("g${widget.grade}_", "")}_quiz';
    try {
      setState(() => _downloadProgress[cardKey] = 0.15);
      onProgress?.call(0.15);

      final quizMode = mode == 'exam' ? QuizMode.exam : QuizMode.practice;
      final questions = await QuizService.fetchQuestions(
        grade: widget.grade,
        subject: widget.subjectId,
        unit: activeUnitNum,
        mode: quizMode,
        questionType: type ?? 'all',
      );

      if (questions.isEmpty) {
        throw Exception("ጥያቄዎች አልተገኙም");
      }

      onProgress?.call(0.6);
      if (mounted) setState(() => _downloadProgress[cardKey] = 0.6);

      await OfflineManager.saveOfflineQuestionsByMode(
        unitId: cleanUnitId,
        mode: mode,
        questionType: type,
        questions: questions,
        grade: widget.grade,
        unit: activeUnitNum,
      );

      onProgress?.call(1.0);
      if (mounted) setState(() => _downloadProgress[cardKey] = 1.0);
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        setState(() {
          _downloadProgress.remove(cardKey);
          _downloadedUnits.add(cardKey);
          _downloadedUnits.add(cleanUnitId);
        });

        final label = mode == 'exam'
            ? (widget.languageCode == 'am' ? 'የፈተና ጥያቄዎች (Exam Mode)' : 'Exam Mode Questions')
            : (widget.languageCode == 'am' ? 'የልምምድ ጥያቄዎች (${(type ?? "all").toUpperCase()})' : 'Practice Questions (${(type ?? "all").toUpperCase()})');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.languageCode == 'am'
                        ? '$label ለ Unit $activeUnitNum በተሟላ ሁኔታ ወርዷል (Completed)!'
                        : '$label for Unit $activeUnitNum downloaded completely (Completed)!',
                    style: GoogleFonts.notoSansEthiopic(fontWeight: FontWeight.bold),
                  ),
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
        setState(() => _downloadProgress.remove(cardKey));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ማውረድ አልተሳካም፡ $e', style: GoogleFonts.notoSansEthiopic()),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Widget _buildDownloadOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isDownloaded,
    required VoidCallback onDownload,
    required Color cardBg,
    required Color textColor,
    required Color subColor,
    bool isDownloading = false,
    double? progress,
  }) {
    final bool isAm = widget.languageCode == 'am';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDownloaded
              ? const Color(0xFF10B981).withValues(alpha: 0.4)
              : (cardBg == Colors.white ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.notoSansEthiopic(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: subColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: isDownloading ? null : onDownload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDownloaded
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : (isDownloading ? const Color(0xFF3B82F6) : const Color(0xFF2563EB)),
                  foregroundColor: isDownloaded ? const Color(0xFF10B981) : Colors.white,
                  elevation: 0,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: isDownloading
                    ? const SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(
                        isDownloaded ? Icons.check_circle_rounded : Icons.download_rounded,
                        size: 15,
                      ),
                label: Text(
                  isDownloading
                      ? '${((progress ?? 0) * 100).toInt()}%'
                      : (isDownloaded
                          ? (isAm ? 'ወርዷል (Completed)' : 'Completed')
                          : (isAm ? 'አውርድ' : 'Download')),
                  style: GoogleFonts.notoSansEthiopic(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (isDownloading && progress != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isAm ? 'በማውረድ ላይ...' : 'Downloading process...',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: iconColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: iconColor.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(iconColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _downloadUnit(String unitId) async {
    final String typeSuffix = widget.isShortNotesMode ? '_notes' : '_quiz';
    final String downloadKey = 'g${widget.grade}_${unitId}$typeSuffix';
    final String cleanKey = downloadKey.replaceAll('_notes', '');
    final bool isExpired = _expiredUnits.contains(downloadKey);
    if ((_downloadedUnits.contains(cleanKey) || _downloadedUnits.contains(downloadKey)) && !isExpired) return;

    final String languageCode = AppStateProvider.of(context).languageCode;
    final allUnits = _getUnits();
    final unitIndex = allUnits.indexWhere((u) => u['id'] == unitId) + 1;
    final int activeUnitNum = unitIndex > 0 ? unitIndex : 1;

    void performDownload() async {
      // Start download status with 0% progress
      setState(() {
        _downloadProgress[downloadKey] = 0.0;
      });

      double currentProgress = 0.0;
      // Use a standard Stream.periodic timer to smoothly count progress from 0% to 100%
      final progressTimer = Stream.periodic(const Duration(milliseconds: 100)).listen((_) {
        if (currentProgress < 0.90) {
          // Slow down near 90% for realism
          currentProgress += 0.04 + (0.04 * (1.0 - currentProgress));
          if (currentProgress > 0.90) currentProgress = 0.90;
          if (mounted) {
            setState(() {
              _downloadProgress[downloadKey] = currentProgress;
            });
          }
        }
      });

      try {
        int fetchedQuestionsCount = 0;
        if (widget.isShortNotesMode) {
          String getNormalizedSubjectName(String rawId) {
            final sub = rawId.toLowerCase();
            if (sub.contains('math')) return 'mathematics';
            if (sub.contains('biol') || sub.contains('bio')) return 'biology';
            if (sub.contains('phys')) return 'physics';
            if (sub.contains('chem')) return 'chemistry';
            if (sub.contains('geog') || sub.contains('geo')) return 'geography';
            if (sub.contains('hist')) return 'history';
            if (sub.contains('civ')) return 'civics';
            if (sub.contains('agri') || sub.contains('agr')) return 'agriculture';
            if (sub.contains('econ') || sub.contains('eco')) return 'economics';
            if (sub.contains('eng')) return 'english';
            return sub;
          }

          final String normalizedSubject = getNormalizedSubjectName(widget.subjectId);

          List<Map<String, dynamic>> fetchedNotes = [];
          
          try {
            // Fetch from short_notes table with current schema (grade, subject, unit_number, pdf_url)
            final shortNotesResponse = await Supabase.instance.client
                .from('short_notes')
                .select('grade, subject, unit_number, pdf_url')
                .eq('grade', widget.grade)
                .eq('unit_number', activeUnitNum)
                .ilike('subject', '%$normalizedSubject%');

            if (shortNotesResponse.isNotEmpty) {
              fetchedNotes = List<Map<String, dynamic>>.from(shortNotesResponse);
            }
          } catch (e) {
            debugPrint('[Offline Download] Short notes query notice: $e');
          }

          // Fallback to unit_notes if short_notes is empty
          if (fetchedNotes.isEmpty) {
            final String expectedSubjectId = '${widget.grade}_$normalizedSubject';
            final fetchedNotesResponse = await Supabase.instance.client
                .from('units')
                .select('''
                  id,
                  subject_id,
                  unit_number,
                  subjects!inner(
                    id,
                    name,
                    grade
                  ),
                  unit_notes (
                    id,
                    unit_id,
                    title,
                    html_content,
                    created_at
                  )
                ''')
                .eq('unit_number', activeUnitNum)
                .eq('subjects.grade', widget.grade)
                .or('subject_id.eq.$expectedSubjectId,subject_id.ilike.%$normalizedSubject%,subject_id.ilike.%${widget.subjectId}%')
                .maybeSingle();

            if (fetchedNotesResponse != null && fetchedNotesResponse['unit_notes'] != null) {
              fetchedNotes = List<Map<String, dynamic>>.from(fetchedNotesResponse['unit_notes']);
            }
          }

          if (fetchedNotes.isEmpty) {
            throw Exception("No notes available on developer server.");
          }

          await OfflineManager.saveOfflineNotes(
            downloadKey,
            fetchedNotes,
            grade: widget.grade,
            unit: activeUnitNum,
          );
        } else {
          final fetchedQuestions = await QuizService.fetchQuestions(
            grade: widget.grade,
            subject: widget.subjectId,
            unit: activeUnitNum,
          );

          if (fetchedQuestions.isEmpty) {
            throw Exception("No questions available on developer server.");
          }
          fetchedQuestionsCount = fetchedQuestions.length;

          await OfflineManager.saveOfflineQuestions(
            downloadKey,
            fetchedQuestions,
            grade: widget.grade,
            unit: activeUnitNum,
          );
        }
        await OfflineManager.addDownload(downloadKey);

        // Log Analytics Event for offline unit download
        AnalyticsService.logOfflineDownload(
          unitTitle: 'Unit $activeUnitNum',
          subject: widget.subjectId,
          grade: widget.grade,
        );

        progressTimer.cancel();

        // Finish progress smoothly to 100%
        if (mounted) {
          setState(() {
            _downloadProgress[downloadKey] = 1.0;
          });
        }

        // Brief delay so 100% is clearly visible to user
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          setState(() {
            _downloadProgress.remove(downloadKey);
            _downloadedUnits.add(downloadKey);
            _expiredUnits.remove(downloadKey);
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.isShortNotesMode
                          ? (languageCode == 'en'
                              ? 'Downloaded completely (Completed)! Short note is available offline.'
                              : 'በተሟላ ሁኔታ ወርዷል (Completed)! አጭር ማስታወሻ ከመስመር ውጭ ዝግጁ ነው።')
                          : (languageCode == 'en'
                              ? 'Downloaded completely (Completed)! ${fetchedQuestionsCount} questions available offline.'
                              : 'በተሟላ ሁኔታ ወርዷል (Completed)! ${fetchedQuestionsCount} ጥያቄዎች ከመስመር ውጭ ዝግጁ ናቸው።'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        progressTimer.cancel();
        if (mounted) {
          setState(() {
            _downloadProgress.remove(downloadKey);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      languageCode == 'en'
                          ? 'Download failed. Check network connection.'
                          : (widget.isShortNotesMode
                              ? 'ማስታወሻዎችን ማውረድ አልተቻለም፡ በይነመረብዎን ያረጋግጡ።'
                              : 'ጥያቄዎችን ማውረድ አልተቻለም፡ በይነመረብዎን ያረጋግጡ።'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }

    try {
      final bool hasConn = await _hasInternet();
      if (!hasConn) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      languageCode == 'en'
                          ? 'No internet connection. Please connect to download.'
                          : 'ምንም የኢንተርኔት ግንኙነት የለም። እባክዎ ለማውረድ ከኢንተርኔት ጋር ይገናኙ።',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      performDownload();
    } catch (e) {
      debugPrint("Error in download logic: $e");
      performDownload();
    }
  }

  void _showInfoSheet() {
    final appConfig = AppStateProvider.of(context);
    final isLight = !appConfig.isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.download_for_offline_rounded, color: widget.color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _local('info_sheet'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isLight ? const Color(0xFF0F172A) : Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _local('info_desc'),
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _local('bytes_info'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.color,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Live query from AppStateProvider for absolute zero delay updates
    final appConfig = AppStateProvider.of(context);
    final bool isDarkMode = appConfig.isDarkMode;
    final String languageCode = appConfig.languageCode;
    final bool isLight = !isDarkMode;

    final Color bgColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color cardBgColor = isLight ? Colors.white : const Color(0xFF1E293B);
    final Color headerTextColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final Color descColor = isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8);

    final allUnits = _getUnits();
    final filteredUnits = allUnits;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: isLight ? Colors.white : const Color(0xFF1E293B),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: headerTextColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          languageCode == 'en' ? widget.enTitle : widget.amTitle,
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w900,
            color: headerTextColor,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Downloads Hub',
            icon: Icon(Icons.download_done_rounded, color: headerTextColor, size: 20),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DownloadsScreen(
                    initialGrade: widget.grade,
                    initialSubject: widget.enTitle,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.info_outline_rounded, color: headerTextColor, size: 20),
            onPressed: _showInfoSheet,
          ),
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round_outlined,
              color: headerTextColor,
              size: 20,
            ),
            onPressed: appConfig.onToggleTheme,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: bgColor,
          image: DecorationImage(
            image: const AssetImage('assets/images/education_bg_pattern.png'),
            repeat: ImageRepeat.repeat,
            opacity: isLight ? 0.09 : 0.03,
            colorFilter: isLight ? null : const ColorFilter.mode(Colors.white54, BlendMode.modulate),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Beautiful Hero section with Subject Card presentation
              Container(
                decoration: BoxDecoration(
                  color: isLight ? Colors.white : const Color(0xFF1E293B),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isLight
                          ? Colors.black.withValues(alpha: 0.03)
                          : Colors.black.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dynamic scaled illustration in unique background box
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: widget.color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 36,
                              height: 36,
                              child: widget.icon,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Titles and Grade
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: widget.color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  languageCode == 'en'
                                      ? 'GRADE ${widget.grade}'
                                      : 'ክፍል ${widget.grade}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: widget.color,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                languageCode == 'en' ? widget.enTitle : widget.amTitle,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: headerTextColor,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                languageCode == 'en'
                                    ? 'High-quality comprehensive unit reviews'
                                    : 'ምርጥ ከመስመር ውጭ የትምህርት ክፍሎች',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: descColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1, thickness: 1),
                    const SizedBox(height: 8),
                    // Progress metric section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _local('progress_label'),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: headerTextColor),
                        ),
                        Text(
                          languageCode == 'en'
                              ? '${_downloadedUnits.length} / ${allUnits.length} Offline'
                              : '${_downloadedUnits.length} / ${allUnits.length} ወርዷል',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: widget.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Custom layout ProgressBar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: allUnits.isEmpty ? 0.0 : (_downloadedUnits.length / allUnits.length),
                        minHeight: 6.0,
                        backgroundColor: widget.color.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                      ),
                    ),
                  ],
                ),
              ),

              if (_showOfflineTipBanner)
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BFFF).withValues(alpha: isLight ? 0.08 : 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF00BFFF).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF00BFFF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.download_for_offline_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              languageCode == 'am' ? '💡 ከመስመር ውጭ (Offline) ያንብቡ' : '💡 Study 100% Offline',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isLight ? const Color(0xFF0F172A) : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              languageCode == 'am'
                                  ? 'የእያንዳንዱን ምዕራፍ ጥያቄዎችና ማስታወሻዎች አውርደው ያለ ኢንተርኔት ይጠቀሙ!'
                                  : 'Download units once to access quizzes & short notes without any internet connection!',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isLight ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _dismissOfflineTipBanner,
                        color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ),

              if (filteredUnits.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                  child: Column(
                    children: [
                      Icon(Icons.layers_clear_rounded, color: descColor.withValues(alpha: 0.4), size: 48),
                      const SizedBox(height: 12),
                      Text(
                        languageCode == 'en' ? 'No units available yet.' : 'ምንም የትምህርት ክፍሎች አልተገኙም።',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: descColor, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  itemCount: filteredUnits.length,
                  itemBuilder: (context, index) {
                    final unit = filteredUnits[index];
                    final String unitId = unit['id'];
                    final String typeSuffix = widget.isShortNotesMode ? '_notes' : '_quiz';
                    final String downloadKey = 'g${widget.grade}_${unitId}$typeSuffix';
                    final String cleanKey = downloadKey.replaceAll('_notes', '');
                    final bool isDownloaded = _downloadedUnits.contains(cleanKey) || _downloadedUnits.contains(downloadKey);
                    final bool isExpired = _expiredUnits.contains(downloadKey);
                    final double? progress = _downloadProgress[downloadKey];

                    final String title = unit['enUnit'] ?? '';
                    final String desc = languageCode == 'en' ? unit['enDesc'] : unit['amDesc'];
                    final bool isSelected = _selectedUnitIndex == index;

                    final selectedUnit = filteredUnits[index];
                    final originalIndex = allUnits.indexOf(selectedUnit);
                    final int activeUnitNum = originalIndex >= 0 ? originalIndex + 1 : index + 1;

                    final indexFactor = index * 100;
                    final bool isLocked = activeUnitNum > 1 && !_isPackageUnlocked;
                    return TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 300 + indexFactor),
                      curve: Curves.easeOutCubic,
                      builder: (context, animValue, animChild) {
                        return Transform.translate(
                          offset: Offset(0.0, 30.0 * (1.1 - animValue)),
                          child: Opacity(
                            opacity: animValue,
                            child: animChild,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 11.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cardBgColor,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isLight ? 0.02 : 0.12),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: isSelected
                                        ? widget.color
                                        : (isLight ? const Color(0xFFEDF2F7) : const Color(0xFF334155)),
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        if (widget.isShortNotesMode) {
                                          setState(() {
                                            _selectedUnitIndex = index;
                                          });
                                          _checkRegistrationAndProceed(index, activeUnitNum, onSuccess: () {
                                            _openShortNotePdf(activeUnitNum);
                                          });
                                        } else {
                                          _checkRegistrationAndProceed(index, activeUnitNum, onSuccess: () {
                                            setState(() {
                                              _selectedUnitIndex = index;
                                            });
                                            _showUnitOptionsSheet(context, activeUnitNum, unitId, title, isDownloaded);
                                          });
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                                        child: Row(
                                          children: [
                                            // Left: circular container with lock or icon
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: isLocked
                                                    ? (isLight ? const Color(0xFFE2E8F0) : const Color(0xFF334155))
                                                    : widget.color.withValues(alpha: 0.08),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: isLocked
                                                    ? Icon(
                                                        Icons.lock_rounded,
                                                        color: isLight ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                                        size: 20,
                                                      )
                                                    : SizedBox(
                                                        width: 24,
                                                        height: 24,
                                                        child: widget.icon,
                                                      ),
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            // Middle: Unit Title and subtitle
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    title,
                                                    style: TextStyle(
                                                      fontSize: 14.0,
                                                      fontWeight: FontWeight.w900,
                                                      color: headerTextColor,
                                                      height: 1.25,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    desc,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 11.5,
                                                      fontWeight: FontWeight.w500,
                                                      color: descColor,
                                                    ),
                                                  ),
                                                  if (isLocked) ...[
                                                    const SizedBox(height: 4),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                                        borderRadius: BorderRadius.circular(6),
                                                        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          const Icon(Icons.lock_rounded, size: 11, color: Color(0xFFEF4444)),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            widget.isShortNotesMode
                                                                ? (languageCode == 'am' ? 'Subscribe • ተቆልፏል' : 'Subscribe to Unlock')
                                                                : (languageCode == 'am' ? 'ተቆልፏል • ለመክፈት ይንኩ' : 'Locked • Tap to unlock'),
                                                            style: const TextStyle(
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.w800,
                                                              color: Color(0xFFEF4444),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                  if (progress != null) ...[
                                                    const SizedBox(height: 8),
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            Text(
                                                              widget.isShortNotesMode
                                                                  ? (languageCode == 'en' ? 'Downloading short note...' : 'ማስታወሻ በማውረድ ላይ...')
                                                                  : (languageCode == 'en' ? 'Downloading questions...' : 'ጥያቄዎችን በማውረድ ላይ...'),
                                                              style: TextStyle(
                                                                fontSize: 10.5,
                                                                fontWeight: FontWeight.bold,
                                                                color: widget.color,
                                                              ),
                                                            ),
                                                            Text(
                                                              '${(progress * 100).toInt()}%',
                                                              style: TextStyle(
                                                                fontSize: 10.5,
                                                                fontWeight: FontWeight.w900,
                                                                color: widget.color,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 4),
                                                        ClipRRect(
                                                          borderRadius: BorderRadius.circular(4),
                                                          child: LinearProgressIndicator(
                                                            value: progress,
                                                            minHeight: 6,
                                                            backgroundColor: widget.color.withValues(alpha: 0.12),
                                                            valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                  if (_unitBestScores.containsKey(activeUnitNum)) ...[
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                                            borderRadius: BorderRadius.circular(6),
                                                            border: Border.all(
                                                              color: const Color(0xFF10B981).withValues(alpha: 0.25),
                                                              width: 1.0,
                                                            ),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              const Icon(
                                                                Icons.emoji_events_rounded,
                                                                color: Colors.amber,
                                                                size: 12,
                                                              ),
                                                              const SizedBox(width: 4),
                                                              Text(
                                                                languageCode == 'en'
                                                                    ? "Score: ${_unitBestScores[activeUnitNum]}%"
                                                                    : "ውጤት: ${_unitBestScores[activeUnitNum]}%",
                                                                style: const TextStyle(
                                                                  fontSize: 10.5,
                                                                  fontWeight: FontWeight.w800,
                                                                  color: Color(0xFF10B981),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Tiny grey chevron arrow on the right
                                            Icon(
                                              Icons.chevron_right_rounded,
                                              color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                             // Separate Download Button next to each card
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isLocked
                                    ? (isLight ? const Color(0xFF8C95A0) : const Color(0xFF475569)) // Grey for locked
                                    : (isDownloaded
                                        ? (isExpired ? const Color(0xFFD97706) : const Color(0xFF10B981)) // Amber if expired, Green if fresh
                                        : const Color(0xFFCC4A52)), // Red if unlocked / not downloaded
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isLocked
                                            ? Colors.black
                                            : (isDownloaded
                                                ? (isExpired ? const Color(0xFFD97706) : const Color(0xFF10B981))
                                                : const Color(0xFFCC4A52)))
                                        .withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Tooltip(
                                message: isLocked 
                                     ? (widget.isShortNotesMode ? (languageCode == 'am' ? 'Subscribe • ተቆልፏል' : 'Subscribe to Unlock') : 'Locked') 
                                     : (languageCode == 'en'
                                         ? (isDownloaded
                                             ? (isExpired ? 'Re-download' : 'Completed')
                                             : 'Download')
                                         : (isDownloaded
                                             ? (isExpired ? 'እንደገና አውርድ' : 'ወርዷል (Completed)')
                                             : 'አውርድ')),
                                child: progress != null
                                    ? Center(
                                        child: Text(
                                          '${(progress * 100).toInt()}%',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      )
                                    : IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: Icon(
                                          isLocked 
                                              ? Icons.lock_rounded
                                              : (isDownloaded
                                                  ? (isExpired ? Icons.update_rounded : Icons.cloud_done_rounded)
                                                  : Icons.download_rounded),
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                        onPressed: () {
                                          if (isLocked) {
                                            LockedUnitDialog.show(
                                              context,
                                              grade: widget.grade,
                                              subject: widget.enTitle,
                                              unitNumber: activeUnitNum,
                                              unitTitle: title,
                                              languageCode: widget.languageCode,
                                              isDarkMode: AppStateProvider.of(context).isDarkMode,
                                              onUnlocked: () {
                                                _checkRegistrationStatus();
                                                if (widget.isShortNotesMode) {
                                                  _openShortNotePdf(activeUnitNum);
                                                }
                                              },
                                            );
                                            return;
                                          }
                                          if (widget.isShortNotesMode) {
                                            if (isDownloaded) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: [
                                                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          languageCode == 'am'
                                                              ? 'የ Unit $activeUnitNum ማስታወሻ አስቀድሞ በተሟላ ሁኔታ ወርዷል (Completed)!'
                                                              : 'Unit $activeUnitNum Short Note is already downloaded completely (Completed)!',
                                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  backgroundColor: const Color(0xFF10B981),
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                            } else {
                                              _downloadUnit(unitId);
                                            }
                                            return;
                                          }
                                          _checkRegistrationAndProceed(index, activeUnitNum, onSuccess: () {
                                            _showDownloadOptionsModal(
                                              unitId: unitId,
                                              activeUnitNum: activeUnitNum,
                                              unitTitle: title,
                                            );
                                          });
                                        },
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    ),
  );
  }
}

