// ignore_for_file: prefer_final_fields, prefer_interpolation_to_compose_strings
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/offline_manager.dart';
import '../services/analytics_service.dart';
import '../widgets/math_text.dart';
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

    // Firebase Analytics tracking for screen view and custom event
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

  /// Sanitizes HTML to prevent duplicated headers and enforce clean nested markup.
  String _sanitizeHtml(String rawHtml, String title) {
    if (rawHtml.isEmpty) return '<p>No content available for this section.</p>';
    String cleaned = rawHtml.trim();

    // Strip duplicated <h1>/<h2> tags matching the section title
    if (title.isNotEmpty) {
      final escapedTitle = RegExp.escape(title.trim());
      cleaned = cleaned.replaceAll(RegExp(r'<h[1-2][^>]*>\s*' + escapedTitle + r'\s*<\/h[1-2]>', caseSensitive: false), '');
    }

    // Convert LaTeX math delimiters ($...$, $$...$$, \(...\), \[...\]) to clean formatted text
    cleaned = cleaned.replaceAllMapped(RegExp(r'\$\$([\s\S]+?)\$\$|\$([\s\S]+?)\$|\\\[([\s\S]+?)\\\]|\\\(([\s\S]+?)\\\)'), (m) {
      final mathExpr = m.group(1) ?? m.group(2) ?? m.group(3) ?? m.group(4) ?? '';
      return ' <i><b>${MathText.formatMathString(mathExpr)}</b></i> ';
    });

    return cleaned;
  }

  /// Counts words in text, ignoring HTML tags.
  int _countWords(String text) {
    final plainText = text.replaceAll(RegExp(r'<[^>]*>'), ' ').trim();
    if (plainText.isEmpty) return 0;
    return plainText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  /// Automatically chunks long HTML or plain text into reader-friendly pages (~280 words).
  List<String> _splitContentIntoWordPages(String content, {int targetWordsPerPage = 280}) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return [];

    final bool hasHtml = RegExp(r'<(?:p|h[1-6]|div|ul|ol|table|blockquote|li)\b', caseSensitive: false).hasMatch(trimmed);

    List<String> blocks = [];
    if (hasHtml) {
      final rawBlocks = trimmed.split(RegExp(r'(</(?:p|h[1-6]|div|ul|ol|blockquote|table)>)', caseSensitive: false));
      int i = 0;
      while (i < rawBlocks.length) {
        String chunk = rawBlocks[i].trim();
        if (i + 1 < rawBlocks.length && rawBlocks[i + 1].startsWith('</')) {
          chunk += rawBlocks[i + 1];
          i += 2;
        } else {
          i += 1;
        }
        if (chunk.isNotEmpty) {
          blocks.add(chunk);
        }
      }
    } else {
      blocks = trimmed
          .split(RegExp(r'\n\s*\n'))
          .where((p) => p.trim().isNotEmpty)
          .map((p) => '<p>${p.trim().replaceAll('\n', '<br/>')}</p>')
          .toList();
      if (blocks.isEmpty) {
        blocks = ['<p>$trimmed</p>'];
      }
    }

    final List<String> pages = [];
    final List<String> currentPageBlocks = [];
    int currentWords = 0;

    for (final block in blocks) {
      final int blockWords = _countWords(block);
      if (blockWords == 0) {
        currentPageBlocks.add(block);
        continue;
      }

      // If a single block is huge (> targetWordsPerPage * 1.4), split by sentences
      if (blockWords > (targetWordsPerPage * 1.4).toInt()) {
        final inner = block.replaceAll(RegExp(r'^<p[^>]*>|</p>$', caseSensitive: false), '').trim();
        final sentences = inner.split(RegExp(r'(?<=[.?!።])\s+'));
        final List<String> subChunk = [];
        int subWords = 0;

        for (final s in sentences) {
          final int sWords = _countWords(s);
          if (currentWords + subWords + sWords > targetWordsPerPage && (currentPageBlocks.isNotEmpty || subChunk.isNotEmpty)) {
            if (subChunk.isNotEmpty) {
              currentPageBlocks.add('<p>${subChunk.join(' ')}</p>');
            }
            pages.add(currentPageBlocks.join(''));
            currentPageBlocks.clear();
            subChunk.clear();
            currentWords = 0;
            subWords = 0;
          }
          subChunk.add(s);
          subWords += sWords;
        }

        if (subChunk.isNotEmpty) {
          currentPageBlocks.add('<p>${subChunk.join(' ')}</p>');
          currentWords += subWords;
        }
        continue;
      }

      if (currentWords + blockWords > targetWordsPerPage && currentPageBlocks.isNotEmpty) {
        pages.add(currentPageBlocks.join(''));
        currentPageBlocks.clear();
        currentPageBlocks.add(block);
        currentWords = blockWords;
      } else {
        currentPageBlocks.add(block);
        currentWords += blockWords;
      }
    }

    if (currentPageBlocks.isNotEmpty) {
      pages.add(currentPageBlocks.join(''));
    }

    return pages.isNotEmpty ? pages : [content];
  }

  /// Automatically paginates database notes by word count (~85 words per mobile screen).
  List<Map<String, dynamic>> _paginateNotesByWords(
    List<Map<String, dynamic>> rawNotes, {
    int targetWordsPerPage = 280,
  }) {
    final List<Map<String, dynamic>> paginatedList = [];
    final bool isEn = widget.languageCode == 'en';

    // 1. Direct Database Pages Support:
    // If multiple rows are returned from the database, or any row has an explicit page number,
    // directly map each row to 1 page in the reader (no arbitrary chopping).
    final bool hasExplicitPages = rawNotes.length > 1 ||
        (rawNotes.isNotEmpty &&
            (rawNotes.first['page_number'] != null ||
                rawNotes.first['page'] != null ||
                rawNotes.first['order_index'] != null));

    if (hasExplicitPages) {
      for (int i = 0; i < rawNotes.length; i++) {
        final Map<String, dynamic> pageNote = Map<String, dynamic>.from(rawNotes[i]);
        final String rawTitle = pageNote['title']?.toString().trim() ?? widget.unitTitle;
        final int pageNum = ((pageNote['page_number'] ?? pageNote['page'] ?? pageNote['order_index'] ?? (i + 1)) as num).toInt();

        pageNote['virtual_page'] = pageNum;
        pageNote['total_virtual_pages'] = rawNotes.length;
        pageNote['title'] = rawTitle;
        paginatedList.add(pageNote);
      }
      return paginatedList;
    }

    // 2. Fallback for single legacy row without page_number
    for (final note in rawNotes) {
      final String rawTitle = note['title']?.toString().trim() ?? widget.unitTitle;
      final String rawHtml = note['html_content']?.toString() ??
          note['content']?.toString() ??
          '';

      if (rawHtml.trim().isEmpty) continue;

      final int totalWords = _countWords(rawHtml);

      // If already within comfortable single-screen threshold, keep as a single page
      if (totalWords <= targetWordsPerPage + 15) {
        paginatedList.add(Map<String, dynamic>.from(note));
        continue;
      }

      // Automatically split large single-blob into multiple pages
      final List<String> pageContents = _splitContentIntoWordPages(
        rawHtml,
        targetWordsPerPage: targetWordsPerPage,
      );

      final int pageCount = pageContents.length;
      for (int i = 0; i < pageCount; i++) {
        final Map<String, dynamic> pageNote = Map<String, dynamic>.from(note);
        pageNote['html_content'] = pageContents[i];

        if (pageCount > 1) {
          final String partLabel = isEn
              ? "Part ${i + 1} of $pageCount"
              : "ክፍል ${i + 1} (ከ $pageCount)";
          pageNote['title'] = "$rawTitle • $partLabel";
        } else {
          pageNote['title'] = rawTitle;
        }

        pageNote['virtual_page'] = i + 1;
        pageNote['total_virtual_pages'] = pageCount;
        paginatedList.add(pageNote);
      }
    }

    return paginatedList;
  }

  Future<void> _fetchNotes() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorType = NotesErrorType.none;
      });

      // Check internet connection proactively
      bool hasConnection = true;
      try {
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult.isEmpty || connectivityResult.contains(ConnectivityResult.none)) {
          hasConnection = false;
        }
      } catch (_) {}

      final String unitId = _getUnitId();
      final bool isNotesDownloaded = await OfflineManager.isDownloaded(unitId);
      List<Map<String, dynamic>> fetchedNotes = [];

      if (isNotesDownloaded) {
        fetchedNotes = await OfflineManager.getOfflineNotes(unitId);
      } else {
        if (!hasConnection) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorType = NotesErrorType.noInternet;
          });
          return;
        } else {
          final String normalizedSubject = _getNormalizedSubjectName();

          // 1. Primary Query: Supabase short_notes table with full column selection and sorting
          try {
            final shortNotesResponse = await Supabase.instance.client
                .from('short_notes')
                .select('*')
                .eq('grade', widget.grade)
                .eq('unit_number', widget.unitNumber)
                .ilike('subject', '%$normalizedSubject%');

            if (shortNotesResponse.isNotEmpty) {
              fetchedNotes = List<Map<String, dynamic>>.from(shortNotesResponse);
              
              // Sort notes by page_number ASC, order_index ASC, or created_at ASC
              fetchedNotes.sort((a, b) {
                final num? pageA = a['page_number'] ?? a['page'] ?? a['order_index'];
                final num? pageB = b['page_number'] ?? b['page'] ?? b['order_index'];
                if (pageA != null && pageB != null) {
                  return pageA.compareTo(pageB);
                }
                if (pageA != null) return -1;
                if (pageB != null) return 1;
                final String dateA = (a['created_at'] ?? '').toString();
                final String dateB = (b['created_at'] ?? '').toString();
                return dateA.compareTo(dateB);
              });
            }
          } catch (e) {
            debugPrint('[Short Notes] Supabase query notice: $e');
          }
        }
      }

      if (fetchedNotes.isNotEmpty) {
        _notesList = _paginateNotesByWords(fetchedNotes, targetWordsPerPage: 280);
        _currentPageIndex = 0;
      }

      setState(() {
        _isLoading = false;
        if (_notesList.isEmpty) {
          _hasError = true;
          _errorType = !hasConnection ? NotesErrorType.noInternet : NotesErrorType.emptyData;
        } else {
          _hasError = false;
          _errorType = NotesErrorType.none;
        }
      });
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException fetching short notes: ${e.code} - ${e.message}');
      setState(() {
        _notesList = [];
        _hasError = true;
        _isLoading = false;
        _errorType = NotesErrorType.serverError;
      });
    } catch (e) {
      debugPrint('Error fetching short notes: $e');
      setState(() {
        _notesList = [];
        _hasError = true;
        _isLoading = false;
        _errorType = NotesErrorType.serverError;
      });
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

      _showFloatingSnackbar(
        _isBookmarked
            ? (widget.languageCode == 'en' ? 'Short note bookmarked!' : 'ማስታወሻው ተቀምጧል!')
            : (widget.languageCode == 'en' ? 'Bookmark removed' : 'ማስታወሻው ከምርጫዎች ተሰርዟል'),
        isSuccess: _isBookmarked,
      );
    } catch (_) {}
  }

  void _shareNote() {
    if (_notesList.isEmpty) return;
    final currentNote = _notesList[_currentPageIndex];
    final title = currentNote['title']?.toString() ?? widget.unitTitle;
    final content = currentNote['html_content']?.toString() ?? '';
    final cleanText = content.replaceAll(RegExp(r'<[^>]*>'), ' ').trim();
    final shareContent = '📚 ${widget.subjectId.toUpperCase()} Grade ${widget.grade} — Unit ${widget.unitNumber}\n'
        '$title\n\n'
        '${cleanText.length > 300 ? cleanText.substring(0, 300) + '...' : cleanText}\n\n'
        'Study with Smart X Ethiopian App!\n'
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
                // Celebration Badge
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

                // Congratulatory Title
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
                const SizedBox(height: 16),

                // Unit details pill card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.menu_book_rounded, size: 20, color: widget.themeColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Grade ${widget.grade} • ${widget.subjectId.toUpperCase()}",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              "Unit ${widget.unitNumber}: ${widget.unitTitle}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Primary Action: Return to Units List
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: Text(
                      isEn ? "Return to Units List" : "ወደ ክፍሎች ዝርዝር ተመለስ",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.themeColor,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Secondary Action: Review from Beginning
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _pageController.animateToPage(
                        0,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: Text(
                      isEn ? "Review from Beginning" : "ከመጀመሪያው ድጋሚ አንብብ",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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
    final Color cardBg = isDark ? const Color(0xFF1C2541) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final bool isEn = widget.languageCode == 'en';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
        leadingWidth: 100,
        leading: InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                const SizedBox(width: 6),
                Text(
                  isEn ? "Back" : "ተመለስ",
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          // 1. Dark/Light Mode Toggle (Moon icon)
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF0F172A),
              size: 22,
            ),
            tooltip: isDark ? "Light Mode" : "Dark Mode",
            onPressed: _toggleThemeMode,
          ),

          // 2. Bookmark Toggle
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: _isBookmarked ? const Color(0xFF0284C7) : (isDark ? Colors.white : const Color(0xFF0F172A)),
              size: 23,
            ),
            tooltip: "Bookmark",
            onPressed: _toggleBookmark,
          ),

          // 3. Share
          IconButton(
            icon: Icon(
              Icons.share_outlined,
              size: 21,
              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
            ),
            tooltip: "Share",
            onPressed: _shareNote,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search Bar if toggled
          if (_isSearchOpen)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark ? const Color(0xFF1C2541) : Colors.white,
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, size: 19, color: Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: TextStyle(color: textColor, fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: widget.languageCode == 'en' ? "Search key concepts..." : "ፅንሰ-ሀሳቦችን ይፈልጉ...",
                        hintStyle: TextStyle(color: subColor, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim();
                        });
                      },
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                      child: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                    ),
                ],
              ),
            ),

          // Main Paginated Reading View (PageView)
          Expanded(
            child: _buildPaginatedContent(isDark, cardBg, textColor, subColor),
          ),

          // Bottom Action & Navigation Bar (Strictly bottom-aligned, no top tabs)
          if (!_isLoading && !_hasError && _notesList.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    width: 1.0,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // PREV Button (Outlined Red Pill)
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: _currentPageIndex > 0
                                  ? () {
                                      _pageController.previousPage(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOutCubic,
                                      );
                                    }
                                  : null,
                              icon: const Icon(Icons.arrow_back_rounded, size: 16),
                              label: Text(
                                isEn ? "PREV" : "ወደ ኋላ",
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFDC2626),
                                disabledForegroundColor:
                                    isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                                side: BorderSide(
                                  color: _currentPageIndex > 0
                                      ? const Color(0xFFFCA5A5)
                                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Center Page Progress Indicator Badge (Pill)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "${_currentPageIndex + 1} / ${_notesList.length}",
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ),

                        // NEXT / Finish Button (Solid Red Pill)
                        Expanded(
                          flex: 4,
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_currentPageIndex < _notesList.length - 1) {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOutCubic,
                                  );
                                } else {
                                  _showCompletionDialog();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDC2626),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _currentPageIndex == _notesList.length - 1
                                        ? Icons.check_circle_rounded
                                        : Icons.arrow_forward_rounded,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _currentPageIndex == _notesList.length - 1
                                        ? (isEn ? "FINISH" : "ጨርስ")
                                        : (isEn ? "NEXT" : "ቀጣይ"),
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.4,
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
                ),
        ],
      ),
    );
  }

  Widget _buildStudentFriendlyError(bool isDark, Color cardBg, Color textColor, Color subColor) {
    final bool isEn = widget.languageCode == 'en';

    IconData iconData = Icons.cloud_off_rounded;
    Color iconColor = const Color(0xFFEF4444);
    String title = '';
    String subtitle = '';

    switch (_errorType) {
      case NotesErrorType.noInternet:
        iconData = Icons.wifi_off_rounded;
        iconColor = const Color(0xFFF59E0B);
        title = isEn ? "No Internet Connection" : "የኢንተርኔት ግንኙነት የለም";
        subtitle = isEn
            ? "No internet connection or network timed out. Please check your connection and try again."
            : "ኢንተርኔት የለም ወይም ተቋርጧል። እባክዎ ኮኔክሽንዎን ፈትሸው ድጋሚ ይሞክሩ።";
        break;

      case NotesErrorType.emptyData:
        iconData = Icons.menu_book_outlined;
        iconColor = const Color(0xFF0EA5E9);
        title = isEn ? "Notes Not Available" : "ማጠቃለያ አልተገኘም";
        subtitle = isEn
            ? "Summary notes for this unit have not been published yet. They will be uploaded soon!"
            : "ለዚህ ክፍል የተዘጋጀ ማጠቃለያ አልተገኘም። በቅርቡ ይጫናል።";
        break;

      case NotesErrorType.serverError:
      default:
        iconData = Icons.cloud_sync_rounded;
        iconColor = const Color(0xFFEF4444);
        title = isEn ? "Server Connection Error" : "የሰርቨር ግንኙነት ችግር";
        subtitle = isEn
            ? "Could not load educational notes from the server right now. Please try again in a few minutes."
            : "መረጃዎችን ከሰርቨር ላይ መጫን አልተቻለም። እባክዎ በጥቂት ደቂቃዎች ውስጥ ድጋሚ ይሞክሩ።";
        break;
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withValues(alpha: 0.12),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(iconData, size: 36, color: iconColor),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  color: subColor,
                ),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        side: BorderSide(
                          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        isEn ? "Go Back" : "ተመለስ",
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _fetchNotes,
                      icon: const Icon(Icons.refresh_rounded, size: 17),
                      label: Text(
                        isEn ? "Retry" : "ድጋሚ ይሞክሩ",
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.themeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginatedContent(bool isDark, Color cardBg, Color textColor, Color subColor) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(widget.themeColor),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              widget.languageCode == 'en'
                  ? "Loading short notes..."
                  : "አጫጭር ማስታወሻዎችን በመጫን ላይ...",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: subColor,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError || _notesList.isEmpty) {
      return _buildStudentFriendlyError(isDark, cardBg, textColor, subColor);
    }

    return PageView.builder(
      controller: _pageController,
      physics: const BouncingScrollPhysics(),
      itemCount: _notesList.length,
      onPageChanged: (pageIndex) {
        setState(() {
          _currentPageIndex = pageIndex;
        });
      },
      itemBuilder: (context, index) {
        final note = _notesList[index];
        final String noteTitle = note['title']?.toString() ?? 'Section ${index + 1}';
        final String htmlRaw = note['html_content']?.toString() ??
            note['content']?.toString() ??
            '<p>No content available for this section.</p>';
        final String sanitizedHtml = _sanitizeHtml(htmlRaw, noteTitle);

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Title (Bold and Clean)
                  Text(
                    noteTitle,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.2,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Rich HTML Content rendered with custom HTML styles from JSON database
                  HtmlWidget(
                    sanitizedHtml,
                    textStyle: TextStyle(
                      fontSize: 15.5,
                      height: 1.65,
                      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                    ),
                    customStylesBuilder: (element) {
                      if (element.localName == 'h1') {
                        return {'font-size': '22px', 'font-weight': '800', 'color': isDark ? '#FFFFFF' : '#0F172A', 'margin': '12px 0 8px 0'};
                      }
                      if (element.localName == 'h2' || element.localName == 'h3') {
                        return {'font-size': '18px', 'font-weight': '700', 'color': isDark ? '#38BDF8' : '#0284C7', 'margin': '14px 0 6px 0'};
                      }
                      if (element.localName == 'table') {
                        return {'width': '100%', 'border-collapse': 'collapse', 'margin': '14px 0'};
                      }
                      if (element.localName == 'th') {
                        return {
                          'font-weight': '800',
                          'color': isDark ? '#38BDF8' : '#0284C7',
                          'background-color': isDark ? '#1E293B' : '#F1F5F9',
                          'padding': '10px 12px',
                          'border': '1px solid ${isDark ? "#334155" : "#CBD5E1"}',
                        };
                      }
                      if (element.localName == 'td') {
                        return {
                          'padding': '8px 12px',
                          'border': '1px solid ${isDark ? "#334155" : "#CBD5E1"}',
                        };
                      }
                      // Math / Physics / Chemistry Formula Boxes
                      if (element.classes.contains('formula') ||
                          element.classes.contains('formula-box') ||
                          element.classes.contains('math-box') ||
                          element.classes.contains('equation') ||
                          element.classes.contains('law-box')) {
                        return {
                          'background-color': isDark ? '#1E293B' : '#FEF2F2',
                          'border': '1.5px solid ${isDark ? "#EF4444" : "#F87171"}',
                          'border-radius': '10px',
                          'padding': '12px 16px',
                          'margin': '16px 0',
                          'color': isDark ? '#FCA5A5' : '#B91C1C',
                          'font-weight': '700',
                          'font-size': '16px',
                          'text-align': 'center',
                        };
                      }
                      // Chemistry Reaction Box
                      if (element.classes.contains('chem-box') ||
                          element.classes.contains('reaction') ||
                          element.classes.contains('chem-eq')) {
                        return {
                          'background-color': isDark ? '#064E3B' : '#ECFDF5',
                          'border': '1.5px solid ${isDark ? "#10B981" : "#34D399"}',
                          'border-radius': '10px',
                          'padding': '12px 16px',
                          'margin': '16px 0',
                          'color': isDark ? '#A7F3D0' : '#065F46',
                          'font-weight': '700',
                          'font-size': '16px',
                          'text-align': 'center',
                        };
                      }
                      // Fractions
                      if (element.classes.contains('fraction') || element.classes.contains('frac')) {
                        return {
                          'font-weight': '700',
                          'display': 'inline-block',
                          'text-align': 'center',
                          'padding': '0 4px',
                        };
                      }
                      // Callout / Info / Note / Tip Boxes
                      if (element.classes.contains('callout') ||
                          element.classes.contains('keynote') ||
                          element.classes.contains('note') ||
                          element.classes.contains('tip') ||
                          element.localName == 'blockquote') {
                        return {
                          'background-color': isDark ? '#0C4A6E25' : '#E0F2FE',
                          'border-left': '4px solid #0EA5E9',
                          'border-radius': '0 8px 8px 0',
                          'padding': '12px 16px',
                          'margin': '14px 0',
                        };
                      }
                      // Definition Box
                      if (element.classes.contains('definition')) {
                        return {
                          'background-color': isDark ? '#78350F25' : '#FEF3C7',
                          'border-left': '4px solid #F59E0B',
                          'border-radius': '0 8px 8px 0',
                          'padding': '12px 16px',
                          'margin': '14px 0',
                        };
                      }
                      // Example / Worked Solution Box
                      if (element.classes.contains('example') || element.classes.contains('solution')) {
                        return {
                          'background-color': isDark ? '#4C1D9525' : '#EDE9FE',
                          'border-left': '4px solid #8B5CF6',
                          'border-radius': '0 8px 8px 0',
                          'padding': '12px 16px',
                          'margin': '14px 0',
                        };
                      }
                      // Summary / Review Box
                      if (element.classes.contains('summary-box') || element.classes.contains('summary-card')) {
                        return {
                          'background-color': isDark ? '#1E293B' : '#F8FAFC',
                          'border': '1px solid ${isDark ? "#334155" : "#E2E8F0"}',
                          'border-radius': '12px',
                          'padding': '14px 18px',
                          'margin': '16px 0',
                        };
                      }
                      // Inline Code
                      if (element.localName == 'code') {
                        return {
                          'background-color': isDark ? '#334155' : '#E2E8F0',
                          'color': isDark ? '#38BDF8' : '#0284C7',
                          'padding': '2px 6px',
                          'border-radius': '4px',
                          'font-family': 'monospace',
                        };
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
