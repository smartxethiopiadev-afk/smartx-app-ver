import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/offline_manager.dart';
import '../services/pdf_cache_service.dart';
import '../main.dart';

enum NotesErrorType {
  none,
  noInternet,
  emptyData,
  accessDenied,
  pdfLoadError,
  unknown,
}

class NotesScreen extends StatefulWidget {
  final int grade;
  final String subjectId;
  final int unitNumber;
  final String unitTitle;
  final Color themeColor;
  final bool isDarkMode;
  final String languageCode;

  const NotesScreen({
    super.key,
    required this.grade,
    required this.subjectId,
    required this.unitNumber,
    required this.unitTitle,
    required this.themeColor,
    required this.isDarkMode,
    required this.languageCode,
  });

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  late PdfViewerController _pdfViewerController;
  bool _isBookmarked = false;
  bool _isLoading = true;
  bool _hasError = false;

  NotesErrorType _errorType = NotesErrorType.none;
  String? _debugErrorDetails;
  bool _showDebugInfo = false;

  List<Map<String, dynamic>> _notesList = [];
  int _selectedNoteIndex = 0;
  String? _pdfUrl;
  String? _pdfTitle;

  File? _localPdfFile;
  bool _isDownloadingPdf = false;

  int _currentPage = 1;
  int _pageCount = 0;

  final PdfScrollDirection _scrollDirection = PdfScrollDirection.vertical;
  final bool _isColorInverted = false;
  final bool _isPageByPage = false;

