import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/offline_manager.dart';

enum NotesErrorType {
  none,
  noInternet,
  emptyData,
  accessDenied,
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
  bool _isBookmarked = false;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isDownloaded = false;
  bool _isDownloading = false;

  NotesErrorType _errorType = NotesErrorType.none;

  List<Map<String, dynamic>> _notesList = [];
  int _selectedNoteIndex = 0;
  String? _noteTitle;
  String? _htmlContent;

  double _fontScale = 1.0; // Scaler from 0.85 to 1.45
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
    _checkOfflineStatus();
    _fetchNotes();
  }

  @override
  void dispose() {
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
    String sub = (widget.subjectId).toLowerCase();
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

  Future<void> _checkOfflineStatus() async {
    final String unitId = _getUnitId();
    final bool downloaded = await OfflineManager.isDownloaded(unitId);
    if (mounted) {
      setState(() {
        _isDownloaded = downloaded;
      });
    }
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

        // 1. Primary Query: Supabase short_notes table
        try {
          final shortNotesResponse = await Supabase.instance.client
              .from('short_notes')
              .select('id, grade, subject, unit_number, title, html_content, created_at')
              .eq('grade', widget.grade)
              .eq('unit_number', widget.unitNumber)
              .ilike('subject', '%$normalizedSubject%')
              .order('created_at', ascending: true);

          if (shortNotesResponse.isNotEmpty) {
            fetchedNotes = List<Map<String, dynamic>>.from(shortNotesResponse);
          }
        } catch (e) {
          debugPrint('[Short Notes] Supabase short_notes query info: $e');
        }

        // 2. Secondary Fallback Query: units & unit_notes
        if (fetchedNotes.isEmpty) {
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
                  html_content,
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
        }

        // 3. Built-in High-Quality Curriculum Seed Fallback if server table not yet seeded
        if (fetchedNotes.isEmpty) {
          fetchedNotes = _generateCurriculumFallbackNotes();
        }
      }

      if (fetchedNotes.isNotEmpty) {
        _notesList = fetchedNotes;
        _selectedNoteIndex = 0;
        _applySelectedNote(0);
      }

      setState(() {
        _isLoading = false;
        if (_notesList.isEmpty || _htmlContent == null || _htmlContent!.isEmpty) {
          _hasError = true;
          _errorType = NotesErrorType.emptyData;
        } else {
          _hasError = false;
          _errorType = NotesErrorType.none;
        }
      });
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException fetching short notes: ${e.code} - ${e.message}');
      setState(() {
        _notesList = _generateCurriculumFallbackNotes();
        if (_notesList.isNotEmpty) {
          _selectedNoteIndex = 0;
          _applySelectedNote(0);
          _hasError = false;
          _isLoading = false;
        } else {
          _hasError = true;
          _isLoading = false;
          _errorType = NotesErrorType.accessDenied;
        }
      });
    } catch (e) {
      debugPrint('Error fetching short notes: $e');
      final fallback = _generateCurriculumFallbackNotes();
      setState(() {
        if (fallback.isNotEmpty) {
          _notesList = fallback;
          _selectedNoteIndex = 0;
          _applySelectedNote(0);
          _hasError = false;
          _isLoading = false;
        } else {
          _notesList = [];
          _hasError = true;
          _isLoading = false;
          _errorType = NotesErrorType.unknown;
        }
      });
    }
  }

  void _applySelectedNote(int index) {
    if (index >= 0 && index < _notesList.length) {
      final note = _notesList[index];
      _selectedNoteIndex = index;
      _noteTitle = note['title']?.toString() ?? 'Unit ${widget.unitNumber} Short Note';
      _htmlContent = note['html_content']?.toString() ??
          note['content']?.toString() ??
          '<p>No content available for this section.</p>';
    }
  }

  List<Map<String, dynamic>> _generateCurriculumFallbackNotes() {
    final sub = _getNormalizedSubjectName();
    final g = widget.grade;
    final u = widget.unitNumber;

    if (sub == 'physics') {
      return [
        {
          'id': 'fallback_phys_${g}_$u',
          'grade': g,
          'subject': 'physics',
          'unit_number': u,
          'title': 'Unit $u: Core Concepts & Formulae',
          'html_content': '''
            <div class="note-container">
              <h2>Grade $g Physics — Unit $u Summary</h2>
              <div class="callout">
                <strong>Unit Focus:</strong> Key laws, mathematical relations, dimensional checks, and exam problem strategies.
              </div>
              
              <h3>1. Fundamental Principles</h3>
              <p>In physics, every observed phenomenon is quantified through reproducible measurements and mathematical formulations. Always verify consistency using <em>SI Base Units</em>.</p>
              
              <div class="definition">
                <strong>Standard Definition:</strong> Work done is defined as the scalar product of force and displacement vectors (<em>W = F &bull; d = Fd cos&theta;</em>).
              </div>

              <h3>2. Essential Formulas</h3>
              <div class="formula">
                <p><strong>Kinematics & Motion:</strong></p>
                <ul>
                  <li>v = u + at</li>
                  <li>s = ut + &frac12;at<sup>2</sup></li>
                  <li>v<sup>2</sup> = u<sup>2</sup> + 2as</li>
                </ul>
              </div>

              <div class="formula">
                <p><strong>Work, Energy & Power:</strong></p>
                <ul>
                  <li>Kinetic Energy: <em>KE = &frac12;mv<sup>2</sup></em></li>
                  <li>Potential Energy: <em>PE = mgh</em></li>
                  <li>Power: <em>P = W / t = F &times; v</em></li>
                </ul>
              </div>

              <h3>3. Common Pitfalls & Exam Tips</h3>
              <ul>
                <li>Always convert non-standard units (e.g., km/h &rarr; m/s, cm &rarr; m, grams &rarr; kg) before calculating.</li>
                <li>Remember that vectors have both magnitude and direction; resolve components along orthogonal axes (<em>x</em> and <em>y</em>).</li>
                <li>Check conservation principles (Conservation of Mechanical Energy, Conservation of Linear Momentum).</li>
              </ul>
            </div>
          ''',
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'id': 'fallback_phys_${g}_${u}_summary',
          'grade': g,
          'subject': 'physics',
          'unit_number': u,
          'title': 'Quick Revision & Key Terms',
          'html_content': '''
            <div class="note-container">
              <h2>Key Terms & Definitions</h2>
              <table>
                <thead>
                  <tr><th>Concept</th><th>Definition</th><th>SI Unit</th></tr>
                </thead>
                <tbody>
                  <tr><td>Impulse</td><td>Change in linear momentum (J = F &Delta;t)</td><td>N&bull;s or kg&bull;m/s</td></tr>
                  <tr><td>Efficiency</td><td>(Useful Energy Output / Total Energy Input) &times; 100%</td><td>Percentage (%)</td></tr>
                  <tr><td>Torque</td><td>Turning effect of a force (&tau; = r &times; F)</td><td>N&bull;m</td></tr>
                </tbody>
              </table>
            </div>
          ''',
          'created_at': DateTime.now().toIso8601String(),
        }
      ];
    }

    if (sub == 'mathematics') {
      return [
        {
          'id': 'fallback_math_${g}_$u',
          'grade': g,
          'subject': 'mathematics',
          'unit_number': u,
          'title': 'Unit $u: Core Theorems & Rules',
          'html_content': '''
            <div class="note-container">
              <h2>Grade $g Mathematics — Unit $u Short Note</h2>
              <div class="callout">
                <strong>Objective:</strong> Master foundational theorems, identities, algebraic manipulations, and graphical interpretations.
              </div>

              <h3>1. Key Identities & Rules</h3>
              <div class="formula">
                <p><strong>Logarithmic Properties:</strong></p>
                <ul>
                  <li>log<sub>b</sub>(xy) = log<sub>b</sub>(x) + log<sub>b</sub>(y)</li>
                  <li>log<sub>b</sub>(x/y) = log<sub>b</sub>(x) - log<sub>b</sub>(y)</li>
                  <li>log<sub>b</sub>(x<sup>k</sup>) = k &times; log<sub>b</sub>(x)</li>
                </ul>
              </div>

              <h3>2. Step-by-Step Problem Strategy</h3>
              <div class="example">
                <strong>Standard Method:</strong>
                <ol>
                  <li>Identify the domain constraints and given conditions.</li>
                  <li>Simplify equations by grouping like terms or factoring.</li>
                  <li>Substitute values and verify candidate solutions against the original domain.</li>
                </ol>
              </div>
            </div>
          ''',
          'created_at': DateTime.now().toIso8601String(),
        }
      ];
    }

    // Generic fallback for Chemistry, Biology, English, etc.
    return [
      {
        'id': 'fallback_${sub}_${g}_$u',
        'grade': g,
        'subject': sub,
        'unit_number': u,
        'title': 'Unit $u: Study Guide & Key Points',
        'html_content': '''
          <div class="note-container">
            <h2>Grade $g ${widget.subjectId.toUpperCase()} — Unit $u Notes</h2>
            <div class="callout">
              <strong>Overview:</strong> Comprehensive review notes curated according to the Ethiopian National Curriculum standards.
            </div>

            <h3>1. Fundamental Concepts</h3>
            <p>Review the main principles, classifications, and experimental observations covered in Unit $u.</p>

            <div class="definition">
              <strong>Core Terminology:</strong> Make sure you understand the foundational definitions and their practical applications.
            </div>

            <h3>2. Key Takeaways</h3>
            <ul>
              <li>Understand the relationship between theoretical models and real-world observations.</li>
              <li>Practice standard unit test and national matric sample problems regularly.</li>
              <li>Review the summary tables before taking unit practice quizzes.</li>
            </ul>
          </div>
        ''',
        'created_at': DateTime.now().toIso8601String(),
      }
    ];
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

  Future<void> _toggleOfflineDownload() async {
    final String unitId = _getUnitId();
    if (_isDownloaded) {
      // Remove offline download
      await OfflineManager.removeDownload(unitId);
      setState(() {
        _isDownloaded = false;
      });
      _showFloatingSnackbar(
        widget.languageCode == 'en'
            ? 'Removed from offline storage.'
            : 'ከስልክዎ ማከማቻ ተሰርዟል።',
      );
    } else {
      // Download and cache
      setState(() {
        _isDownloading = true;
      });

      _showFloatingSnackbar(
        widget.languageCode == 'en'
            ? 'Saving note for offline reading...'
            : 'ለስልክዎ ማስታወሻው በማስቀመጥ ላይ...',
        isInfo: true,
      );

      try {
        if (_notesList.isNotEmpty) {
          await OfflineManager.saveOfflineNotes(
            unitId,
            _notesList,
            grade: widget.grade,
            unit: widget.unitNumber,
          );
          await OfflineManager.addDownload(unitId);
        }

        if (mounted) {
          setState(() {
            _isDownloaded = true;
            _isDownloading = false;
          });
          _showFloatingSnackbar(
            widget.languageCode == 'en'
                ? 'Saved offline! You can read anytime without internet.'
                : 'በስኬት ተቀምጧል! ያለ ኢንተርኔት በማንኛውም ጊዜ ማንበብ ይችላሉ።',
            isSuccess: true,
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
          });
          _showFloatingSnackbar(
            widget.languageCode == 'en'
                ? 'Failed to save offline: $e'
                : 'ማስቀመጥ አልተሳካም፡ $e',
            isError: true,
          );
        }
      }
    }
  }

  void _shareNote() {
    if (_noteTitle == null && _htmlContent == null) return;
    final cleanText = _htmlContent?.replaceAll(RegExp(r'<[^>]*>'), ' ').trim() ?? '';
    final shareContent = '📚 ${widget.subjectId.toUpperCase()} Grade ${widget.grade} — Unit ${widget.unitNumber}\n'
        '$_noteTitle\n\n'
        '${cleanText.length > 300 ? cleanText.substring(0, 300) + '...' : cleanText}\n\n'
        'Study with Smart X ET App!';

    Share.share(shareContent, subject: _noteTitle ?? 'Short Notes');
  }

  void _copyToClipboard() {
    final cleanText = _htmlContent?.replaceAll(RegExp(r'<[^>]*>'), ' ').trim() ?? '';
    Clipboard.setData(ClipboardData(text: cleanText));
    _showFloatingSnackbar(
      widget.languageCode == 'en' ? 'Note copied to clipboard!' : 'ማስታወሻው ተገልብጧል!',
      isSuccess: true,
    );
  }

  Map<String, Style> _buildHtmlStyles(bool isDark) {
    final Color textColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B);
    final Color headingColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final Color calloutBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final Color formulaBg = isDark ? const Color(0xFF0F2338) : const Color(0xFFEFF6FF);

    return {
      "body": Style(
        margin: Margins.zero,
        padding: HtmlPaddings.zero,
        fontSize: FontSize(15.5 * _fontScale),
        lineHeight: LineHeight(1.65),
        color: textColor,
        fontFamily: 'Georgia',
      ),
      "h1": Style(
        fontSize: FontSize(22.0 * _fontScale),
        fontWeight: FontWeight.w900,
        color: headingColor,
        margin: Margins.only(top: 18, bottom: 12),
        fontFamily: 'Georgia',
      ),
      "h2": Style(
        fontSize: FontSize(19.0 * _fontScale),
        fontWeight: FontWeight.w800,
        color: widget.themeColor,
        margin: Margins.only(top: 16, bottom: 10),
        fontFamily: 'Georgia',
      ),
      "h3": Style(
        fontSize: FontSize(16.5 * _fontScale),
        fontWeight: FontWeight.w700,
        color: headingColor,
        margin: Margins.only(top: 14, bottom: 8),
        fontFamily: 'Georgia',
      ),
      "p": Style(
        margin: Margins.only(bottom: 12),
        lineHeight: LineHeight(1.65),
      ),
      "ul": Style(
        margin: Margins.only(left: 12, bottom: 14),
        padding: HtmlPaddings.only(left: 12),
      ),
      "ol": Style(
        margin: Margins.only(left: 12, bottom: 14),
        padding: HtmlPaddings.only(left: 12),
      ),
      "li": Style(
        margin: Margins.only(bottom: 6),
        lineHeight: LineHeight(1.5),
      ),
      "strong": Style(
        fontWeight: FontWeight.w800,
        color: headingColor,
      ),
      "em": Style(
        fontStyle: FontStyle.italic,
      ),
      "table": Style(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border.all(color: borderColor, width: 1.0),
        margin: Margins.symmetric(vertical: 14),
      ),
      "th": Style(
        backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
        padding: HtmlPaddings.symmetric(horizontal: 10, vertical: 8),
        fontWeight: FontWeight.w800,
        color: headingColor,
        border: Border.all(color: borderColor, width: 0.8),
      ),
      "td": Style(
        padding: HtmlPaddings.symmetric(horizontal: 10, vertical: 8),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      "code": Style(
        backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        color: widget.themeColor,
        fontFamily: 'monospace',
        padding: HtmlPaddings.symmetric(horizontal: 6, vertical: 2),
      ),
      ".callout": Style(
        backgroundColor: calloutBg,
        border: Border(left: BorderSide(color: widget.themeColor, width: 4.0)),
        padding: HtmlPaddings.all(14),
        margin: Margins.symmetric(vertical: 14),
      ),
      ".formula": Style(
        backgroundColor: formulaBg,
        border: Border.all(color: widget.themeColor.withValues(alpha: 0.35), width: 1.2),
        padding: HtmlPaddings.all(14),
        margin: Margins.symmetric(vertical: 14),
      ),
      ".definition": Style(
        backgroundColor: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
        border: Border(left: BorderSide(color: const Color(0xFF10B981), width: 4.0)),
        padding: HtmlPaddings.all(14),
        margin: Margins.symmetric(vertical: 14),
      ),
      ".example": Style(
        backgroundColor: isDark ? const Color(0xFF28241D) : const Color(0xFFFEF9C3),
        border: Border(left: BorderSide(color: const Color(0xFFF59E0B), width: 4.0)),
        padding: HtmlPaddings.all(14),
        margin: Margins.symmetric(vertical: 14),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark || widget.isDarkMode;
    final Color bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final Color cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${widget.subjectId.toUpperCase()} • Unit ${widget.unitNumber}",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: widget.themeColor,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _noteTitle ?? widget.unitTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ],
        ),
        actions: [
          // Offline Download Toggle
          IconButton(
            icon: _isDownloading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : Icon(
                    _isDownloaded ? Icons.download_done_rounded : Icons.download_rounded,
                    color: _isDownloaded ? const Color(0xFF10B981) : textColor,
                    size: 22,
                  ),
            tooltip: _isDownloaded ? "Saved Offline" : "Save Offline",
            onPressed: _toggleOfflineDownload,
          ),

          // Bookmark Toggle
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: _isBookmarked ? const Color(0xFFFFB703) : textColor,
              size: 22,
            ),
            tooltip: "Bookmark",
            onPressed: _toggleBookmark,
          ),

          // Share
          IconButton(
            icon: const Icon(Icons.share_rounded, size: 20),
            tooltip: "Share",
            onPressed: _shareNote,
          ),

          // Search in note toggle
          IconButton(
            icon: Icon(
              _isSearchOpen ? Icons.close_rounded : Icons.search_rounded,
              size: 22,
            ),
            tooltip: "Search in note",
            onPressed: () {
              setState(() {
                _isSearchOpen = !_isSearchOpen;
                if (!_isSearchOpen) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Search Bar if toggled
          if (_isSearchOpen)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, size: 20, color: Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: TextStyle(color: textColor, fontSize: 14),
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

          // Sub-topic / Module Pills if multiple notes exist
          if (_notesList.length > 1)
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _notesList.length,
                itemBuilder: (context, idx) {
                  final isSelected = idx == _selectedNoteIndex;
                  final title = _notesList[idx]['title']?.toString() ?? 'Section ${idx + 1}';
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: widget.themeColor,
                      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _applySelectedNote(idx);
                          });
                        }
                      },
                    ),
                  );
                },
              ),
            ),

          // Main Content View
          Expanded(
            child: _buildMainContent(isDark, cardBg, textColor, subColor),
          ),

          // Bottom Quick Bar (Font Size Adjuster + Copy text)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Font Size Scaler
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Aa",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: subColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.text_decrease_rounded, size: 18),
                        visualDensity: VisualDensity.compact,
                        tooltip: "Decrease text size",
                        onPressed: _fontScale > 0.85
                            ? () {
                                setState(() {
                                  _fontScale = (_fontScale - 0.1).clamp(0.85, 1.45);
                                });
                              }
                            : null,
                      ),
                      Text(
                        "${(_fontScale * 100).toInt()}%",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      IconButton(
                        icon: const Icon(Icons.text_increase_rounded, size: 18),
                        visualDensity: VisualDensity.compact,
                        tooltip: "Increase text size",
                        onPressed: _fontScale < 1.45
                            ? () {
                                setState(() {
                                  _fontScale = (_fontScale + 0.1).clamp(0.85, 1.45);
                                });
                              }
                            : null,
                      ),
                    ],
                  ),

                  // Copy Note & Quick Action
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        onPressed: _copyToClipboard,
                        icon: const Icon(Icons.content_copy_rounded, size: 15),
                        label: Text(
                          widget.languageCode == 'en' ? "Copy Text" : "ጽሑፉን ቅዳ",
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: widget.themeColor,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(bool isDark, Color cardBg, Color textColor, Color subColor) {
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

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _errorType == NotesErrorType.noInternet
                    ? Icons.wifi_off_rounded
                    : Icons.menu_book_outlined,
                size: 56,
                color: widget.themeColor,
              ),
              const SizedBox(height: 16),
              Text(
                _errorType == NotesErrorType.noInternet
                    ? (widget.languageCode == 'en'
                        ? "No internet connection"
                        : "የኢንተርኔት ግንኙነት የለም")
                    : (widget.languageCode == 'en'
                        ? "No notes found for this unit"
                        : "ለዚህ ክፍል ማስታወሻ አልተገኘም"),
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.languageCode == 'en'
                    ? "You can retry or access offline study materials."
                    : "እንደገና መሞከር ወይም የተቀመጡ ማስታወሻዎችን ማንበብ ይችላሉ።",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: subColor),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchNotes,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(widget.languageCode == 'en' ? "Retry" : "እንደገና ሞክር"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.themeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final renderedHtml = _htmlContent ?? '<p>No content available</p>';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFEDF2F7),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Subject & Grade Header Tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.themeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "GRADE ${widget.grade} • ${_getNormalizedSubjectName().toUpperCase()}",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: widget.themeColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (_isDownloaded)
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Text(
                          "Offline Ready",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF065F46),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Rich HTML Content rendered dynamically with flutter_html
              Html(
                data: renderedHtml,
                style: _buildHtmlStyles(isDark),
              ),

              const SizedBox(height: 30),
              Divider(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                thickness: 1,
              ),
              const SizedBox(height: 16),

              // End of Note Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Smart X ET • Educational Notes",
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: subColor,
                    ),
                  ),
                  InkWell(
                    onTap: _shareNote,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.share_rounded, size: 14, color: widget.themeColor),
                          const SizedBox(width: 4),
                          Text(
                            widget.languageCode == 'en' ? "Share Note" : "አጋራ",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: widget.themeColor,
                            ),
                          ),
                        ],
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
}
