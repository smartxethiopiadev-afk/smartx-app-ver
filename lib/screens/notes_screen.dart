// ignore_for_file: prefer_final_fields, prefer_interpolation_to_compose_strings, deprecated_member_use
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/offline_manager.dart';
import '../services/analytics_service.dart';
import '../widgets/math_text.dart';
import '../widgets/in_app_pdf_viewer_dialog.dart';
import '../main.dart';

enum NotesErrorType {
  none,
  noInternet,
  emptyData,
  serverError,
}

class NotesScreen extends StatefulWidget {
  final int grade;
  final String subjectId;
  final int unitNumber;
  final String unitTitle;
  final Color themeColor;
  final bool isDarkMode;
  final String languageCode;
  final VoidCallback? onToggleTheme;

  const NotesScreen({
    super.key,
    required this.grade,
    required this.subjectId,
    required this.unitNumber,
    required this.unitTitle,
    required this.themeColor,
    required this.isDarkMode,
    required this.languageCode,
    this.onToggleTheme,
  });

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  bool _isBookmarked = false;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isOfflineDownloaded = false;
  bool _isDownloading = false;
  late bool _isDarkMode;

  NotesErrorType _errorType = NotesErrorType.none;

  List<Map<String, dynamic>> _notesList = [];
  int _currentPageIndex = 0;
  late PageController _pageController;

  int _pdfCurrentPage = 1;
  final int _pdfTotalPages = 6;
  double _pdfZoomScale = 1.0;
  final TransformationController _pdfTransformationController = TransformationController();

  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const String _telegramChannelUrl = 'https://t.me/SmartX_Discussion';

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
    _pageController = PageController(initialPage: 0);

    // Analytics tracking for screen view and custom event
    logScreen('ShortNotesScreen');
    logEvent(
      name: 'short_note_opened',
      parameters: {
        'unit': widget.unitTitle,
        'subject': widget.subjectId,
        'grade': widget.grade,
        'unit_number': widget.unitNumber,
      },
    );