  PdfPageLayoutMode get _pageLayoutMode =>
      _isPageByPage ? PdfPageLayoutMode.single : PdfPageLayoutMode.continuous;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _checkBookmarkStatus();
    _fetchNotes();
  }

  void _showFloatingSnackbar(String message, {bool isError = false, bool isSuccess = false, bool isInfo = false}) {
    if (!mounted) return;
    Color bgColor = const Color(0xFF1E293B);
    IconData iconData = Icons.info_outline_rounded;
    if (isError) {
      bgColor = const Color(0xFFDC2626);
      iconData = Icons.error_outline_rounded;
    } else if (isSuccess) {
      bgColor = const Color(0xFF059669);
      iconData = Icons.check_circle_outline_rounded;
    } else if (isInfo) {
      bgColor = const Color(0xFF0284C7);
      iconData = Icons.downloading_rounded;
    }

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(iconData, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 4 : 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _checkAndLoadLocalPdf() async {
    if (_pdfUrl == null || _pdfUrl!.isEmpty) return;
    final String unitId = _getUnitId();
    try {
      final file = await PdfCacheService.getLocalPdfFile(unitId, _pdfUrl!);
      if (mounted) {
        setState(() {
          _localPdfFile = file;
        });
      }
    } catch (e) {
      debugPrint('[PDF Cache Error] Error checking local file for $unitId: $e');
    }
  }

  Future<void> _downloadPdfForOffline() async {
    if (_pdfUrl == null || _pdfUrl!.isEmpty) return;
    final String unitId = _getUnitId();

    setState(() {
      _isDownloadingPdf = true;
    });

    _showFloatingSnackbar(
      widget.languageCode == 'en'
          ? 'Downloading PDF note for offline reading...'
          : 'ለስልክዎ ማስታወሻው በማውረድ ላይ ነው...',
      isInfo: true,
    );

    try {
      final savedFile = await PdfCacheService.downloadAndSavePdf(
        unitId: unitId,
        pdfUrl: _pdfUrl!,
        registerOffline: false,
      );

      if (_notesList.isNotEmpty) {
        await OfflineManager.saveOfflineNotes(
          unitId,
          _notesList,
          grade: widget.grade,
          unit: widget.unitNumber,
        );
      }

      await OfflineManager.addDownload(unitId);

      if (mounted) {
        setState(() {
          _localPdfFile = savedFile;
          _isDownloadingPdf = false;
        });
        _showFloatingSnackbar(
          widget.languageCode == 'en'
              ? 'PDF downloaded successfully! Offline reading enabled.'
              : 'ማስታወሻው በስኬት ወርዷል! ያለ ኢንተርኔት ማንበብ ይችላሉ።',
          isSuccess: true,
        );
      }
    } catch (e) {
      debugPrint('[PDF Cache Error] User download failed for $unitId: $e');
      await OfflineManager.removeDownload(unitId);
      if (mounted) {
        setState(() {
          _isDownloadingPdf = false;
        });
        _showFloatingSnackbar(
          widget.languageCode == 'en'
              ? 'PDF download failed: ${e.toString().replaceAll('Exception: ', '')}'
              : 'ማውረድ አልተሳካም፡ ${e.toString().replaceAll('Exception: ', '')}',
          isError: true,
        );
      }
    }
  }

  void _backgroundCacheCurrentPdf() async {
    if (_pdfUrl == null || _pdfUrl!.isEmpty || _localPdfFile != null) return;
    try {
      final unitId = _getUnitId();
      final file = await PdfCacheService.downloadAndSavePdf(
        unitId: unitId,
        pdfUrl: _pdfUrl!,
        registerOffline: false,
      );
      if (mounted) {
        setState(() {
          _localPdfFile = file;
        });
      }
    } catch (e) {
      debugPrint('[PDF Cache Error] Auto background cache caught: $e');
    }
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  void _showDebugSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '[Debug] $message',
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _getUnitId() {
    String sub = (widget.subjectId).toLowerCase();
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
    return 'g${widget.grade}_$prefix${widget.unitNumber}';
  }

  String _getNormalizedSubjectName() {
    final sub = widget.subjectId.toLowerCase();
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

  Future<void> _fetchNotes() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorType = NotesErrorType.none;
        _debugErrorDetails = null;
      });

      final String unitId = _getUnitId();
      final bool isNotesDownloaded = await OfflineManager.isDownloaded(unitId);
      List<Map<String, dynamic>> fetchedNotes = [];

      if (isNotesDownloaded) {
        fetchedNotes = await OfflineManager.getOfflineNotes(unitId);
      } else {
        final String normalizedSubject = _getNormalizedSubjectName();
        final String expectedSubjectId = '${widget.grade}_$normalizedSubject';

        _debugErrorDetails = 'Grade: ${widget.grade}, SubjectId: ${widget.subjectId}, '
            'NormalizedSubject: $normalizedSubject, ExpectedSubjectId: $expectedSubjectId, '
            'UnitNumber: ${widget.unitNumber}';

        final response = await Supabase.instance.client
            .from('units')
            .select('''
              id,
              unit_number,
              subject_id,
              subjects!inner(
                id,
                name,
                grade
              ),
              unit_notes(
                id,
                unit_id,
                title,
                pdf_url,
                created_at
              )
            ''')
            .eq('unit_number', widget.unitNumber)
            .eq('subjects.grade', widget.grade)
            .ilike('subjects.name', '%$normalizedSubject%')
            .maybeSingle();

        if (response != null && response['unit_notes'] != null) {
          fetchedNotes = List<Map<String, dynamic>>.from(response['unit_notes']);
        }

        if (response == null) {
          _debugErrorDetails = 'Supabase query returned null.\nQuery filters:\n'
              '  unit_number: ${widget.unitNumber}\n'
              '  grade: ${widget.grade}\n'
              '  subjectId: ${widget.subjectId}\n'
              '  expectedSubjectId: $expectedSubjectId\n'
              '  normalizedSubject: $normalizedSubject';
        } else if (fetchedNotes.isEmpty) {
          _debugErrorDetails = 'Unit record found (ID: ${response['id']}), but "unit_notes" array is empty.\n'
              '  subject_id: ${response['subject_id']}\n'
              '  unit_number: ${response['unit_number']}';
        }
      }

      if (fetchedNotes.isNotEmpty) {
        fetchedNotes.sort((a, b) {
          final String dateA = (a['created_at'] ?? '').toString();
          final String dateB = (b['created_at'] ?? '').toString();
          return dateA.compareTo(dateB);
        });

        _notesList = fetchedNotes;
        _selectedNoteIndex = 0;
        _pdfUrl = fetchedNotes.first['pdf_url']?.toString().trim();
        _pdfTitle = fetchedNotes.first['title']?.toString().trim();
        await _checkAndLoadLocalPdf();
      }

      setState(() {
        _isLoading = false;
        if (_pdfUrl == null || _pdfUrl!.isEmpty) {
          _hasError = true;
          _errorType = NotesErrorType.emptyData;
        } else {
          _hasError = false;
          _errorType = NotesErrorType.none;
        }
      });
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException fetching notes: ${e.code} - ${e.message}');
      final isRls = e.code == '42501' ||
          e.message.toLowerCase().contains('permission') ||
          e.message.toLowerCase().contains('denied') ||
          e.message.toLowerCase().contains('row-level security') ||
          e.message.toLowerCase().contains('rls');

      setState(() {
        _notesList = [];
        _hasError = true;
        _isLoading = false;
        _errorType = isRls ? NotesErrorType.accessDenied : NotesErrorType.unknown;
        _debugErrorDetails = 'PostgrestException [Code: ${e.code}]: ${e.message}\nDetails: ${e.details ?? "None"}\nHint: ${e.hint ?? "None"}';
      });
      _showDebugSnackbar('DB Permission Error [${e.code}]: ${e.message}');
    } catch (e) {
      debugPrint('Error fetching PDF notes: $e');
      final String errStr = e.toString().toLowerCase();
      final bool isNetErr = errStr.contains('socketexception') ||
          errStr.contains('clientexception') ||
          errStr.contains('network') ||
          errStr.contains('connection') ||
          errStr.contains('failed to connect') ||
          errStr.contains('offline') ||
          errStr.contains('getaddrinfo');

      setState(() {
        _notesList = [];
        _hasError = true;
        _isLoading = false;
        _errorType = isNetErr ? NotesErrorType.noInternet : NotesErrorType.unknown;
        _debugErrorDetails = 'Exception: $e';
      });
      _showDebugSnackbar(isNetErr ? 'Network Connection Error' : 'Error: $e');
    }
  }

  Future<void> _checkBookmarkStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarks = prefs.getStringList('bookmarked_notes') ?? [];
      final bookmarkId = '${widget.subjectId}_g${widget.grade}_u${widget.unitNumber}';
      setState(() {
        _isBookmarked = bookmarks.contains(bookmarkId);
      });
    } catch (_) {}
  }

  Future<void> _toggleBookmark() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarks = prefs.getStringList('bookmarked_notes') ?? [];
      final bookmarkId = '${widget.subjectId}_g${widget.grade}_u${widget.unitNumber}';

      if (_isBookmarked) {
        bookmarks.remove(bookmarkId);
      } else {
        bookmarks.add(bookmarkId);
      }

      await prefs.setStringList('bookmarked_notes', bookmarks);
      setState(() {
        _isBookmarked = !_isBookmarked;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isBookmarked
                  ? (widget.languageCode == 'en' ? 'PDF Note bookmarked!' : 'ማስታወሻው ተቀምጧል!')
                  : (widget.languageCode == 'en' ? 'Bookmark removed' : 'ማስታወሻው ከምርጫዎች ተሰርዟል'),
            ),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (_) {}
  }

  void _shareNoteContent() async {
    try {
      if (_pdfUrl == null || _pdfUrl!.isEmpty) return;

      File? targetFile = _localPdfFile;
      if (targetFile == null) {
        final String unitId = _getUnitId();
        targetFile = await PdfCacheService.getLocalPdfFile(unitId, _pdfUrl!);
      }

      if (targetFile == null) {
        _showFloatingSnackbar(
          widget.languageCode == 'en'
              ? 'Downloading PDF file for sharing...'
              : 'የPDF ፋይሉን ለማጋራት በማውረድ ላይ...',
          isInfo: true,
        );

        try {
          final String unitId = _getUnitId();
          targetFile = await PdfCacheService.downloadAndSavePdf(
            unitId: unitId,
            pdfUrl: _pdfUrl!,
          );
          if (mounted) {
            setState(() {
              _localPdfFile = targetFile;
            });
          }
        } catch (e) {
          debugPrint('[PDF Share Error] Failed to download PDF before sharing: $e');
        }
      }

      if (targetFile != null && await targetFile.exists()) {
        debugPrint('[Share PDF] Sharing clean PDF file directly: ${targetFile.path}');
        await Share.shareXFiles(
          [XFile(targetFile.path)],
          subject: _pdfTitle ?? 'Unit ${widget.unitNumber} Notes',
        );
      } else {
        _showFloatingSnackbar(
          widget.languageCode == 'en'
              ? 'Unable to share PDF file. Please try downloading it first.'
              : 'የPDF ፋይሉን ማጋራት አልተሳካም። እባክዎ አስቀድመው ያውርዱት።',
          isError: true,
        );
      }
    } catch (e) {
      debugPrint("Error sharing PDF note file: $e");
      _showFloatingSnackbar(
        widget.languageCode == 'en'
            ? 'Error sharing PDF: ${e.toString().replaceAll('Exception: ', '')}'
            : 'ማጋራት አልተሳካም፡ ${e.toString().replaceAll('Exception: ', '')}',
        isError: true,
      );
    }
  }

  Widget _buildCustomHeader(BuildContext context, bool isDarkMode) {
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final Color shareColor = const Color(0xFF00BFFF);
    final Color saveColor = Colors.amber[600] ?? Colors.amber;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: textColor,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.languageCode == 'en' ? "Back" : "ተመለስ",
                    style: GoogleFonts.inter(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _pdfTitle ?? 'Unit ${widget.unitNumber} Notes',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_pageCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        '$_currentPage / $_pageCount',
                        maxLines: 1,
                        style: GoogleFonts.inter(
                          color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  isDarkMode ? Icons.wb_sunny_rounded : Icons.nights_stay_outlined,
                  color: textColor,
                  size: 22,
                ),
                tooltip: widget.languageCode == 'en' ? 'Toggle Theme' : 'ገጽታ ቀይር',
                onPressed: () {
                  AppStateProvider.of(context).onToggleTheme();
                },
              ),
              _isDownloadingPdf
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      ),
                    )
                  : IconButton(
                      icon: Icon(
                        _localPdfFile != null ? Icons.download_done_rounded : Icons.download_rounded,
                        color: _localPdfFile != null ? const Color(0xFF10B981) : textColor,
                        size: 22,
                      ),
                      tooltip: widget.languageCode == 'en'
                          ? (_localPdfFile != null ? 'Downloaded Offline' : 'Download PDF Offline')
                          : (_localPdfFile != null ? 'ለስልክዎ ወርዷል' : 'PDF ወደ ስልክህ አውርድ'),
                      onPressed: _downloadPdfForOffline,
                    ),
              IconButton(
                icon: Icon(
                  _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                  color: _isBookmarked ? saveColor : textColor,
                  size: 22,
                ),
                tooltip: widget.languageCode == 'en' ? 'Save Note' : 'ማስታወሻ አስቀምጥ',
                onPressed: _toggleBookmark,
              ),
              IconButton(
                icon: Icon(
                  Icons.share_rounded,
                  color: shareColor,
                  size: 22,
                ),
                tooltip: widget.languageCode == 'en' ? 'Share Note' : 'ማስታወሻ አጋራ',
                onPressed: _shareNoteContent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelegramBottomBar(bool isDarkMode) {
    final isEn = widget.languageCode == 'en';
    final Color telegramAccent = isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF0D2353);
    final Color containerBg = isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final Color borderColor = isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: containerBg,
        border: Border(
          top: BorderSide(
            color: borderColor,
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: () async {
            final uri = Uri.parse('https://t.me/smartx_et');
            try {
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                _showFloatingSnackbar(
                  isEn ? 'Could not launch Telegram URL' : 'የቴሌግራም ሊንክ መክፈት አልተሳካም',
                  isError: true,
                );
              }
            } catch (e) {
              debugPrint('[Telegram Launch Error] $e');
            }
          },
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF38BDF8).withValues(alpha: 0.12)
                  : const Color(0xFF0D2353).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: isDarkMode
                    ? const Color(0xFF38BDF8).withValues(alpha: 0.3)
                    : const Color(0xFF0D2353).withValues(alpha: 0.2),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.telegram_rounded,
                  color: telegramAccent,
                  size: 22,
                ),
                const SizedBox(width: 10.0),
                Text(
                  isEn ? 'Join Telegram Channel' : 'የቴሌግራም ቻናል ይቀላቀሉ',
                  style: GoogleFonts.plusJakartaSans(
                    color: telegramAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.0,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.open_in_new_rounded,
                  color: telegramAccent,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateUI(bool isDarkMode) {
    final isAmharic = widget.languageCode == 'am';

    IconData iconData;
    Color iconColor;
    String title;
    String description;

    switch (_errorType) {
      case NotesErrorType.noInternet:
        iconData = Icons.wifi_off_rounded;
        iconColor = Colors.amber[600] ?? Colors.amber;
        title = isAmharic ? 'የኢንተርኔት ግንኙነት የለም' : 'No Internet Connection';
        description = isAmharic
            ? 'እባክዎን የእርስዎን የኢንተርኔት ግንኙነት ይፈትሹ እና እንደገና ይሞክሩ። የወረዱ ማስታወሻዎች ካሉ ያለ ኢንተርኔት ማንበብ ይችላሉ።'
            : 'Please check your internet network connection and try again. Downloaded notes can be accessed offline.';
        break;

      case NotesErrorType.accessDenied:
        iconData = Icons.lock_person_rounded;
        iconColor = Colors.redAccent;
        title = isAmharic ? 'መዳረሻ ተከልክሏል' : 'Access Denied';
        description = isAmharic
            ? 'ይህንን ማስታወሻ ለማየት በቂ ፈቃድ የለዎትም። (Row-Level Security) እባክዎን አስተዳዳሪውን ያነጋግሩ።'
            : 'You do not have permission to view these notes (Row-Level Security constraint). Please contact your administrator.';
        break;

      case NotesErrorType.pdfLoadError:
        iconData = Icons.picture_as_pdf_rounded;
        iconColor = Colors.deepOrangeAccent;
        title = isAmharic ? 'ማስታወሻውን መጫን አልተቻለም' : 'Failed to Load PDF';
        description = isAmharic
            ? 'የPDF ማስታወሻውን በመጫን ላይ ስህተት አጋጥሟል። ሊንኩ ወይም ፋይሉ ችግር ሊኖረው ይችላል።'
            : 'An error occurred while loading or rendering the PDF file. The URL or file format may be invalid.';
        break;

      case NotesErrorType.emptyData:
      case NotesErrorType.none:
      case NotesErrorType.unknown:
        iconData = Icons.menu_book_rounded;
        iconColor = widget.themeColor;
        title = isAmharic ? 'ማስታወሻ አልተገኘም' : 'No Notes Found';
        description = isAmharic
            ? 'ለክፍል ${widget.grade} ${widget.subjectId} ምዕራፍ ${widget.unitNumber} የተዘጋጀ ማስታወሻ አልተገኘም። መምህራኖቻችን በቅርቡ ይጫኑታል።'
            : 'No Notes Found for Grade ${widget.grade} ${widget.subjectId} Unit ${widget.unitNumber}. Our content team is actively preparing these notes.';
        break;
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 36.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 52,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _fetchNotes,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      isAmharic ? 'እንደገና ሞክር' : 'Try Again',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.themeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: Text(
                      isAmharic ? 'ተመለስ' : 'Go Back',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                      side: BorderSide(color: isDarkMode ? const Color(0xFF334155) : Colors.grey[300]!),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showDebugInfo = !_showDebugInfo;
                  });
                },
                icon: Icon(
                  _showDebugInfo ? Icons.bug_report_rounded : Icons.bug_report_outlined,
                  size: 16,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                label: Text(
                  _showDebugInfo
                      ? (isAmharic ? 'የዲበግ መረጃ ደብቅ' : 'Hide Debug Info')
                      : (isAmharic ? 'የዲበግ መረጃ አሳይ' : 'Show Debug Info'),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
              if (_showDebugInfo) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '[DEBUG DIAGNOSTICS]',
                        style: GoogleFonts.firaCode(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: widget.themeColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        'ErrorType: $_errorType\n'
                        'Grade: ${widget.grade}\n'
                        'SubjectId: ${widget.subjectId}\n'
                        'NormalizedSubject: ${_getNormalizedSubjectName()}\n'
                        'UnitNumber: ${widget.unitNumber}\n'
                        'PDF URL: ${_pdfUrl ?? "None"}\n\n'
                        'Details:\n${_debugErrorDetails ?? "No raw error logged"}',
                        style: GoogleFonts.firaCode(
                          fontSize: 11,
                          color: isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = widget.isDarkMode || AppStateProvider.of(context).isDarkMode;
    final Color screenBgColor = isDarkMode ? const Color(0xFF0F172A) : Colors.white;

    Widget bodyContent;

    if (_isLoading) {
      bodyContent = Container(
        color: screenBgColor,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(widget.themeColor),
          ),
        ),
      );
    } else if (_hasError || _pdfUrl == null || _pdfUrl!.isEmpty) {
      bodyContent = Container(
        color: screenBgColor,
        child: _buildEmptyStateUI(isDarkMode),
      );
    } else {
      bodyContent = Column(
        children: [
          _buildCustomHeader(context, isDarkMode),

          if (_notesList.length > 1)
            Container(
              height: 44,
              color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _notesList.length,
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedNoteIndex;
                  final item = _notesList[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: ChoiceChip(
                      label: Text(
                        item['title'] ?? 'Note ${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : (isDarkMode ? Colors.white70 : Colors.black87),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: widget.themeColor,
                      backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.grey[200],
                      side: BorderSide(
                        color: isDarkMode ? const Color(0xFF334155) : Colors.transparent,
                      ),
                      onSelected: (selected) async {
                        if (selected) {
                          setState(() {
                            _selectedNoteIndex = index;
                            _pdfUrl = item['pdf_url']?.toString();
                            _pdfTitle = item['title']?.toString();
                            _currentPage = 1;
                            _localPdfFile = null;
                          });
                          await _checkAndLoadLocalPdf();
                        }
                      },
                    ),
                  );
                },
              ),
            ),

          Expanded(
            child: Container(
              color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              child: Builder(
                builder: (context) {
                  Widget pdfWidget = _localPdfFile != null
                      ? SfPdfViewer.file(
                          _localPdfFile!,
                          controller: _pdfViewerController,
                          scrollDirection: _scrollDirection,
                          pageLayoutMode: _pageLayoutMode,
                          canShowScrollHead: true,
                          canShowScrollStatus: true,
                          onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                            if (mounted) {
                              setState(() {
                                _pageCount = details.document.pages.count;
                              });
                            }
                          },
                          onPageChanged: (PdfPageChangedDetails details) {
                            if (mounted) {
                              setState(() {
                                _currentPage = details.newPageNumber;
                              });
                            }
                          },
                          onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) async {
                            debugPrint('[PDF Cache Error] Local file load failed: ${details.error} - ${details.description}');
                            final String unitId = _getUnitId();
                            await PdfCacheService.deleteCachedPdf(unitId, _pdfUrl!);
                            await OfflineManager.removeDownload(unitId);
                            if (mounted) {
                              setState(() {
                                _localPdfFile = null;
                              });
                            }
                          },
                        )
                      : SfPdfViewer.network(
                          _pdfUrl!,
                          controller: _pdfViewerController,
                          scrollDirection: _scrollDirection,
                          pageLayoutMode: _pageLayoutMode,
                          canShowScrollHead: true,
                          canShowScrollStatus: true,
                          onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                            if (mounted) {
                              setState(() {
                                _pageCount = details.document.pages.count;
                              });
                              _backgroundCacheCurrentPdf();
                            }
                          },
                          onPageChanged: (PdfPageChangedDetails details) {
                            if (mounted) {
                              setState(() {
                                _currentPage = details.newPageNumber;
                              });
                            }
                          },
                          onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                            debugPrint('[PDF Cache Error] Network load failed: ${details.error} - ${details.description}');
                            if (mounted) {
                              final String errStr = details.description.toLowerCase();
                              final bool isNetErr = errStr.contains('socket') || errStr.contains('connection') || errStr.contains('network') || errStr.contains('failed to connect');
                              setState(() {
                                _hasError = true;
                                _errorType = isNetErr ? NotesErrorType.noInternet : NotesErrorType.pdfLoadError;
                                _debugErrorDetails = 'PDF Load Failed: ${details.error}\nDescription: ${details.description}\nURL: $_pdfUrl';
                              });
                              _showFloatingSnackbar(
                                widget.languageCode == 'en'
                                    ? 'PDF Load Failed: ${details.description}'
                                    : 'PDF መክፈት አልተሳካም፡ ${details.description}',
                                isError: true,
                              );
                            }
                          },
                        );

                  final bool shouldInvertPdf = isDarkMode || _isColorInverted;
                  if (shouldInvertPdf) {
                    return ColorFiltered(
                      colorFilter: const ColorFilter.matrix([
                        -1,  0,  0, 0, 255,
                         0, -1,  0, 0, 255,
                         0,  0, -1, 0, 255,
                         0,  0,  0, 1,   0,
                      ]),
                      child: pdfWidget,
                    );
                  }
                  return pdfWidget;
                },
              ),
            ),
          ),

          _buildTelegramBottomBar(isDarkMode),
        ],
      );
    }

    return Scaffold(
      backgroundColor: screenBgColor,
      body: SafeArea(
        child: bodyContent,
      ),
    );
  }
}
