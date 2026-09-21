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
      if (offlineNotes.isNotEmpty) {
        if (mounted) {
          setState(() {
            _notesList = offlineNotes;
            _isLoading = false;
            _isOfflineDownloaded = true;
          });
        }
        return;
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
    if (pdfUrl.isEmpty) {
      _showFloatingSnackbar(
        widget.languageCode == 'am'
            ? 'የፒዲኤፍ ማስፈንጠሪያ አልተገኘም'
            : 'PDF link not available for this note',
        isError: true,
      );
      return;
    }

    final currentNote = _notesList.isNotEmpty ? _notesList[_currentPageIndex] : {};
    final title = currentNote['title']?.toString() ?? widget.unitTitle;

    await InAppPdfViewerDialog.show(
      context,
      pdfUrl: pdfUrl,
      title: title,
      isDark: _isDarkMode,
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
        '${pdfUrl.isNotEmpty ? '\n📥 Supabase PDF Link: $pdfUrl\n' : ''}\n'
        'Study with Smart Learn Ethiopia App!\n'
        'Telegram: $_telegramChannelUrl';

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
              isAmharic ? 'የፒዲኤፍ ማጠቃለያውን በመጫን ላይ...' : 'Loading short notes from Supabase...',
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

    final currentNote = _notesList[_currentPageIndex];
    final String title = currentNote['title']?.toString() ?? 'Unit ${widget.unitNumber} Short Note';
    final String pdfUrl = _getPdfUrl(currentNote);
    final String summary = currentNote['summary']?.toString() ??
        currentNote['content']?.toString() ??
        currentNote['html_content']?.toString() ??
        '';
    final dynamic fileSize = currentNote['file_size_mb'] ?? currentNote['size'] ?? 2.5;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Supabase Storage PDF Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.themeColor,
                  widget.themeColor.withValues(alpha: 0.82),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: widget.themeColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'SUPABASE STORAGE PDF',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildPillBadge('Grade ${widget.grade}', Icons.school_rounded),
                    const SizedBox(width: 8),
                    _buildPillBadge(widget.subjectId.toUpperCase(), Icons.auto_stories_rounded),
                    const SizedBox(width: 8),
                    _buildPillBadge('$fileSize MB', Icons.data_usage_rounded),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    // Open PDF Button
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: () => _openPdf(pdfUrl),
                        icon: const Icon(Icons.open_in_new_rounded, size: 18, color: Color(0xFF0F172A)),
                        label: Text(
                          isAmharic ? 'PDF ክፈት (Open PDF)' : 'Open PDF File',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Download for Offline Button
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: _isDownloading ? null : _saveOffline,
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
                                _isOfflineDownloaded
                                    ? Icons.check_circle_rounded
                                    : Icons.download_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                        label: Text(
                          _isOfflineDownloaded
                              ? (isAmharic ? 'ወርዷል' : 'Downloaded')
                              : (isAmharic ? 'አውርድ' : 'Offline'),
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Overview & Key Concepts Card
          if (summary.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.summarize_rounded, color: widget.themeColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isAmharic ? 'የዩኒቱ ማጠቃለያ ነጥቦች' : 'Key Concepts & Highlights',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryContent(summary, textColor, subColor),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Ethiopian Curriculum Study Guidance
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAmharic ? 'የኢትዮጵያ አዲሱ ካሪኩለም ማጠቃለያ' : 'New Ethiopian Curriculum Standard',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAmharic
                            ? 'ይህ የፒዲኤፍ ማስታወሻ በቀጥታ ከሱፓቤዝ ስቶሬጅ የሚወርድ ሲሆን፣ ለፈተና ዝግጅት ወሳኝ የሆኑ ቀመሮችን እና ፅንሰ ሃሳቦችን ይዟል።'
                            : 'This PDF short note is hosted securely on Supabase Storage, containing full curriculum formulas, exam summaries, and concise unit reviews.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: subColor,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Community & Ask Teacher Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: _isDarkMode ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF0284C7).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0284C7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAmharic ? 'ጥያቄዎችዎን በቴሌግራም ይጠይቁ' : 'Join Discussion & Ask Tutors',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      Text(
                        isAmharic ? 'ከሌሎች ተማሪዎች እና መምህራን ጋር ይወያዩ' : 'Connect with other Ethiopian high school students',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: subColor,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final uri = Uri.parse(_telegramChannelUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Text(
                    isAmharic ? 'ተቀላቀል' : 'Join',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0284C7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
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
    String title = isAmharic ? 'ማስታወሻ አልተገኘም' : 'No Short Notes Found';
    String desc = isAmharic
        ? 'ለዚህ ዩኒት ማስታወሻ በሱፓቤዝ ዳታቤዝ ውስጥ ገና አልተካተተም። እባክዎ በSQL table ላይ የፒዲኤፍ ሊንክ ያስገቡ።'
        : 'Short notes for this unit have not been added to Supabase database yet.';

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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.themeColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _errorType == NotesErrorType.noInternet
                    ? Icons.wifi_off_rounded
                    : Icons.menu_book_rounded,
                size: 48,
                color: widget.themeColor,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: subColor,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchNotes,
              icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
              label: Text(
                isAmharic ? 'እንደገና ሞክር' : 'Try Again',
                style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.themeColor,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