    _checkBookmarkStatus();
    _fetchNotes();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    _pdfTransformationController.dispose();
    super.dispose();
  }

  void _showFloatingSnackbar(
    String message, {
    bool isError = false,
    bool isSuccess = false,
    bool isInfo = false,
  }) {
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
        duration: Duration(seconds: isError ? 4 : 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _getUnitId() {
    String sub = widget.subjectId.toLowerCase();
    String prefix = 'phys_u';
    if (sub.contains('math')) {
      prefix = 'math_u';
    } else if (sub.contains('biol') || sub.contains('bio')) {
      prefix = 'bio_u';
    } else if (sub.contains('phys')) {
      prefix = 'phys_u';
    } else if (sub.contains('chem')) {
      prefix = 'chem_u';
    } else if (sub.contains('geog') || sub.contains('geo')) {
      prefix = 'geo_u';
    } else if (sub.contains('hist')) {
      prefix = 'hist_u';
    } else if (sub.contains('civ')) {
      prefix = 'civ_u';
    } else if (sub.contains('agri') || sub.contains('agr')) {
      prefix = 'agri_u';
    } else if (sub.contains('econ') || sub.contains('eco')) {
      prefix = 'econ_u';
    } else if (sub.contains('eng')) {
      prefix = 'eng_u';
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

  Future<void> _checkBookmarkStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarks = prefs.getStringList('bookmarked_notes') ?? [];
      final bookmarkId = '${widget.grade}_${widget.subjectId}_${widget.unitNumber}';
      if (mounted) {
        setState(() {
          _isBookmarked = bookmarks.contains(bookmarkId);
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchNotes() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorType = NotesErrorType.none;
    });

    final unitId = _getUnitId();

    // 1. Check local offline cache first
    try {
      final offlineNotes = await OfflineManager.getOfflineNotes(unitId);
      final hasOfflinePdf = await OfflineManager.hasOfflinePdf(unitId);
      if (offlineNotes.isNotEmpty) {
        if (mounted) {
          setState(() {
            _notesList = offlineNotes;
            _isLoading = false;
            _isOfflineDownloaded = true;
          });
        }
        return;
      } else if (hasOfflinePdf) {
        final pdfData = await OfflineManager.getOfflinePdf(unitId);
        if (pdfData != null && mounted) {
          setState(() {
            _notesList = [
              {
                'id': pdfData['unitId'],
                'title': pdfData['title'] ?? widget.unitTitle,
                'summary': pdfData['summary'] ?? '',
                'pdf_url': pdfData['pdfUrl'] ?? '',
                'grade': widget.grade,
                'unit_number': widget.unitNumber,
              }
            ];
            _isLoading = false;
            _isOfflineDownloaded = true;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('[NotesScreen] Offline check notice: $e');
    }

    // 2. Check network connectivity
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorType = NotesErrorType.noInternet;
        });
      }
      return;
    }

    // 3. Query Supabase database
    try {
      final supabase = Supabase.instance.client;
      final normalizedSub = _getNormalizedSubjectName();

      List<dynamic> response = [];

      // Primary query: check short_notes table with grade, subject, unit_number
      try {
        response = await supabase
            .from('short_notes')
            .select()
            .eq('grade', widget.grade)
            .ilike('subject', '%$normalizedSub%')
            .eq('unit_number', widget.unitNumber)
            .order('id', ascending: true);
      } catch (e) {
        debugPrint('[NotesScreen] short_notes query error: $e');
        // Fallback: search with subjectId raw
        try {
          response = await supabase
              .from('short_notes')
              .select()
              .eq('grade', widget.grade)
              .eq('unit_number', widget.unitNumber);
        } catch (_) {}
      }

      if (response.isEmpty) {
        // Fallback check on 'notes' or 'unit_notes' tables
        try {
          response = await supabase
              .from('notes')
              .select()
              .eq('grade', widget.grade)
              .eq('unit_number', widget.unitNumber);
        } catch (_) {}
      }

      if (response.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorType = NotesErrorType.emptyData;
          });
        }
        return;
      }

      final List<Map<String, dynamic>> parsedList = [];
      for (final item in response) {
        if (item is Map<String, dynamic>) {
          parsedList.add(item);
        } else if (item is Map) {
          parsedList.add(Map<String, dynamic>.from(item));
        }
      }

      if (mounted) {
        setState(() {
          _notesList = parsedList;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      debugPrint('[NotesScreen] Supabase fetch error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorType = NotesErrorType.serverError;
        });
      }
    }
  }

  Future<void> _toggleBookmark() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarks = prefs.getStringList('bookmarked_notes') ?? [];
      final bookmarkId = '${widget.grade}_${widget.subjectId}_${widget.unitNumber}';

      if (bookmarks.contains(bookmarkId)) {
        bookmarks.remove(bookmarkId);
      } else {
        bookmarks.add(bookmarkId);
      }

      await prefs.setStringList('bookmarked_notes', bookmarks);
      if (mounted) {
        setState(() {
          _isBookmarked = !_isBookmarked;
        });
      }

      _showFloatingSnackbar(
        _isBookmarked
            ? (widget.languageCode == 'en' ? 'Short note bookmarked!' : 'ማስታወሻው ተቀምጧል!')
            : (widget.languageCode == 'en' ? 'Bookmark removed' : 'ማስታወሻው ከምርጫዎች ተሰርዟል'),
        isSuccess: _isBookmarked,
      );
    } catch (_) {}
  }

  Future<void> _saveOffline() async {
    if (_notesList.isEmpty) return;
    setState(() {
      _isDownloading = true;
    });

    try {
      final unitId = _getUnitId();
      await OfflineManager.saveOfflineNotes(
        unitId,
        _notesList,
        grade: widget.grade,
        unit: widget.unitNumber,
      );

      if (mounted) {
        setState(() {
          _isOfflineDownloaded = true;
          _isDownloading = false;
        });
        _showFloatingSnackbar(
          widget.languageCode == 'am'
              ? 'ማስታወሻው ከመስመር ውጭ ዝግጁ ሆኗል!'
              : 'Short note saved for offline study!',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
        _showFloatingSnackbar(
          widget.languageCode == 'am'
              ? 'ከመስመር ውጭ ማስቀመጥ አልተቻለም'
              : 'Failed to save offline note',
          isError: true,
        );
      }
    }
  }

  String _getPdfUrl(Map<String, dynamic> note) {
    return (note['pdf_url'] ??
            note['file_url'] ??
            note['url'] ??
            note['download_url'] ??
            note['link'] ??
            '')
        .toString()
        .trim();
  }

  Future<void> _openPdf(String pdfUrl) async {
    final currentNote = _notesList.isNotEmpty ? _notesList[_currentPageIndex] : {};
    final title = currentNote['title']?.toString() ?? widget.unitTitle;
    final summary = currentNote['summary']?.toString() ?? currentNote['content']?.toString();

    await InAppPdfViewerDialog.show(
      context,
      pdfUrl: pdfUrl,
      title: title,
      isDark: _isDarkMode,
      summary: summary,
      grade: widget.grade,
      subject: widget.subjectId,
      unit: widget.unitNumber,
      unitId: _getUnitId(),
    );
  }

  void _shareNote() {
    if (_notesList.isEmpty) return;
    final currentNote = _notesList[_currentPageIndex];
    final title = currentNote['title']?.toString() ?? widget.unitTitle;
    final pdfUrl = _getPdfUrl(currentNote);
    final summary = currentNote['summary']?.toString() ?? '';

    final shareContent = '📚 ${widget.subjectId.toUpperCase()} Grade ${widget.grade} — Unit ${widget.unitNumber}\n'
        '$title\n'
        '${summary.isNotEmpty ? '\n$summary\n' : ''}'
        '${pdfUrl.isNotEmpty ? '\n📥 PDF Link: $pdfUrl\n' : ''}\n'
        'Smart Learn Ethiopia Mobile App';

    Share.share(shareContent, subject: title);
  }

  void _toggleThemeMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });

    if (widget.onToggleTheme != null) {
      widget.onToggleTheme!();
    } else {
      try {
        AppStateProvider.of(context).onToggleTheme();
      } catch (_) {}
    }
  }

  void _showCompletionDialog() {
    final bool isDark = _isDarkMode;
    final bool isEn = widget.languageCode == 'en';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        widget.themeColor,
                        widget.themeColor.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.themeColor.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  isEn ? "Thanks for reading!" : "እንኳን ደስ አለዎት!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isEn
                      ? "You have completed all summary notes for this unit."
                      : "የትምህርቱን ማጠቃለያ በስኬት ጨርሰዋል።",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: widget.themeColor,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.themeColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      isEn ? "Done" : "እሺ (ጨርሻለሁ)",
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = _isDarkMode;
    final bool isAmharic = widget.languageCode == 'am';
    final Color bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final Color cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: _isSearchOpen
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText: isAmharic ? 'በማስታወሻው ውስጥ ፈልግ...' : 'Search in short notes...',
                  hintStyle: TextStyle(color: subColor),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unit ${widget.unitNumber}: ${widget.unitTitle}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  Text(
                    'Grade ${widget.grade} • ${widget.subjectId.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: subColor,
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearchOpen ? Icons.close_rounded : Icons.search_rounded,
              color: textColor,
            ),
            onPressed: () {
              setState(() {
                _isSearchOpen = !_isSearchOpen;
                if (!_isSearchOpen) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: _isBookmarked ? const Color(0xFFF59E0B) : textColor,
            ),
            onPressed: _toggleBookmark,
          ),
          IconButton(
            icon: Icon(Icons.share_rounded, color: textColor),
            onPressed: _shareNote,
          ),
          IconButton(
            icon: Icon(
              _isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: textColor,
            ),
            onPressed: _toggleThemeMode,
          ),
        ],
      ),
      body: _buildBody(bgColor, cardColor, textColor, subColor, isAmharic),
      bottomNavigationBar: _notesList.isNotEmpty ? _buildBottomBar(cardColor, textColor, subColor, isAmharic) : null,
    );
  }

  Widget _buildBody(Color bgColor, Color cardColor, Color textColor, Color subColor, bool isAmharic) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(widget.themeColor),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              isAmharic ? 'የፒዲኤፍ ማጠቃለያውን በመጫን ላይ...' : 'Loading short notes...',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: subColor,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return _buildErrorView(textColor, subColor, isAmharic);
    }

    final currentNote = _notesList.isNotEmpty ? _notesList[_currentPageIndex] : {};
    final String title = currentNote['title']?.toString() ?? widget.unitTitle;
    final String summary = currentNote['summary']?.toString() ?? currentNote['content']?.toString() ?? '';

    return Column(
      children: [
        // Top Download Status Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF131D38) : const Color(0xFFEFF6FF),
            border: Border(
              bottom: BorderSide(
                color: _isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFDBEAFE),
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _isOfflineDownloaded ? Icons.check_circle_rounded : Icons.offline_pin_rounded,
                color: _isOfflineDownloaded ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _isOfflineDownloaded
                      ? (isAmharic ? 'ይህ ፒዲኤፍ ለኦፍላይን ጥናት በስልክዎ ተቀምጧል' : 'Downloaded for offline study')
                      : (isAmharic ? 'ፒዲኤፉን ያውርዱ እና ያለ ኢንተርኔት በፈለጉበት ሰዓት ያንብቡ' : 'Download PDF for offline study anytime'),
                  style: GoogleFonts.notoSansEthiopic(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isDownloading ? null : _saveOffline,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isOfflineDownloaded ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                icon: _isDownloading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        _isOfflineDownloaded ? Icons.done_all_rounded : Icons.download_rounded,
                        size: 16,
                      ),
                label: Text(
                  _isDownloading
                      ? '...'
                      : (_isOfflineDownloaded
                          ? (isAmharic ? 'ወርዷል' : 'Saved')
                          : (isAmharic ? 'አውርድ' : 'Download')),
                  style: GoogleFonts.notoSansEthiopic(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Toolbar: Page Stepper & Zoom Controls
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: cardColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Page Controls
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    visualDensity: VisualDensity.compact,
                    onPressed: _pdfCurrentPage > 1 ? () => setState(() => _pdfCurrentPage--) : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isDarkMode ? const Color(0xFF0B132B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isAmharic ? 'ገጽ $_pdfCurrentPage / $_pdfTotalPages' : 'Page $_pdfCurrentPage / $_pdfTotalPages',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    visualDensity: VisualDensity.compact,
                    onPressed: _pdfCurrentPage < _pdfTotalPages ? () => setState(() => _pdfCurrentPage++) : null,
                  ),
                ],
              ),

              // Zoom Controls
              Row(
                children: [
                  IconButton(
                    tooltip: isAmharic ? 'አሳንስ' : 'Zoom Out',
                    icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      setState(() {
                        _pdfZoomScale = (_pdfZoomScale - 0.25).clamp(0.75, 2.5);
                        _pdfTransformationController.value = Matrix4.identity()..scale(_pdfZoomScale);
                      });
                    },
                  ),
                  Text(
                    '${(_pdfZoomScale * 100).toInt()}%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: subColor,
                    ),
                  ),
                  IconButton(
                    tooltip: isAmharic ? 'አሳድግ' : 'Zoom In',
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      setState(() {
                        _pdfZoomScale = (_pdfZoomScale + 0.25).clamp(0.75, 2.5);
                        _pdfTransformationController.value = Matrix4.identity()..scale(_pdfZoomScale);
                      });
                    },
                  ),
                  IconButton(
                    tooltip: isAmharic ? 'ወደ ነበረበት መልስ' : 'Reset Zoom',
                    icon: const Icon(Icons.restart_alt_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      setState(() {
                        _pdfZoomScale = 1.0;
                        _pdfTransformationController.value = Matrix4.identity();
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // Interactive PDF Document Page Viewer
        Expanded(
          child: InteractiveViewer(
            transformationController: _pdfTransformationController,
            minScale: 0.8,
            maxScale: 3.0,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: _isDarkMode ? const Color(0xFF131D38) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Official Ministry Watermark Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.picture_as_pdf_rounded,
                                    color: Color(0xFF2563EB),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'የኢትዮጵያ ትምህርት ሚኒስቴር ስርዓተ-ትምህርት',
                                      style: GoogleFonts.notoSansEthiopic(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF2563EB),
                                      ),
                                    ),
                                    Text(
                                      'Ethiopian National Curriculum Standard',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        color: subColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isAmharic ? 'ገጽ $_pdfCurrentPage / $_pdfTotalPages' : 'Page $_pdfCurrentPage / $_pdfTotalPages',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),

                        // Document Title
                        Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${widget.subjectId.toUpperCase()} • Grade ${widget.grade} • Unit ${widget.unitNumber}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Page Content
                        _buildPdfDocumentPageContent(summary, textColor, subColor, isAmharic),

                        const Divider(height: 40),

                        // Footer details
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Smart Learn Ethiopia Mobile System',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: subColor),
                            ),
                            Text(
                              '© 2026 Academic Notes',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: subColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPdfDocumentPageContent(String summary, Color textColor, Color subColor, bool isAmharic) {
    switch (_pdfCurrentPage) {
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isAmharic ? 'ክፍል 1፡ የዩኒቱ አጠቃላይ መግቢያና ዋና ዋና አላማዎች' : 'Part 1: Key Objectives & Introduction',
                      style: GoogleFonts.notoSansEthiopic(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (summary.isNotEmpty)
              _buildSummaryContent(summary, textColor, subColor)
            else
              Text(
                isAmharic
                    ? 'በዚህ ዩኒት ውስጥ በኢትዮጵያ የትምህርት ካሪኩለም መሰረት ዋና ዋና ጽንሰ-ሀሳቦችን፣ ቀመሮችን እና ለፈተና የሚያዘጋጁ ነጥቦችን በዝርዝር ተቀምጠዋል።'
                    : 'In this unit, key concepts, formulas, and national exam preparation points are detailed according to the Ethiopian Curriculum standard.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  height: 1.7,
                  color: textColor,
                ),
              ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAmharic ? 'ክፍል 2፡ ዋና ዋና ቀመሮች እና የሂሳብ/ሳይንስ ህጎች (Key Principles)' : 'Part 2: Core Formulas & Principles',
              style: GoogleFonts.notoSansEthiopic(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 14),
            _buildConceptCard(
              isAmharic ? '1. መሠረታዊ ህጎች (Fundamental Laws)' : '1. Fundamental Laws',
              isAmharic
                  ? 'በዚህ ምዕራፍ የተካተቱት ቀመሮች ለብሔራዊ ፈተና (Entrance Exam) ከፍተኛ ድርሻ ያላቸው ሲሆኑ ቀመሮቹን በቃላት ሳይሆን በተግባራዊ ጥያቄዎች ላይ ተግባራዊ ማድረግ ያስፈልጋል።'
                  : 'Key formulas in this section carry high weight for National Examinations.',
              textColor,
              subColor,
            ),
            const SizedBox(height: 12),
            _buildConceptCard(
              isAmharic ? '2. የአተገባበር ስልት (Application Methods)' : '2. Problem Solving Methods',
              isAmharic
                  ? 'ጥያቄዎች ሲቀርቡ ቀመሩን በቀጥታ ከመጠቀም በፊት የተሰጡትን ዳታዎች (Given Data) ለይቶ ማስቀመጥ አስፈላጊ ነው።'
                  : 'Identify given variables first before applying equations step-by-step.',
              textColor,
              subColor,
            ),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAmharic ? 'ክፍል 3፡ የጥናት ማጠቃለያ እና ፈጣን ማስታወሻዎች (Revision Sheet)' : 'Part 3: Quick Revision Sheet',
              style: GoogleFonts.notoSansEthiopic(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: Text(
                isAmharic
                    ? '• አጠቃላይ ነጥቦቹን በየቀኑ መከለስ የማስታወስ ብቃትን ያሳድጋል።\n• የልምምድ ጥያቄዎችን (MCQ, Matching, Blank Space) በመስራት እራስዎን ይገምግሙ።\n• የፈተና ሰዓት አያያዝን በ Exam Mode ይለማመዱ።'
                    : '• Daily review reinforces long-term memory.\n• Test yourself using practice questions.\n• Practice time management using Exam Mode.',
                style: GoogleFonts.notoSansEthiopic(
                  fontSize: 13,
                  height: 1.8,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAmharic ? 'ክፍል $_pdfCurrentPage፡ ተጨማሪ የንባብ ማብራሪያዎች' : 'Part $_pdfCurrentPage: Extended Notes & Explanations',
              style: GoogleFonts.notoSansEthiopic(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isAmharic
                  ? 'ይህ የፒዲኤፍ ማስታወሻ የተማሪዎችን የትምህርት ደረጃ ከፍ ለማድረግ በባለሙያዎች የተዘጋጀ ሲሆን፣ ከመስመር ውጭ በማውረድ ያለ ምንም የኢንተርኔት ክፍያና ፍጆታ በማንኛውም ቦታና ሰዓት ማጥናት ይችላሉ።'
                  : 'Prepared by curriculum specialists to enhance learning outcomes for Ethiopian students offline.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                height: 1.7,
                color: textColor,
              ),
            ),
          ],
        );
    }
  }

  Widget _buildConceptCard(String title, String desc, Color textColor, Color subColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              height: 1.5,
              color: subColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryContent(String text, Color textColor, Color subColor) {
    final cleanText = text.replaceAll(RegExp(r'<[^>]*>'), ' ').trim();
    List<String> lines = cleanText.split('\n').where((l) => l.trim().isNotEmpty).toList();

    if (_searchQuery.isNotEmpty) {
      lines = lines.where((l) => l.toLowerCase().contains(_searchQuery)).toList();
      if (lines.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            widget.languageCode == 'am' ? 'ከፍለጋው ጋር የሚስማማ ነጥብ አልተገኘም' : 'No matching points found for search',
            style: TextStyle(fontSize: 12.5, color: subColor, fontStyle: FontStyle.italic),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6, right: 10),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: widget.themeColor,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: MathText(
                  line.trim(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    color: textColor,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPillBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(Color cardColor, Color textColor, Color subColor, bool isAmharic) {
    final int totalPages = _notesList.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(
          top: BorderSide(
            color: _isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton.icon(
              onPressed: _currentPageIndex > 0
                  ? () {
                      setState(() {
                        _currentPageIndex--;
                      });
                    }
                  : null,
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: Text(isAmharic ? 'ቀዳሚ' : 'Previous'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            Text(
              '${_currentPageIndex + 1} / $totalPages',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: textColor,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (_currentPageIndex < totalPages - 1) {
                  setState(() {
                    _currentPageIndex++;
                  });
                } else {
                  _showCompletionDialog();
                }
              },
              icon: Icon(
                _currentPageIndex < totalPages - 1
                    ? Icons.arrow_forward_rounded
                    : Icons.check_circle_rounded,
                size: 16,
                color: Colors.white,
              ),
              label: Text(
                _currentPageIndex < totalPages - 1
                    ? (isAmharic ? 'ቀጣይ' : 'Next')
                    : (isAmharic ? 'ጨርስ' : 'Finish'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.themeColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(Color textColor, Color subColor, bool isAmharic) {
    String title = isAmharic ? 'በቅርብ ቀን ይጠብቁ (Coming Soon)' : 'Coming Soon';
    String desc = isAmharic
        ? 'የዚህ ዩኒት ማጠቃለያ ፒዲኤፍ (PDF) በቅርቡ ወደ ዳታቤዝ ይካተታል።'
        : 'The PDF short notes for this unit will be available very soon.';

    if (_errorType == NotesErrorType.noInternet) {
      title = isAmharic ? 'የኢንተርኔት ግንኙነት የለም' : 'No Internet Connection';
      desc = isAmharic
          ? 'እባክዎ የኢንተርኔት ግንኙነትዎን ያረጋግጡ ወይም ቀደም ሲል ያወረዷቸውን ማስታወሻዎች ይጠቀሙ።'
          : 'Please check your internet connection or open previously downloaded notes.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: widget.themeColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _errorType == NotesErrorType.noInternet
                    ? Icons.wifi_off_rounded
                    : Icons.hourglass_top_rounded,
                size: 50,
                color: widget.themeColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: subColor,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: _fetchNotes,
              icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
              label: Text(
                isAmharic ? 'እንደገና ሞክር' : 'Try Again',
                style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.themeColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
